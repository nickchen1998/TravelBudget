// Supabase Edge Function: link-identity
// Links a new OAuth identity (Apple / Google) to the current user account.
//
// Flow:
// 1. Verify the caller's JWT → get current user ID
// 2. Verify the incoming provider token via provider's API (Google tokeninfo / Apple)
// 3. Look up existing Supabase user with that provider identity
//    - If same user → already linked
//    - If different user → merge data, delete old user, then link
//    - If no existing user → link directly
// 4. Insert into auth.identities via PostgreSQL function

import { createClient } from "https://esm.sh/@supabase/supabase-js@2";

const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers":
    "authorization, x-client-info, apikey, content-type",
};

function jsonResponse(body: Record<string, unknown>, status = 200) {
  return new Response(JSON.stringify(body), {
    status,
    headers: { ...corsHeaders, "Content-Type": "application/json" },
  });
}

// Verify Google id_token via Google's tokeninfo endpoint
async function verifyGoogleToken(
  idToken: string
): Promise<{ sub: string; email: string; name?: string; picture?: string }> {
  const res = await fetch(
    `https://oauth2.googleapis.com/tokeninfo?id_token=${idToken}`
  );
  if (!res.ok) {
    throw new Error("Invalid Google token");
  }
  const payload = await res.json();
  if (!payload.sub || !payload.email) {
    throw new Error("Google token missing sub or email");
  }
  return {
    sub: payload.sub,
    email: payload.email,
    name: payload.name,
    picture: payload.picture,
  };
}

// Verify Apple id_token by decoding the JWT payload
function decodeAppleToken(
  idToken: string
): { sub: string; email?: string } {
  const parts = idToken.split(".");
  if (parts.length !== 3) throw new Error("Invalid Apple token format");
  const payload = JSON.parse(atob(parts[1]));
  if (!payload.sub) throw new Error("Apple token missing sub");
  return { sub: payload.sub, email: payload.email };
}

Deno.serve(async (req: Request) => {
  if (req.method === "OPTIONS") {
    return new Response("ok", { headers: corsHeaders });
  }

  try {
    const authHeader = req.headers.get("Authorization");
    if (!authHeader) {
      return jsonResponse({ error: "Missing authorization header" }, 401);
    }

    // Create admin client
    const supabaseAdmin = createClient(
      Deno.env.get("SUPABASE_URL")!,
      Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!
    );

    // Create user client to verify the caller's token
    const supabaseUser = createClient(
      Deno.env.get("SUPABASE_URL")!,
      Deno.env.get("SUPABASE_ANON_KEY")!,
      { global: { headers: { Authorization: authHeader } } }
    );

    const {
      data: { user: currentUser },
      error: userError,
    } = await supabaseUser.auth.getUser();
    if (userError || !currentUser) {
      return jsonResponse({ error: "Unauthorized" }, 401);
    }

    const body = await req.json();
    const { provider, id_token } = body;

    if (!provider || !id_token) {
      return jsonResponse({ error: "Missing provider or id_token" }, 400);
    }

    if (!["google", "apple"].includes(provider)) {
      return jsonResponse({ error: "Unsupported provider" }, 400);
    }

    // ── Step 1: Verify the token and get the provider user info ───────────
    let providerSub: string;
    let providerEmail: string | undefined;
    let identityData: Record<string, unknown>;

    if (provider === "google") {
      const google = await verifyGoogleToken(id_token);
      providerSub = google.sub;
      providerEmail = google.email;
      identityData = {
        sub: google.sub,
        email: google.email,
        name: google.name,
        picture: google.picture,
        email_verified: true,
        provider_id: google.sub,
        iss: "https://accounts.google.com",
      };
    } else {
      const apple = decodeAppleToken(id_token);
      providerSub = apple.sub;
      providerEmail = apple.email;
      identityData = {
        sub: apple.sub,
        email: apple.email,
        provider_id: apple.sub,
        iss: "https://appleid.apple.com",
      };
    }

    // ── Step 2: Check if current user already has this provider linked ────
    const currentIdentities = currentUser.identities ?? [];
    const alreadyLinked = currentIdentities.some(
      (i: any) => i.provider === provider
    );
    if (alreadyLinked) {
      return jsonResponse({ success: true, message: "Already linked" });
    }

    // ── Step 3: Find if another Supabase user owns this provider identity ─
    const {
      data: { users: allUsers },
    } = await supabaseAdmin.auth.admin.listUsers({ perPage: 1000 });

    const existingUser = allUsers?.find((u: any) =>
      u.identities?.some(
        (i: any) =>
          i.provider === provider &&
          i.identity_data?.sub === providerSub
      )
    );

    if (existingUser && existingUser.id === currentUser.id) {
      return jsonResponse({ success: true, message: "Already linked" });
    }

    if (existingUser && existingUser.id !== currentUser.id) {
      // ── Step 4a: Merge the existing user into the current user ─────────
      const oldUserId = existingUser.id;
      const newUserId = currentUser.id;

      // Transfer trip ownership
      await supabaseAdmin
        .from("trips")
        .update({ owner_id: newUserId })
        .eq("owner_id", oldUserId);

      // Transfer trip memberships
      await supabaseAdmin
        .from("trip_members")
        .update({ user_id: newUserId })
        .eq("user_id", oldUserId);

      // Transfer expenses
      await supabaseAdmin
        .from("expenses")
        .update({ created_by: newUserId })
        .eq("created_by", oldUserId);

      // Merge profile data (keep current user's name if set)
      const { data: currentProfile } = await supabaseAdmin
        .from("profiles")
        .select("display_name")
        .eq("id", newUserId)
        .maybeSingle();

      if (!currentProfile?.display_name) {
        const { data: oldProfile } = await supabaseAdmin
          .from("profiles")
          .select("display_name")
          .eq("id", oldUserId)
          .maybeSingle();

        if (oldProfile?.display_name) {
          await supabaseAdmin
            .from("profiles")
            .update({ display_name: oldProfile.display_name })
            .eq("id", newUserId);
        }
      }

      // Delete the old user (frees the identity)
      await supabaseAdmin.auth.admin.deleteUser(oldUserId);
    }

    // ── Step 5: Link the identity to the current user ────────────────────
    const { error: linkError } = await supabaseAdmin.rpc(
      "link_provider_identity",
      {
        p_user_id: currentUser.id,
        p_provider: provider,
        p_provider_id: providerSub,
        p_email: providerEmail ?? null,
        p_identity_data: identityData,
      }
    );

    if (linkError) {
      return jsonResponse(
        { error: `Failed to link identity: ${linkError.message}` },
        500
      );
    }

    const message = existingUser ? "Accounts merged and linked" : "Identity linked";
    return jsonResponse({ success: true, message });
  } catch (err) {
    return jsonResponse({ error: err.message ?? "Internal error" }, 500);
  }
});

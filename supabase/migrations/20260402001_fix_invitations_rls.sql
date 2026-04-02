-- 1.1 刪除 trip_invitations 過度開放的 SELECT policy
-- invitations_select_by_token 允許任何已登入用戶用 WHERE true 讀取所有邀請
-- accept_invitation 是 SECURITY DEFINER RPC，不需要呼叫者有 SELECT 權限

-- 注意：同表還有 invitations_select（限制 invited_by = uid OR owner），這個保留
DROP POLICY IF EXISTS "invitations_select_by_token" ON trip_invitations;

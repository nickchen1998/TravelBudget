-- ─────────────────────────────────────────────────────────────────────────────
-- 改版：免費與付費功能完全相同，只差雲端旅行數量（免費 3 / 付費 20）
--
-- 1. 放寬 check_trip_limit：免費 5 → 3（grandfathered，不刪除舊資料）
-- 2. 移除分帳的付費限制（check_split_premium_trigger）
-- 3. 移除建立邀請碼的付費限制（check_invitation_premium_trigger）
-- ─────────────────────────────────────────────────────────────────────────────

-- 1. 降低免費上限到 3
CREATE OR REPLACE FUNCTION public.check_trip_limit()
  RETURNS trigger
  LANGUAGE plpgsql
  SECURITY DEFINER
AS $function$
DECLARE
  trip_count INTEGER;
  user_premium BOOLEAN;
  max_trips INTEGER;
BEGIN
  SELECT COALESCE(is_premium, FALSE) INTO user_premium
    FROM profiles
    WHERE id = NEW.owner_id;

  max_trips := CASE WHEN user_premium THEN 20 ELSE 3 END;

  SELECT COUNT(*) INTO trip_count
    FROM trips
    WHERE owner_id = NEW.owner_id;

  IF trip_count >= max_trips THEN
    RAISE EXCEPTION 'TRIP_LIMIT_EXCEEDED'
      USING ERRCODE = 'P0001',
            DETAIL = format('{"code": "TRIP_LIMIT_EXCEEDED", "limit": %s}', max_trips);
  END IF;

  RETURN NEW;
END;
$function$;

-- 2. 移除分帳 premium trigger
DROP TRIGGER IF EXISTS check_split_premium_trigger ON public.trips;
DROP FUNCTION IF EXISTS public.check_split_premium();

-- 3. 移除邀請碼 premium trigger
DROP TRIGGER IF EXISTS check_invitation_premium_trigger ON public.trip_invitations;
DROP FUNCTION IF EXISTS public.check_invitation_premium();

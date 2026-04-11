-- ─────────────────────────────────────────────────────────────────────────────
-- 收緊免費方案：
--   1. 免費版雲端旅行上限從 10 降到 5（付費維持 20）
--   2. 將「分帳」與「建立協作邀請」移到付費方案
--   3. 對既有已建立 >5 個旅行的免費用戶做 grandfathering：
--      不刪除任何旅行，只是阻止他們繼續「新建」超過現有數量
-- ─────────────────────────────────────────────────────────────────────────────

-- ── 1. 更新 check_trip_limit: 免費 5 / 付費 20（grandfathered）──────────────
-- 當免費用戶已擁有 >= 5 筆旅行時，會直接擋下新增（不刪除舊的）
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

  max_trips := CASE WHEN user_premium THEN 20 ELSE 5 END;

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

-- ── 2. 「開啟分帳」僅限付費用戶 ─────────────────────────────────────────────
-- 針對 trips.split_enabled 的 INSERT/UPDATE 檢查 owner 是否為付費用戶
-- 既有已開啟分帳的旅行不受影響（trigger 只在 split_enabled = true 時檢查）
CREATE OR REPLACE FUNCTION public.check_split_premium()
  RETURNS trigger
  LANGUAGE plpgsql
  SECURITY DEFINER
AS $function$
DECLARE
  owner_premium BOOLEAN;
BEGIN
  -- 只在「從 false/null 變成 true」時檢查
  IF COALESCE(NEW.split_enabled, FALSE) = TRUE
     AND COALESCE(OLD.split_enabled, FALSE) = FALSE THEN
    SELECT COALESCE(is_premium, FALSE) INTO owner_premium
      FROM profiles
      WHERE id = NEW.owner_id;

    IF NOT owner_premium THEN
      RAISE EXCEPTION 'SPLIT_REQUIRES_PREMIUM'
        USING ERRCODE = 'P0001',
              DETAIL = '{"code": "SPLIT_REQUIRES_PREMIUM"}';
    END IF;
  END IF;

  RETURN NEW;
END;
$function$;

DROP TRIGGER IF EXISTS check_split_premium_trigger ON public.trips;
CREATE TRIGGER check_split_premium_trigger
  BEFORE INSERT OR UPDATE OF split_enabled ON public.trips
  FOR EACH ROW
  EXECUTE FUNCTION public.check_split_premium();

-- ── 3. 「建立邀請碼」僅限付費用戶 ────────────────────────────────────────────
-- 免費用戶仍可以透過邀請碼「加入」他人旅行（不動 accept_invitation 邏輯）
-- 但無法自行建立新的 invitation
CREATE OR REPLACE FUNCTION public.check_invitation_premium()
  RETURNS trigger
  LANGUAGE plpgsql
  SECURITY DEFINER
AS $function$
DECLARE
  inviter_premium BOOLEAN;
BEGIN
  SELECT COALESCE(is_premium, FALSE) INTO inviter_premium
    FROM profiles
    WHERE id = NEW.invited_by;

  IF NOT inviter_premium THEN
    RAISE EXCEPTION 'INVITE_REQUIRES_PREMIUM'
      USING ERRCODE = 'P0001',
            DETAIL = '{"code": "INVITE_REQUIRES_PREMIUM"}';
  END IF;

  RETURN NEW;
END;
$function$;

DROP TRIGGER IF EXISTS check_invitation_premium_trigger ON public.trip_invitations;
CREATE TRIGGER check_invitation_premium_trigger
  BEFORE INSERT ON public.trip_invitations
  FOR EACH ROW
  EXECUTE FUNCTION public.check_invitation_premium();

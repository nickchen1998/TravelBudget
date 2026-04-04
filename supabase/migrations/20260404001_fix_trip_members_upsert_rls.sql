-- 修復 trip_members SELECT RLS policy
-- 問題：upsert 需要 SELECT 權限檢查衝突，但新旅行的 owner 尚未在 trip_members 中，
-- is_trip_member() 回傳 false → upsert 整體 403 失敗。
-- 修復：允許旅行 owner 也能 SELECT trip_members（即使自己還不在裡面）。

DROP POLICY IF EXISTS trip_members_select ON trip_members;

CREATE POLICY trip_members_select ON trip_members
  FOR SELECT USING (
    is_trip_member(trip_id)
    OR EXISTS (
      SELECT 1 FROM trips t
      WHERE t.id = trip_members.trip_id AND t.owner_id = auth.uid()
    )
  );

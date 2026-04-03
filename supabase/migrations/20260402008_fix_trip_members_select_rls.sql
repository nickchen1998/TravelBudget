-- 修復：協作者在成員頁面無法看到擁有者或其他成員
-- 使用 is_trip_member() SECURITY DEFINER 函式避免 RLS 遞迴
-- （直接在 policy 裡子查詢 trip_members 會觸發 infinite recursion）

DROP POLICY IF EXISTS "trip_members_select" ON trip_members;

CREATE POLICY "trip_members_select"
  ON trip_members
  FOR SELECT
  TO authenticated
  USING (is_trip_member(trip_id));

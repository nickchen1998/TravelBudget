-- 修復：協作者在成員頁面無法看到擁有者或其他成員
-- 現有 policy: user_id = auth.uid() OR owner_id = auth.uid()
-- 問題：協作者只看到自己那一筆，看不到其他人
-- 修正：同旅行的成員可以互相看到

DROP POLICY IF EXISTS "trip_members_select" ON trip_members;

CREATE POLICY "trip_members_select"
  ON trip_members
  FOR SELECT
  TO authenticated
  USING (
    trip_id IN (
      SELECT tm.trip_id FROM trip_members tm WHERE tm.user_id = auth.uid()
    )
  );

-- 1.2 修復 profiles SELECT policy 洩露 email
-- 現有 profiles_select 使用 USING (true)，任何登入用戶可查所有人 email
-- 改為：自己可讀完整 profile；同旅行成員可讀（透過 trip_members 關聯）

DROP POLICY IF EXISTS "profiles_select" ON profiles;

CREATE POLICY "profiles_select"
  ON profiles
  FOR SELECT
  TO authenticated
  USING (
    id = auth.uid()
    OR id IN (
      SELECT tm.user_id FROM trip_members tm
      WHERE tm.trip_id IN (
        SELECT tm2.trip_id FROM trip_members tm2 WHERE tm2.user_id = auth.uid()
      )
    )
  );

-- 1.2 修復 profiles SELECT policy 洩露 email
-- 改為只能讀取自己的 profile；協作者名稱透過 view 取得（僅 display_name）

DROP POLICY IF EXISTS "Users can view all profiles" ON profiles;
DROP POLICY IF EXISTS "Public profiles are viewable by everyone" ON profiles;

-- 只允許讀取自己的完整 profile
CREATE POLICY "users_can_view_own_profile"
  ON profiles
  FOR SELECT
  TO authenticated
  USING (id = auth.uid());

-- 建立只暴露 id + display_name 的 View（供成員列表使用）
CREATE OR REPLACE VIEW public.member_profiles AS
  SELECT p.id, p.display_name
  FROM profiles p
  WHERE p.id IN (
    SELECT tm.user_id FROM trip_members tm
    WHERE tm.trip_id IN (
      SELECT tm2.trip_id FROM trip_members tm2 WHERE tm2.user_id = auth.uid()
    )
  );

GRANT SELECT ON public.member_profiles TO authenticated;

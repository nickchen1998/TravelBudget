-- 1.1 刪除 invitations 過度開放的 SELECT policy
-- 任何登入用戶都能列舉所有邀請記錄，但 accept_invitation 是 SECURITY DEFINER，不需要呼叫者有 SELECT 權限

DROP POLICY IF EXISTS "invitations_select_by_token" ON invitations;
DROP POLICY IF EXISTS "Allow users to read invitations by token" ON invitations;

-- 為旅行擁有者保留限縮的 SELECT policy（管理邀請碼）
CREATE POLICY "owners_can_view_own_trip_invitations"
  ON invitations
  FOR SELECT
  TO authenticated
  USING (
    trip_id IN (
      SELECT id FROM trips WHERE owner_id = auth.uid()
    )
  );

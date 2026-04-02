-- 2.5 expenses RLS 明確指定 authenticated 角色
-- 防止 anon 用戶在邊緣情況下意外存取

-- 重建所有 expenses policies，確保都有 TO authenticated

DROP POLICY IF EXISTS "expenses_select_policy" ON expenses;
DROP POLICY IF EXISTS "expenses_insert_policy" ON expenses;
DROP POLICY IF EXISTS "expenses_update_policy" ON expenses;
DROP POLICY IF EXISTS "expenses_delete_policy" ON expenses;
DROP POLICY IF EXISTS "Users can view expenses of their trips" ON expenses;
DROP POLICY IF EXISTS "Users can insert expenses to their trips" ON expenses;
DROP POLICY IF EXISTS "Users can update expenses of their trips" ON expenses;
DROP POLICY IF EXISTS "Users can delete expenses of their trips" ON expenses;

CREATE POLICY "expenses_select_policy"
  ON expenses
  FOR SELECT
  TO authenticated
  USING (
    trip_id IN (
      SELECT trip_id FROM trip_members WHERE user_id = auth.uid()
    )
  );

CREATE POLICY "expenses_insert_policy"
  ON expenses
  FOR INSERT
  TO authenticated
  WITH CHECK (
    trip_id IN (
      SELECT trip_id FROM trip_members
      WHERE user_id = auth.uid() AND role IN ('owner', 'editor')
    )
  );

CREATE POLICY "expenses_update_policy"
  ON expenses
  FOR UPDATE
  TO authenticated
  USING (
    trip_id IN (
      SELECT trip_id FROM trip_members
      WHERE user_id = auth.uid() AND role IN ('owner', 'editor')
    )
  );

CREATE POLICY "expenses_delete_policy"
  ON expenses
  FOR DELETE
  TO authenticated
  USING (
    trip_id IN (
      SELECT trip_id FROM trip_members
      WHERE user_id = auth.uid() AND role IN ('owner', 'editor')
    )
  );

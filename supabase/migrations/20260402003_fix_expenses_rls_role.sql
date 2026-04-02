-- 2.5 expenses RLS 明確指定 authenticated 角色
-- 現有 policy 名稱：expenses_select, expenses_insert, expenses_update, expenses_delete
-- 透過 trips 表 JOIN 判斷權限，但未指定 TO authenticated
-- 重建所有 policy 加上 TO authenticated，並改為直接用 trip_members 判斷

DROP POLICY IF EXISTS "expenses_select" ON expenses;
DROP POLICY IF EXISTS "expenses_insert" ON expenses;
DROP POLICY IF EXISTS "expenses_update" ON expenses;
DROP POLICY IF EXISTS "expenses_delete" ON expenses;

CREATE POLICY "expenses_select"
  ON expenses
  FOR SELECT
  TO authenticated
  USING (
    trip_id IN (
      SELECT trip_id FROM trip_members WHERE user_id = auth.uid()
    )
  );

CREATE POLICY "expenses_insert"
  ON expenses
  FOR INSERT
  TO authenticated
  WITH CHECK (
    trip_id IN (
      SELECT trip_id FROM trip_members
      WHERE user_id = auth.uid() AND role IN ('owner', 'editor')
    )
  );

CREATE POLICY "expenses_update"
  ON expenses
  FOR UPDATE
  TO authenticated
  USING (
    trip_id IN (
      SELECT trip_id FROM trip_members
      WHERE user_id = auth.uid() AND role IN ('owner', 'editor')
    )
  );

CREATE POLICY "expenses_delete"
  ON expenses
  FOR DELETE
  TO authenticated
  USING (
    trip_id IN (
      SELECT trip_id FROM trip_members
      WHERE user_id = auth.uid() AND role IN ('owner', 'editor')
    )
  );

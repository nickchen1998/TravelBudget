-- 3.2 修復 Storage RLS 允許協作者上傳旅行封面
-- 現有 policy 用 auth.uid() = foldername[1] 限制只能上傳到自己的資料夾
-- 協作者 userId 跟擁有者不同，導致上傳失敗
-- 改為：trip_members 中 role 為 owner 或 editor 的成員都可上傳

-- 路徑格式：{userId}/{tripUuid}.webp
-- split_part(name, '/', 2) → '{tripUuid}.webp'
-- regexp_replace(..., '\.webp$', '') → '{tripUuid}'

DROP POLICY IF EXISTS "users can upload trip covers" ON storage.objects;
DROP POLICY IF EXISTS "users can update own trip covers" ON storage.objects;

-- 允許旅行成員（owner + editor）上傳封面
CREATE POLICY "trip_members_can_upload_cover"
  ON storage.objects
  FOR INSERT
  TO authenticated
  WITH CHECK (
    bucket_id = 'trip-covers'
    AND EXISTS (
      SELECT 1 FROM trip_members
      WHERE trip_id = regexp_replace(split_part(name, '/', 2), '\.webp$', '')::uuid
        AND user_id = auth.uid()
        AND role IN ('owner', 'editor')
    )
  );

-- 允許旅行成員更新（upsert）封面
CREATE POLICY "trip_members_can_update_cover"
  ON storage.objects
  FOR UPDATE
  TO authenticated
  USING (
    bucket_id = 'trip-covers'
    AND EXISTS (
      SELECT 1 FROM trip_members
      WHERE trip_id = regexp_replace(split_part(name, '/', 2), '\.webp$', '')::uuid
        AND user_id = auth.uid()
        AND role IN ('owner', 'editor')
    )
  );

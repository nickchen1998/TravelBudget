-- 3.2 修復 Storage RLS 允許協作者上傳旅行封面
-- 路徑格式：{userId}/{tripUuid}.webp

DROP POLICY IF EXISTS "Users can upload their own trip covers" ON storage.objects;
DROP POLICY IF EXISTS "Anyone can view trip covers" ON storage.objects;

-- 允許旅行成員（owner + editor）上傳封面
CREATE POLICY "trip_members_can_upload_cover"
  ON storage.objects
  FOR INSERT
  TO authenticated
  WITH CHECK (
    bucket_id = 'trip-covers'
    AND EXISTS (
      SELECT 1 FROM trip_members
      WHERE trip_id = regexp_replace(split_part(name, '/', 2), '\.webp$', '')
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
      WHERE trip_id = regexp_replace(split_part(name, '/', 2), '\.webp$', '')
        AND user_id = auth.uid()
        AND role IN ('owner', 'editor')
    )
  );

-- 公開讀取封面圖片（已有 public URL）
CREATE POLICY "public_trip_covers_read"
  ON storage.objects
  FOR SELECT
  TO public
  USING (bucket_id = 'trip-covers');

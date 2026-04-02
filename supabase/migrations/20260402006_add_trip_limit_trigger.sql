-- 2.2 雲端旅行數量上限（每用戶最多 10 個）
-- 僅限制雲端旅行；本地旅行不受影響

CREATE OR REPLACE FUNCTION check_trip_limit()
RETURNS TRIGGER AS $$
DECLARE
  trip_count INTEGER;
BEGIN
  SELECT COUNT(*) INTO trip_count
    FROM trips
    WHERE owner_id = NEW.owner_id;

  IF trip_count >= 10 THEN
    RAISE EXCEPTION 'TRIP_LIMIT_EXCEEDED'
      USING ERRCODE = 'P0001',
            DETAIL = '{"code": "TRIP_LIMIT_EXCEEDED", "limit": 10}';
  END IF;

  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

CREATE TRIGGER check_trip_limit_trigger
  BEFORE INSERT ON trips
  FOR EACH ROW
  EXECUTE FUNCTION check_trip_limit();

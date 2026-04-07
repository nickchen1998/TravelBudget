-- Add is_premium column to profiles
ALTER TABLE public.profiles ADD COLUMN is_premium BOOLEAN NOT NULL DEFAULT FALSE;

-- Update check_trip_limit trigger to support 20 trips for premium users
CREATE OR REPLACE FUNCTION public.check_trip_limit()
  RETURNS trigger
  LANGUAGE plpgsql
  SECURITY DEFINER
AS $function$
DECLARE
  trip_count INTEGER;
  user_premium BOOLEAN;
  max_trips INTEGER;
BEGIN
  -- Check if user is premium
  SELECT COALESCE(is_premium, FALSE) INTO user_premium
    FROM profiles
    WHERE id = NEW.owner_id;

  -- Set limit based on premium status
  max_trips := CASE WHEN user_premium THEN 20 ELSE 10 END;

  SELECT COUNT(*) INTO trip_count
    FROM trips
    WHERE owner_id = NEW.owner_id;

  IF trip_count >= max_trips THEN
    RAISE EXCEPTION 'TRIP_LIMIT_EXCEEDED'
      USING ERRCODE = 'P0001',
            DETAIL = format('{"code": "TRIP_LIMIT_EXCEEDED", "limit": %s}', max_trips);
  END IF;

  RETURN NEW;
END;
$function$;

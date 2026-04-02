-- 2.1 欄位長度限制
-- 防止攻擊者塞超長字串填滿 500MB 免費配額

-- trips 表
ALTER TABLE trips
  ADD CONSTRAINT trips_name_length CHECK (char_length(name) <= 50),
  ADD CONSTRAINT trips_base_currency_format CHECK (char_length(base_currency) = 3),
  ADD CONSTRAINT trips_target_currency_format CHECK (char_length(target_currency) = 3),
  ADD CONSTRAINT trips_cover_url_length CHECK (char_length(cover_image_url) <= 500);

-- expenses 表
ALTER TABLE expenses
  ADD CONSTRAINT expenses_title_length CHECK (char_length(title) <= 50),
  ADD CONSTRAINT expenses_note_length CHECK (char_length(note) <= 200),
  ADD CONSTRAINT expenses_currency_format CHECK (char_length(currency) = 3);

-- profiles 表
ALTER TABLE profiles
  ADD CONSTRAINT profiles_display_name_length CHECK (char_length(display_name) <= 50);

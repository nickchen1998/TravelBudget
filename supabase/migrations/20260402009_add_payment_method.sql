-- 新增支付方式欄位（nullable，向後相容）
-- 既有 51 筆消費資料的 payment_method 保持 null
ALTER TABLE expenses ADD COLUMN payment_method TEXT;

-- 長度限制
ALTER TABLE expenses
  ADD CONSTRAINT expenses_payment_method_length
    CHECK (payment_method IS NULL OR char_length(payment_method) <= 20);

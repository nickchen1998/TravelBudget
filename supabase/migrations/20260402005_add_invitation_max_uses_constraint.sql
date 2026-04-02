-- 2.4 邀請 max_uses 上限（最大 20）
-- 防止邀請碼被公開散布，大量用戶加入

-- 先將超過上限的現有記錄修正
UPDATE invitations SET max_uses = 20 WHERE max_uses > 20;

ALTER TABLE invitations
  ADD CONSTRAINT invitations_max_uses_range
    CHECK (max_uses >= 1 AND max_uses <= 20);

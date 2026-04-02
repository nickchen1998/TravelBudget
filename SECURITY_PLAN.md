# 熊好算 TravelBudget — 安全與用量防護方案

> 版本：1.0 | 日期：2026-04-02

---

## 目錄

1. [整體架構說明](#整體架構說明)
2. [修復項目一覽](#修復項目一覽)
3. [🔴 高風險 — RLS Policy 修復](#高風險--rls-policy-修復)
   - [1.1 invitations_select_by_token 過度開放](#11-invitations_select_by_token-過度開放)
   - [1.2 profiles 表 SELECT policy 洩露 email](#12-profiles-表-select-policy-洩露-email)
4. [🟠 中風險 — 用量限制](#中風險--用量限制)
   - [2.1 欄位長度限制](#21-欄位長度限制)
   - [2.2 雲端旅行數量上限](#22-雲端旅行數量上限)
   - [2.3 雲端消費筆數上限](#23-雲端消費筆數上限)
   - [2.4 邀請 max_uses 上限](#24-邀請-max_uses-上限)
   - [2.5 expenses RLS 缺少角色限制](#25-expenses-rls-缺少角色限制)
5. [🟡 其他問題 — 圖片處理](#其他問題--圖片處理)
   - [3.1 協作者上傳圖片失敗靜默清除 URL](#31-協作者上傳圖片失敗靜默清除-url)
   - [3.2 Storage RLS 拒絕協作者上傳](#32-storage-rls-拒絕協作者上傳)
6. [UX 設計規範](#ux-設計規範)
7. [修改檔案總覽](#修改檔案總覽)
8. [執行順序建議](#執行順序建議)

---

## 整體架構說明

本方案基於以下專案架構進行設計：

- **前端**：Flutter + Provider，資料存取透過 `TripRepository` / `ExpenseRepository`，UI 層在 `screens/` 與 `providers/`
- **後端**：Supabase（PostgreSQL + RLS + Edge Functions）
- **混合架構**：本地 SQLite（離線優先）+ Supabase 雲端同步
- **用量限制原則**：**僅針對同步到雲端的旅行**；手機本地旅行（`uuid == null`）不受限制

### 用量上限設定依據

| 項目 | 建議上限 | 理由 |
|------|---------|------|
| 雲端旅行數 | **10 個** | 一般使用者一年出遊 2–5 次；超過 10 趟屬重度使用，限制可防止儲存濫用 |
| 每趟旅行消費筆數 | **200 筆** | 14 天行程每天 14 筆已屬高頻；200 筆可涵蓋 2–3 週長途旅行 |
| 邀請 max_uses | **20 人** | 家庭/小型旅遊團成員數，防止公開散布邀請碼 |

---

## 修復項目一覽

| # | 風險等級 | 問題 | 影響 |
|---|---------|------|------|
| 1.1 | 🔴 高 | `invitations` SELECT policy 過度開放 | 任何登入用戶可列舉所有邀請記錄 |
| 1.2 | 🔴 高 | `profiles` SELECT policy 洩露 email | 任何登入用戶可查詢所有人的 email |
| 2.1 | 🟠 中 | 無欄位長度限制 | 攻擊者塞超長字串填滿 500MB 免費配額 |
| 2.2 | 🟠 中 | 無雲端旅行數量上限 | 單一用戶創建無限旅行 |
| 2.3 | 🟠 中 | 無消費筆數上限 | 單一旅行塞入無限消費記錄 |
| 2.4 | 🟠 中 | 邀請 max_uses 無上限 | 邀請碼可被公開散布，大量用戶加入 |
| 2.5 | 🟠 中 | expenses RLS 未指定 `authenticated` 角色 | 潛在的未授權存取風險 |
| 3.1 | 🟡 低 | 協作者上傳圖片失敗靜默清除 URL | 封面圖片意外消失，用戶困惑 |
| 3.2 | 🟡 低 | Storage RLS 可能拒絕協作者上傳 | 協作者無法更新旅行封面 |

---

## 🔴 高風險 — RLS Policy 修復

---

### 1.1 invitations_select_by_token 過度開放

#### 問題描述

目前 `invitations` 表存在一個 SELECT policy，允許任何已登入用戶透過 token 查詢邀請記錄。這表示攻擊者可以用已知或暴力枚舉的 token 查詢所有邀請資訊（包括對應的 trip_id、使用次數、過期時間等）。

然而，`accept_invitation` 是一個 `SECURITY DEFINER` 的 RPC 函式，它在自己的安全上下文中執行，**不需要**呼叫者對 `invitations` 表有任何 SELECT 權限即可讀取記錄。因此這個 SELECT policy 是多餘且有害的。

#### 修復策略

**後端（Supabase Migration）：**
1. **刪除** `invitations_select_by_token` RLS policy（或等效的允許所有已登入用戶 SELECT 的 policy）
2. `invitations` 表上不應保留任何對一般用戶開放的 SELECT policy
3. 只有 `SECURITY DEFINER` 函式（如 `accept_invitation`）可以在內部查詢邀請表
4. 可選：為旅行擁有者保留一個限縮的 SELECT policy，讓他們能查詢自己旅行的邀請（`trip_id IN (SELECT id FROM trips WHERE owner_id = auth.uid())`）

**前端（Flutter）：**
- 不需要改動，`accept_invitation` RPC 仍然正常運作（它不依賴呼叫者的 SELECT 權限）
- 確認 `JoinTripScreen` 中只呼叫 `accept_invitation` RPC，不直接 SELECT invitations 表

#### 需要修改的檔案

- `supabase/migrations/YYYYMMDD_fix_invitations_rls.sql`（新增 migration）
- `lib/screens/join_trip_screen.dart`（確認呼叫方式正確，應無需修改）

#### Migration SQL 邏輯描述

```sql
-- 1. 刪除過度開放的 SELECT policy
DROP POLICY IF EXISTS invitations_select_by_token ON invitations;
-- 或使用精確名稱：
DROP POLICY IF EXISTS "Allow users to read invitations by token" ON invitations;

-- 2. 為旅行擁有者新增限縮的 SELECT policy（可選）
-- 允許擁有者查看自己旅行的邀請碼（例如在邀請碼管理頁面顯示）
CREATE POLICY "owners_can_view_own_trip_invitations"
  ON invitations
  FOR SELECT
  TO authenticated
  USING (
    trip_id IN (
      SELECT id FROM trips WHERE owner_id = auth.uid()
    )
  );
```

#### UX 流程描述

- **不影響現有用戶流程**：`JoinTripScreen` 的邀請碼輸入 → `accept_invitation` RPC 流程完全不變
- 如果未來需要顯示邀請碼管理頁面，擁有者仍可透過新增的限縮 policy 查詢自己旅行的邀請

#### 影響評估

- **風險降低**：攻擊者無法再列舉所有邀請記錄
- **相容性**：完全向後相容，功能不受影響
- **注意**：上線前確認 `accept_invitation` 函式確實有 `SECURITY DEFINER` 標記

---

### 1.2 profiles 表 SELECT policy 洩露 email

#### 問題描述

目前 `profiles` 表的 SELECT policy 允許任何已登入用戶查詢所有其他用戶的 profile，包含 **email 地址**。這等同於把整個用戶資料庫暴露給任何一個使用者，違反了最小權限原則，也可能違反個資保護法規（GDPR、個資法）。

#### 修復策略

**後端（Supabase Migration）：**

有三個層次的修復方案，建議採用方案三（最嚴格）：

**方案一（最寬鬆）**：只允許讀取顯示名稱，不暴露 email
```
允許：SELECT id, display_name, avatar_url WHERE true（所有已登入用戶）
禁止：直接存取 email 欄位
```
實作方式：用 Column Security 或 View 限制欄位存取

**方案二（中等）**：只允許讀取同旅行成員的 profile
```
允許：SELECT * FROM profiles
WHERE id IN (
  SELECT user_id FROM trip_members
  WHERE trip_id IN (
    SELECT trip_id FROM trip_members WHERE user_id = auth.uid()
  )
)
```

**方案三（最嚴格，建議）**：只允許讀取自己的 profile；協作者顯示名稱透過 RPC 取得
```
允許：SELECT * FROM profiles WHERE id = auth.uid()
其他人的資訊透過限縮的 RPC 或 View 取得（僅 display_name，無 email）
```

**前端修改（Flutter）：**
- `lib/services/auth_service.dart`：`getProfile()` 只查詢自己的 profile（已是 `WHERE id = auth.uid()`，確認無誤）
- `lib/screens/trip/trip_detail_screen.dart`：成員列表顯示功能需確認只讀取 `display_name`，不暴露 email
- 如果現有程式碼有直接 SELECT 其他用戶 profiles 的邏輯，需改為呼叫限縮的 RPC

#### 需要修改的檔案

- `supabase/migrations/YYYYMMDD_fix_profiles_rls.sql`（新增 migration）
- `lib/services/auth_service.dart`（確認 getProfile 邏輯）
- `lib/screens/trip/trip_detail_screen.dart`（確認成員列表邏輯）

#### Migration SQL 邏輯描述

```sql
-- 1. 刪除現有過度開放的 SELECT policy
DROP POLICY IF EXISTS "Users can view all profiles" ON profiles;
DROP POLICY IF EXISTS "Public profiles are viewable by everyone" ON profiles;

-- 2. 建立：只允許讀取自己的 profile
CREATE POLICY "users_can_view_own_profile"
  ON profiles
  FOR SELECT
  TO authenticated
  USING (id = auth.uid());

-- 3. 建立：只能讀取同旅行成員的 display_name（透過 View）
-- 建立一個只暴露 id 和 display_name 的 View
CREATE OR REPLACE VIEW public.member_profiles AS
  SELECT id, display_name
  FROM profiles
  WHERE id IN (
    SELECT user_id FROM trip_members
    WHERE trip_id IN (
      SELECT trip_id FROM trip_members WHERE user_id = auth.uid()
    )
  );

-- 授予已登入用戶查詢此 View 的權限
GRANT SELECT ON public.member_profiles TO authenticated;
```

#### UX 流程描述

- **成員列表頁面**（`TripDetailScreen` 成員 Tab）：
  - 改為查詢 `member_profiles` View 而非直接查 `profiles`
  - 只顯示 `display_name`，不顯示 email（UI 上本來也只顯示名稱）
- **設定頁面**（個人 Profile 設定）：
  - 查詢自己的完整 profile，不受影響

#### 影響評估

- **風險降低**：任何用戶無法再查詢其他人的 email
- **相容性**：需確認所有查詢 `profiles` 表的地方（搜尋 `from('profiles')`）
- **注意**：Supabase Dashboard 的 Auth 管理功能不受 RLS 影響（仍可在後台查看）

---

## 🟠 中風險 — 用量限制

---

### 2.1 欄位長度限制

#### 問題描述

資料庫欄位目前沒有長度限制。攻擊者可以在 `name`、`note`、`title` 等文字欄位填入數 MB 的字串，逐步消耗 Supabase 免費方案的 500MB 儲存配額。

#### 修復策略

**後端（Supabase Migration）：**

為所有文字欄位加上 `CHECK` 約束（而非改為 `VARCHAR`，避免影響現有資料）：

| 表 | 欄位 | 建議長度上限 | 理由 |
|---|------|------------|------|
| `trips` | `name` | 50 字元 | 旅行名稱 |
| `trips` | `base_currency` | 3 字元 | ISO 4217 幣別代碼 |
| `trips` | `target_currency` | 3 字元 | ISO 4217 幣別代碼 |
| `trips` | `cover_image_url` | 500 字元 | URL 長度 |
| `expenses` | `title` | 50 字元 | 消費名稱 |
| `expenses` | `note` | 200 字元 | 備註 |
| `expenses` | `currency` | 3 字元 | ISO 4217 幣別代碼 |
| `profiles` | `display_name` | 50 字元 | 顯示名稱 |
| `invitations` | `token` | 20 字元 | 邀請碼長度固定 |

**前端（Flutter）：**
- `lib/screens/trip/trip_form_screen.dart`：表單欄位加上 `maxLength` 限制（`name` 最多 50 字）
- `lib/screens/expense/expense_form_screen.dart`：`title` 最多 50 字，`note` 最多 200 字
- `lib/services/auth_service.dart`：`updateDisplayName` 呼叫前在前端驗證長度

#### 需要修改的檔案

- `supabase/migrations/YYYYMMDD_add_field_length_constraints.sql`（新增 migration）
- `lib/screens/trip/trip_form_screen.dart`（表單 `maxLength` + validator）
- `lib/screens/expense/expense_form_screen.dart`（表單 `maxLength` + validator）
- `lib/services/auth_service.dart`（顯示名稱長度驗證）

#### Migration SQL 邏輯描述

```sql
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
```

#### UX 流程描述

前端表單欄位加上 `maxLength` 後，TextField 會自動顯示字數計數器（例如 `45/50`），在接近上限時提示用戶。不需要額外的錯誤訊息設計。

若用戶繞過前端直接呼叫 API，後端 CHECK 約束會回傳 `23514` 錯誤碼，前端接到時顯示通用的「儲存失敗，請確認輸入內容」。

#### 影響評估

- **相容性**：現有資料不受影響（僅限制新寫入）
- **風險**：migration 執行前需確認現有資料無超過長度限制的記錄（用 `SELECT count(*) WHERE char_length(name) > 50` 確認）

---

### 2.2 雲端旅行數量上限

#### 問題描述

用戶可以無限創建雲端旅行，消耗伺服器儲存與計算資源。目前的 `uploadLocalTripToCloud` 和 `addTrip`（若未來支援直接在雲端創建）沒有數量檢查。

**上限設定：每個用戶最多 10 個雲端旅行（本地旅行不受限）**

#### 修復策略

**後端（Supabase）：**

建立 `BEFORE INSERT` trigger，在新增旅行前檢查該用戶擁有的旅行數：

```
trigger: check_trip_limit_trigger
  - 觸發時機：BEFORE INSERT ON trips FOR EACH ROW
  - 邏輯：
    COUNT 該 user_id 在 trips 表中的記錄數（owner_id = NEW.owner_id）
    若 count >= 10，RAISE EXCEPTION 'TRIP_LIMIT_EXCEEDED' (SQLSTATE 'P0001')
  - 錯誤訊息格式：'{"code": "TRIP_LIMIT_EXCEEDED", "limit": 10}'
```

**前端（Flutter）：**

1. `lib/repositories/trip_repository.dart`：在 `uploadLocalTripToCloud` 呼叫前，先查詢雲端旅行數量（或攔截 trigger 拋出的錯誤）
2. `lib/providers/trip_provider.dart`：新增 `LimitExceededException` 的錯誤處理，回傳 `'trip_limit_exceeded'` 錯誤 key
3. `lib/screens/home/home_screen.dart`：攔截 `'trip_limit_exceeded'` 錯誤，顯示特定提示
4. 在首頁旅行列表中，若雲端旅行數達到 8/10（達到 80%），顯示黃色警告橫幅

#### 需要修改的檔案

- `supabase/migrations/YYYYMMDD_add_trip_limit_trigger.sql`（新增 migration）
- `lib/repositories/trip_repository.dart`（錯誤攔截）
- `lib/providers/trip_provider.dart`（錯誤 key 轉換）
- `lib/screens/home/home_screen.dart`（上限警告 UI + 錯誤提示）
- `lib/l10n/`（新增本地化字串）

#### Migration SQL 邏輯描述

```sql
-- 建立 trigger function
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

-- 掛載 trigger
CREATE TRIGGER check_trip_limit_trigger
  BEFORE INSERT ON trips
  FOR EACH ROW
  EXECUTE FUNCTION check_trip_limit();
```

#### UX 流程描述

**正常情況（< 8 個雲端旅行）：** 無任何提示，功能正常。

**接近上限（8–9 個雲端旅行）：**
- 首頁旅行列表頂部顯示黃色提示條：
  > ⚠️ 您已有 8/10 個雲端旅行，接近上限。本地旅行不受限制。

**達到上限（10 個雲端旅行）：**
- 用戶點擊「上傳到雲端」按鈕時：
  - 後端 trigger 拋出錯誤
  - 前端顯示 AlertDialog：
    > **無法上傳到雲端**
    >
    > 您的雲端旅行已達上限（10 個）。請先刪除不需要的雲端旅行，或繼續使用本地儲存。
    >
    > [確定]  [查看雲端旅行]
- **注意**：新建本地旅行（`addTrip`）不受此限制影響，始終可以正常新增

**如何取得雲端旅行數量（前端預檢）：**
```
TripProvider.trips.where((t) => t.uuid != null && t.memberRole == 'owner').length
```
前端可在顯示「上傳到雲端」按鈕前先做預檢，若已達上限則直接禁用該按鈕並顯示提示文字。

#### 影響評估

- **現有用戶**：若已有超過 10 個雲端旅行，不受影響（trigger 僅限制新增）
- **協作旅行**：加入他人旅行（`trip_members` 新增記錄）不受此 trigger 影響，因為不 INSERT 到 `trips` 表

---

### 2.3 雲端消費筆數上限

#### 問題描述

每個雲端旅行可以新增無限筆消費記錄，消耗資料庫儲存空間。

**上限設定：每個雲端旅行最多 200 筆消費**

#### 修復策略

**後端（Supabase）：**

建立 `BEFORE INSERT` trigger，在新增消費前檢查該旅行的消費數：

```
trigger: check_expense_limit_trigger
  - 觸發時機：BEFORE INSERT ON expenses FOR EACH ROW
  - 邏輯：
    COUNT expenses WHERE trip_id = NEW.trip_id
    若 count >= 200，RAISE EXCEPTION 'EXPENSE_LIMIT_EXCEEDED' (SQLSTATE 'P0001')
  - 錯誤訊息格式：'{"code": "EXPENSE_LIMIT_EXCEEDED", "limit": 200}'
```

**前端（Flutter）：**

1. `lib/repositories/expense_repository.dart`：攔截 trigger 拋出的錯誤，拋出 `ExpenseLimitException`
2. `lib/providers/expense_provider.dart`：攔截 `ExpenseLimitException`，回傳 `'expense_limit_exceeded'` 錯誤 key
3. `lib/screens/expense/expense_form_screen.dart`：`_save()` 方法中攔截錯誤，顯示特定提示
4. `lib/screens/trip/trip_detail_screen.dart`：在消費列表頂部，當消費數達到 160/200（80%）時顯示警告

#### 需要修改的檔案

- `supabase/migrations/YYYYMMDD_add_expense_limit_trigger.sql`（新增 migration）
- `lib/repositories/expense_repository.dart`（錯誤攔截 + 新增 `ExpenseLimitException`）
- `lib/providers/expense_provider.dart`（錯誤 key 轉換）
- `lib/screens/expense/expense_form_screen.dart`（錯誤提示）
- `lib/screens/trip/trip_detail_screen.dart`（接近上限警告）
- `lib/l10n/`（新增本地化字串）

#### Migration SQL 邏輯描述

```sql
-- 建立 trigger function
CREATE OR REPLACE FUNCTION check_expense_limit()
RETURNS TRIGGER AS $$
DECLARE
  expense_count INTEGER;
BEGIN
  SELECT COUNT(*) INTO expense_count
    FROM expenses
    WHERE trip_id = NEW.trip_id;

  IF expense_count >= 200 THEN
    RAISE EXCEPTION 'EXPENSE_LIMIT_EXCEEDED'
      USING ERRCODE = 'P0001',
            DETAIL = '{"code": "EXPENSE_LIMIT_EXCEEDED", "limit": 200}';
  END IF;

  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- 掛載 trigger
CREATE TRIGGER check_expense_limit_trigger
  BEFORE INSERT ON expenses
  FOR EACH ROW
  EXECUTE FUNCTION check_expense_limit();
```

#### UX 流程描述

**接近上限（160–199 筆）：**
- `TripDetailScreen` 消費列表頂部顯示黃色提示條：
  > ⚠️ 此旅行已有 {count}/200 筆消費，即將達到上限。

**達到上限（200 筆）：**
- 用戶點「+ 新增消費」→ `ExpenseFormScreen`
- 用戶填完表單，點「儲存」
- 後端 trigger 拋出錯誤，前端 `_save()` 接到 `'expense_limit_exceeded'`
- 顯示 SnackBar：
  > 此旅行的消費筆數已達上限（200 筆）。請刪除部分消費後再新增。

- 另外方案：在 `TripDetailScreen` 的「+ 新增消費」按鈕處，若已達上限則直接禁用按鈕並顯示提示，避免用戶填完表單才發現無法儲存。

**前端預檢邏輯：**
```
ExpenseProvider.expenses.length >= 200
```
若已達上限，「新增消費」的 FAB 顯示為禁用狀態，並加上 Tooltip 提示。

#### 影響評估

- **本地旅行**：不受影響（trigger 只在 INSERT 到 Supabase `expenses` 表時觸發）
- **現有資料**：不受影響
- **協作者**：協作者新增消費也受同一上限限制，確保旅行整體資料量可控

---

### 2.4 邀請 max_uses 上限

#### 問題描述

邀請記錄的 `max_uses` 欄位目前沒有上限限制，用戶可以設定極大的數值（如 99999），讓邀請碼被公開散布、大量用戶加入，導致資源濫用。

**上限設定：max_uses 最大值為 20**

#### 修復策略

**後端（Supabase）：**

1. 在 `invitations` 表加上 CHECK 約束：`max_uses BETWEEN 1 AND 20`
2. 若使用 `create_invitation` RPC 建立邀請，在函式內加上驗證

**前端（Flutter）：**

- `lib/widgets/invite_code_widget.dart`（或建立邀請碼的相關 UI）：若有 `max_uses` 選項，限制最大值為 20
- 若目前邀請碼是固定 `max_uses`（如 1），可直接跳過前端修改

#### 需要修改的檔案

- `supabase/migrations/YYYYMMDD_add_invitation_max_uses_constraint.sql`（新增 migration）
- `lib/widgets/invite_code_widget.dart`（視現有邏輯決定是否需修改）

#### Migration SQL 邏輯描述

```sql
-- 加上 max_uses 範圍限制
ALTER TABLE invitations
  ADD CONSTRAINT invitations_max_uses_range
    CHECK (max_uses >= 1 AND max_uses <= 20);

-- 若現有資料有超過上限的記錄，先更新
UPDATE invitations SET max_uses = 20 WHERE max_uses > 20;
```

#### UX 流程描述

- 若 App 目前的邀請碼建立流程是固定 `max_uses = 1`（一次性），則本項對 UX 無任何影響
- 若未來要讓用戶自訂 `max_uses`，UI 元件（如 Slider 或 TextField）需限制最大值為 20

#### 影響評估

- **低影響**：多數情況下邀請碼是一次性使用，此修改主要防止資料層的異常輸入

---

### 2.5 expenses RLS 缺少角色限制

#### 問題描述

`expenses` 表的 RLS policy 在 `TO` 子句中可能未明確指定 `authenticated` 角色，導致 `anon`（未登入）用戶在某些邊緣情況下可能意外存取資料。雖然 Supabase 預設 RLS 會阻擋未登入用戶，但明確指定角色是最佳實踐。

#### 修復策略

**後端（Supabase Migration）：**

確認並修改 `expenses` 表上所有 RLS policy，確保都有 `TO authenticated` 子句：

```sql
-- 確認所有 policy 都指定 authenticated 角色
-- 範例修復：
DROP POLICY IF EXISTS "expenses_select_policy" ON expenses;
CREATE POLICY "expenses_select_policy"
  ON expenses
  FOR SELECT
  TO authenticated  -- 明確指定！
  USING (
    trip_id IN (
      SELECT trip_id FROM trip_members WHERE user_id = auth.uid()
    )
  );

-- 同樣修正 INSERT、UPDATE、DELETE policies
```

#### 需要修改的檔案

- `supabase/migrations/YYYYMMDD_fix_expenses_rls_role.sql`（新增 migration）

#### UX 流程描述

純後端修改，對用戶體驗無影響。

#### 影響評估

- **低風險修改**：主要是防禦性修復，明確化 policy 的適用範圍
- **建議順序**：配合 2.2、2.3 的 trigger migration 一起執行

---

## 🟡 其他問題 — 圖片處理

---

### 3.1 協作者上傳圖片失敗靜默清除 URL

#### 問題描述

在 `lib/repositories/trip_repository.dart` 的 `updateTrip` 方法中（第 106–116 行），當 `trip.coverImagePath != null && trip.coverImageUrl == null` 時，會嘗試上傳圖片。若上傳失敗（`uploaded == null`），`coverImageUrl` 保持為 `null`，但後續 `toSupabaseMap` 仍會把 `cover_image_url: null` 寫入雲端，**清除了原本已存在的封面 URL**。

此問題影響場景：
1. 協作者（editor）本地選了圖片但 Storage RLS 拒絕上傳 → 封面被清除
2. 網路不穩導致上傳失敗 → 封面被清除

#### 修復策略

**前端（Flutter）：**

修改 `lib/repositories/trip_repository.dart` 的 `updateTrip` 方法：

```
修復邏輯：
1. 若 coverImagePath != null（有選新圖片）：
   a. 嘗試上傳
   b. 若上傳成功 → 使用新的 URL
   c. 若上傳失敗 → 保留原本的 trip.coverImageUrl（不寫 null）
      並記錄 log/回傳警告

2. 若 coverImagePath == null（沒有選新圖片）：
   不改動 cover_image_url（不包含此欄位在 updateMap 中）
```

具體實作：在 `toSupabaseMap` 之後，若 `coverImageUrl` 為 null 但原始 `trip` 物件有 `coverImageUrl`，則從 `updateMap` 移除 `cover_image_url` key，避免覆寫。

#### 需要修改的檔案

- `lib/repositories/trip_repository.dart`（`updateTrip` 方法，第 96–130 行）

#### UX 流程描述

- **修復前**：協作者編輯旅行名稱 → 旅行封面消失（靜默 bug）
- **修復後**：上傳失敗時封面保持不變，可選擇顯示 SnackBar 提示「封面圖片上傳失敗，其他變更已儲存」

#### 影響評估

- **重要修復**：此 bug 會造成用戶資料靜默損失，優先修復
- **測試重點**：模擬 Storage RLS 拒絕 → 確認旅行名稱更新成功，封面 URL 不被清除

---

### 3.2 Storage RLS 可能拒絕協作者上傳

#### 問題描述

`ImageStorageService.uploadTripCover` 上傳到 Supabase Storage `trip-covers` bucket，路徑格式為 `{userId}/{tripUuid}.webp`。若 Storage 的 RLS policy 只允許 `owner_id == auth.uid()` 上傳，則協作者（editor）會被拒絕，導致上述的圖片清除問題。

#### 修復策略

**後端（Supabase Storage Policy）：**

修改 `trip-covers` bucket 的上傳 policy，允許旅行的編輯成員上傳：

```
修改 Storage policy：
FROM: path.startsWith(auth.uid())
TO: 上傳者是該旅行的 member（role IN ('owner', 'editor')）

判斷方式：path 格式為 {userId}/{tripUuid}.webp
從 path 提取 tripUuid（取最後一段，移除 .webp 副檔名）
然後查 trip_members WHERE trip_id = extracted_uuid AND user_id = auth.uid()
```

**注意**：Supabase Storage 的 RLS 比較複雜，可用 `storage.objects` 系統表來寫 policy。

另一個更簡單的方案：

**改變路徑結構**：把路徑從 `{ownerId}/{tripUuid}.webp` 改為 `trips/{tripUuid}.webp`，然後 policy 改為「只要是 trip 的 member 就可以上傳同名路徑」。

**前端（Flutter）：**

- `lib/services/image_storage_service.dart`：考慮路徑結構是否需要調整（配合 Storage policy 修改）

#### 需要修改的檔案

- Supabase Storage bucket `trip-covers` 的 policy 設定（透過 Dashboard 或 migration）
- `lib/services/image_storage_service.dart`（可能需調整路徑格式）

#### Migration SQL 邏輯描述（Storage Objects Policy）

```sql
-- 刪除現有限制性的 INSERT policy
DROP POLICY IF EXISTS "Users can upload their own trip covers" ON storage.objects;

-- 建立新 policy：允許旅行成員（owner + editor）上傳
-- 路徑格式：trips/{tripUuid}.webp
CREATE POLICY "trip_members_can_upload_cover"
  ON storage.objects
  FOR INSERT
  TO authenticated
  WITH CHECK (
    bucket_id = 'trip-covers'
    AND EXISTS (
      SELECT 1 FROM trip_members
      WHERE trip_id = (
        -- 從路徑 'trips/{uuid}.webp' 提取 uuid
        regexp_replace(split_part(name, '/', 2), '\\.webp$', '')
      )
      AND user_id = auth.uid()
      AND role IN ('owner', 'editor')
    )
  );
```

#### UX 流程描述

- **修復前**：協作者點「更換封面」→ 選圖 → 上傳失敗 → 封面消失（雙重打擊）
- **修復後**：協作者可以正常上傳新封面，體驗與旅行擁有者一致

#### 影響評估

- **需搭配 3.1 一起修復**：先修 3.1 防止靜默清除，再修 3.2 讓上傳實際可行
- **路徑遷移**：若改變路徑格式，需考慮現有已上傳封面的遷移（或暫保留雙路徑支援）

---

## UX 設計規範

### 錯誤訊息標準化

所有用量上限錯誤都應顯示友善的繁體中文提示，以下為建議的文案：

| 錯誤 Key | 錯誤類型 | 建議 UI 元件 | 建議文案 |
|---------|---------|------------|---------|
| `trip_limit_exceeded` | 雲端旅行達上限 | AlertDialog | **無法上傳到雲端**\n您的雲端旅行已達上限（10 個）。請刪除不需要的雲端旅行，或繼續使用本地儲存。 |
| `expense_limit_exceeded` | 消費筆數達上限 | SnackBar + 按鈕 | 此旅行的消費筆數已達上限（200 筆）。 |
| `field_too_long` | 欄位超長 | TextField validator | 最多輸入 {n} 個字元 |
| `cover_upload_failed` | 封面上傳失敗 | SnackBar | 封面圖片上傳失敗，其他變更已儲存 |

### 接近上限警告（Soft Warning）

在以下位置加入黃色警告提示，讓用戶提前知道：

1. **首頁（HomeScreen）**：雲端旅行數 ≥ 8 時，在旅行列表頂部顯示橫幅
   ```
   ⚠️ 您已有 {count}/10 個雲端旅行，即將達到上限。
   ```

2. **旅行詳情頁（TripDetailScreen）**：消費筆數 ≥ 160 時，在 FAB 上方或列表頂部顯示橫幅
   ```
   ⚠️ 此旅行已有 {count}/200 筆消費，即將達到上限。
   ```

### 後端錯誤攔截標準

前端在 Repository 層統一攔截 Supabase 錯誤，辨識 `DETAIL` 欄位中的 JSON code：

```dart
// 統一錯誤攔截邏輯（在 TripRepository / ExpenseRepository 中）
on PostgrestException catch (e) {
  final detail = e.details?.toString() ?? '';
  if (detail.contains('TRIP_LIMIT_EXCEEDED')) {
    throw const TripLimitException();
  } else if (detail.contains('EXPENSE_LIMIT_EXCEEDED')) {
    throw const ExpenseLimitException();
  }
  rethrow;
}
```

Provider 層將 Exception 轉換為錯誤 key，Screen 層根據 key 顯示對應的 UI。

---

## 修改檔案總覽

### 後端（Supabase Migrations）

| Migration 檔案 | 內容 |
|---------------|------|
| `YYYYMMDD_fix_invitations_rls.sql` | 刪除過度開放的 SELECT policy |
| `YYYYMMDD_fix_profiles_rls.sql` | 限制 profiles SELECT + 建立 member_profiles view |
| `YYYYMMDD_add_field_length_constraints.sql` | 欄位長度 CHECK 約束 |
| `YYYYMMDD_add_trip_limit_trigger.sql` | 雲端旅行數量 trigger |
| `YYYYMMDD_add_expense_limit_trigger.sql` | 消費筆數 trigger |
| `YYYYMMDD_add_invitation_max_uses_constraint.sql` | max_uses 上限 |
| `YYYYMMDD_fix_expenses_rls_role.sql` | expenses policy 加上 TO authenticated |
| Storage Policy 修改 | trip-covers 允許 editor 上傳 |

### 前端（Flutter）

| 檔案 | 修改內容 |
|------|---------|
| `lib/repositories/trip_repository.dart` | 攔截 TripLimitException；修復 updateTrip 不清除封面 URL |
| `lib/repositories/expense_repository.dart` | 攔截 ExpenseLimitException |
| `lib/providers/trip_provider.dart` | 處理 TripLimitException → 'trip_limit_exceeded' |
| `lib/providers/expense_provider.dart` | 處理 ExpenseLimitException → 'expense_limit_exceeded' |
| `lib/screens/home/home_screen.dart` | 顯示雲端旅行接近上限警告；處理 trip_limit_exceeded 錯誤 |
| `lib/screens/trip/trip_detail_screen.dart` | 顯示消費接近上限警告；查詢改用 member_profiles view |
| `lib/screens/expense/expense_form_screen.dart` | maxLength 限制；處理 expense_limit_exceeded 錯誤 |
| `lib/screens/trip/trip_form_screen.dart` | maxLength 限制（name 欄位） |
| `lib/services/auth_service.dart` | display_name 長度驗證 |
| `lib/services/image_storage_service.dart` | 可能需調整上傳路徑（配合 Storage policy） |
| `lib/l10n/app_localizations.dart` | 新增錯誤訊息字串 |

---

## 執行順序建議

建議依以下順序執行，優先處理安全風險，再處理用量問題：

### 第一階段：安全漏洞修復（立即執行）

1. **1.1** 刪除 `invitations_select_by_token` policy → 純後端，無前端影響，風險低
2. **1.2** 修復 `profiles` SELECT policy → 後端 + 確認前端查詢邏輯
3. **2.5** 修復 `expenses` RLS 角色指定 → 純後端，防禦性修復

### 第二階段：用量限制（次優先）

4. **2.1** 欄位長度限制 → 後端約束 + 前端 maxLength（需確認現有資料）
5. **2.4** 邀請 max_uses 上限 → 低影響，快速完成
6. **2.2** 雲端旅行數量上限 → 後端 trigger + 前端錯誤處理 + UX 警告
7. **2.3** 消費筆數上限 → 後端 trigger + 前端錯誤處理 + UX 警告

### 第三階段：圖片問題修復

8. **3.1** 修復 `updateTrip` 靜默清除封面 → 純前端，重要 bug 修復
9. **3.2** 修復 Storage RLS 允許協作者上傳 → 後端 + 可能需前端路徑調整

---

*本方案文件依 2026-04-02 時的專案架構分析撰寫。執行前請確認各項細節與當前程式碼一致。*

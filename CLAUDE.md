# 熊好算 TravelBudget — 開發指南

> **語言規則**：所有回覆一律使用**繁體中文**。

海外旅遊輕量化記帳 App，解決外幣輸入、匯率換算、預算控管的痛點。支援多人協作分帳、雲端同步、離線使用。

## 技術棧

| 類別 | 技術 |
|------|------|
| **框架** | Flutter (Dart ^3.10.8) |
| **狀態管理** | Provider (ChangeNotifier) |
| **本地資料庫** | sqflite (SQLite)，離線優先 |
| **雲端後端** | Supabase（Auth、Realtime、Storage、Edge Functions、PostgreSQL） |
| **認證** | Sign In With Apple、Google Sign-In，支援帳號綁定合併 |
| **匯率 API** | ExchangeRate API (`open.er-api.com`，免費、不需 API Key、支援 TWD) |
| **圖表** | fl_chart (圓餅圖 + 柱狀圖 + 折線圖) |
| **圖片** | image_picker + flutter_image_compress（壓縮為 WebP） |
| **廣告** | Google Mobile Ads (AdMob Banner) |
| **內購** | in_app_purchase（移除廣告） |
| **多語系** | 自建 AppLocalizations（zh_TW、en、ja、ko、zh_CN） |
| **深層連結** | app_links（travelbudget:// URI） |

## 架構

```
lib/
├── constants/        # AppTheme、Categories、Currencies、PaymentMethods
├── models/           # Trip、Expense、ExchangeRate
├── db/               # SQLite 單例 (DatabaseHelper) + DAO (TripDao、ExpenseDao)
├── repositories/     # TripRepository、ExpenseRepository（混合本地+雲端資料層）
├── services/         # AuthService、SyncService、ExchangeRateService、
│                     #   SplitService、ImageStorageService、AdService、PurchaseService
├── providers/        # AuthProvider、TripProvider、ExpenseProvider、
│                     #   AdProvider、LocaleProvider、ConnectivityProvider
├── screens/          # HomeScreen（三分頁）、LoginScreen、TripFormScreen、
│                     #   TripDetailScreen、ExpenseFormScreen、AnalyticsScreen、
│                     #   OverviewScreen、SettingsScreen、JoinTripScreen、SettlementScreen
├── widgets/          # TripCard、ExpenseTile、BudgetProgressBar、
│                     #   CategoryPieChart、InviteCodeWidget、BannerAdWidget
├── l10n/             # AppLocalizations（多語系字串）
└── main.dart         # 入口、MultiProvider、AppTheme
```

## 設計風格

文青風格，色調參考 TravelLanguage 專案：
- **主色**: 橙色 `#E8763A`（來自 app icon）
- **背景**: 奶油色 `#F6F1EA` / 暖白 `#FFFDF9`
- **邊框**: 羊皮紙色 `#E8DED0`
- **文字**: 墨色三階 `#2C2420` / `#6B5E56` / `#A89B91`
- **分類色**: 苔蘚綠、梅紫、靛藍、琥珀等文青色系

所有色彩定義集中於 `lib/constants/app_theme.dart`。

## 資料庫 Schema

### 本地 SQLite（v4）

三張表：`trips`、`expenses`、`rate_cache`。
- 每筆消費儲存時即寫入 `converted_amount` 和 `exchange_rate`，匯率更新不影響歷史紀錄
- 匯率快取有效期為 1 天
- `uuid` 欄位為 null 表示純本地旅行，有值表示已同步至雲端
- `is_dirty` 標記本地修改，下次同步時推送

### Supabase 雲端（PostgreSQL）

六張表：`trips`、`expenses`、`trip_members`、`trip_invitations`、`profiles`、`expense_splits`、`settlements`。
- RLS (Row-Level Security) 保護所有表
- `trip_members` 控制協作權限（owner / editor / viewer）
- 旅行上限 10 筆（透過 `check_trip_limit` trigger 限制 `trips.owner_id` 數量）
- 邀請碼 6 碼，有效期 30 天

### Edge Functions

- `link-identity`：OAuth 帳號綁定與合併（Apple / Google），處理資料遷移

## 關鍵架構模式

- **離線優先 (Offline-First)**：SQLite 永遠可用，雲端功能在離線時優雅降級
- **Repository 模式**：TripRepository / ExpenseRepository 抽象本地 vs 雲端資料存取
- **Dirty-Flag 同步**：`is_dirty` 標記本地修改，登入時重試推送
- **Realtime 訂閱**：透過 Supabase Realtime channel 即時更新共享旅行
- **貪婪結算演算法**：SplitService 最小化分帳轉帳次數

## Fastlane 部署

Fastlane 設定位於 `ios/fastlane/`，使用 Bundler 管理 gem。

### 執行 TestFlight 上傳

```bash
cd ios
export LANG=en_US.UTF-8
export LC_ALL=en_US.UTF-8
export PATH="/opt/homebrew/lib/ruby/gems/4.0.0/bin:/opt/homebrew/opt/ruby/bin:$PATH"
ASC_KEY_ID=ZX525S46LM \
ASC_ISSUER_ID=d610c472-a7f5-40ff-9382-f9e58b7b5ebc \
ASC_KEY_PATH=~/.appstoreconnect/private_keys/AuthKey_ZX525S46LM.p8 \
/opt/homebrew/opt/ruby/bin/bundle exec fastlane beta
```

> **注意**：
> - 執行前**必須**設定 `LANG`/`LC_ALL=en_US.UTF-8`，否則 xcodebuild 輸出含非 ASCII 字元時會觸發 `Encoding::InvalidByteSequenceError`
> - 需將 CocoaPods 路徑加入 `PATH`
> - ASC API Key 與 TravelLanguage、TravelDiary 共用同一組（Team ID: `53GU4PUP6R`）
> - 系統 Ruby 太舊，必須用 Homebrew Ruby (`/opt/homebrew/opt/ruby/bin/bundle`)
> - Fastfile 中 flutter 指令使用完整路徑 `/opt/homebrew/bin/flutter`（Bundler unbundled env 不含 PATH）

## 出口合規 (Export Compliance)

本 App **未使用加密演算法**（`crypto` 套件僅用於 Apple Sign In 的 nonce SHA-256 雜湊，屬認證流程，非加密），上傳 TestFlight / App Store 時出口合規問題一律選「否」。

## 注意事項

- **Supabase Migration 原則**：所有透過 MCP 或 Dashboard 直接執行的 schema 變更，都必須同步寫一份 `.sql` 檔到 `supabase/migrations/`，確保資料庫可重建、變更可追蹤
- Bundle ID: `com.travelbudget.travelBudget`
- Frankfurter API **不支援 TWD**，已改用 ExchangeRate API
- Xcode 26 beta 有模擬器 destination specifier 相容性問題，建議用實機測試
- App Icon 使用 `flutter_launcher_icons` 從根目錄 `app-icon.png` 生成
- 免費用戶雲端旅行上限 10 筆

# 旅算 TravelBudget — 開發指南

> **語言規則**：所有回覆一律使用**繁體中文**。

海外旅遊輕量化記帳 App，解決外幣輸入、匯率換算、預算控管的痛點。

## 技術棧

- **框架**: Flutter (Dart ^3.10.8)
- **狀態管理**: Provider (ChangeNotifier)
- **本地資料庫**: sqflite (SQLite)
- **匯率 API**: ExchangeRate API (`open.er-api.com`，免費、不需 API Key、支援 TWD)
- **OCR**: google_mlkit_text_recognition（目前因 iOS 26 模擬器不支援 arm64 pod 暫時停用，實機可啟用）
- **圖表**: fl_chart (圓餅圖 + 柱狀圖)
- **圖片選取**: image_picker

## 架構

```
lib/
├── constants/      # 分類定義、幣別列表、主題色彩 (AppTheme)
├── models/         # Trip、Expense、ExchangeRate 資料模型
├── db/             # SQLite 單例 (DatabaseHelper) + DAO (TripDao、ExpenseDao)
├── services/       # 匯率服務 (ExchangeRateService)、OCR 服務 (OcrService)
├── providers/      # TripProvider、ExpenseProvider
├── screens/        # 首頁、旅行表單、旅行明細、消費表單、統計頁
├── widgets/        # BudgetProgressBar、CategoryPieChart、ExpenseTile、TripCard
└── main.dart       # 入口、MultiProvider、AppTheme
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

三張表：`trips`、`expenses`、`rate_cache`。
- 每筆消費儲存時即寫入 `converted_amount` 和 `exchange_rate`，匯率更新不影響歷史紀錄
- 匯率快取有效期為 1 天

## Fastlane 部署

Fastlane 設定位於 `ios/fastlane/`，使用 Bundler 管理 gem。

### 執行 TestFlight 上傳

```bash
cd ios
ASC_KEY_ID=ZX525S46LM \
ASC_ISSUER_ID=d610c472-a7f5-40ff-9382-f9e58b7b5ebc \
ASC_KEY_PATH=~/.appstoreconnect/private_keys/AuthKey_ZX525S46LM.p8 \
/opt/homebrew/opt/ruby/bin/bundle exec fastlane beta
```

> ASC API Key 與 TravelLanguage、TravelDiary 共用同一組（Team ID: `53GU4PUP6R`）。
> 系統 Ruby 2.6 太舊，必須用 Homebrew Ruby (`/opt/homebrew/opt/ruby/bin/bundle`)。

## 出口合規 (Export Compliance)

本 App **未使用任何加密演算法**（No Encryption），上傳 TestFlight / App Store 時出口合規問題一律選「否」。

## 注意事項

- Bundle ID: `com.travelbudget.travelBudget`
- Frankfurter API **不支援 TWD**，已改用 ExchangeRate API
- Xcode 26 beta 有模擬器 destination specifier 相容性問題，建議用實機測試
- App Icon 使用 `flutter_launcher_icons` 從根目錄 `app-icon.png` 生成

import 'package:flutter/material.dart';

class AppLocalizations {
  final Locale locale;

  AppLocalizations(this.locale);

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  static const supportedLocales = [
    Locale('zh', 'TW'),
    Locale('en'),
    Locale('ja'),
    Locale('ko'),
    Locale('zh', 'CN'),
  ];

  static const localeNames = {
    'zh_TW': '繁體中文',
    'en': 'English',
    'ja': '日本語',
    'ko': '한국어',
    'zh_CN': '简体中文',
  };

  String get localeKey {
    if (locale.countryCode != null) {
      return '${locale.languageCode}_${locale.countryCode}';
    }
    return locale.languageCode;
  }

  // === Common ===
  String get appName => _t('appName');
  String get cancel => _t('cancel');
  String get delete => _t('delete');
  String get save => _t('save');
  String get confirm => _t('confirm');
  String get next => _t('next');
  String get edit => _t('edit');

  // === Home / Trips ===
  String get tabTrips => _t('tabTrips');
  String get tabStats => _t('tabStats');
  String get tabSettings => _t('tabSettings');
  String get noTripsTitle => _t('noTripsTitle');
  String get noTripsSubtitle => _t('noTripsSubtitle');
  String get deleteTrip => _t('deleteTrip');
  String get deleteTripConfirm => _t('deleteTripConfirm');
  String get createdAt => _t('createdAt');

  // === Trip Form ===
  String get newTrip => _t('newTrip');
  String get editTrip => _t('editTrip');
  String get tripName => _t('tripName');
  String get tripNameHint => _t('tripNameHint');
  String get tripNameRequired => _t('tripNameRequired');
  String get startDate => _t('startDate');
  String get endDate => _t('endDate');
  String get baseCurrency => _t('baseCurrency');
  String get targetCurrency => _t('targetCurrency');
  String get noBudgetLimit => _t('noBudgetLimit');
  String get budgetAmount => _t('budgetAmount');
  String get budgetRequired => _t('budgetRequired');
  String get invalidNumber => _t('invalidNumber');
  String get addCoverImage => _t('addCoverImage');
  String get createTrip => _t('createTrip');
  String get saveChanges => _t('saveChanges');

  // === Expense ===
  String get newExpense => _t('newExpense');
  String get editExpense => _t('editExpense');
  String get category => _t('category');
  String get itemName => _t('itemName');
  String get itemNameHint => _t('itemNameHint');
  String get itemNameRequired => _t('itemNameRequired');
  String get amount => _t('amount');
  String get amountRequired => _t('amountRequired');
  String get invalidAmount => _t('invalidAmount');
  String get currency => _t('currency');
  String get date => _t('date');
  String get noteOptional => _t('noteOptional');
  String get add => _t('add');
  String get update => _t('update');

  // === Categories ===
  String get catFood => _t('catFood');
  String get catClothing => _t('catClothing');
  String get catLodging => _t('catLodging');
  String get catTransport => _t('catTransport');
  String get catEducation => _t('catEducation');
  String get catEntertainment => _t('catEntertainment');

  // === Budget / Stats ===
  String get spent => _t('spent');
  String get budget => _t('budget');
  String get remaining => _t('remaining');
  String get overspent => _t('overspent');
  String get noBudget => _t('noBudget');
  String get noRecords => _t('noRecords');
  String get budgetProgress => _t('budgetProgress');
  String get spendingBreakdown => _t('spendingBreakdown');
  String get dailySpending => _t('dailySpending');
  String get totalSpent => _t('totalSpent');
  String get avgDaily => _t('avgDaily');
  String get expenseCount => _t('expenseCount');

  // === Overview ===
  String get statsOverview => _t('statsOverview');
  String get noStatsTitle => _t('noStatsTitle');
  String get noStatsSubtitle => _t('noStatsSubtitle');
  String get tripsCount => _t('tripsCount');
  String get expensesCount => _t('expensesCount');
  String get totalSpending => _t('totalSpending');
  String get totalBreakdown => _t('totalBreakdown');
  String get perTripSpending => _t('perTripSpending');

  // === Trip Detail ===
  String get details => _t('details');
  String get stats => _t('stats');
  String daysRemaining(int days, String amount) =>
      _t('daysRemaining').replaceAll('{days}', '$days').replaceAll('{amount}', amount);
  String budgetRemaining(String amount) =>
      _t('budgetRemaining').replaceAll('{amount}', amount);
  String budgetOver(String amount) =>
      _t('budgetOver').replaceAll('{amount}', amount);
  String get ratePrefix => _t('ratePrefix');

  // === Settings ===
  String get settings => _t('settings');
  String get about => _t('about');
  String get version => _t('version');
  String get developer => _t('developer');
  String get exchangeRate => _t('exchangeRate');
  String get rateSource => _t('rateSource');
  String get updateFrequency => _t('updateFrequency');
  String get dailyOnce => _t('dailyOnce');
  String get data => _t('data');
  String get storageMethod => _t('storageMethod');
  String get storageDesc => _t('storageDesc');
  String get exportAll => _t('exportAll');
  String get exportDesc => _t('exportDesc');
  String get importData => _t('importData');
  String get importDesc => _t('importDesc');
  String get language => _t('language');
  String get exportFailed => _t('exportFailed');
  String get importCsv => _t('importCsv');
  String get pasteCsvContent => _t('pasteCsvContent');
  String get pasteCsvHint => _t('pasteCsvHint');
  String get parseFailed => _t('parseFailed');
  String get confirmImport => _t('confirmImport');
  String importPreview(int count) =>
      _t('importPreview').replaceAll('{count}', '$count');
  String get importFailed => _t('importFailed');
  String get saveFailed => _t('saveFailed');
  String get newLabel => _t('newLabel');
  String expenseUnit(int count) =>
      _t('expenseUnit').replaceAll('{count}', '$count');
  String skippedLines(int count) =>
      _t('skippedLines').replaceAll('{count}', '$count');

  String _t(String key) {
    final map = _localizedValues[localeKey] ?? _localizedValues['zh_TW']!;
    return map[key] ?? _localizedValues['zh_TW']![key] ?? key;
  }

  static const Map<String, Map<String, String>> _localizedValues = {
    'zh_TW': _zhTW,
    'en': _en,
    'ja': _ja,
    'ko': _ko,
    'zh_CN': _zhCN,
  };

  static const _zhTW = {
    'appName': '旅算 TravelBudget',
    'cancel': '取消',
    'delete': '刪除',
    'save': '儲存',
    'confirm': '確認',
    'next': '下一步',
    'edit': '編輯',
    'tabTrips': '旅行',
    'tabStats': '統計',
    'tabSettings': '設定',
    'noTripsTitle': '還沒有旅行計畫',
    'noTripsSubtitle': '點擊下方按鈕，開始記錄你的旅程',
    'deleteTrip': '刪除旅行',
    'deleteTripConfirm': '確定要刪除此旅行嗎？所有相關的消費紀錄都會一併刪除。',
    'createdAt': '建立於',
    'newTrip': '新增旅行',
    'editTrip': '編輯旅行',
    'tripName': '旅行名稱',
    'tripNameHint': '例：2026 東京賞櫻',
    'tripNameRequired': '請輸入旅行名稱',
    'startDate': '開始日期',
    'endDate': '結束日期',
    'baseCurrency': '主幣別',
    'targetCurrency': '旅行幣別',
    'noBudgetLimit': '不設定預算上限',
    'budgetAmount': '預算金額',
    'budgetRequired': '請輸入預算金額',
    'invalidNumber': '請輸入有效數字',
    'addCoverImage': '新增封面圖',
    'createTrip': '建立旅行',
    'saveChanges': '儲存變更',
    'newExpense': '新增消費',
    'editExpense': '編輯消費',
    'category': '分類',
    'itemName': '項目名稱',
    'itemNameHint': '例：一蘭拉麵',
    'itemNameRequired': '請輸入項目名稱',
    'amount': '金額',
    'amountRequired': '請輸入金額',
    'invalidAmount': '無效金額',
    'currency': '幣別',
    'date': '日期',
    'noteOptional': '備註（選填）',
    'add': '新增',
    'update': '更新',
    'catFood': '飲食',
    'catClothing': '服飾',
    'catLodging': '住宿',
    'catTransport': '交通',
    'catEducation': '教育',
    'catEntertainment': '娛樂',
    'spent': '已花費',
    'budget': '預算',
    'remaining': '剩餘',
    'overspent': '超支',
    'noBudget': '無預算上限',
    'noRecords': '尚無消費紀錄',
    'budgetProgress': '預算進度',
    'spendingBreakdown': '消費結構',
    'dailySpending': '每日花費',
    'totalSpent': '總花費',
    'avgDaily': '平均每日',
    'expenseCount': '消費筆數',
    'statsOverview': '統計總覽',
    'noStatsTitle': '尚無統計資料',
    'noStatsSubtitle': '新增旅行並記帳後，統計會顯示在這裡',
    'tripsCount': '趟旅行',
    'expensesCount': '筆消費',
    'totalSpending': '總花費',
    'totalBreakdown': '總消費結構',
    'perTripSpending': '各旅行花費',
    'details': '明細',
    'stats': '統計',
    'daysRemaining': '剩餘 {days} 天，每日可花 {amount}',
    'budgetRemaining': '距離預算上限還有 {amount}',
    'budgetOver': '已超過預算 {amount}',
    'ratePrefix': '匯率',
    'settings': '設定',
    'about': '關於',
    'version': '版本',
    'developer': '開發者',
    'exchangeRate': '匯率',
    'rateSource': '匯率來源',
    'updateFrequency': '更新頻率',
    'dailyOnce': '每日一次',
    'data': '資料',
    'storageMethod': '儲存方式',
    'storageDesc': '所有資料儲存在裝置本機，不會上傳至雲端',
    'exportAll': '匯出全部資料',
    'exportDesc': '將所有旅行的消費紀錄匯出為 CSV 檔案',
    'importData': '匯入資料',
    'importDesc': '從 CSV 檔案匯入消費紀錄',
    'language': '語言',
    'exportFailed': '匯出失敗',
    'importCsv': '匯入 CSV',
    'pasteCsvContent': '請將 CSV 檔案內容貼上：',
    'pasteCsvHint': '貼上 CSV 內容...',
    'parseFailed': '解析失敗',
    'confirmImport': '確認匯入',
    'importPreview': '即將匯入 {count} 筆消費',
    'importFailed': '匯入失敗',
    'saveFailed': '儲存失敗',
    'newLabel': '新增',
    'expenseUnit': '{count} 筆',
    'skippedLines': '{count} 筆無法解析，將略過',
  };

  static const _en = {
    'appName': 'TravelBudget',
    'cancel': 'Cancel',
    'delete': 'Delete',
    'save': 'Save',
    'confirm': 'OK',
    'next': 'Next',
    'edit': 'Edit',
    'tabTrips': 'Trips',
    'tabStats': 'Stats',
    'tabSettings': 'Settings',
    'noTripsTitle': 'No trips yet',
    'noTripsSubtitle': 'Tap the button below to start tracking',
    'deleteTrip': 'Delete Trip',
    'deleteTripConfirm': 'Are you sure? All expenses will be deleted.',
    'createdAt': 'Created',
    'newTrip': 'New Trip',
    'editTrip': 'Edit Trip',
    'tripName': 'Trip Name',
    'tripNameHint': 'e.g. Tokyo 2026',
    'tripNameRequired': 'Please enter a trip name',
    'startDate': 'Start Date',
    'endDate': 'End Date',
    'baseCurrency': 'Base Currency',
    'targetCurrency': 'Trip Currency',
    'noBudgetLimit': 'No budget limit',
    'budgetAmount': 'Budget',
    'budgetRequired': 'Please enter a budget',
    'invalidNumber': 'Please enter a valid number',
    'addCoverImage': 'Add cover image',
    'createTrip': 'Create Trip',
    'saveChanges': 'Save Changes',
    'newExpense': 'New Expense',
    'editExpense': 'Edit Expense',
    'category': 'Category',
    'itemName': 'Item',
    'itemNameHint': 'e.g. Ichiran Ramen',
    'itemNameRequired': 'Please enter an item name',
    'amount': 'Amount',
    'amountRequired': 'Please enter an amount',
    'invalidAmount': 'Invalid amount',
    'currency': 'Currency',
    'date': 'Date',
    'noteOptional': 'Note (optional)',
    'add': 'Add',
    'update': 'Update',
    'catFood': 'Food',
    'catClothing': 'Clothing',
    'catLodging': 'Lodging',
    'catTransport': 'Transport',
    'catEducation': 'Education',
    'catEntertainment': 'Fun',
    'spent': 'Spent',
    'budget': 'Budget',
    'remaining': 'Remaining',
    'overspent': 'Overspent',
    'noBudget': 'No limit',
    'noRecords': 'No records yet',
    'budgetProgress': 'Budget',
    'spendingBreakdown': 'Breakdown',
    'dailySpending': 'Daily Spending',
    'totalSpent': 'Total',
    'avgDaily': 'Daily Avg',
    'expenseCount': 'Expenses',
    'statsOverview': 'Overview',
    'noStatsTitle': 'No stats yet',
    'noStatsSubtitle': 'Add a trip and start tracking',
    'tripsCount': 'trips',
    'expensesCount': 'expenses',
    'totalSpending': 'Total Spending',
    'totalBreakdown': 'Overall Breakdown',
    'perTripSpending': 'Per Trip',
    'details': 'Details',
    'stats': 'Stats',
    'daysRemaining': '{days} days left, {amount}/day',
    'budgetRemaining': '{amount} under budget',
    'budgetOver': '{amount} over budget',
    'ratePrefix': 'Rate',
    'settings': 'Settings',
    'about': 'About',
    'version': 'Version',
    'developer': 'Developer',
    'exchangeRate': 'Exchange Rate',
    'rateSource': 'Rate Source',
    'updateFrequency': 'Update Frequency',
    'dailyOnce': 'Once daily',
    'data': 'Data',
    'storageMethod': 'Storage',
    'storageDesc': 'All data is stored locally on device',
    'exportAll': 'Export All Data',
    'exportDesc': 'Export all expenses to CSV',
    'importData': 'Import Data',
    'importDesc': 'Import expenses from CSV',
    'language': 'Language',
    'exportFailed': 'Export failed',
    'importCsv': 'Import CSV',
    'pasteCsvContent': 'Paste CSV content:',
    'pasteCsvHint': 'Paste CSV here...',
    'parseFailed': 'Parse failed',
    'confirmImport': 'Confirm Import',
    'importPreview': 'About to import {count} expenses',
    'importFailed': 'Import failed',
    'saveFailed': 'Save failed',
    'newLabel': 'New',
    'expenseUnit': '{count}',
    'skippedLines': '{count} lines skipped (unparseable)',
  };

  static const _ja = {
    'appName': '旅算 TravelBudget',
    'cancel': 'キャンセル',
    'delete': '削除',
    'save': '保存',
    'confirm': '確認',
    'next': '次へ',
    'edit': '編集',
    'tabTrips': '旅行',
    'tabStats': '統計',
    'tabSettings': '設定',
    'noTripsTitle': 'まだ旅行がありません',
    'noTripsSubtitle': '下のボタンをタップして旅行を追加',
    'deleteTrip': '旅行を削除',
    'deleteTripConfirm': 'この旅行を削除しますか？関連するすべての支出も削除されます。',
    'createdAt': '作成日',
    'newTrip': '旅行を追加',
    'editTrip': '旅行を編集',
    'tripName': '旅行名',
    'tripNameHint': '例：2026 東京花見',
    'tripNameRequired': '旅行名を入力してください',
    'startDate': '開始日',
    'endDate': '終了日',
    'baseCurrency': '基本通貨',
    'targetCurrency': '旅行通貨',
    'noBudgetLimit': '予算上限なし',
    'budgetAmount': '予算',
    'budgetRequired': '予算を入力してください',
    'invalidNumber': '有効な数字を入力してください',
    'addCoverImage': 'カバー画像を追加',
    'createTrip': '旅行を作成',
    'saveChanges': '変更を保存',
    'newExpense': '支出を追加',
    'editExpense': '支出を編集',
    'category': 'カテゴリ',
    'itemName': '項目名',
    'itemNameHint': '例：一蘭ラーメン',
    'itemNameRequired': '項目名を入力してください',
    'amount': '金額',
    'amountRequired': '金額を入力してください',
    'invalidAmount': '無効な金額',
    'currency': '通貨',
    'date': '日付',
    'noteOptional': 'メモ（任意）',
    'add': '追加',
    'update': '更新',
    'catFood': '食事',
    'catClothing': '衣類',
    'catLodging': '宿泊',
    'catTransport': '交通',
    'catEducation': '教育',
    'catEntertainment': '娯楽',
    'spent': '使用済み',
    'budget': '予算',
    'remaining': '残り',
    'overspent': '超過',
    'noBudget': '上限なし',
    'noRecords': 'まだ記録がありません',
    'budgetProgress': '予算進捗',
    'spendingBreakdown': '支出内訳',
    'dailySpending': '日別支出',
    'totalSpent': '合計',
    'avgDaily': '日平均',
    'expenseCount': '件数',
    'statsOverview': '統計概要',
    'noStatsTitle': '統計データなし',
    'noStatsSubtitle': '旅行を追加して記録を始めましょう',
    'tripsCount': '旅行',
    'expensesCount': '件の支出',
    'totalSpending': '総支出',
    'totalBreakdown': '全体の内訳',
    'perTripSpending': '旅行別支出',
    'details': '明細',
    'stats': '統計',
    'daysRemaining': '残り{days}日、1日あたり{amount}',
    'budgetRemaining': '予算まであと {amount}',
    'budgetOver': '予算を {amount} 超過',
    'ratePrefix': 'レート',
    'settings': '設定',
    'about': '情報',
    'version': 'バージョン',
    'developer': '開発者',
    'exchangeRate': '為替レート',
    'rateSource': 'レート元',
    'updateFrequency': '更新頻度',
    'dailyOnce': '1日1回',
    'data': 'データ',
    'storageMethod': '保存方法',
    'storageDesc': 'すべてのデータは端末内に保存されます',
    'exportAll': '全データをエクスポート',
    'exportDesc': 'すべての支出をCSVでエクスポート',
    'importData': 'データをインポート',
    'importDesc': 'CSVから支出をインポート',
    'language': '言語',
    'exportFailed': 'エクスポート失敗',
    'importCsv': 'CSVインポート',
    'pasteCsvContent': 'CSVの内容を貼り付け：',
    'pasteCsvHint': 'CSVを貼り付け...',
    'parseFailed': '解析失敗',
    'confirmImport': 'インポート確認',
    'importPreview': '{count}件の支出をインポートします',
    'importFailed': 'インポート失敗',
    'saveFailed': '保存失敗',
    'newLabel': '新規',
    'expenseUnit': '{count}件',
    'skippedLines': '{count}件は解析できません',
  };

  static const _ko = {
    'appName': '旅算 TravelBudget',
    'cancel': '취소',
    'delete': '삭제',
    'save': '저장',
    'confirm': '확인',
    'next': '다음',
    'edit': '편집',
    'tabTrips': '여행',
    'tabStats': '통계',
    'tabSettings': '설정',
    'noTripsTitle': '아직 여행이 없습니다',
    'noTripsSubtitle': '아래 버튼을 눌러 여행을 추가하세요',
    'deleteTrip': '여행 삭제',
    'deleteTripConfirm': '이 여행을 삭제하시겠습니까? 모든 관련 지출도 삭제됩니다.',
    'createdAt': '생성일',
    'newTrip': '여행 추가',
    'editTrip': '여행 편집',
    'tripName': '여행 이름',
    'tripNameHint': '예: 2026 도쿄 벚꽃',
    'tripNameRequired': '여행 이름을 입력하세요',
    'startDate': '시작일',
    'endDate': '종료일',
    'baseCurrency': '기본 통화',
    'targetCurrency': '여행 통화',
    'noBudgetLimit': '예산 제한 없음',
    'budgetAmount': '예산',
    'budgetRequired': '예산을 입력하세요',
    'invalidNumber': '유효한 숫자를 입력하세요',
    'addCoverImage': '커버 이미지 추가',
    'createTrip': '여행 만들기',
    'saveChanges': '변경 저장',
    'newExpense': '지출 추가',
    'editExpense': '지출 편집',
    'category': '카테고리',
    'itemName': '항목명',
    'itemNameHint': '예: 이치란 라멘',
    'itemNameRequired': '항목명을 입력하세요',
    'amount': '금액',
    'amountRequired': '금액을 입력하세요',
    'invalidAmount': '유효하지 않은 금액',
    'currency': '통화',
    'date': '날짜',
    'noteOptional': '메모 (선택)',
    'add': '추가',
    'update': '수정',
    'catFood': '식비',
    'catClothing': '의류',
    'catLodging': '숙박',
    'catTransport': '교통',
    'catEducation': '교육',
    'catEntertainment': '오락',
    'spent': '사용',
    'budget': '예산',
    'remaining': '남은',
    'overspent': '초과',
    'noBudget': '제한 없음',
    'noRecords': '기록이 없습니다',
    'budgetProgress': '예산 진행',
    'spendingBreakdown': '지출 구조',
    'dailySpending': '일별 지출',
    'totalSpent': '총액',
    'avgDaily': '일 평균',
    'expenseCount': '지출 수',
    'statsOverview': '통계 개요',
    'noStatsTitle': '통계 데이터 없음',
    'noStatsSubtitle': '여행을 추가하고 기록을 시작하세요',
    'tripsCount': '여행',
    'expensesCount': '건 지출',
    'totalSpending': '총 지출',
    'totalBreakdown': '전체 구조',
    'perTripSpending': '여행별 지출',
    'details': '내역',
    'stats': '통계',
    'daysRemaining': '{days}일 남음, 하루 {amount}',
    'budgetRemaining': '예산까지 {amount} 남음',
    'budgetOver': '예산 {amount} 초과',
    'ratePrefix': '환율',
    'settings': '설정',
    'about': '정보',
    'version': '버전',
    'developer': '개발자',
    'exchangeRate': '환율',
    'rateSource': '환율 출처',
    'updateFrequency': '업데이트 주기',
    'dailyOnce': '하루 1회',
    'data': '데이터',
    'storageMethod': '저장 방식',
    'storageDesc': '모든 데이터는 기기에 로컬로 저장됩니다',
    'exportAll': '전체 데이터 내보내기',
    'exportDesc': '모든 지출을 CSV로 내보내기',
    'importData': '데이터 가져오기',
    'importDesc': 'CSV에서 지출 가져오기',
    'language': '언어',
    'exportFailed': '내보내기 실패',
    'importCsv': 'CSV 가져오기',
    'pasteCsvContent': 'CSV 내용을 붙여넣기:',
    'pasteCsvHint': 'CSV를 붙여넣기...',
    'parseFailed': '분석 실패',
    'confirmImport': '가져오기 확인',
    'importPreview': '{count}건의 지출을 가져옵니다',
    'importFailed': '가져오기 실패',
    'saveFailed': '저장 실패',
    'newLabel': '신규',
    'expenseUnit': '{count}건',
    'skippedLines': '{count}건 분석 불가, 건너뜁니다',
  };

  static const _zhCN = {
    'appName': '旅算 TravelBudget',
    'cancel': '取消',
    'delete': '删除',
    'save': '保存',
    'confirm': '确认',
    'next': '下一步',
    'edit': '编辑',
    'tabTrips': '旅行',
    'tabStats': '统计',
    'tabSettings': '设置',
    'noTripsTitle': '还没有旅行计划',
    'noTripsSubtitle': '点击下方按钮，开始记录你的旅程',
    'deleteTrip': '删除旅行',
    'deleteTripConfirm': '确定要删除此旅行吗？所有相关的消费记录都会一并删除。',
    'createdAt': '创建于',
    'newTrip': '新增旅行',
    'editTrip': '编辑旅行',
    'tripName': '旅行名称',
    'tripNameHint': '例：2026 东京赏樱',
    'tripNameRequired': '请输入旅行名称',
    'startDate': '开始日期',
    'endDate': '结束日期',
    'baseCurrency': '主币别',
    'targetCurrency': '旅行币别',
    'noBudgetLimit': '不设定预算上限',
    'budgetAmount': '预算金额',
    'budgetRequired': '请输入预算金额',
    'invalidNumber': '请输入有效数字',
    'addCoverImage': '新增封面图',
    'createTrip': '创建旅行',
    'saveChanges': '保存更改',
    'newExpense': '新增消费',
    'editExpense': '编辑消费',
    'category': '分类',
    'itemName': '项目名称',
    'itemNameHint': '例：一兰拉面',
    'itemNameRequired': '请输入项目名称',
    'amount': '金额',
    'amountRequired': '请输入金额',
    'invalidAmount': '无效金额',
    'currency': '币别',
    'date': '日期',
    'noteOptional': '备注（选填）',
    'add': '新增',
    'update': '更新',
    'catFood': '饮食',
    'catClothing': '服饰',
    'catLodging': '住宿',
    'catTransport': '交通',
    'catEducation': '教育',
    'catEntertainment': '娱乐',
    'spent': '已花费',
    'budget': '预算',
    'remaining': '剩余',
    'overspent': '超支',
    'noBudget': '无预算上限',
    'noRecords': '尚无消费记录',
    'budgetProgress': '预算进度',
    'spendingBreakdown': '消费结构',
    'dailySpending': '每日花费',
    'totalSpent': '总花费',
    'avgDaily': '平均每日',
    'expenseCount': '消费笔数',
    'statsOverview': '统计总览',
    'noStatsTitle': '尚无统计资料',
    'noStatsSubtitle': '新增旅行并记账后，统计会显示在这里',
    'tripsCount': '趟旅行',
    'expensesCount': '笔消费',
    'totalSpending': '总花费',
    'totalBreakdown': '总消费结构',
    'perTripSpending': '各旅行花费',
    'details': '明细',
    'stats': '统计',
    'daysRemaining': '剩余 {days} 天，每日可花 {amount}',
    'budgetRemaining': '距离预算上限还有 {amount}',
    'budgetOver': '已超过预算 {amount}',
    'ratePrefix': '汇率',
    'settings': '设置',
    'about': '关于',
    'version': '版本',
    'developer': '开发者',
    'exchangeRate': '汇率',
    'rateSource': '汇率来源',
    'updateFrequency': '更新频率',
    'dailyOnce': '每日一次',
    'data': '数据',
    'storageMethod': '储存方式',
    'storageDesc': '所有数据储存在设备本机，不会上传至云端',
    'exportAll': '导出全部数据',
    'exportDesc': '将所有旅行的消费记录导出为 CSV 文件',
    'importData': '导入数据',
    'importDesc': '从 CSV 文件导入消费记录',
    'language': '语言',
    'exportFailed': '导出失败',
    'importCsv': '导入 CSV',
    'pasteCsvContent': '请将 CSV 文件内容粘贴：',
    'pasteCsvHint': '粘贴 CSV 内容...',
    'parseFailed': '解析失败',
    'confirmImport': '确认导入',
    'importPreview': '即将导入 {count} 笔消费',
    'importFailed': '导入失败',
    'saveFailed': '保存失败',
    'newLabel': '新增',
    'expenseUnit': '{count} 笔',
    'skippedLines': '{count} 笔无法解析，将略过',
  };
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  bool isSupported(Locale locale) {
    if (locale.languageCode == 'zh') {
      return locale.countryCode == 'TW' || locale.countryCode == 'CN';
    }
    return ['en', 'ja', 'ko'].contains(locale.languageCode);
  }

  @override
  Future<AppLocalizations> load(Locale locale) async {
    return AppLocalizations(locale);
  }

  @override
  bool shouldReload(covariant LocalizationsDelegate<AppLocalizations> old) =>
      false;
}

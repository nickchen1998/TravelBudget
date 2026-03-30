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
  String get leave => _t('leave');
  String get leaveTrip => _t('leaveTrip');
  String get leaveTripConfirm => _t('leaveTripConfirm');
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

  // === Sharing ===
  String get shareTrip => _t('shareTrip');
  String get shareAsEditor => _t('shareAsEditor');
  String get shareAsViewer => _t('shareAsViewer');
  String get shareLinkCopied => _t('shareLinkCopied');
  String get shareInviteTitle => _t('shareInviteTitle');
  String get shareInviteDesc => _t('shareInviteDesc');
  String get joinTrip => _t('joinTrip');
  String get joinTripDesc => _t('joinTripDesc');
  String get joinWithCode => _t('joinWithCode');
  String get joinWithCodeDesc => _t('joinWithCodeDesc');
  String get inviteCode => _t('inviteCode');
  String get inviteCodeDesc => _t('inviteCodeDesc');
  String get inviteCodeExpiry => _t('inviteCodeExpiry');
  String get copyCode => _t('copyCode');
  String get codeCopied => _t('codeCopied');
  String get regenerateCode => _t('regenerateCode');
  String get enterInviteCode => _t('enterInviteCode');
  String get loginRequired => _t('loginRequired');
  String get loginRequiredDesc => _t('loginRequiredDesc');
  String get newTripDesc => _t('newTripDesc');
  String get joinSuccess => _t('joinSuccess');
  String get joinFailed => _t('joinFailed');
  String get sharedBadge => _t('sharedBadge');
  String get memberCount => _t('memberCount');
  String get roleOwner => _t('roleOwner');
  String get roleEditor => _t('roleEditor');
  String get roleViewer => _t('roleViewer');
  String get signInToShare => _t('signInToShare');
  String get signInToJoin => _t('signInToJoin');
  String get members => _t('members');
  String get inviteLink => _t('inviteLink');
  String get generateLink => _t('generateLink');
  String get linkExpiry => _t('linkExpiry');

  // === Account / Cloud ===
  String get account => _t('account');
  String get signInWithApple => _t('signInWithApple');
  String get signInDesc => _t('signInDesc');
  String get signOut => _t('signOut');
  String get signOutConfirm => _t('signOutConfirm');
  String get signInFailed => _t('signInFailed');
  String get signedInAs => _t('signedInAs');
  String get offlineReadOnly => _t('offlineReadOnly');
  String get offlineBanner => _t('offlineBanner');
  String get networkRequiredError => _t('networkRequiredError');
  String get syncFailed => _t('syncFailed');
  String get deleteAccount => _t('deleteAccount');
  String get deleteAccountConfirm => _t('deleteAccountConfirm');
  String get deleteAccountWarning => _t('deleteAccountWarning');
  String get deleteAccountFailed => _t('deleteAccountFailed');
  String get editNickname => _t('editNickname');
  String get nicknameHint => _t('nicknameHint');
  String get nicknameSaved => _t('nicknameSaved');
  String get nicknameFailed => _t('nicknameFailed');
  String get cloudBackup => _t('cloudBackup');
  String get cloudBackupDesc => _t('cloudBackupDesc');
  String get cloudBackupSignInCta => _t('cloudBackupSignInCta');
  String get syncing => _t('syncing');
  String get preparingLink => _t('preparingLink');
  String get linkCopied => _t('linkCopied');
  String get syncNow => _t('syncNow');
  String get lastSynced => _t('lastSynced');
  String get neverSynced => _t('neverSynced');
  String lastSyncedTime(String time) =>
      _t('lastSyncedTime').replaceAll('{time}', time);

  // === Ads / Purchase ===
  String get removeAds => _t('removeAds');
  String get removeAdsDesc => _t('removeAdsDesc');
  String get restorePurchase => _t('restorePurchase');
  String get restorePurchaseDesc => _t('restorePurchaseDesc');
  String get noPurchaseFound => _t('noPurchaseFound');
  String get purchaseSuccess => _t('purchaseSuccess');
  String get purchaseRestored => _t('purchaseRestored');
  String get purchaseFailed => _t('purchaseFailed');
  String get adsAlreadyRemoved => _t('adsAlreadyRemoved');

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
    'appName': '熊好算 TravelBudget',
    'cancel': '取消',
    'delete': '刪除',
    'leave': '退出',
    'leaveTrip': '退出旅程',
    'leaveTripConfirm': '確定要退出此旅程嗎？您過去新增的消費紀錄將會保留。',
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
    'shareTrip': '分享旅程',
    'shareAsEditor': '可編輯',
    'shareAsViewer': '僅查看',
    'shareLinkCopied': '連結已複製',
    'shareInviteTitle': '邀請夥伴',
    'shareInviteDesc': '分享連結給朋友，一起記帳旅程',
    'joinTrip': '加入旅程',
    'joinTripDesc': '你被邀請加入旅程，登入後即可查看',
    'joinWithCode': '使用邀請碼加入',
    'joinWithCodeDesc': '輸入邀請碼即可加入他人的旅程',
    'inviteCode': '邀請碼',
    'inviteCodeDesc': '將此邀請碼分享給朋友，對方登入後輸入即可加入',
    'inviteCodeExpiry': '有效期 7 天 · 最多 50 人',
    'copyCode': '複製邀請碼',
    'codeCopied': '已複製',
    'regenerateCode': '重新產生邀請碼',
    'enterInviteCode': '輸入邀請碼',
    'loginRequired': '需要登入',
    'loginRequiredDesc': '加入共享旅程前，請先以 Apple 帳號登入',
    'newTripDesc': '建立一個全新的旅程',
    'joinSuccess': '已成功加入旅程！',
    'joinFailed': '加入失敗',
    'sharedBadge': '共享',
    'memberCount': '人協作',
    'roleOwner': '擁有者',
    'roleEditor': '協作者',
    'roleViewer': '查看者',
    'signInToShare': '需要登入才能分享旅程',
    'signInToJoin': '需要登入才能加入旅程',
    'members': '成員',
    'inviteLink': '邀請連結',
    'generateLink': '產生連結',
    'linkExpiry': '連結 7 天後到期',
    'account': '帳號',
    'signInWithApple': '使用 Apple 登入',
    'signInDesc': '登入後可分享旅程給朋友一起記帳',
    'signOut': '登出',
    'signOutConfirm': '確定要登出嗎？',
    'signInFailed': '登入失敗',
    'signedInAs': '已登入',
    'offlineReadOnly': '協作旅程離線中，僅可查閱，無法新增或編輯',
    'offlineBanner': '目前尚未連上網路，顯示快取資料',
    'networkRequiredError': '需要網路連線才能執行此操作',
    'syncFailed': '同步失敗，請稍後再試',
    'deleteAccount': '刪除帳號',
    'deleteAccountConfirm': '確定要刪除帳號？',
    'deleteAccountWarning': '• 你在別人旅程中的共編權限將被移除\n• 你擁有的旅程協作成員將被踢出\n• 本機旅程資料仍保留，但不再同步\n\n此操作無法復原。',
    'deleteAccountFailed': '刪除帳號失敗',
    'editNickname': '編輯暱稱',
    'nicknameHint': '輸入暱稱（顯示給協作者看）',
    'nicknameSaved': '暱稱已更新',
    'nicknameFailed': '更新暱稱失敗',
    'cloudBackup': '雲端備份',
    'cloudBackupDesc': '登入後資料自動備份到雲端，換機也不怕遺失',
    'cloudBackupSignInCta': '登入以備份資料',
    'syncing': '同步中...',
    'preparingLink': '正在準備連結...',
    'linkCopied': '連結已複製到剪貼簿',
    'syncNow': '立即同步',
    'lastSynced': '上次同步',
    'neverSynced': '尚未同步',
    'lastSyncedTime': '上次同步：{time}',
    'removeAds': '移除廣告',
    'removeAdsDesc': '一次購買，永久移除所有廣告',
    'restorePurchase': '恢復購買',
    'restorePurchaseDesc': '若曾在此 Apple ID 購買過，可在此恢復',
    'noPurchaseFound': '找不到購買紀錄，請確認使用相同的 Apple ID',
    'purchaseSuccess': '已成功移除廣告！',
    'purchaseRestored': '已恢復購買',
    'purchaseFailed': '購買失敗',
    'adsAlreadyRemoved': '廣告已移除',
  };

  static const _en = {
    'appName': 'TravelBudget',
    'cancel': 'Cancel',
    'delete': 'Delete',
    'leave': 'Leave',
    'leaveTrip': 'Leave Trip',
    'leaveTripConfirm': 'Are you sure you want to leave? Your expenses will be kept.',
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
    'shareTrip': 'Share Trip',
    'shareAsEditor': 'Can Edit',
    'shareAsViewer': 'View Only',
    'shareLinkCopied': 'Link copied',
    'shareInviteTitle': 'Invite Others',
    'shareInviteDesc': 'Share a link to collaborate on this trip',
    'joinTrip': 'Join Trip',
    'joinTripDesc': 'You have been invited. Sign in to join.',
    'joinWithCode': 'Join with Invite Code',
    'joinWithCodeDesc': 'Enter an invite code to join someone\'s trip',
    'inviteCode': 'Invite Code',
    'inviteCodeDesc': 'Share this code with friends. They can join after signing in.',
    'inviteCodeExpiry': 'Valid for 7 days · up to 50 uses',
    'copyCode': 'Copy Code',
    'codeCopied': 'Copied',
    'regenerateCode': 'Regenerate Code',
    'enterInviteCode': 'Enter Invite Code',
    'loginRequired': 'Sign In Required',
    'loginRequiredDesc': 'Please sign in with Apple before joining a shared trip',
    'newTripDesc': 'Create a brand new trip',
    'joinSuccess': 'Joined successfully!',
    'joinFailed': 'Failed to join',
    'sharedBadge': 'Shared',
    'memberCount': ' members',
    'roleOwner': 'Owner',
    'roleEditor': 'Collaborator',
    'roleViewer': 'Viewer',
    'signInToShare': 'Sign in to share this trip',
    'signInToJoin': 'Sign in to join this trip',
    'members': 'Members',
    'inviteLink': 'Invite Link',
    'generateLink': 'Generate Link',
    'linkExpiry': 'Link expires in 7 days',
    'account': 'Account',
    'signInWithApple': 'Sign in with Apple',
    'signInDesc': 'Sign in to share trips with friends',
    'signOut': 'Sign Out',
    'signOutConfirm': 'Are you sure you want to sign out?',
    'signInFailed': 'Sign in failed',
    'signedInAs': 'Signed in',
    'offlineReadOnly': 'Collaborative trip is offline — read-only',
    'offlineBanner': 'No internet connection — showing cached data',
    'networkRequiredError': 'Internet connection required',
    'syncFailed': 'Sync failed, please try again',
    'deleteAccount': 'Delete Account',
    'deleteAccountConfirm': 'Delete your account?',
    'deleteAccountWarning': '• You will lose access to trips you collaborate on\n• Members of your shared trips will lose access\n• Local trip data is kept but will no longer sync\n\nThis action cannot be undone.',
    'deleteAccountFailed': 'Failed to delete account',
    'editNickname': 'Edit Nickname',
    'nicknameHint': 'Shown to collaborators',
    'nicknameSaved': 'Nickname saved',
    'nicknameFailed': 'Failed to update nickname',
    'cloudBackup': 'Cloud Backup',
    'cloudBackupDesc': 'Sign in to back up your data automatically',
    'cloudBackupSignInCta': 'Sign in to back up data',
    'syncing': 'Syncing...',
    'preparingLink': 'Preparing link...',
    'linkCopied': 'Link copied to clipboard',
    'syncNow': 'Sync Now',
    'lastSynced': 'Last synced',
    'neverSynced': 'Never synced',
    'lastSyncedTime': 'Last synced: {time}',
    'removeAds': 'Remove Ads',
    'removeAdsDesc': 'One-time purchase to remove all ads',
    'restorePurchase': 'Restore Purchase',
    'restorePurchaseDesc': 'Restore a previous purchase made with this Apple ID',
    'noPurchaseFound': 'No purchase found for this Apple ID',
    'purchaseSuccess': 'Ads removed successfully!',
    'purchaseRestored': 'Purchase restored',
    'purchaseFailed': 'Purchase failed',
    'adsAlreadyRemoved': 'Ads already removed',
  };

  static const _ja = {
    'appName': '熊好算 TravelBudget',
    'cancel': 'キャンセル',
    'delete': '削除',
    'leave': '退出',
    'leaveTrip': '旅行から退出',
    'leaveTripConfirm': 'この旅行から退出しますか？追加した支出記録は保持されます。',
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
    'shareTrip': '旅行を共有',
    'shareAsEditor': '編集可能',
    'shareAsViewer': '閲覧のみ',
    'shareLinkCopied': 'リンクをコピーしました',
    'shareInviteTitle': '仲間を招待',
    'shareInviteDesc': 'リンクを共有して一緒に記録',
    'joinTrip': '旅行に参加',
    'joinTripDesc': '招待されました。サインインして参加してください。',
    'joinWithCode': '招待コードで参加',
    'joinWithCodeDesc': '招待コードを入力して旅行に参加できます',
    'inviteCode': '招待コード',
    'inviteCodeDesc': 'このコードを友達に共有してください。サインイン後に参加できます。',
    'inviteCodeExpiry': '有効期間 7 日 · 最大 50 名',
    'copyCode': 'コードをコピー',
    'codeCopied': 'コピーしました',
    'regenerateCode': 'コードを再生成',
    'enterInviteCode': '招待コードを入力',
    'loginRequired': 'サインインが必要です',
    'loginRequiredDesc': '共有旅行に参加する前にAppleアカウントでサインインしてください',
    'newTripDesc': '新しい旅行を作成する',
    'joinSuccess': '旅行に参加しました！',
    'joinFailed': '参加に失敗しました',
    'sharedBadge': '共有',
    'memberCount': '人',
    'roleOwner': 'オーナー',
    'roleEditor': '協力者',
    'roleViewer': '閲覧者',
    'signInToShare': '共有するにはサインインが必要です',
    'signInToJoin': '参加するにはサインインが必要です',
    'members': 'メンバー',
    'inviteLink': '招待リンク',
    'generateLink': 'リンクを生成',
    'linkExpiry': 'リンクは7日後に期限切れ',
    'account': 'アカウント',
    'signInWithApple': 'Appleでサインイン',
    'signInDesc': 'サインインして旅行を友達と共有',
    'signOut': 'サインアウト',
    'signOutConfirm': 'サインアウトしますか？',
    'signInFailed': 'サインインに失敗しました',
    'signedInAs': 'サインイン中',
    'offlineReadOnly': '共同旅程はオフライン中のため閲覧のみ可能です',
    'offlineBanner': 'インターネット未接続 — キャッシュデータを表示中',
    'networkRequiredError': 'この操作にはネット接続が必要です',
    'syncFailed': '同期に失敗しました。後でもう一度お試しください',
    'deleteAccount': 'アカウント削除',
    'deleteAccountConfirm': 'アカウントを削除しますか？',
    'deleteAccountWarning': '• 参加している共同旅程へのアクセスが失われます\n• あなたが所有する旅程の共同編集者が削除されます\n• ローカルデータは保持されますが同期されなくなります\n\nこの操作は元に戻せません。',
    'deleteAccountFailed': 'アカウントの削除に失敗しました',
    'editNickname': 'ニックネームを編集',
    'nicknameHint': '共同作業者に表示されます',
    'nicknameSaved': 'ニックネームを更新しました',
    'nicknameFailed': 'ニックネームの更新に失敗しました',
    'cloudBackup': 'クラウドバックアップ',
    'cloudBackupDesc': 'サインインしてデータを自動バックアップ',
    'cloudBackupSignInCta': 'データをバックアップするにはサインイン',
    'syncing': '同期中...',
    'preparingLink': 'リンクを準備中...',
    'linkCopied': 'リンクをクリップボードにコピーしました',
    'syncNow': '今すぐ同期',
    'lastSynced': '最終同期',
    'neverSynced': '未同期',
    'lastSyncedTime': '最終同期：{time}',
    'removeAds': '広告を削除',
    'removeAdsDesc': '一度の購入ですべての広告を削除',
    'restorePurchase': '購入を復元',
    'restorePurchaseDesc': 'この Apple ID で以前購入した場合は復元できます',
    'noPurchaseFound': 'この Apple ID に購入履歴が見つかりません',
    'purchaseSuccess': '広告を削除しました！',
    'purchaseRestored': '購入を復元しました',
    'purchaseFailed': '購入に失敗しました',
    'adsAlreadyRemoved': '広告は削除済みです',
  };

  static const _ko = {
    'appName': '熊好算 TravelBudget',
    'cancel': '취소',
    'delete': '삭제',
    'leave': '나가기',
    'leaveTrip': '여행 나가기',
    'leaveTripConfirm': '이 여행에서 나가시겠습니까? 추가한 지출 기록은 유지됩니다.',
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
    'shareTrip': '여행 공유',
    'shareAsEditor': '편집 가능',
    'shareAsViewer': '보기만',
    'shareLinkCopied': '링크 복사됨',
    'shareInviteTitle': '친구 초대',
    'shareInviteDesc': '링크를 공유하여 함께 기록하세요',
    'joinTrip': '여행 참가',
    'joinTripDesc': '초대받으셨습니다. 로그인하여 참가하세요.',
    'joinWithCode': '초대 코드로 참가',
    'joinWithCodeDesc': '초대 코드를 입력하여 여행에 참가하세요',
    'inviteCode': '초대 코드',
    'inviteCodeDesc': '이 코드를 친구에게 공유하세요. 로그인 후 참가할 수 있습니다.',
    'inviteCodeExpiry': '유효 기간 7일 · 최대 50명',
    'copyCode': '코드 복사',
    'codeCopied': '복사됨',
    'regenerateCode': '코드 재생성',
    'enterInviteCode': '초대 코드 입력',
    'loginRequired': '로그인 필요',
    'loginRequiredDesc': '공유 여행에 참가하기 전에 Apple 계정으로 로그인하세요',
    'newTripDesc': '새로운 여행 만들기',
    'joinSuccess': '여행에 참가했습니다!',
    'joinFailed': '참가 실패',
    'sharedBadge': '공유',
    'memberCount': '명',
    'roleOwner': '소유자',
    'roleEditor': '협력자',
    'roleViewer': '뷰어',
    'signInToShare': '여행을 공유하려면 로그인이 필요합니다',
    'signInToJoin': '여행에 참가하려면 로그인이 필요합니다',
    'members': '멤버',
    'inviteLink': '초대 링크',
    'generateLink': '링크 생성',
    'linkExpiry': '링크는 7일 후 만료',
    'account': '계정',
    'signInWithApple': 'Apple로 로그인',
    'signInDesc': '로그인하여 친구와 여행을 공유하세요',
    'signOut': '로그아웃',
    'signOutConfirm': '로그아웃하시겠습니까?',
    'signInFailed': '로그인 실패',
    'signedInAs': '로그인됨',
    'offlineReadOnly': '공동 여행 오프라인 중 — 읽기 전용',
    'offlineBanner': '인터넷 미연결 — 캐시 데이터 표시 중',
    'networkRequiredError': '이 작업을 위해 인터넷 연결이 필요합니다',
    'syncFailed': '동기화 실패, 나중에 다시 시도해주세요',
    'deleteAccount': '계정 삭제',
    'deleteAccountConfirm': '계정을 삭제하시겠습니까？',
    'deleteAccountWarning': '• 참여 중인 공동 여행의 접근 권한이 제거됩니다\n• 소유한 여행의 공동 편집자가 제거됩니다\n• 로컬 데이터는 유지되지만 동기화되지 않습니다\n\n이 작업은 되돌릴 수 없습니다.',
    'deleteAccountFailed': '계정 삭제 실패',
    'editNickname': '닉네임 편집',
    'nicknameHint': '공동 작업자에게 표시됩니다',
    'nicknameSaved': '닉네임이 저장되었습니다',
    'nicknameFailed': '닉네임 업데이트 실패',
    'cloudBackup': '클라우드 백업',
    'cloudBackupDesc': '로그인하면 데이터가 자동으로 백업됩니다',
    'cloudBackupSignInCta': '데이터 백업을 위해 로그인',
    'syncing': '동기화 중...',
    'preparingLink': '링크 준비 중...',
    'linkCopied': '링크가 클립보드에 복사되었습니다',
    'syncNow': '지금 동기화',
    'lastSynced': '마지막 동기화',
    'neverSynced': '동기화 안 됨',
    'lastSyncedTime': '마지막 동기화: {time}',
    'removeAds': '광고 제거',
    'removeAdsDesc': '한 번 구매로 모든 광고 제거',
    'restorePurchase': '구매 복원',
    'restorePurchaseDesc': '이 Apple ID로 이전에 구매한 경우 복원할 수 있습니다',
    'noPurchaseFound': '이 Apple ID에서 구매 내역을 찾을 수 없습니다',
    'purchaseSuccess': '광고가 제거되었습니다!',
    'purchaseRestored': '구매가 복원되었습니다',
    'purchaseFailed': '구매 실패',
    'adsAlreadyRemoved': '광고가 이미 제거되었습니다',
  };

  static const _zhCN = {
    'appName': '熊好算 TravelBudget',
    'cancel': '取消',
    'delete': '删除',
    'leave': '退出',
    'leaveTrip': '退出旅程',
    'leaveTripConfirm': '确定要退出此旅程吗？您添加的消费记录将会保留。',
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
    'shareTrip': '分享旅程',
    'shareAsEditor': '可编辑',
    'shareAsViewer': '仅查看',
    'shareLinkCopied': '链接已复制',
    'shareInviteTitle': '邀请伙伴',
    'shareInviteDesc': '分享链接给朋友，一起记账旅程',
    'joinTrip': '加入旅程',
    'joinTripDesc': '你被邀请加入旅程，登录后即可查看',
    'joinWithCode': '使用邀请码加入',
    'joinWithCodeDesc': '输入邀请码即可加入他人的旅程',
    'inviteCode': '邀请码',
    'inviteCodeDesc': '将此邀请码分享给朋友，对方登录后输入即可加入',
    'inviteCodeExpiry': '有效期 7 天 · 最多 50 人',
    'copyCode': '复制邀请码',
    'codeCopied': '已复制',
    'regenerateCode': '重新生成邀请码',
    'enterInviteCode': '输入邀请码',
    'loginRequired': '需要登录',
    'loginRequiredDesc': '加入共享旅程前，请先以 Apple 账号登录',
    'newTripDesc': '创建一个全新的旅程',
    'joinSuccess': '已成功加入旅程！',
    'joinFailed': '加入失败',
    'sharedBadge': '共享',
    'memberCount': '人协作',
    'roleOwner': '拥有者',
    'roleEditor': '协作者',
    'roleViewer': '查看者',
    'signInToShare': '需要登录才能分享旅程',
    'signInToJoin': '需要登录才能加入旅程',
    'members': '成员',
    'inviteLink': '邀请链接',
    'generateLink': '生成链接',
    'linkExpiry': '链接 7 天后到期',
    'account': '账号',
    'signInWithApple': '使用 Apple 登录',
    'signInDesc': '登录后可分享旅程给朋友一起记账',
    'signOut': '退出登录',
    'signOutConfirm': '确定要退出登录吗？',
    'signInFailed': '登录失败',
    'signedInAs': '已登录',
    'offlineReadOnly': '协作旅程离线中，仅可查阅，无法新增或编辑',
    'offlineBanner': '当前未连接网络，显示缓存数据',
    'networkRequiredError': '执行此操作需要网络连接',
    'syncFailed': '同步失败，请稍后再试',
    'deleteAccount': '删除账号',
    'deleteAccountConfirm': '确定要删除账号？',
    'deleteAccountWarning': '• 您将失去参与的协作旅程访问权限\n• 您拥有的旅程协作成员将被移除\n• 本地旅程数据保留，但不再同步\n\n此操作无法撤销。',
    'deleteAccountFailed': '删除账号失败',
    'editNickname': '编辑昵称',
    'nicknameHint': '显示给协作者',
    'nicknameSaved': '昵称已更新',
    'nicknameFailed': '更新昵称失败',
    'cloudBackup': '云端备份',
    'cloudBackupDesc': '登录后数据自动备份到云端，换机也不怕丢失',
    'cloudBackupSignInCta': '登录以备份数据',
    'syncing': '同步中...',
    'preparingLink': '正在准备链接...',
    'linkCopied': '链接已复制到剪贴板',
    'syncNow': '立即同步',
    'lastSynced': '上次同步',
    'neverSynced': '尚未同步',
    'lastSyncedTime': '上次同步：{time}',
    'removeAds': '移除广告',
    'removeAdsDesc': '一次购买，永久移除所有广告',
    'restorePurchase': '恢复购买',
    'restorePurchaseDesc': '若曾使用此 Apple ID 购买过，可在此恢复',
    'noPurchaseFound': '未找到购买记录，请确认使用相同的 Apple ID',
    'purchaseSuccess': '已成功移除广告！',
    'purchaseRestored': '已恢复购买',
    'purchaseFailed': '购买失败',
    'adsAlreadyRemoved': '广告已移除',
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

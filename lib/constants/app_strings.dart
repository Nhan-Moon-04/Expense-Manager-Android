import '../l10n/app_localizations.dart';

class AppStrings {
  // App Info
  static String get appName => AppLocalizations.get('appName');
  static String get appVersion => AppLocalizations.get('appVersion');
  static String get appDescription => AppLocalizations.get('appDescription');

  // Auth Strings
  static String get login => AppLocalizations.get('login');
  static String get register => AppLocalizations.get('register');
  static String get logout => AppLocalizations.get('logout');
  static String get email => AppLocalizations.get('email');
  static String get password => AppLocalizations.get('password');
  static String get confirmPassword => AppLocalizations.get('confirmPassword');
  static String get fullName => AppLocalizations.get('fullName');
  static String get phone => AppLocalizations.get('phone');
  static String get forgotPassword => AppLocalizations.get('forgotPassword');
  static String get dontHaveAccount => AppLocalizations.get('dontHaveAccount');
  static String get alreadyHaveAccount =>
      AppLocalizations.get('alreadyHaveAccount');
  static String get resetPassword => AppLocalizations.get('resetPassword');

  // Navigation
  static String get home => AppLocalizations.get('home');
  static String get expenses => AppLocalizations.get('expenses');
  static String get notes => AppLocalizations.get('notes');
  static String get groups => AppLocalizations.get('groups');
  static String get profile => AppLocalizations.get('profile');

  // Expense
  static String get addExpense => AppLocalizations.get('addExpense');
  static String get editExpense => AppLocalizations.get('editExpense');
  static String get deleteExpense => AppLocalizations.get('deleteExpense');
  static String get amount => AppLocalizations.get('amount');
  static String get category => AppLocalizations.get('category');
  static String get date => AppLocalizations.get('date');
  static String get description => AppLocalizations.get('description');
  static String get income => AppLocalizations.get('income');
  static String get expense => AppLocalizations.get('expense');
  static String get totalBalance => AppLocalizations.get('totalBalance');
  static String get todayExpense => AppLocalizations.get('todayExpense');
  static String get monthlyExpense => AppLocalizations.get('monthlyExpense');

  // Categories
  static String get food => AppLocalizations.get('food');
  static String get transport => AppLocalizations.get('transport');
  static String get shopping => AppLocalizations.get('shopping');
  static String get entertainment => AppLocalizations.get('entertainment');
  static String get bills => AppLocalizations.get('bills');
  static String get health => AppLocalizations.get('health');
  static String get education => AppLocalizations.get('education');
  static String get other => AppLocalizations.get('other');

  // Notes
  static String get addNote => AppLocalizations.get('addNote');
  static String get editNote => AppLocalizations.get('editNote');
  static String get deleteNote => AppLocalizations.get('deleteNote');
  static String get noteTitle => AppLocalizations.get('noteTitle');
  static String get noteContent => AppLocalizations.get('noteContent');

  // Groups
  static String get createGroup => AppLocalizations.get('createGroup');
  static String get joinGroup => AppLocalizations.get('joinGroup');
  static String get leaveGroup => AppLocalizations.get('leaveGroup');
  static String get groupName => AppLocalizations.get('groupName');
  static String get groupMembers => AppLocalizations.get('groupMembers');
  static String get addMember => AppLocalizations.get('addMember');
  static String get sharedExpenses => AppLocalizations.get('sharedExpenses');
  static String get splitBill => AppLocalizations.get('splitBill');
  static String get groupCode => AppLocalizations.get('groupCode');

  // Reminders
  static String get reminders => AppLocalizations.get('reminders');
  static String get addReminder => AppLocalizations.get('addReminder');
  static String get editReminder => AppLocalizations.get('editReminder');
  static String get deleteReminder => AppLocalizations.get('deleteReminder');
  static String get reminderTitle => AppLocalizations.get('reminderTitle');
  static String get reminderTime => AppLocalizations.get('reminderTime');
  static String get reminderRepeat => AppLocalizations.get('reminderRepeat');

  // Profile
  static String get editProfile => AppLocalizations.get('editProfile');
  static String get settings => AppLocalizations.get('settings');
  static String get notifications => AppLocalizations.get('notifications');
  static String get changePassword => AppLocalizations.get('changePassword');
  static String get language => AppLocalizations.get('language');
  static String get currency => AppLocalizations.get('currency');
  static String get about => AppLocalizations.get('about');

  // Actions
  static String get save => AppLocalizations.get('save');
  static String get cancel => AppLocalizations.get('cancel');
  static String get delete => AppLocalizations.get('delete');
  static String get edit => AppLocalizations.get('edit');
  static String get add => AppLocalizations.get('add');
  static String get confirm => AppLocalizations.get('confirm');
  static String get search => AppLocalizations.get('search');
  static String get filter => AppLocalizations.get('filter');
  static String get sort => AppLocalizations.get('sort');

  // Messages
  static String get loading => AppLocalizations.get('loading');
  static String get success => AppLocalizations.get('success');
  static String get error => AppLocalizations.get('error');
  static String get noData => AppLocalizations.get('noData');
  static String get confirmDelete => AppLocalizations.get('confirmDelete');
  static String get loginSuccess => AppLocalizations.get('loginSuccess');
  static String get registerSuccess => AppLocalizations.get('registerSuccess');
  static String get logoutSuccess => AppLocalizations.get('logoutSuccess');
  static String get saveSuccess => AppLocalizations.get('saveSuccess');
  static String get deleteSuccess => AppLocalizations.get('deleteSuccess');
  static String get invalidEmail => AppLocalizations.get('invalidEmail');
  static String get invalidPassword => AppLocalizations.get('invalidPassword');
  static String get passwordNotMatch =>
      AppLocalizations.get('passwordNotMatch');
  static String get requiredField => AppLocalizations.get('requiredField');

  // Wallet
  static String get wallets => AppLocalizations.get('wallets');
  static String get walletManagement =>
      AppLocalizations.get('walletManagement');
  static String get primaryWallet => AppLocalizations.get('primaryWallet');
  static String get allWallets => AppLocalizations.get('allWallets');

  // Statistics
  static String get statistics => AppLocalizations.get('statistics');

  // Profile screen
  static String get theme => AppLocalizations.get('theme');
  static String get defaultUserName => AppLocalizations.get('defaultUserName');
  static String get otherSection => AppLocalizations.get('otherSection');
  static String get help => AppLocalizations.get('help');
  static String get selectLanguage => AppLocalizations.get('selectLanguage');
  static String get logoutConfirm => AppLocalizations.get('logoutConfirm');

  // Dashboard
  static String get growthGood => AppLocalizations.get('growthGood');
  static String get growthStable => AppLocalizations.get('growthStable');
  static String get growthSlightDrop =>
      AppLocalizations.get('growthSlightDrop');
  static String get growthDrop => AppLocalizations.get('growthDrop');
  static String get hideBalance => AppLocalizations.get('hideBalance');
  static String get showBalance => AppLocalizations.get('showBalance');
  static String get refresh => AppLocalizations.get('refresh');
  static String get viewDetails => AppLocalizations.get('viewDetails');
  static String get upcomingReminders =>
      AppLocalizations.get('upcomingReminders');
  static String get noTransactions => AppLocalizations.get('noTransactions');
  static String get addFirstExpense => AppLocalizations.get('addFirstExpense');
  static String get greetingMorning => AppLocalizations.get('greetingMorning');
  static String get greetingAfternoon =>
      AppLocalizations.get('greetingAfternoon');
  static String get greetingEvening => AppLocalizations.get('greetingEvening');
  static String get quickActions => AppLocalizations.get('quickActions');
  static String get recentTransactions =>
      AppLocalizations.get('recentTransactions');
  static String get viewAll => AppLocalizations.get('viewAll');
  static String get comparedToLastMonth =>
      AppLocalizations.get('comparedToLastMonth');

  // Expense list
  static String get manageYourTransactions =>
      AppLocalizations.get('manageYourTransactions');
  static String get searchExpenseHint =>
      AppLocalizations.get('searchExpenseHint');
  static String get selectWallet => AppLocalizations.get('selectWallet');
  static String get primaryBadge => AppLocalizations.get('primaryBadge');
  static String get monthBalance => AppLocalizations.get('monthBalance');
  static String get transactionsThisMonth =>
      AppLocalizations.get('transactionsThisMonth');
  static String get all => AppLocalizations.get('all');
  static String get addFirstTransaction =>
      AppLocalizations.get('addFirstTransaction');
  static String get autoBadge => AppLocalizations.get('autoBadge');
  static String get filterTitle => AppLocalizations.get('filterTitle');
  static String get allTransactions => AppLocalizations.get('allTransactions');
  static String get incomeOnly => AppLocalizations.get('incomeOnly');
  static String get expenseOnly => AppLocalizations.get('expenseOnly');
  static String get today => AppLocalizations.get('today');
  static String get yesterday => AppLocalizations.get('yesterday');

  // Add expense
  static String get updateSuccess => AppLocalizations.get('updateSuccess');
  static String get addSuccess => AppLocalizations.get('addSuccess');
  static String get errorOccurred => AppLocalizations.get('errorOccurred');
  static String get addIncome => AppLocalizations.get('addIncome');
  static String get editIncome => AppLocalizations.get('editIncome');
  static String get invalidAmount => AppLocalizations.get('invalidAmount');
  static String get descriptionHint => AppLocalizations.get('descriptionHint');
  static String get create => AppLocalizations.get('create');

  // Settings
  static String get displayName => AppLocalizations.get('displayName');
  static String get avatar => AppLocalizations.get('avatar');
  static String get tapCameraToChange =>
      AppLocalizations.get('tapCameraToChange');
  static String get changeAvatar => AppLocalizations.get('changeAvatar');
  static String get pickFromGallery => AppLocalizations.get('pickFromGallery');
  static String get takeNewPhoto => AppLocalizations.get('takeNewPhoto');
  static String get removeAvatar => AppLocalizations.get('removeAvatar');
  static String get avatarUpdated => AppLocalizations.get('avatarUpdated');
  static String get cannotUploadPhoto =>
      AppLocalizations.get('cannotUploadPhoto');
  static String get avatarRemoved => AppLocalizations.get('avatarRemoved');
  static String get changeDisplayName =>
      AppLocalizations.get('changeDisplayName');
  static String get enterYourName => AppLocalizations.get('enterYourName');
  static String get displayNameUpdated =>
      AppLocalizations.get('displayNameUpdated');
  static String get autoRecordExpense =>
      AppLocalizations.get('autoRecordExpense');
  static String get autoAddExpenseLabel =>
      AppLocalizations.get('autoAddExpenseLabel');
  static String get autoAddExpenseSubtitle =>
      AppLocalizations.get('autoAddExpenseSubtitle');
  static String get autoAddIncomeLabel =>
      AppLocalizations.get('autoAddIncomeLabel');
  static String get autoAddIncomeSubtitle =>
      AppLocalizations.get('autoAddIncomeSubtitle');
  static String get readBankNotifications =>
      AppLocalizations.get('readBankNotifications');
  static String get readBankNotificationsSubtitle =>
      AppLocalizations.get('readBankNotificationsSubtitle');
  static String get permissionRequired =>
      AppLocalizations.get('permissionRequired');
  static String get permissionRequiredSubtitle =>
      AppLocalizations.get('permissionRequiredSubtitle');
  static String get grantPermission => AppLocalizations.get('grantPermission');
  static String get supportedBanks => AppLocalizations.get('supportedBanks');
  static String get supportedBanksSubtitle =>
      AppLocalizations.get('supportedBanksSubtitle');
  static String get generalNotifications =>
      AppLocalizations.get('generalNotifications');
  static String get generalNotificationsSubtitle =>
      AppLocalizations.get('generalNotificationsSubtitle');
  static String get reminderNotificationsSubtitle =>
      AppLocalizations.get('reminderNotificationsSubtitle');
  static String get testNotification =>
      AppLocalizations.get('testNotification');
  static String get testNotificationSubtitle =>
      AppLocalizations.get('testNotificationSubtitle');
  static String get testNotificationSent =>
      AppLocalizations.get('testNotificationSent');
  static String get backupSubtitle => AppLocalizations.get('backupSubtitle');
  static String get restoreSubtitle => AppLocalizations.get('restoreSubtitle');
  static String get exportReportSubtitle =>
      AppLocalizations.get('exportReportSubtitle');
  static String get deleteAllDataSubtitle =>
      AppLocalizations.get('deleteAllDataSubtitle');
  static String get selectCurrency => AppLocalizations.get('selectCurrency');
  static String get restoreData => AppLocalizations.get('restoreData');
  static String get restoreConfirm => AppLocalizations.get('restoreConfirm');
  static String get restoreAction => AppLocalizations.get('restoreAction');
  static String get willPermanentlyDelete =>
      AppLocalizations.get('willPermanentlyDelete');
  static String get allNotes => AppLocalizations.get('allNotes');
  static String get allReminders => AppLocalizations.get('allReminders');
  static String get allNotifications =>
      AppLocalizations.get('allNotifications');
  static String get allGroups => AppLocalizations.get('allGroups');
  static String get accountWillBeKept =>
      AppLocalizations.get('accountWillBeKept');
  static String get autoBackupBeforeDelete =>
      AppLocalizations.get('autoBackupBeforeDelete');
  static String get deleteAll => AppLocalizations.get('deleteAll');
  static String get backingUpBeforeDelete =>
      AppLocalizations.get('backingUpBeforeDelete');
  static String get deletingAllData => AppLocalizations.get('deletingAllData');
  static String get info => AppLocalizations.get('info');
  static String get version => AppLocalizations.get('version');
  static String get checkingVersion => AppLocalizations.get('checkingVersion');
  static String get upToDate => AppLocalizations.get('upToDate');

  // Settings sections
  static String get account => AppLocalizations.get('account');
  static String get display => AppLocalizations.get('display');
  static String get dataSection => AppLocalizations.get('data');
  static String get dangerZone => AppLocalizations.get('dangerZone');
  static String get backup => AppLocalizations.get('backup');
  static String get restore => AppLocalizations.get('restore');
  static String get exportReport => AppLocalizations.get('exportReport');
  static String get deleteAllData => AppLocalizations.get('deleteAllData');
  static String get chooseTheme => AppLocalizations.get('chooseTheme');
  static String get lightTheme => AppLocalizations.get('lightTheme');
  static String get darkTheme => AppLocalizations.get('darkTheme');
  static String get systemTheme => AppLocalizations.get('systemTheme');

  // Backup/Restore/Delete
  static String get backupSuccess => AppLocalizations.get('backupSuccess');
  static String get backupDetail => AppLocalizations.get('backupDetail');
  static String get restoreNoBackup => AppLocalizations.get('restoreNoBackup');
  static String get unknown => AppLocalizations.get('unknown');
  static String get backupAt => AppLocalizations.get('backupAt');
  static String get transactionUnit => AppLocalizations.get('transactionUnit');
  static String get noteUnit => AppLocalizations.get('noteUnit');
  static String get reminderUnit => AppLocalizations.get('reminderUnit');
  static String get groupUnit => AppLocalizations.get('groupUnit');
  static String get expenseUnit => AppLocalizations.get('expenseUnit');
  static String get backupFileSaved => AppLocalizations.get('backupFileSaved');
  static String get currentVer => AppLocalizations.get('currentVer');
  static String get deleted => AppLocalizations.get('deleted');

  // Notes
  static String get searchNotesHint => AppLocalizations.get('searchNotesHint');
  static String get noNotesFound => AppLocalizations.get('noNotesFound');
  static String get noNotesYet => AppLocalizations.get('noNotesYet');
  static String get pinned => AppLocalizations.get('pinned');
  static String get unpin => AppLocalizations.get('unpin');
  static String get pin => AppLocalizations.get('pin');
  static String get deleteNoteConfirm =>
      AppLocalizations.get('deleteNoteConfirm');

  // Groups
  static String get yourGroups => AppLocalizations.get('yourGroups');
  static String get activeGroups => AppLocalizations.get('activeGroups');
  static String get totalContribution =>
      AppLocalizations.get('totalContribution');
  static String get target => AppLocalizations.get('target');
  static String get inProgress => AppLocalizations.get('inProgress');
  static String get join => AppLocalizations.get('join');
  static String get noGroupsYet => AppLocalizations.get('noGroupsYet');
  static String get noGroupsSubtitle =>
      AppLocalizations.get('noGroupsSubtitle');
  static String get membersCount => AppLocalizations.get('membersCount');
  static String get contributed => AppLocalizations.get('contributed');
  static String get spent => AppLocalizations.get('spent');
  static String get groupTarget => AppLocalizations.get('groupTarget');
  static String get joinGroupSubtitle =>
      AppLocalizations.get('joinGroupSubtitle');
  static String get groupCodeInvalid =>
      AppLocalizations.get('groupCodeInvalid');
  static String get joinGroupSuccess =>
      AppLocalizations.get('joinGroupSuccess');

  // Statistics
  static String get noStatisticsData =>
      AppLocalizations.get('noStatisticsData');
  static String get dailyExpense => AppLocalizations.get('dailyExpense');
  static String get monthlyBalanceStat =>
      AppLocalizations.get('monthlyBalanceStat');
  static String get expenseTransactionCount =>
      AppLocalizations.get('expenseTransactionCount');
  static String get incomeTransactionCount =>
      AppLocalizations.get('incomeTransactionCount');
  static String get transactionsSuffix =>
      AppLocalizations.get('transactionsSuffix');
  static String get avgDailyExpense => AppLocalizations.get('avgDailyExpense');
  static String get topSpendingDay => AppLocalizations.get('topSpendingDay');
  static String get noExpenseThisMonth =>
      AppLocalizations.get('noExpenseThisMonth');
  static String get salary => AppLocalizations.get('salary');
  static String get bonus => AppLocalizations.get('bonus');

  // Wallets
  static String get walletList => AppLocalizations.get('walletList');
  static String get walletCount => AppLocalizations.get('walletCount');
  static String get noWalletsYet => AppLocalizations.get('noWalletsYet');
  static String get noWalletsSubtitle =>
      AppLocalizations.get('noWalletsSubtitle');
  static String get enterWalletName => AppLocalizations.get('enterWalletName');
  static String get walletCreatedSuccess =>
      AppLocalizations.get('walletCreatedSuccess');

  // About
  static String get aboutApp => AppLocalizations.get('aboutApp');
  static String get versionPrefix => AppLocalizations.get('versionPrefix');
  static String get aboutDescription =>
      AppLocalizations.get('aboutDescription');
  static String get developer => AppLocalizations.get('developer');
  static String get phoneContact => AppLocalizations.get('phoneContact');

  // Help
  static String get helpTitle => AppLocalizations.get('helpTitle');
  static String get needHelp => AppLocalizations.get('needHelp');
  static String get alwaysReadyToHelp =>
      AppLocalizations.get('alwaysReadyToHelp');
  static String get faq => AppLocalizations.get('faq');
  static String get faqQuestion1 => AppLocalizations.get('faqQuestion1');
  static String get faqAnswer1 => AppLocalizations.get('faqAnswer1');
  static String get faqQuestion2 => AppLocalizations.get('faqQuestion2');
  static String get faqAnswer2 => AppLocalizations.get('faqAnswer2');
  static String get faqQuestion3 => AppLocalizations.get('faqQuestion3');
  static String get faqAnswer3 => AppLocalizations.get('faqAnswer3');
  static String get faqQuestion4 => AppLocalizations.get('faqQuestion4');
  static String get faqAnswer4 => AppLocalizations.get('faqAnswer4');
  static String get faqQuestion5 => AppLocalizations.get('faqQuestion5');
  static String get faqAnswer5 => AppLocalizations.get('faqAnswer5');
  static String get faqQuestion6 => AppLocalizations.get('faqQuestion6');
  static String get faqAnswer6 => AppLocalizations.get('faqAnswer6');
  static String get contactSupport => AppLocalizations.get('contactSupport');
  static String get facebookMessenger =>
      AppLocalizations.get('facebookMessenger');
  static String get zaloChat => AppLocalizations.get('zaloChat');
  static String get callPhone => AppLocalizations.get('callPhone');
  static String get reportBugGithub => AppLocalizations.get('reportBugGithub');

  // Misc
  static String get otherNotes => AppLocalizations.get('otherNotes');
  static String get wallet => AppLocalizations.get('wallet');
  static String get deleteNoteTitle => AppLocalizations.get('deleteNoteTitle');
  static String get dayPrefix => AppLocalizations.get('dayPrefix');

  // Statistics (additional)
  static String get categoryBreakdown =>
      AppLocalizations.get('categoryBreakdown');
  static String get incomeVsExpense => AppLocalizations.get('incomeVsExpense');
  static String get linkedBanks => AppLocalizations.get('linkedBanks');
  static String get createWallet => AppLocalizations.get('createWallet');

  // Auth - additional
  static String get loginFailed => AppLocalizations.get('loginFailed');
  static String get smartFinanceTagline =>
      AppLocalizations.get('smartFinanceTagline');
  static String get orDivider => AppLocalizations.get('orDivider');
  static String get loginWithGoogle => AppLocalizations.get('loginWithGoogle');
  static String get pleaseEnterEmail =>
      AppLocalizations.get('pleaseEnterEmail');
  static String get resetPasswordSent =>
      AppLocalizations.get('resetPasswordSent');
  static String get enterYourEmail => AppLocalizations.get('enterYourEmail');
  static String get registerFailed => AppLocalizations.get('registerFailed');
  static String get createAccountSubtitle =>
      AppLocalizations.get('createAccountSubtitle');
  static String get optionalLabel => AppLocalizations.get('optionalLabel');

  // Wallet detail
  static String get editWallet => AppLocalizations.get('editWallet');
  static String get deleteWallet => AppLocalizations.get('deleteWallet');
  static String get balance => AppLocalizations.get('balance');
  static String get noBanksAssigned => AppLocalizations.get('noBanksAssigned');
  static String get addBank => AppLocalizations.get('addBank');
  static String get searchBankHint => AppLocalizations.get('searchBankHint');
  static String get assigned => AppLocalizations.get('assigned');
  static String get assignedToOther => AppLocalizations.get('assignedToOther');
  static String get renameWallet => AppLocalizations.get('renameWallet');
  static String get enterNewName => AppLocalizations.get('enterNewName');
  static String get rename => AppLocalizations.get('rename');
  static String get walletRenamed => AppLocalizations.get('walletRenamed');
  static String get cannotDeletePrimary =>
      AppLocalizations.get('cannotDeletePrimary');
  static String get walletDeleted => AppLocalizations.get('walletDeleted');

  // Reminders - additional
  static String get active => AppLocalizations.get('active');
  static String get completedStatus => AppLocalizations.get('completedStatus');
  static String get noActiveReminders =>
      AppLocalizations.get('noActiveReminders');
  static String get noCompletedReminders =>
      AppLocalizations.get('noCompletedReminders');
  static String get deleteReminderConfirm =>
      AppLocalizations.get('deleteReminderConfirm');
  static String get disabled => AppLocalizations.get('disabled');

  // Add Reminder
  static String get pleaseEnterTitle =>
      AppLocalizations.get('pleaseEnterTitle');
  static String get reminderAddedSuccess =>
      AppLocalizations.get('reminderAddedSuccess');
  static String get reminderTitleHint =>
      AppLocalizations.get('reminderTitleHint');
  static String get relatedAmount => AppLocalizations.get('relatedAmount');
  static String get enterAmount => AppLocalizations.get('enterAmount');
  static String get enterDescription =>
      AppLocalizations.get('enterDescription');

  // Update dialog
  static String get forceUpdate => AppLocalizations.get('forceUpdate');
  static String get newVersionAvailable =>
      AppLocalizations.get('newVersionAvailable');
  static String get whatsNew => AppLocalizations.get('whatsNew');
  static String get mustUpdateMessage =>
      AppLocalizations.get('mustUpdateMessage');
  static String get downloadingProgress =>
      AppLocalizations.get('downloadingProgress');
  static String get updateNow => AppLocalizations.get('updateNow');
  static String get later => AppLocalizations.get('later');
  static String get installError => AppLocalizations.get('installError');

  // Notifications
  static String get unreadSuffix => AppLocalizations.get('unreadSuffix');
  static String get allRead => AppLocalizations.get('allRead');
  static String get markAllRead => AppLocalizations.get('markAllRead');
  static String get newNotificationsSuffix =>
      AppLocalizations.get('newNotificationsSuffix');
  static String get youHave => AppLocalizations.get('youHave');
  static String get tapToViewDetails =>
      AppLocalizations.get('tapToViewDetails');
  static String get readAll => AppLocalizations.get('readAll');
  static String get noNotifications => AppLocalizations.get('noNotifications');
  static String get noNotificationsSubtitle =>
      AppLocalizations.get('noNotificationsSubtitle');
  static String get thisWeek => AppLocalizations.get('thisWeek');
  static String get earlier => AppLocalizations.get('earlier');
  static String get justNow => AppLocalizations.get('justNow');
  static String get minutesAgo => AppLocalizations.get('minutesAgo');
  static String get hoursAgo => AppLocalizations.get('hoursAgo');
  static String get daysAgo => AppLocalizations.get('daysAgo');
  static String get deleteAllNotificationsConfirm =>
      AppLocalizations.get('deleteAllNotificationsConfirm');

  // Notes - additional
  static String get noteAddedSuccess =>
      AppLocalizations.get('noteAddedSuccess');
  static String get noteContentHint => AppLocalizations.get('noteContentHint');
  static String get chooseBackgroundColor =>
      AppLocalizations.get('chooseBackgroundColor');

  // Expense detail
  static String get transactionDetail =>
      AppLocalizations.get('transactionDetail');
  static String get source => AppLocalizations.get('source');
  static String get autoFromBank => AppLocalizations.get('autoFromBank');
  static String get createdAt => AppLocalizations.get('createdAt');
  static String get updatedAt => AppLocalizations.get('updatedAt');
  static String get deleteTransaction =>
      AppLocalizations.get('deleteTransaction');
  static String get deleteTransactionConfirm =>
      AppLocalizations.get('deleteTransactionConfirm');
  static String get transactionDeleted =>
      AppLocalizations.get('transactionDeleted');

  // Group detail
  static String get deleteGroup => AppLocalizations.get('deleteGroup');
  static String get overview => AppLocalizations.get('overview');
  static String get transactions => AppLocalizations.get('transactions');
  static String get members => AppLocalizations.get('members');
  static String get groupInfo => AppLocalizations.get('groupInfo');
  static String get noDescription => AppLocalizations.get('noDescription');
  static String get createdDate => AppLocalizations.get('createdDate');
  static String get groupInviteCode => AppLocalizations.get('groupInviteCode');
  static String get inviteCodeCopied =>
      AppLocalizations.get('inviteCodeCopied');
  static String get copyCode => AppLocalizations.get('copyCode');
  static String get remainingAmount => AppLocalizations.get('remainingAmount');
  static String get daysRemaining => AppLocalizations.get('daysRemaining');
  static String get daysUnit => AppLocalizations.get('daysUnit');
  static String get addTransactionHint =>
      AppLocalizations.get('addTransactionHint');
  static String get groupOwner => AppLocalizations.get('groupOwner');
  static String get adminRole => AppLocalizations.get('adminRole');
  static String get contributionLabel =>
      AppLocalizations.get('contributionLabel');
  static String get totalGroupExpense =>
      AppLocalizations.get('totalGroupExpense');
  static String get averagePrefix => AppLocalizations.get('averagePrefix');
  static String get perPerson => AppLocalizations.get('perPerson');
  static String get splitBillDetail => AppLocalizations.get('splitBillDetail');
  static String get receivable => AppLocalizations.get('receivable');
  static String get payable => AppLocalizations.get('payable');
  static String get inviteFriends => AppLocalizations.get('inviteFriends');
  static String get shareCodeToInvite =>
      AppLocalizations.get('shareCodeToInvite');

  // Create group
  static String get editGroup => AppLocalizations.get('editGroup');
  static String get createNewGroup => AppLocalizations.get('createNewGroup');
  static String get addPhoto => AppLocalizations.get('addPhoto');
  static String get groupAvatar => AppLocalizations.get('groupAvatar');
  static String get basicInfo => AppLocalizations.get('basicInfo');
  static String get groupNameExample =>
      AppLocalizations.get('groupNameExample');
  static String get pleaseEnterGroupName =>
      AppLocalizations.get('pleaseEnterGroupName');
  static String get groupDescriptionHint =>
      AppLocalizations.get('groupDescriptionHint');
  static String get fundingTarget => AppLocalizations.get('fundingTarget');
  static String get targetAmount => AppLocalizations.get('targetAmount');
  static String get targetName => AppLocalizations.get('targetName');
  static String get targetNameExample =>
      AppLocalizations.get('targetNameExample');
  static String get deadline => AppLocalizations.get('deadline');
  static String get selectDateOptional =>
      AppLocalizations.get('selectDateOptional');
  static String get saveChanges => AppLocalizations.get('saveChanges');
  static String get selectAvatar => AppLocalizations.get('selectAvatar');
  static String get takePhoto => AppLocalizations.get('takePhoto');
  static String get photoGallery => AppLocalizations.get('photoGallery');
  static String get groupUpdatedSuccess =>
      AppLocalizations.get('groupUpdatedSuccess');
  static String get groupCreatedSuccess =>
      AppLocalizations.get('groupCreatedSuccess');
  static String get deleteGroupConfirm =>
      AppLocalizations.get('deleteGroupConfirm');
  static String get addTransaction => AppLocalizations.get('addTransaction');
  static String get descriptionOptional =>
      AppLocalizations.get('descriptionOptional');
  static String get transactionAddedSuccess =>
      AppLocalizations.get('transactionAddedSuccess');
  static String get deleteGroupWarning =>
      AppLocalizations.get('deleteGroupWarning');
  static String get deleteGroupSuccess =>
      AppLocalizations.get('deleteGroupSuccess');
  static String get cannotDeleteGroup =>
      AppLocalizations.get('cannotDeleteGroup');
  static String get ownerCannotLeave =>
      AppLocalizations.get('ownerCannotLeave');
  static String get leaveGroupConfirm =>
      AppLocalizations.get('leaveGroupConfirm');
  static String get leftGroupSuccess =>
      AppLocalizations.get('leftGroupSuccess');
  static String get deleteGroupConfirmName =>
      AppLocalizations.get('deleteGroupConfirmName');
  static String get walletName => AppLocalizations.get('walletName');
  static String get walletBalance => AppLocalizations.get('walletBalance');
}

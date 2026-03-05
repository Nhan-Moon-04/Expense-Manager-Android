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
}

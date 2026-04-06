import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_ar.dart';
import 'app_localizations_en.dart';
import 'app_localizations_fa.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'translations/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('ar'),
    Locale('en'),
    Locale('fa'),
  ];

  /// No description provided for @hello.
  ///
  /// In en, this message translates to:
  /// **'Hello, {name}'**
  String hello(String name);

  /// No description provided for @required.
  ///
  /// In en, this message translates to:
  /// **'{name} is required'**
  String required(String name);

  /// No description provided for @requiredField.
  ///
  /// In en, this message translates to:
  /// **'Please fill all required fields in {name}'**
  String requiredField(String name);

  /// No description provided for @lightMode.
  ///
  /// In en, this message translates to:
  /// **'Light'**
  String get lightMode;

  /// No description provided for @darkMode.
  ///
  /// In en, this message translates to:
  /// **'Dark'**
  String get darkMode;

  /// No description provided for @theme.
  ///
  /// In en, this message translates to:
  /// **'Theme'**
  String get theme;

  /// No description provided for @language.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get language;

  /// No description provided for @systemMode.
  ///
  /// In en, this message translates to:
  /// **'System'**
  String get systemMode;

  /// No description provided for @newDatabase.
  ///
  /// In en, this message translates to:
  /// **'New Database'**
  String get newDatabase;

  /// No description provided for @browse.
  ///
  /// In en, this message translates to:
  /// **'Browse'**
  String get browse;

  /// No description provided for @connect.
  ///
  /// In en, this message translates to:
  /// **'Connect'**
  String get connect;

  /// No description provided for @zaitoonSlogan.
  ///
  /// In en, this message translates to:
  /// **'Empowering Ideas, Building Trust'**
  String get zaitoonSlogan;

  /// No description provided for @zaitoonTitle.
  ///
  /// In en, this message translates to:
  /// **'Zaitoon System'**
  String get zaitoonTitle;

  /// No description provided for @initialStock.
  ///
  /// In en, this message translates to:
  /// **'Initial Stock'**
  String get initialStock;

  /// No description provided for @serverConnection.
  ///
  /// In en, this message translates to:
  /// **'Server Connection'**
  String get serverConnection;

  /// No description provided for @connectToServer.
  ///
  /// In en, this message translates to:
  /// **'Connect to Server'**
  String get connectToServer;

  /// No description provided for @currentServer.
  ///
  /// In en, this message translates to:
  /// **'Current Server'**
  String get currentServer;

  /// No description provided for @deviceIp.
  ///
  /// In en, this message translates to:
  /// **'Device IP'**
  String get deviceIp;

  /// No description provided for @serverIpAddress.
  ///
  /// In en, this message translates to:
  /// **'Server IP Address'**
  String get serverIpAddress;

  /// No description provided for @quickConnect.
  ///
  /// In en, this message translates to:
  /// **'Quick Connect'**
  String get quickConnect;

  /// No description provided for @loading.
  ///
  /// In en, this message translates to:
  /// **'Loading...'**
  String get loading;

  /// No description provided for @login.
  ///
  /// In en, this message translates to:
  /// **'Login'**
  String get login;

  /// No description provided for @signUp.
  ///
  /// In en, this message translates to:
  /// **'Sign Up'**
  String get signUp;

  /// No description provided for @register.
  ///
  /// In en, this message translates to:
  /// **'Register'**
  String get register;

  /// No description provided for @connectedSuccessfully.
  ///
  /// In en, this message translates to:
  /// **'Connected Successfully'**
  String get connectedSuccessfully;

  /// No description provided for @connecting.
  ///
  /// In en, this message translates to:
  /// **'Connecting...'**
  String get connecting;

  /// No description provided for @connectionFailed.
  ///
  /// In en, this message translates to:
  /// **'Connection Failed'**
  String get connectionFailed;

  /// No description provided for @logout.
  ///
  /// In en, this message translates to:
  /// **'Logout'**
  String get logout;

  /// No description provided for @dashboard.
  ///
  /// In en, this message translates to:
  /// **'Dashboard'**
  String get dashboard;

  /// No description provided for @finance.
  ///
  /// In en, this message translates to:
  /// **'Finance'**
  String get finance;

  /// No description provided for @settings.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settings;

  /// No description provided for @report.
  ///
  /// In en, this message translates to:
  /// **'Report'**
  String get report;

  /// No description provided for @journal.
  ///
  /// In en, this message translates to:
  /// **'Journal'**
  String get journal;

  /// No description provided for @stock.
  ///
  /// In en, this message translates to:
  /// **'Stock'**
  String get stock;

  /// No description provided for @stakeholders.
  ///
  /// In en, this message translates to:
  /// **'Stakeholders'**
  String get stakeholders;

  /// No description provided for @username.
  ///
  /// In en, this message translates to:
  /// **'Username'**
  String get username;

  /// No description provided for @password.
  ///
  /// In en, this message translates to:
  /// **'Password'**
  String get password;

  /// No description provided for @incorrectCredential.
  ///
  /// In en, this message translates to:
  /// **'Username or password is incorrect'**
  String get incorrectCredential;

  /// No description provided for @urlNotFound.
  ///
  /// In en, this message translates to:
  /// **'URL not found.'**
  String get urlNotFound;

  /// No description provided for @general.
  ///
  /// In en, this message translates to:
  /// **'General'**
  String get general;

  /// No description provided for @company.
  ///
  /// In en, this message translates to:
  /// **'Company'**
  String get company;

  /// No description provided for @users.
  ///
  /// In en, this message translates to:
  /// **'Users'**
  String get users;

  /// No description provided for @about.
  ///
  /// In en, this message translates to:
  /// **'About'**
  String get about;

  /// No description provided for @profile.
  ///
  /// In en, this message translates to:
  /// **'Profile'**
  String get profile;

  /// No description provided for @glAccounts.
  ///
  /// In en, this message translates to:
  /// **'GL Accounts'**
  String get glAccounts;

  /// No description provided for @accountNumber.
  ///
  /// In en, this message translates to:
  /// **'Acc Number'**
  String get accountNumber;

  /// No description provided for @accountName.
  ///
  /// In en, this message translates to:
  /// **'Acc Name'**
  String get accountName;

  /// No description provided for @accountCategory.
  ///
  /// In en, this message translates to:
  /// **'Acc Category'**
  String get accountCategory;

  /// No description provided for @status.
  ///
  /// In en, this message translates to:
  /// **'Status'**
  String get status;

  /// No description provided for @address.
  ///
  /// In en, this message translates to:
  /// **'Address'**
  String get address;

  /// No description provided for @mobile1.
  ///
  /// In en, this message translates to:
  /// **'Mobile'**
  String get mobile1;

  /// No description provided for @businessName.
  ///
  /// In en, this message translates to:
  /// **'Business name'**
  String get businessName;

  /// No description provided for @website.
  ///
  /// In en, this message translates to:
  /// **'Website'**
  String get website;

  /// No description provided for @email.
  ///
  /// In en, this message translates to:
  /// **'Email'**
  String get email;

  /// No description provided for @update.
  ///
  /// In en, this message translates to:
  /// **'Update'**
  String get update;

  /// No description provided for @cancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancel;

  /// No description provided for @edit.
  ///
  /// In en, this message translates to:
  /// **'Edit'**
  String get edit;

  /// No description provided for @newKeyword.
  ///
  /// In en, this message translates to:
  /// **'NEW'**
  String get newKeyword;

  /// No description provided for @active.
  ///
  /// In en, this message translates to:
  /// **'Active'**
  String get active;

  /// No description provided for @blocked.
  ///
  /// In en, this message translates to:
  /// **'Blocked'**
  String get blocked;

  /// No description provided for @userOwner.
  ///
  /// In en, this message translates to:
  /// **'User owner'**
  String get userOwner;

  /// No description provided for @id.
  ///
  /// In en, this message translates to:
  /// **'ID'**
  String get id;

  /// No description provided for @admin.
  ///
  /// In en, this message translates to:
  /// **'Admin'**
  String get admin;

  /// No description provided for @manager.
  ///
  /// In en, this message translates to:
  /// **'Manager'**
  String get manager;

  /// No description provided for @viewer.
  ///
  /// In en, this message translates to:
  /// **'Viewer'**
  String get viewer;

  /// No description provided for @adminstrator.
  ///
  /// In en, this message translates to:
  /// **'Administrator'**
  String get adminstrator;

  /// No description provided for @userInformation.
  ///
  /// In en, this message translates to:
  /// **'User Information'**
  String get userInformation;

  /// No description provided for @systemSettings.
  ///
  /// In en, this message translates to:
  /// **'System'**
  String get systemSettings;

  /// No description provided for @refresh.
  ///
  /// In en, this message translates to:
  /// **'Refresh'**
  String get refresh;

  /// No description provided for @connected.
  ///
  /// In en, this message translates to:
  /// **'Connected'**
  String get connected;

  /// No description provided for @checkConnectivity.
  ///
  /// In en, this message translates to:
  /// **'Check Connectivity'**
  String get checkConnectivity;

  /// No description provided for @search.
  ///
  /// In en, this message translates to:
  /// **'Search'**
  String get search;

  /// No description provided for @flag.
  ///
  /// In en, this message translates to:
  /// **'Flag'**
  String get flag;

  /// No description provided for @currencyCode.
  ///
  /// In en, this message translates to:
  /// **'Code'**
  String get currencyCode;

  /// No description provided for @currencyTitle.
  ///
  /// In en, this message translates to:
  /// **'Currency'**
  String get currencyTitle;

  /// No description provided for @ccyLocalName.
  ///
  /// In en, this message translates to:
  /// **'Local name'**
  String get ccyLocalName;

  /// No description provided for @ccySymbol.
  ///
  /// In en, this message translates to:
  /// **'Symbol'**
  String get ccySymbol;

  /// No description provided for @create.
  ///
  /// In en, this message translates to:
  /// **'Create'**
  String get create;

  /// No description provided for @countryCode.
  ///
  /// In en, this message translates to:
  /// **'Country code'**
  String get countryCode;

  /// No description provided for @ccyName.
  ///
  /// In en, this message translates to:
  /// **'Currency name'**
  String get ccyName;

  /// No description provided for @gotIt.
  ///
  /// In en, this message translates to:
  /// **'Got it'**
  String get gotIt;

  /// No description provided for @accounts.
  ///
  /// In en, this message translates to:
  /// **'Accounts'**
  String get accounts;

  /// No description provided for @financialPeriod.
  ///
  /// In en, this message translates to:
  /// **'Financial Period'**
  String get financialPeriod;

  /// No description provided for @nationalId.
  ///
  /// In en, this message translates to:
  /// **'National ID'**
  String get nationalId;

  /// No description provided for @newStakeholder.
  ///
  /// In en, this message translates to:
  /// **'New Stakeholder'**
  String get newStakeholder;

  /// No description provided for @fullName.
  ///
  /// In en, this message translates to:
  /// **'Full name'**
  String get fullName;

  /// No description provided for @emailValidationMessage.
  ///
  /// In en, this message translates to:
  /// **'Email is not valid.'**
  String get emailValidationMessage;

  /// No description provided for @categoryTitle.
  ///
  /// In en, this message translates to:
  /// **'Category'**
  String get categoryTitle;

  /// No description provided for @profileAndAccounts.
  ///
  /// In en, this message translates to:
  /// **'Profile & Accounts'**
  String get profileAndAccounts;

  /// No description provided for @createdBy.
  ///
  /// In en, this message translates to:
  /// **'Created By'**
  String get createdBy;

  /// No description provided for @delete.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get delete;

  /// No description provided for @more.
  ///
  /// In en, this message translates to:
  /// **'More'**
  String get more;

  /// No description provided for @selectAll.
  ///
  /// In en, this message translates to:
  /// **'Select All'**
  String get selectAll;

  /// No description provided for @baseCurrency.
  ///
  /// In en, this message translates to:
  /// **'Base Currency'**
  String get baseCurrency;

  /// No description provided for @comDetails.
  ///
  /// In en, this message translates to:
  /// **'Company Details'**
  String get comDetails;

  /// No description provided for @addressHint.
  ///
  /// In en, this message translates to:
  /// **'Manage you company address.'**
  String get addressHint;

  /// No description provided for @profileHint.
  ///
  /// In en, this message translates to:
  /// **'Manage your company profile'**
  String get profileHint;

  /// No description provided for @welcomeBoss.
  ///
  /// In en, this message translates to:
  /// **'Welcome Boss!'**
  String get welcomeBoss;

  /// No description provided for @emailOrUsrname.
  ///
  /// In en, this message translates to:
  /// **'Email or Username'**
  String get emailOrUsrname;

  /// No description provided for @forgotPassword.
  ///
  /// In en, this message translates to:
  /// **'Forgot Password?'**
  String get forgotPassword;

  /// No description provided for @rememberMe.
  ///
  /// In en, this message translates to:
  /// **'Remember me'**
  String get rememberMe;

  /// No description provided for @settingsHint.
  ///
  /// In en, this message translates to:
  /// **'Adjust preferences to suit your needs'**
  String get settingsHint;

  /// No description provided for @am.
  ///
  /// In en, this message translates to:
  /// **'AM'**
  String get am;

  /// No description provided for @pm.
  ///
  /// In en, this message translates to:
  /// **'PM'**
  String get pm;

  /// No description provided for @zPetroleum.
  ///
  /// In en, this message translates to:
  /// **'Zaitoon System'**
  String get zPetroleum;

  /// No description provided for @hijriShamsi.
  ///
  /// In en, this message translates to:
  /// **'Hijri Shamsi'**
  String get hijriShamsi;

  /// No description provided for @gregorian.
  ///
  /// In en, this message translates to:
  /// **'Gregorian'**
  String get gregorian;

  /// No description provided for @dateTypeTitle.
  ///
  /// In en, this message translates to:
  /// **'System Date'**
  String get dateTypeTitle;

  /// No description provided for @dashboardClock.
  ///
  /// In en, this message translates to:
  /// **'Digital Clock'**
  String get dashboardClock;

  /// No description provided for @dateFormat.
  ///
  /// In en, this message translates to:
  /// **'Date Format'**
  String get dateFormat;

  /// No description provided for @clockHint.
  ///
  /// In en, this message translates to:
  /// **'Display a digital clock on the main dashboard'**
  String get clockHint;

  /// No description provided for @exchangeRateTitle.
  ///
  /// In en, this message translates to:
  /// **'Exchange Rate'**
  String get exchangeRateTitle;

  /// No description provided for @exhangeRateHint.
  ///
  /// In en, this message translates to:
  /// **'Display the latest currency exchange rate for quick reference.'**
  String get exhangeRateHint;

  /// No description provided for @buyTitle.
  ///
  /// In en, this message translates to:
  /// **'Buy'**
  String get buyTitle;

  /// No description provided for @sellTitle.
  ///
  /// In en, this message translates to:
  /// **'Sell'**
  String get sellTitle;

  /// No description provided for @pendingTransactions.
  ///
  /// In en, this message translates to:
  /// **'Pending'**
  String get pendingTransactions;

  /// No description provided for @authorizedTransactions.
  ///
  /// In en, this message translates to:
  /// **'Authorized'**
  String get authorizedTransactions;

  /// No description provided for @allTransactions.
  ///
  /// In en, this message translates to:
  /// **'All Transactions'**
  String get allTransactions;

  /// No description provided for @deposit.
  ///
  /// In en, this message translates to:
  /// **'Deposit'**
  String get deposit;

  /// No description provided for @withdraw.
  ///
  /// In en, this message translates to:
  /// **'Withdraw'**
  String get withdraw;

  /// No description provided for @accountTransfer.
  ///
  /// In en, this message translates to:
  /// **'Fund Transfer'**
  String get accountTransfer;

  /// No description provided for @fxTransaction.
  ///
  /// In en, this message translates to:
  /// **'FX Transaction'**
  String get fxTransaction;

  /// No description provided for @expense.
  ///
  /// In en, this message translates to:
  /// **'Expenses'**
  String get expense;

  /// No description provided for @returnGoods.
  ///
  /// In en, this message translates to:
  /// **'Return Goods'**
  String get returnGoods;

  /// No description provided for @cashFlow.
  ///
  /// In en, this message translates to:
  /// **'Cash Flow'**
  String get cashFlow;

  /// No description provided for @income.
  ///
  /// In en, this message translates to:
  /// **'Income'**
  String get income;

  /// No description provided for @systemAction.
  ///
  /// In en, this message translates to:
  /// **'System Actions'**
  String get systemAction;

  /// No description provided for @glCreditTitle.
  ///
  /// In en, this message translates to:
  /// **'GL Credit'**
  String get glCreditTitle;

  /// No description provided for @glDebitTitle.
  ///
  /// In en, this message translates to:
  /// **'GL Debit'**
  String get glDebitTitle;

  /// No description provided for @transport.
  ///
  /// In en, this message translates to:
  /// **'Transport'**
  String get transport;

  /// No description provided for @accountStatement.
  ///
  /// In en, this message translates to:
  /// **'Account Statement'**
  String get accountStatement;

  /// No description provided for @creditors.
  ///
  /// In en, this message translates to:
  /// **'Creditors'**
  String get creditors;

  /// No description provided for @debtors.
  ///
  /// In en, this message translates to:
  /// **'Debtors'**
  String get debtors;

  /// No description provided for @treasury.
  ///
  /// In en, this message translates to:
  /// **'Cash Balances'**
  String get treasury;

  /// No description provided for @exchangeRate.
  ///
  /// In en, this message translates to:
  /// **'Exchange Rate'**
  String get exchangeRate;

  /// No description provided for @products.
  ///
  /// In en, this message translates to:
  /// **'Products'**
  String get products;

  /// No description provided for @salesInvoice.
  ///
  /// In en, this message translates to:
  /// **'Sales Invoice'**
  String get salesInvoice;

  /// No description provided for @purchaseInvoice.
  ///
  /// In en, this message translates to:
  /// **'Purchase Invoice'**
  String get purchaseInvoice;

  /// No description provided for @referenceTransaction.
  ///
  /// In en, this message translates to:
  /// **'Reference Transaction'**
  String get referenceTransaction;

  /// No description provided for @balanceSheet.
  ///
  /// In en, this message translates to:
  /// **'Balance Sheet'**
  String get balanceSheet;

  /// No description provided for @activities.
  ///
  /// In en, this message translates to:
  /// **'Activities'**
  String get activities;

  /// No description provided for @incomeStatement.
  ///
  /// In en, this message translates to:
  /// **'Profit & Loss'**
  String get incomeStatement;

  /// No description provided for @glReport.
  ///
  /// In en, this message translates to:
  /// **'GL Report'**
  String get glReport;

  /// No description provided for @transactions.
  ///
  /// In en, this message translates to:
  /// **'Transactions'**
  String get transactions;

  /// No description provided for @glStatement.
  ///
  /// In en, this message translates to:
  /// **'GL Statement'**
  String get glStatement;

  /// No description provided for @branches.
  ///
  /// In en, this message translates to:
  /// **'Branches'**
  String get branches;

  /// No description provided for @shift.
  ///
  /// In en, this message translates to:
  /// **'Goods Shift'**
  String get shift;

  /// No description provided for @sales.
  ///
  /// In en, this message translates to:
  /// **'Sales'**
  String get sales;

  /// No description provided for @inventory.
  ///
  /// In en, this message translates to:
  /// **'Inventory'**
  String get inventory;

  /// No description provided for @attendence.
  ///
  /// In en, this message translates to:
  /// **'Attendance'**
  String get attendence;

  /// No description provided for @employees.
  ///
  /// In en, this message translates to:
  /// **'Employees'**
  String get employees;

  /// No description provided for @hr.
  ///
  /// In en, this message translates to:
  /// **'HR Manager'**
  String get hr;

  /// No description provided for @hrTitle.
  ///
  /// In en, this message translates to:
  /// **'Human Resource Management'**
  String get hrTitle;

  /// No description provided for @fiscalYear.
  ///
  /// In en, this message translates to:
  /// **'EOY Operation'**
  String get fiscalYear;

  /// No description provided for @manageFinance.
  ///
  /// In en, this message translates to:
  /// **'Manage fiscal years, currencies, and exchange rates.'**
  String get manageFinance;

  /// No description provided for @hrManagement.
  ///
  /// In en, this message translates to:
  /// **'Manage employees, attendance, and user access.'**
  String get hrManagement;

  /// No description provided for @stakeholderManage.
  ///
  /// In en, this message translates to:
  /// **'Manage Stakeholders & Accounts.'**
  String get stakeholderManage;

  /// No description provided for @payRoll.
  ///
  /// In en, this message translates to:
  /// **'Payroll'**
  String get payRoll;

  /// No description provided for @noDataFound.
  ///
  /// In en, this message translates to:
  /// **'No result found'**
  String get noDataFound;

  /// No description provided for @stakeholderInfo.
  ///
  /// In en, this message translates to:
  /// **'Stakeholder Information'**
  String get stakeholderInfo;

  /// No description provided for @noInternet.
  ///
  /// In en, this message translates to:
  /// **'No Internet Connection'**
  String get noInternet;

  /// No description provided for @url404.
  ///
  /// In en, this message translates to:
  /// **'URL 404 not found.'**
  String get url404;

  /// No description provided for @badRequest.
  ///
  /// In en, this message translates to:
  /// **'Bad Request! Please check your input.'**
  String get badRequest;

  /// No description provided for @unAuthorized.
  ///
  /// In en, this message translates to:
  /// **'Unauthorized! Please login again.'**
  String get unAuthorized;

  /// No description provided for @forbidden.
  ///
  /// In en, this message translates to:
  /// **'Access Denied! You don\'t have permission.'**
  String get forbidden;

  /// No description provided for @internalServerError.
  ///
  /// In en, this message translates to:
  /// **'Server Error! Please try again later.'**
  String get internalServerError;

  /// No description provided for @serviceUnavailable.
  ///
  /// In en, this message translates to:
  /// **'Service Unavailable! Please try later.'**
  String get serviceUnavailable;

  /// No description provided for @serverError.
  ///
  /// In en, this message translates to:
  /// **'Server error:'**
  String get serverError;

  /// No description provided for @networkError.
  ///
  /// In en, this message translates to:
  /// **'Network Error! Please check your connection.'**
  String get networkError;

  /// No description provided for @city.
  ///
  /// In en, this message translates to:
  /// **'City'**
  String get city;

  /// No description provided for @gender.
  ///
  /// In en, this message translates to:
  /// **'Gender'**
  String get gender;

  /// No description provided for @firstName.
  ///
  /// In en, this message translates to:
  /// **'First name'**
  String get firstName;

  /// No description provided for @lastName.
  ///
  /// In en, this message translates to:
  /// **'Last name'**
  String get lastName;

  /// No description provided for @dob.
  ///
  /// In en, this message translates to:
  /// **'Date of Birth'**
  String get dob;

  /// No description provided for @cellNumber.
  ///
  /// In en, this message translates to:
  /// **'Cell Phone'**
  String get cellNumber;

  /// No description provided for @province.
  ///
  /// In en, this message translates to:
  /// **'Province'**
  String get province;

  /// No description provided for @country.
  ///
  /// In en, this message translates to:
  /// **'Country'**
  String get country;

  /// No description provided for @isMilling.
  ///
  /// In en, this message translates to:
  /// **'Is your mailing address same as your address?'**
  String get isMilling;

  /// No description provided for @zipCode.
  ///
  /// In en, this message translates to:
  /// **'Zip code'**
  String get zipCode;

  /// No description provided for @accountInformation.
  ///
  /// In en, this message translates to:
  /// **'Accounts Information'**
  String get accountInformation;

  /// No description provided for @balance.
  ///
  /// In en, this message translates to:
  /// **'Balance'**
  String get balance;

  /// No description provided for @accNameOrNumber.
  ///
  /// In en, this message translates to:
  /// **'Account Name or Number'**
  String get accNameOrNumber;

  /// No description provided for @usrId.
  ///
  /// In en, this message translates to:
  /// **'User ID'**
  String get usrId;

  /// No description provided for @branch.
  ///
  /// In en, this message translates to:
  /// **'Branch'**
  String get branch;

  /// No description provided for @usrRole.
  ///
  /// In en, this message translates to:
  /// **'User Role'**
  String get usrRole;

  /// No description provided for @profileOverview.
  ///
  /// In en, this message translates to:
  /// **'Profile Overview'**
  String get profileOverview;

  /// No description provided for @currencyName.
  ///
  /// In en, this message translates to:
  /// **'Currency Name'**
  String get currencyName;

  /// No description provided for @symbol.
  ///
  /// In en, this message translates to:
  /// **'Symbol'**
  String get symbol;

  /// No description provided for @accountLimit.
  ///
  /// In en, this message translates to:
  /// **'Account Limit'**
  String get accountLimit;

  /// No description provided for @asset.
  ///
  /// In en, this message translates to:
  /// **'Asset'**
  String get asset;

  /// No description provided for @liability.
  ///
  /// In en, this message translates to:
  /// **'Liability'**
  String get liability;

  /// No description provided for @yes.
  ///
  /// In en, this message translates to:
  /// **'Yes'**
  String get yes;

  /// No description provided for @ignore.
  ///
  /// In en, this message translates to:
  /// **'Ignore'**
  String get ignore;

  /// No description provided for @areYouSure.
  ///
  /// In en, this message translates to:
  /// **'Are you sure?'**
  String get areYouSure;

  /// No description provided for @currencyActivationMessage.
  ///
  /// In en, this message translates to:
  /// **'Do you wanna activate this currency?'**
  String get currencyActivationMessage;

  /// No description provided for @entities.
  ///
  /// In en, this message translates to:
  /// **'Individuals'**
  String get entities;

  /// No description provided for @individuals.
  ///
  /// In en, this message translates to:
  /// **'Individuals'**
  String get individuals;

  /// No description provided for @male.
  ///
  /// In en, this message translates to:
  /// **'Male'**
  String get male;

  /// No description provided for @female.
  ///
  /// In en, this message translates to:
  /// **'Female'**
  String get female;

  /// No description provided for @socialMedia.
  ///
  /// In en, this message translates to:
  /// **'Social Profile'**
  String get socialMedia;

  /// No description provided for @overview.
  ///
  /// In en, this message translates to:
  /// **'Overview'**
  String get overview;

  /// No description provided for @userLog.
  ///
  /// In en, this message translates to:
  /// **'User Log'**
  String get userLog;

  /// No description provided for @permissions.
  ///
  /// In en, this message translates to:
  /// **'Permissions'**
  String get permissions;

  /// No description provided for @deniedPermissionMessage.
  ///
  /// In en, this message translates to:
  /// **'Access Denied! You don’t have permission to view this section.'**
  String get deniedPermissionMessage;

  /// No description provided for @deniedPermissionTitle.
  ///
  /// In en, this message translates to:
  /// **'Restricted Section'**
  String get deniedPermissionTitle;

  /// No description provided for @userManagement.
  ///
  /// In en, this message translates to:
  /// **'User Management'**
  String get userManagement;

  /// No description provided for @manageUser.
  ///
  /// In en, this message translates to:
  /// **'Review user activities and permissions.'**
  String get manageUser;

  /// No description provided for @createdAt.
  ///
  /// In en, this message translates to:
  /// **'Created at'**
  String get createdAt;

  /// No description provided for @cashOperations.
  ///
  /// In en, this message translates to:
  /// **'Cash Operations'**
  String get cashOperations;

  /// No description provided for @usersAndAuthorizations.
  ///
  /// In en, this message translates to:
  /// **'Users & Authorizations'**
  String get usersAndAuthorizations;

  /// No description provided for @incorrectPassword.
  ///
  /// In en, this message translates to:
  /// **'Password is incorrect.'**
  String get incorrectPassword;

  /// No description provided for @accessDenied.
  ///
  /// In en, this message translates to:
  /// **'Access Denied!'**
  String get accessDenied;

  /// No description provided for @unverified.
  ///
  /// In en, this message translates to:
  /// **'You haven\'t verified your email yet.'**
  String get unverified;

  /// No description provided for @blockedMessage.
  ///
  /// In en, this message translates to:
  /// **'The targeted account is blocked, kindly contact administrator for reason.'**
  String get blockedMessage;

  /// No description provided for @ceo.
  ///
  /// In en, this message translates to:
  /// **'CEO'**
  String get ceo;

  /// No description provided for @deputy.
  ///
  /// In en, this message translates to:
  /// **'Deputy'**
  String get deputy;

  /// No description provided for @authoriser.
  ///
  /// In en, this message translates to:
  /// **'Authoriser'**
  String get authoriser;

  /// No description provided for @officer.
  ///
  /// In en, this message translates to:
  /// **'Officer'**
  String get officer;

  /// No description provided for @customerService.
  ///
  /// In en, this message translates to:
  /// **'Customer Service'**
  String get customerService;

  /// No description provided for @customer.
  ///
  /// In en, this message translates to:
  /// **'Customer'**
  String get customer;

  /// No description provided for @selectRole.
  ///
  /// In en, this message translates to:
  /// **'Select Role'**
  String get selectRole;

  /// No description provided for @confirmPassword.
  ///
  /// In en, this message translates to:
  /// **'Re-enter password'**
  String get confirmPassword;

  /// No description provided for @password8Char.
  ///
  /// In en, this message translates to:
  /// **'Password must be at least 8 characters'**
  String get password8Char;

  /// No description provided for @passwordUpperCase.
  ///
  /// In en, this message translates to:
  /// **'Password must include an uppercase letter'**
  String get passwordUpperCase;

  /// No description provided for @passwordLowerCase.
  ///
  /// In en, this message translates to:
  /// **'Password must include a lowercase letter'**
  String get passwordLowerCase;

  /// No description provided for @passwordWithDigit.
  ///
  /// In en, this message translates to:
  /// **'Password must include a number'**
  String get passwordWithDigit;

  /// No description provided for @passwordWithSpecialChar.
  ///
  /// In en, this message translates to:
  /// **'Password must include a special character'**
  String get passwordWithSpecialChar;

  /// No description provided for @passwordNotMatch.
  ///
  /// In en, this message translates to:
  /// **'Passwords do not match.'**
  String get passwordNotMatch;

  /// No description provided for @usernameMinLength.
  ///
  /// In en, this message translates to:
  /// **'Username must be at least 4 characters'**
  String get usernameMinLength;

  /// No description provided for @usernameNoStartDigit.
  ///
  /// In en, this message translates to:
  /// **'Username cannot start with a number'**
  String get usernameNoStartDigit;

  /// No description provided for @usernameInvalidChars.
  ///
  /// In en, this message translates to:
  /// **'Username can only contain letters, numbers.'**
  String get usernameInvalidChars;

  /// No description provided for @usernameNoSpaces.
  ///
  /// In en, this message translates to:
  /// **'Username cannot contain spaces'**
  String get usernameNoSpaces;

  /// No description provided for @addUserTitle.
  ///
  /// In en, this message translates to:
  /// **'Add User'**
  String get addUserTitle;

  /// No description provided for @cashier.
  ///
  /// In en, this message translates to:
  /// **'Cashier'**
  String get cashier;

  /// No description provided for @emailExists.
  ///
  /// In en, this message translates to:
  /// **'Email already exists, please choose another.'**
  String get emailExists;

  /// No description provided for @usernameExists.
  ///
  /// In en, this message translates to:
  /// **'Username already exists. Please choose another.'**
  String get usernameExists;

  /// No description provided for @backTitle.
  ///
  /// In en, this message translates to:
  /// **'Back'**
  String get backTitle;

  /// No description provided for @changePasswordTitle.
  ///
  /// In en, this message translates to:
  /// **'Change Password'**
  String get changePasswordTitle;

  /// No description provided for @newPasswordTitle.
  ///
  /// In en, this message translates to:
  /// **'New Password'**
  String get newPasswordTitle;

  /// No description provided for @forceChangePasswordHint.
  ///
  /// In en, this message translates to:
  /// **'For your security, please set a new password.'**
  String get forceChangePasswordHint;

  /// No description provided for @oldPassword.
  ///
  /// In en, this message translates to:
  /// **'Old Password'**
  String get oldPassword;

  /// No description provided for @errorHint.
  ///
  /// In en, this message translates to:
  /// **'Check your services or refresh to try again.'**
  String get errorHint;

  /// No description provided for @oldPasswordIncorrect.
  ///
  /// In en, this message translates to:
  /// **'The old password you entered is incorrect.'**
  String get oldPasswordIncorrect;

  /// No description provided for @forceChangePasswordTitle.
  ///
  /// In en, this message translates to:
  /// **'Password Change'**
  String get forceChangePasswordTitle;

  /// No description provided for @forceEmailVerificationTitle.
  ///
  /// In en, this message translates to:
  /// **'Require Email Verification'**
  String get forceEmailVerificationTitle;

  /// No description provided for @rate.
  ///
  /// In en, this message translates to:
  /// **'Exchange Rate'**
  String get rate;

  /// No description provided for @from.
  ///
  /// In en, this message translates to:
  /// **'From CCY'**
  String get from;

  /// No description provided for @toCurrency.
  ///
  /// In en, this message translates to:
  /// **'To CCY'**
  String get toCurrency;

  /// No description provided for @amountGreaterZero.
  ///
  /// In en, this message translates to:
  /// **'Amount must be greater than zero.'**
  String get amountGreaterZero;

  /// No description provided for @newExchangeRateTitle.
  ///
  /// In en, this message translates to:
  /// **'New Exchange Rate'**
  String get newExchangeRateTitle;

  /// No description provided for @drivers.
  ///
  /// In en, this message translates to:
  /// **'Drivers'**
  String get drivers;

  /// No description provided for @shipping.
  ///
  /// In en, this message translates to:
  /// **'Shipping'**
  String get shipping;

  /// No description provided for @vehicles.
  ///
  /// In en, this message translates to:
  /// **'Vehicles'**
  String get vehicles;

  /// No description provided for @facebook.
  ///
  /// In en, this message translates to:
  /// **'Facebook'**
  String get facebook;

  /// No description provided for @instagram.
  ///
  /// In en, this message translates to:
  /// **'Instagram'**
  String get instagram;

  /// No description provided for @whatsApp.
  ///
  /// In en, this message translates to:
  /// **'WhatsApp'**
  String get whatsApp;

  /// No description provided for @amount.
  ///
  /// In en, this message translates to:
  /// **'Amount'**
  String get amount;

  /// No description provided for @narration.
  ///
  /// In en, this message translates to:
  /// **'Narration'**
  String get narration;

  /// No description provided for @referenceNumber.
  ///
  /// In en, this message translates to:
  /// **'Reference'**
  String get referenceNumber;

  /// No description provided for @txnMaker.
  ///
  /// In en, this message translates to:
  /// **'Maker'**
  String get txnMaker;

  /// No description provided for @txnDate.
  ///
  /// In en, this message translates to:
  /// **'Date'**
  String get txnDate;

  /// No description provided for @authorizer.
  ///
  /// In en, this message translates to:
  /// **'Authorizer'**
  String get authorizer;

  /// No description provided for @txnType.
  ///
  /// In en, this message translates to:
  /// **'Type'**
  String get txnType;

  /// No description provided for @branchName.
  ///
  /// In en, this message translates to:
  /// **'Branch name'**
  String get branchName;

  /// No description provided for @branchId.
  ///
  /// In en, this message translates to:
  /// **'Code'**
  String get branchId;

  /// No description provided for @selected.
  ///
  /// In en, this message translates to:
  /// **'Selected'**
  String get selected;

  /// No description provided for @authorize.
  ///
  /// In en, this message translates to:
  /// **'Authorize'**
  String get authorize;

  /// No description provided for @checker.
  ///
  /// In en, this message translates to:
  /// **'Authorized By'**
  String get checker;

  /// No description provided for @maker.
  ///
  /// In en, this message translates to:
  /// **'Created By'**
  String get maker;

  /// No description provided for @branchLimits.
  ///
  /// In en, this message translates to:
  /// **'Branch Limit'**
  String get branchLimits;

  /// No description provided for @branchInformation.
  ///
  /// In en, this message translates to:
  /// **'BRANCH INFORMATION'**
  String get branchInformation;

  /// No description provided for @currentBalance.
  ///
  /// In en, this message translates to:
  /// **'Current Balance'**
  String get currentBalance;

  /// No description provided for @availableBalance.
  ///
  /// In en, this message translates to:
  /// **'Available Balance'**
  String get availableBalance;

  /// No description provided for @txnDetails.
  ///
  /// In en, this message translates to:
  /// **'Transaction Details'**
  String get txnDetails;

  /// No description provided for @transactionRef.
  ///
  /// In en, this message translates to:
  /// **'Transaction Ref'**
  String get transactionRef;

  /// No description provided for @transactionDate.
  ///
  /// In en, this message translates to:
  /// **'Transaction Date'**
  String get transactionDate;

  /// No description provided for @recipient.
  ///
  /// In en, this message translates to:
  /// **'Recipient'**
  String get recipient;

  /// No description provided for @details.
  ///
  /// In en, this message translates to:
  /// **'Details'**
  String get details;

  /// No description provided for @authorizeDeniedMessage.
  ///
  /// In en, this message translates to:
  /// **'You are not allowed to authorize this transaction.'**
  String get authorizeDeniedMessage;

  /// No description provided for @reversed.
  ///
  /// In en, this message translates to:
  /// **'Reversed'**
  String get reversed;

  /// No description provided for @txnReprint.
  ///
  /// In en, this message translates to:
  /// **'TXN Reprint'**
  String get txnReprint;

  /// No description provided for @overLimitMessage.
  ///
  /// In en, this message translates to:
  /// **'Insuffiecent account balance or account limit exceed.'**
  String get overLimitMessage;

  /// No description provided for @deleteAuthorizedMessage.
  ///
  /// In en, this message translates to:
  /// **'This transaction is auhtorized and cannot be deleted.'**
  String get deleteAuthorizedMessage;

  /// No description provided for @deleteInvalidMessage.
  ///
  /// In en, this message translates to:
  /// **'You\'re not allowed to delete this transaction.'**
  String get deleteInvalidMessage;

  /// No description provided for @editInvalidMessage.
  ///
  /// In en, this message translates to:
  /// **'You\'re not allowed to update this transaction.'**
  String get editInvalidMessage;

  /// No description provided for @editInvalidAction.
  ///
  /// In en, this message translates to:
  /// **'Authorized & reversed transactions are not edited.'**
  String get editInvalidAction;

  /// No description provided for @editFailedMessage.
  ///
  /// In en, this message translates to:
  /// **'Transaction updated failed, try again later'**
  String get editFailedMessage;

  /// No description provided for @actions.
  ///
  /// In en, this message translates to:
  /// **'Actions'**
  String get actions;

  /// No description provided for @reverseTitle.
  ///
  /// In en, this message translates to:
  /// **'Reverse'**
  String get reverseTitle;

  /// No description provided for @reverseInvalidMessage.
  ///
  /// In en, this message translates to:
  /// **'You\'re not allowed to revese this transaction.'**
  String get reverseInvalidMessage;

  /// No description provided for @reversePendingMessage.
  ///
  /// In en, this message translates to:
  /// **'Pending transaction is not allowed to reverse.'**
  String get reversePendingMessage;

  /// No description provided for @reverseAlreadyMessage.
  ///
  /// In en, this message translates to:
  /// **'This transaction has already reversed once.'**
  String get reverseAlreadyMessage;

  /// No description provided for @authorizeInvalidMessage.
  ///
  /// In en, this message translates to:
  /// **'You\'re not allowed to authorize this transaction.'**
  String get authorizeInvalidMessage;

  /// No description provided for @apply.
  ///
  /// In en, this message translates to:
  /// **'Apply'**
  String get apply;

  /// No description provided for @selectKeyword.
  ///
  /// In en, this message translates to:
  /// **'Select'**
  String get selectKeyword;

  /// No description provided for @clear.
  ///
  /// In en, this message translates to:
  /// **'Clear'**
  String get clear;

  /// No description provided for @today.
  ///
  /// In en, this message translates to:
  /// **'Today'**
  String get today;

  /// No description provided for @selectYear.
  ///
  /// In en, this message translates to:
  /// **'Select Year'**
  String get selectYear;

  /// No description provided for @selectDate.
  ///
  /// In en, this message translates to:
  /// **'Select date'**
  String get selectDate;

  /// No description provided for @printers.
  ///
  /// In en, this message translates to:
  /// **'Printers'**
  String get printers;

  /// No description provided for @portrait.
  ///
  /// In en, this message translates to:
  /// **'Portrait'**
  String get portrait;

  /// No description provided for @landscape.
  ///
  /// In en, this message translates to:
  /// **'Landscape'**
  String get landscape;

  /// No description provided for @orientation.
  ///
  /// In en, this message translates to:
  /// **'Orientation'**
  String get orientation;

  /// No description provided for @print.
  ///
  /// In en, this message translates to:
  /// **'Print'**
  String get print;

  /// No description provided for @paper.
  ///
  /// In en, this message translates to:
  /// **'Paper'**
  String get paper;

  /// No description provided for @fromDate.
  ///
  /// In en, this message translates to:
  /// **'From date'**
  String get fromDate;

  /// No description provided for @toDate.
  ///
  /// In en, this message translates to:
  /// **'To date'**
  String get toDate;

  /// No description provided for @debitTitle.
  ///
  /// In en, this message translates to:
  /// **'Debit'**
  String get debitTitle;

  /// No description provided for @creditTitle.
  ///
  /// In en, this message translates to:
  /// **'Credit'**
  String get creditTitle;

  /// No description provided for @copies.
  ///
  /// In en, this message translates to:
  /// **'Copies'**
  String get copies;

  /// No description provided for @pages.
  ///
  /// In en, this message translates to:
  /// **'Pages'**
  String get pages;

  /// No description provided for @all.
  ///
  /// In en, this message translates to:
  /// **'All'**
  String get all;

  /// No description provided for @eg.
  ///
  /// In en, this message translates to:
  /// **'e.g, 1,3,5 or 1-3 or 1,3-5,7'**
  String get eg;

  /// No description provided for @accountStatementMessage.
  ///
  /// In en, this message translates to:
  /// **'Select an account and date range to view statement.'**
  String get accountStatementMessage;

  /// No description provided for @department.
  ///
  /// In en, this message translates to:
  /// **'Department'**
  String get department;

  /// No description provided for @executiveManagement.
  ///
  /// In en, this message translates to:
  /// **'Executive management'**
  String get executiveManagement;

  /// No description provided for @operation.
  ///
  /// In en, this message translates to:
  /// **'Operation'**
  String get operation;

  /// No description provided for @legal.
  ///
  /// In en, this message translates to:
  /// **'Legal'**
  String get legal;

  /// No description provided for @marketing.
  ///
  /// In en, this message translates to:
  /// **'Marketing'**
  String get marketing;

  /// No description provided for @it.
  ///
  /// In en, this message translates to:
  /// **'Information Technology (IT)'**
  String get it;

  /// No description provided for @procurement.
  ///
  /// In en, this message translates to:
  /// **'Procurement'**
  String get procurement;

  /// No description provided for @audit.
  ///
  /// In en, this message translates to:
  /// **'Audit'**
  String get audit;

  /// No description provided for @monthly.
  ///
  /// In en, this message translates to:
  /// **'Monthly'**
  String get monthly;

  /// No description provided for @hourly.
  ///
  /// In en, this message translates to:
  /// **'Hourly'**
  String get hourly;

  /// No description provided for @daily.
  ///
  /// In en, this message translates to:
  /// **'Daily'**
  String get daily;

  /// No description provided for @salaryBase.
  ///
  /// In en, this message translates to:
  /// **'Salary base'**
  String get salaryBase;

  /// No description provided for @weekly.
  ///
  /// In en, this message translates to:
  /// **'Weekly'**
  String get weekly;

  /// No description provided for @paymentMethod.
  ///
  /// In en, this message translates to:
  /// **'Payment Method'**
  String get paymentMethod;

  /// No description provided for @salary.
  ///
  /// In en, this message translates to:
  /// **'Salary'**
  String get salary;

  /// No description provided for @employeeRegistration.
  ///
  /// In en, this message translates to:
  /// **'Employee Registration'**
  String get employeeRegistration;

  /// No description provided for @taxInfo.
  ///
  /// In en, this message translates to:
  /// **'TIN number'**
  String get taxInfo;

  /// No description provided for @jobTitle.
  ///
  /// In en, this message translates to:
  /// **'Job title'**
  String get jobTitle;

  /// No description provided for @startDate.
  ///
  /// In en, this message translates to:
  /// **'Start date'**
  String get startDate;

  /// No description provided for @employeeName.
  ///
  /// In en, this message translates to:
  /// **'Employee name'**
  String get employeeName;

  /// No description provided for @noData.
  ///
  /// In en, this message translates to:
  /// **'No data'**
  String get noData;

  /// No description provided for @employed.
  ///
  /// In en, this message translates to:
  /// **'Employed'**
  String get employed;

  /// No description provided for @terminated.
  ///
  /// In en, this message translates to:
  /// **'Terminated'**
  String get terminated;

  /// No description provided for @inactive.
  ///
  /// In en, this message translates to:
  /// **'Inactive'**
  String get inactive;

  /// No description provided for @sameAccountMessage.
  ///
  /// In en, this message translates to:
  /// **'You cannot transfer between the same account.'**
  String get sameAccountMessage;

  /// No description provided for @operationFailedMessage.
  ///
  /// In en, this message translates to:
  /// **'Unable to process your request at this time.'**
  String get operationFailedMessage;

  /// No description provided for @sameCurrencyNotAllowed.
  ///
  /// In en, this message translates to:
  /// **'Currency mismatch detected. Please choose accounts with identical currency.'**
  String get sameCurrencyNotAllowed;

  /// No description provided for @sameCurrencyOnlyAllowed.
  ///
  /// In en, this message translates to:
  /// **'Currency mismatch detected. Please choose accounts with identical currency.'**
  String get sameCurrencyOnlyAllowed;

  /// No description provided for @accountLimitMessage.
  ///
  /// In en, this message translates to:
  /// **'Insufficient balance or account limit reached.'**
  String get accountLimitMessage;

  /// No description provided for @date.
  ///
  /// In en, this message translates to:
  /// **'Date'**
  String get date;

  /// No description provided for @authorizedTransaction.
  ///
  /// In en, this message translates to:
  /// **'Authorized'**
  String get authorizedTransaction;

  /// No description provided for @comLicense.
  ///
  /// In en, this message translates to:
  /// **'License No.'**
  String get comLicense;

  /// No description provided for @saveChanges.
  ///
  /// In en, this message translates to:
  /// **'Save changes'**
  String get saveChanges;

  /// No description provided for @bulkTransfer.
  ///
  /// In en, this message translates to:
  /// **'Fund Transfer - Multi Accounts'**
  String get bulkTransfer;

  /// No description provided for @crop.
  ///
  /// In en, this message translates to:
  /// **'Crop'**
  String get crop;

  /// No description provided for @totalDebit.
  ///
  /// In en, this message translates to:
  /// **'Total Debit'**
  String get totalDebit;

  /// No description provided for @totalCredit.
  ///
  /// In en, this message translates to:
  /// **'Total Credit'**
  String get totalCredit;

  /// No description provided for @difference.
  ///
  /// In en, this message translates to:
  /// **'Difference'**
  String get difference;

  /// No description provided for @debitNoEqualCredit.
  ///
  /// In en, this message translates to:
  /// **'Total debit and credit is not equal, please adjust amounts to balance.'**
  String get debitNoEqualCredit;

  /// No description provided for @successTransactionMessage.
  ///
  /// In en, this message translates to:
  /// **'Transfer has been successfully completed.'**
  String get successTransactionMessage;

  /// No description provided for @addEntry.
  ///
  /// In en, this message translates to:
  /// **'Add Entry'**
  String get addEntry;

  /// No description provided for @blockedAccountMessage.
  ///
  /// In en, this message translates to:
  /// **'Account is blocked.'**
  String get blockedAccountMessage;

  /// No description provided for @currencyMismatchMessage.
  ///
  /// In en, this message translates to:
  /// **'Currency mismatch in transaction'**
  String get currencyMismatchMessage;

  /// No description provided for @transactionMismatchCcyAlert.
  ///
  /// In en, this message translates to:
  /// **'Your accounts currencies are not matching with your transaction main currency.'**
  String get transactionMismatchCcyAlert;

  /// No description provided for @ccyCode.
  ///
  /// In en, this message translates to:
  /// **'CCY'**
  String get ccyCode;

  /// No description provided for @actionBrief.
  ///
  /// In en, this message translates to:
  /// **'Act'**
  String get actionBrief;

  /// No description provided for @transactionFailedTitle.
  ///
  /// In en, this message translates to:
  /// **'Transaction Failed'**
  String get transactionFailedTitle;

  /// No description provided for @fundTransferTitle.
  ///
  /// In en, this message translates to:
  /// **'Fund Transfer'**
  String get fundTransferTitle;

  /// No description provided for @fundTransferMultiTitle.
  ///
  /// In en, this message translates to:
  /// **'Fund Transfer MA'**
  String get fundTransferMultiTitle;

  /// No description provided for @storage.
  ///
  /// In en, this message translates to:
  /// **'Stock'**
  String get storage;

  /// No description provided for @storages.
  ///
  /// In en, this message translates to:
  /// **'Storages'**
  String get storages;

  /// No description provided for @location.
  ///
  /// In en, this message translates to:
  /// **'Location'**
  String get location;

  /// No description provided for @unlimited.
  ///
  /// In en, this message translates to:
  /// **'Unlimited'**
  String get unlimited;

  /// No description provided for @fxTransactionTitle.
  ///
  /// In en, this message translates to:
  /// **'FX Transaction - Multi Accounts'**
  String get fxTransactionTitle;

  /// No description provided for @debitAccCcy.
  ///
  /// In en, this message translates to:
  /// **'Debit Account Currency'**
  String get debitAccCcy;

  /// No description provided for @creditAccCcy.
  ///
  /// In en, this message translates to:
  /// **'Credit Account Currency'**
  String get creditAccCcy;

  /// No description provided for @convertedAmount.
  ///
  /// In en, this message translates to:
  /// **'Converted Amount'**
  String get convertedAmount;

  /// No description provided for @convertedAmountNotMatch.
  ///
  /// In en, this message translates to:
  /// **'Credit amount does not match converted amount.'**
  String get convertedAmountNotMatch;

  /// No description provided for @amountIn.
  ///
  /// In en, this message translates to:
  /// **'Amount In'**
  String get amountIn;

  /// No description provided for @baseTitle.
  ///
  /// In en, this message translates to:
  /// **'Base'**
  String get baseTitle;

  /// No description provided for @creditSide.
  ///
  /// In en, this message translates to:
  /// **'Credit side'**
  String get creditSide;

  /// No description provided for @debitSide.
  ///
  /// In en, this message translates to:
  /// **'Debit side'**
  String get debitSide;

  /// No description provided for @sameCurrency.
  ///
  /// In en, this message translates to:
  /// **'Same Currency'**
  String get sameCurrency;

  /// No description provided for @exchangeRatePercentage.
  ///
  /// In en, this message translates to:
  /// **'Exchange rate can only be adjusted within ±5% of the system rate.'**
  String get exchangeRatePercentage;

  /// No description provided for @balanced.
  ///
  /// In en, this message translates to:
  /// **'BALANCED'**
  String get balanced;

  /// No description provided for @unbalanced.
  ///
  /// In en, this message translates to:
  /// **'UNBALANCED'**
  String get unbalanced;

  /// No description provided for @various.
  ///
  /// In en, this message translates to:
  /// **'Various'**
  String get various;

  /// No description provided for @totalTitle.
  ///
  /// In en, this message translates to:
  /// **'Total'**
  String get totalTitle;

  /// No description provided for @debitNotEqualBaseCurrency.
  ///
  /// In en, this message translates to:
  /// **'Debit and credit amounts must balance.'**
  String get debitNotEqualBaseCurrency;

  /// No description provided for @adjusted.
  ///
  /// In en, this message translates to:
  /// **'Adjusted'**
  String get adjusted;

  /// No description provided for @enterRate.
  ///
  /// In en, this message translates to:
  /// **'Rate'**
  String get enterRate;

  /// No description provided for @driverName.
  ///
  /// In en, this message translates to:
  /// **'Driver Information'**
  String get driverName;

  /// No description provided for @vehicle.
  ///
  /// In en, this message translates to:
  /// **'Vehicle'**
  String get vehicle;

  /// No description provided for @hireDate.
  ///
  /// In en, this message translates to:
  /// **'Hired date'**
  String get hireDate;

  /// No description provided for @vehicleModel.
  ///
  /// In en, this message translates to:
  /// **'Vehicle Model & Driver'**
  String get vehicleModel;

  /// No description provided for @driver.
  ///
  /// In en, this message translates to:
  /// **'Driver'**
  String get driver;

  /// No description provided for @manufacturedYear.
  ///
  /// In en, this message translates to:
  /// **'Model Year'**
  String get manufacturedYear;

  /// No description provided for @vehiclePlate.
  ///
  /// In en, this message translates to:
  /// **'Plate No'**
  String get vehiclePlate;

  /// No description provided for @vehicleType.
  ///
  /// In en, this message translates to:
  /// **'Category'**
  String get vehicleType;

  /// No description provided for @fuelType.
  ///
  /// In en, this message translates to:
  /// **'Fuel'**
  String get fuelType;

  /// No description provided for @vinNumber.
  ///
  /// In en, this message translates to:
  /// **'VIN Number'**
  String get vinNumber;

  /// No description provided for @enginePower.
  ///
  /// In en, this message translates to:
  /// **'Engine Power'**
  String get enginePower;

  /// No description provided for @vclRegisteredNo.
  ///
  /// In en, this message translates to:
  /// **'Registration Number'**
  String get vclRegisteredNo;

  /// No description provided for @ownership.
  ///
  /// In en, this message translates to:
  /// **'Onwership'**
  String get ownership;

  /// No description provided for @rental.
  ///
  /// In en, this message translates to:
  /// **'Rental'**
  String get rental;

  /// No description provided for @owned.
  ///
  /// In en, this message translates to:
  /// **'Owned'**
  String get owned;

  /// No description provided for @lease.
  ///
  /// In en, this message translates to:
  /// **'Lease'**
  String get lease;

  /// No description provided for @petrol.
  ///
  /// In en, this message translates to:
  /// **'Petrol'**
  String get petrol;

  /// No description provided for @diesel.
  ///
  /// In en, this message translates to:
  /// **'Diesel'**
  String get diesel;

  /// No description provided for @cngGas.
  ///
  /// In en, this message translates to:
  /// **'CNG'**
  String get cngGas;

  /// No description provided for @lpgGass.
  ///
  /// In en, this message translates to:
  /// **'LPG'**
  String get lpgGass;

  /// No description provided for @electric.
  ///
  /// In en, this message translates to:
  /// **'Electric'**
  String get electric;

  /// No description provided for @hydrogen.
  ///
  /// In en, this message translates to:
  /// **'Hydrogen'**
  String get hydrogen;

  /// No description provided for @hybrid.
  ///
  /// In en, this message translates to:
  /// **'Hybrid'**
  String get hybrid;

  /// No description provided for @truck.
  ///
  /// In en, this message translates to:
  /// **'Truck'**
  String get truck;

  /// No description provided for @tanker.
  ///
  /// In en, this message translates to:
  /// **'Tanker'**
  String get tanker;

  /// No description provided for @trailer.
  ///
  /// In en, this message translates to:
  /// **'Trailer'**
  String get trailer;

  /// No description provided for @pickup.
  ///
  /// In en, this message translates to:
  /// **'Pickup'**
  String get pickup;

  /// No description provided for @van.
  ///
  /// In en, this message translates to:
  /// **'Van'**
  String get van;

  /// No description provided for @bus.
  ///
  /// In en, this message translates to:
  /// **'Bus'**
  String get bus;

  /// No description provided for @miniVan.
  ///
  /// In en, this message translates to:
  /// **'Mini Van'**
  String get miniVan;

  /// No description provided for @sedan.
  ///
  /// In en, this message translates to:
  /// **'Sedan'**
  String get sedan;

  /// No description provided for @suv.
  ///
  /// In en, this message translates to:
  /// **'SUV'**
  String get suv;

  /// No description provided for @motorcycle.
  ///
  /// In en, this message translates to:
  /// **'Motorcycle'**
  String get motorcycle;

  /// No description provided for @rickshaw.
  ///
  /// In en, this message translates to:
  /// **'Rickshaw'**
  String get rickshaw;

  /// No description provided for @ambulance.
  ///
  /// In en, this message translates to:
  /// **'Ambulance'**
  String get ambulance;

  /// No description provided for @fireTruck.
  ///
  /// In en, this message translates to:
  /// **'Fire Truck'**
  String get fireTruck;

  /// No description provided for @tractor.
  ///
  /// In en, this message translates to:
  /// **'Tractor'**
  String get tractor;

  /// No description provided for @refrigeratedTruck.
  ///
  /// In en, this message translates to:
  /// **'Refrigerated Truck'**
  String get refrigeratedTruck;

  /// No description provided for @meter.
  ///
  /// In en, this message translates to:
  /// **'Odometer'**
  String get meter;

  /// No description provided for @vclExpireDate.
  ///
  /// In en, this message translates to:
  /// **'Expire date'**
  String get vclExpireDate;

  /// No description provided for @remark.
  ///
  /// In en, this message translates to:
  /// **'Remark'**
  String get remark;

  /// No description provided for @transactionDetails.
  ///
  /// In en, this message translates to:
  /// **'Transaction Details'**
  String get transactionDetails;

  /// No description provided for @debitAccount.
  ///
  /// In en, this message translates to:
  /// **'Debit Account'**
  String get debitAccount;

  /// No description provided for @creditAccount.
  ///
  /// In en, this message translates to:
  /// **'Credit Account'**
  String get creditAccount;

  /// No description provided for @vehicleDetails.
  ///
  /// In en, this message translates to:
  /// **'Vehicle Details'**
  String get vehicleDetails;

  /// No description provided for @authorizedTitle.
  ///
  /// In en, this message translates to:
  /// **'Authorized'**
  String get authorizedTitle;

  /// No description provided for @pendingTitle.
  ///
  /// In en, this message translates to:
  /// **'Pending'**
  String get pendingTitle;

  /// No description provided for @shpFrom.
  ///
  /// In en, this message translates to:
  /// **'Shipping from'**
  String get shpFrom;

  /// No description provided for @shpTo.
  ///
  /// In en, this message translates to:
  /// **'Shipping to'**
  String get shpTo;

  /// No description provided for @loadingDate.
  ///
  /// In en, this message translates to:
  /// **'Loading Date'**
  String get loadingDate;

  /// No description provided for @unloadingDate.
  ///
  /// In en, this message translates to:
  /// **'Unloading Date'**
  String get unloadingDate;

  /// No description provided for @shippingRent.
  ///
  /// In en, this message translates to:
  /// **'L/U Cost'**
  String get shippingRent;

  /// No description provided for @loadingSize.
  ///
  /// In en, this message translates to:
  /// **'L/W'**
  String get loadingSize;

  /// No description provided for @unloadingSize.
  ///
  /// In en, this message translates to:
  /// **'U/W'**
  String get unloadingSize;

  /// No description provided for @unit.
  ///
  /// In en, this message translates to:
  /// **'Unit'**
  String get unit;

  /// No description provided for @advanceAmount.
  ///
  /// In en, this message translates to:
  /// **'Advance amount'**
  String get advanceAmount;

  /// No description provided for @tonTitle.
  ///
  /// In en, this message translates to:
  /// **'Ton'**
  String get tonTitle;

  /// No description provided for @kgTitle.
  ///
  /// In en, this message translates to:
  /// **'Kg'**
  String get kgTitle;

  /// No description provided for @completedTitle.
  ///
  /// In en, this message translates to:
  /// **'Delivered'**
  String get completedTitle;

  /// No description provided for @next.
  ///
  /// In en, this message translates to:
  /// **'Next'**
  String get next;

  /// No description provided for @previous.
  ///
  /// In en, this message translates to:
  /// **'Previous'**
  String get previous;

  /// No description provided for @finish.
  ///
  /// In en, this message translates to:
  /// **'Finish'**
  String get finish;

  /// No description provided for @todayTransaction.
  ///
  /// In en, this message translates to:
  /// **'Today\'s Transactions'**
  String get todayTransaction;

  /// No description provided for @pendingTransactionTitle.
  ///
  /// In en, this message translates to:
  /// **'Pending Transactions'**
  String get pendingTransactionTitle;

  /// No description provided for @pendingTransactionHint.
  ///
  /// In en, this message translates to:
  /// **'Awaiting approval or completion'**
  String get pendingTransactionHint;

  /// No description provided for @order.
  ///
  /// In en, this message translates to:
  /// **'Order'**
  String get order;

  /// No description provided for @advancePayment.
  ///
  /// In en, this message translates to:
  /// **'Advance Payment'**
  String get advancePayment;

  /// No description provided for @payment.
  ///
  /// In en, this message translates to:
  /// **'Payment'**
  String get payment;

  /// No description provided for @noExpenseRecorded.
  ///
  /// In en, this message translates to:
  /// **'No expenses recorded'**
  String get noExpenseRecorded;

  /// No description provided for @allShipping.
  ///
  /// In en, this message translates to:
  /// **'All Shipments'**
  String get allShipping;

  /// No description provided for @accountExist.
  ///
  /// In en, this message translates to:
  /// **'Account already exists.'**
  String get accountExist;

  /// No description provided for @glDependentMsg.
  ///
  /// In en, this message translates to:
  /// **'This account is not deleted.'**
  String get glDependentMsg;

  /// No description provided for @glTypes.
  ///
  /// In en, this message translates to:
  /// **'TXN Types'**
  String get glTypes;

  /// No description provided for @productName.
  ///
  /// In en, this message translates to:
  /// **'Product name'**
  String get productName;

  /// No description provided for @productCode.
  ///
  /// In en, this message translates to:
  /// **'Product code'**
  String get productCode;

  /// No description provided for @transactionType.
  ///
  /// In en, this message translates to:
  /// **'Transaction Types'**
  String get transactionType;

  /// No description provided for @deactive.
  ///
  /// In en, this message translates to:
  /// **'Inactive'**
  String get deactive;

  /// No description provided for @userLogActivity.
  ///
  /// In en, this message translates to:
  /// **'Users Log Activity'**
  String get userLogActivity;

  /// No description provided for @yesterday.
  ///
  /// In en, this message translates to:
  /// **'Yesterday'**
  String get yesterday;

  /// No description provided for @lastWeek.
  ///
  /// In en, this message translates to:
  /// **'Last 7 Days'**
  String get lastWeek;

  /// No description provided for @last30Days.
  ///
  /// In en, this message translates to:
  /// **'Last 30 days'**
  String get last30Days;

  /// No description provided for @lastMonth.
  ///
  /// In en, this message translates to:
  /// **'Last 30 Days'**
  String get lastMonth;

  /// No description provided for @dateRange.
  ///
  /// In en, this message translates to:
  /// **'Date range'**
  String get dateRange;

  /// No description provided for @delivered.
  ///
  /// In en, this message translates to:
  /// **'Delivered'**
  String get delivered;

  /// No description provided for @shippingSummary.
  ///
  /// In en, this message translates to:
  /// **'Shipping Summary'**
  String get shippingSummary;

  /// No description provided for @shippingDetails.
  ///
  /// In en, this message translates to:
  /// **'Shipping Details'**
  String get shippingDetails;

  /// No description provided for @fromTo.
  ///
  /// In en, this message translates to:
  /// **'From → To'**
  String get fromTo;

  /// No description provided for @selectCustomer.
  ///
  /// In en, this message translates to:
  /// **'Please select a customer'**
  String get selectCustomer;

  /// No description provided for @selectProduct.
  ///
  /// In en, this message translates to:
  /// **'Please select a product'**
  String get selectProduct;

  /// No description provided for @selectVehicle.
  ///
  /// In en, this message translates to:
  /// **'Please select a vehicle'**
  String get selectVehicle;

  /// No description provided for @fillShippingLocations.
  ///
  /// In en, this message translates to:
  /// **'Please fill in shipping locations'**
  String get fillShippingLocations;

  /// No description provided for @fillLoadingSize.
  ///
  /// In en, this message translates to:
  /// **'Please fill in loading size'**
  String get fillLoadingSize;

  /// No description provided for @fillShippingRent.
  ///
  /// In en, this message translates to:
  /// **'Please enter shipping rent'**
  String get fillShippingRent;

  /// No description provided for @invalidShippingRent.
  ///
  /// In en, this message translates to:
  /// **'Invalid shipping rent amount'**
  String get invalidShippingRent;

  /// No description provided for @invalidAdvanceAmount.
  ///
  /// In en, this message translates to:
  /// **'Invalid advance amount'**
  String get invalidAdvanceAmount;

  /// No description provided for @unloadingSizeRequired.
  ///
  /// In en, this message translates to:
  /// **'Unloading size is required for delivery'**
  String get unloadingSizeRequired;

  /// No description provided for @invalidUnloadingSize.
  ///
  /// In en, this message translates to:
  /// **'Invalid unloading size amount'**
  String get invalidUnloadingSize;

  /// No description provided for @setUnloadingDate.
  ///
  /// In en, this message translates to:
  /// **'Please set the actual unloading date for delivery'**
  String get setUnloadingDate;

  /// No description provided for @unloadingBeforeLoading.
  ///
  /// In en, this message translates to:
  /// **'Unloading date cannot be before loading date'**
  String get unloadingBeforeLoading;

  /// No description provided for @invalidDateFormat.
  ///
  /// In en, this message translates to:
  /// **'Invalid date format'**
  String get invalidDateFormat;

  /// No description provided for @deliveryRequiredFields.
  ///
  /// In en, this message translates to:
  /// **'The following fields are required for delivery:'**
  String get deliveryRequiredFields;

  /// No description provided for @unloadingSizeWarning.
  ///
  /// In en, this message translates to:
  /// **'Unloading Size Warning'**
  String get unloadingSizeWarning;

  /// No description provided for @summary.
  ///
  /// In en, this message translates to:
  /// **'Summary'**
  String get summary;

  /// No description provided for @unloadingSizeWarningMessage.
  ///
  /// In en, this message translates to:
  /// **'differs significantly from loading size'**
  String get unloadingSizeWarningMessage;

  /// No description provided for @unloadingSizeProceedMessage.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to proceed with delivery?'**
  String get unloadingSizeProceedMessage;

  /// No description provided for @proceed.
  ///
  /// In en, this message translates to:
  /// **'Proceed'**
  String get proceed;

  /// No description provided for @createNewShipping.
  ///
  /// In en, this message translates to:
  /// **'CREATE NEW SHIPPING'**
  String get createNewShipping;

  /// No description provided for @newShippingHint.
  ///
  /// In en, this message translates to:
  /// **'Complete the required fields and follow the steps for new shipment.'**
  String get newShippingHint;

  /// No description provided for @updateShipping.
  ///
  /// In en, this message translates to:
  /// **'UPDATE SHIPPING'**
  String get updateShipping;

  /// No description provided for @updateShippingHint.
  ///
  /// In en, this message translates to:
  /// **'Complete the required fields and follow the steps to complete shipment.'**
  String get updateShippingHint;

  /// No description provided for @copied.
  ///
  /// In en, this message translates to:
  /// **'Copied'**
  String get copied;

  /// No description provided for @cashTitle.
  ///
  /// In en, this message translates to:
  /// **'Cash Payment'**
  String get cashTitle;

  /// No description provided for @paymentDescription.
  ///
  /// In en, this message translates to:
  /// **'Finalize payment for this shipping'**
  String get paymentDescription;

  /// No description provided for @totalAmount.
  ///
  /// In en, this message translates to:
  /// **'Total Amount'**
  String get totalAmount;

  /// No description provided for @totalShippingRent.
  ///
  /// In en, this message translates to:
  /// **'Total shipping charges'**
  String get totalShippingRent;

  /// No description provided for @paymentOptions.
  ///
  /// In en, this message translates to:
  /// **'Payment Options'**
  String get paymentOptions;

  /// No description provided for @selectPaymentMethod.
  ///
  /// In en, this message translates to:
  /// **'Select payment method'**
  String get selectPaymentMethod;

  /// No description provided for @cashPayment.
  ///
  /// In en, this message translates to:
  /// **'Cash Payment'**
  String get cashPayment;

  /// No description provided for @cashAmount.
  ///
  /// In en, this message translates to:
  /// **'Cash Amount'**
  String get cashAmount;

  /// No description provided for @enterCashAmount.
  ///
  /// In en, this message translates to:
  /// **'Enter cash amount'**
  String get enterCashAmount;

  /// No description provided for @cashPaidNow.
  ///
  /// In en, this message translates to:
  /// **'Paid now in cash'**
  String get cashPaidNow;

  /// No description provided for @accountPayment.
  ///
  /// In en, this message translates to:
  /// **'Account Payment'**
  String get accountPayment;

  /// No description provided for @remainingBalance.
  ///
  /// In en, this message translates to:
  /// **'Remaining Balance'**
  String get remainingBalance;

  /// No description provided for @selectAccount.
  ///
  /// In en, this message translates to:
  /// **'Select Account'**
  String get selectAccount;

  /// No description provided for @selectReceivableAccount.
  ///
  /// In en, this message translates to:
  /// **'Select receivable account'**
  String get selectReceivableAccount;

  /// No description provided for @selectAccountRequired.
  ///
  /// In en, this message translates to:
  /// **'Please select an account'**
  String get selectAccountRequired;

  /// No description provided for @selectValidAccount.
  ///
  /// In en, this message translates to:
  /// **'Please select a valid account'**
  String get selectValidAccount;

  /// No description provided for @remainingWillBeAddedToAccount.
  ///
  /// In en, this message translates to:
  /// **'Remaining amount will be added to selected account'**
  String get remainingWillBeAddedToAccount;

  /// No description provided for @paymentSummary.
  ///
  /// In en, this message translates to:
  /// **'Payment Summary'**
  String get paymentSummary;

  /// No description provided for @cashPaid.
  ///
  /// In en, this message translates to:
  /// **'Cash Paid'**
  String get cashPaid;

  /// No description provided for @toAccount.
  ///
  /// In en, this message translates to:
  /// **'To Account'**
  String get toAccount;

  /// No description provided for @fullyPaid.
  ///
  /// In en, this message translates to:
  /// **'Fully Paid'**
  String get fullyPaid;

  /// No description provided for @cashExceedsTotal.
  ///
  /// In en, this message translates to:
  /// **'Cash amount cannot exceed total'**
  String get cashExceedsTotal;

  /// No description provided for @noAccountsFound.
  ///
  /// In en, this message translates to:
  /// **'No accounts found'**
  String get noAccountsFound;

  /// No description provided for @cash.
  ///
  /// In en, this message translates to:
  /// **'Cash'**
  String get cash;

  /// No description provided for @totalPaid.
  ///
  /// In en, this message translates to:
  /// **'Total Paid'**
  String get totalPaid;

  /// No description provided for @remainingToPay.
  ///
  /// In en, this message translates to:
  /// **'Remaining to Pay'**
  String get remainingToPay;

  /// No description provided for @thisAmountWillBeAddedToAccount.
  ///
  /// In en, this message translates to:
  /// **'This amount will be added to the selected account'**
  String get thisAmountWillBeAddedToAccount;

  /// No description provided for @enterValidCashAmount.
  ///
  /// In en, this message translates to:
  /// **'Please enter a valid cash amount'**
  String get enterValidCashAmount;

  /// No description provided for @confirmPayment.
  ///
  /// In en, this message translates to:
  /// **'Confirm Payment'**
  String get confirmPayment;

  /// No description provided for @paymentConfirmationMessage.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to process this payment?'**
  String get paymentConfirmationMessage;

  /// No description provided for @addPayment.
  ///
  /// In en, this message translates to:
  /// **'Add Payment'**
  String get addPayment;

  /// No description provided for @editPayment.
  ///
  /// In en, this message translates to:
  /// **'Edit Payment'**
  String get editPayment;

  /// No description provided for @updatePayment.
  ///
  /// In en, this message translates to:
  /// **'Update Payment'**
  String get updatePayment;

  /// No description provided for @savePayment.
  ///
  /// In en, this message translates to:
  /// **'Save Payment'**
  String get savePayment;

  /// No description provided for @paymentDetails.
  ///
  /// In en, this message translates to:
  /// **'Payment Details'**
  String get paymentDetails;

  /// No description provided for @paymentTypeDisplayDual.
  ///
  /// In en, this message translates to:
  /// **'Cash & Account'**
  String get paymentTypeDisplayDual;

  /// No description provided for @paymentTypeDisplayCash.
  ///
  /// In en, this message translates to:
  /// **'Cash Only'**
  String get paymentTypeDisplayCash;

  /// No description provided for @paymentTypeDisplayCard.
  ///
  /// In en, this message translates to:
  /// **'Account Only'**
  String get paymentTypeDisplayCard;

  /// No description provided for @fee.
  ///
  /// In en, this message translates to:
  /// **'Fee'**
  String get fee;

  /// No description provided for @totalPayment.
  ///
  /// In en, this message translates to:
  /// **'Total Payment'**
  String get totalPayment;

  /// No description provided for @totalCharge.
  ///
  /// In en, this message translates to:
  /// **'Total Charge'**
  String get totalCharge;

  /// No description provided for @paymentType.
  ///
  /// In en, this message translates to:
  /// **'Payment Method'**
  String get paymentType;

  /// No description provided for @loadingTitle.
  ///
  /// In en, this message translates to:
  /// **'Please wait…'**
  String get loadingTitle;

  /// No description provided for @payCash.
  ///
  /// In en, this message translates to:
  /// **'Pay with physical cash'**
  String get payCash;

  /// No description provided for @amountToChargeAccount.
  ///
  /// In en, this message translates to:
  /// **'Amount due to account'**
  String get amountToChargeAccount;

  /// No description provided for @enterAmount.
  ///
  /// In en, this message translates to:
  /// **'Enter amount'**
  String get enterAmount;

  /// No description provided for @adjustAmount.
  ///
  /// In en, this message translates to:
  /// **'Adjust amount'**
  String get adjustAmount;

  /// No description provided for @amountToChargeTitle.
  ///
  /// In en, this message translates to:
  /// **'Amount to charge'**
  String get amountToChargeTitle;

  /// No description provided for @accountDetails.
  ///
  /// In en, this message translates to:
  /// **'Account Details'**
  String get accountDetails;

  /// No description provided for @targetAmount.
  ///
  /// In en, this message translates to:
  /// **'Target amount'**
  String get targetAmount;

  /// No description provided for @editPaymentValidation.
  ///
  /// In en, this message translates to:
  /// **'Edited payment amount must match the current shipping total of'**
  String get editPaymentValidation;

  /// No description provided for @paymentMustMatchRemaining.
  ///
  /// In en, this message translates to:
  /// **'Payment must match remaining balance of'**
  String get paymentMustMatchRemaining;

  /// No description provided for @paymentMustMatchTotalShipping.
  ///
  /// In en, this message translates to:
  /// **'Payment must match shipping total of'**
  String get paymentMustMatchTotalShipping;

  /// No description provided for @confirmMethodPayment.
  ///
  /// In en, this message translates to:
  /// **'Please confirm the payment details'**
  String get confirmMethodPayment;

  /// No description provided for @existingPayment.
  ///
  /// In en, this message translates to:
  /// **'Existing Payment'**
  String get existingPayment;

  /// No description provided for @orderStep.
  ///
  /// In en, this message translates to:
  /// **'Order Step'**
  String get orderStep;

  /// No description provided for @shippingStep.
  ///
  /// In en, this message translates to:
  /// **'Shipping Step'**
  String get shippingStep;

  /// No description provided for @paymentIsNotComplete.
  ///
  /// In en, this message translates to:
  /// **'Payment is not complete or doesn\'t match shipping total.'**
  String get paymentIsNotComplete;

  /// No description provided for @paymentNeedsUpdate.
  ///
  /// In en, this message translates to:
  /// **'Cannot mark as delivered. Payment needs to be updated first.'**
  String get paymentNeedsUpdate;

  /// No description provided for @paymentNeedsUpdateTitle.
  ///
  /// In en, this message translates to:
  /// **' Payment needs update! Current:'**
  String get paymentNeedsUpdateTitle;

  /// No description provided for @requiredTitle.
  ///
  /// In en, this message translates to:
  /// **'Required'**
  String get requiredTitle;

  /// No description provided for @paymentMatches.
  ///
  /// In en, this message translates to:
  /// **'Payment matches remaining balance'**
  String get paymentMatches;

  /// No description provided for @paymentMatchesShippingTotal.
  ///
  /// In en, this message translates to:
  /// **'Payment matches shipping total.'**
  String get paymentMatchesShippingTotal;

  /// No description provided for @cashAmountCannotExceed.
  ///
  /// In en, this message translates to:
  /// **'Cash amount cannot exceed'**
  String get cashAmountCannotExceed;

  /// No description provided for @editExistingPayment.
  ///
  /// In en, this message translates to:
  /// **'Editing existing payment'**
  String get editExistingPayment;

  /// No description provided for @lastMonthShipments.
  ///
  /// In en, this message translates to:
  /// **'Shipments'**
  String get lastMonthShipments;

  /// No description provided for @shippingCharges.
  ///
  /// In en, this message translates to:
  /// **'Shipping Charges'**
  String get shippingCharges;

  /// No description provided for @singleAccount.
  ///
  /// In en, this message translates to:
  /// **'Single Account'**
  String get singleAccount;

  /// No description provided for @multiAccount.
  ///
  /// In en, this message translates to:
  /// **'Multi Account'**
  String get multiAccount;

  /// No description provided for @productCategoryTitle.
  ///
  /// In en, this message translates to:
  /// **'Create and manage product categories.'**
  String get productCategoryTitle;

  /// No description provided for @manageProductTitle.
  ///
  /// In en, this message translates to:
  /// **'View, add, and manage product details here.'**
  String get manageProductTitle;

  /// No description provided for @estimateTitle.
  ///
  /// In en, this message translates to:
  /// **'Estimate'**
  String get estimateTitle;

  /// No description provided for @orderTitle.
  ///
  /// In en, this message translates to:
  /// **'Orders'**
  String get orderTitle;

  /// No description provided for @purchaseTitle.
  ///
  /// In en, this message translates to:
  /// **'Purchase'**
  String get purchaseTitle;

  /// No description provided for @invoiceTitle.
  ///
  /// In en, this message translates to:
  /// **'Invoice'**
  String get invoiceTitle;

  /// No description provided for @accountCcyNotMatchBaseCcy.
  ///
  /// In en, this message translates to:
  /// **'The selected account currency does not match the shipping currency.'**
  String get accountCcyNotMatchBaseCcy;

  /// No description provided for @billNo.
  ///
  /// In en, this message translates to:
  /// **'Bill No'**
  String get billNo;

  /// No description provided for @madeIn.
  ///
  /// In en, this message translates to:
  /// **'Made In'**
  String get madeIn;

  /// No description provided for @adjustment.
  ///
  /// In en, this message translates to:
  /// **'Adjustment'**
  String get adjustment;

  /// No description provided for @todayOrdersTitle.
  ///
  /// In en, this message translates to:
  /// **'Today\'s Orders'**
  String get todayOrdersTitle;

  /// No description provided for @ordersSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Purchases, Sales, Return Goods and adjustment'**
  String get ordersSubtitle;

  /// No description provided for @accountBlockedMessage.
  ///
  /// In en, this message translates to:
  /// **'Your account is blocked.'**
  String get accountBlockedMessage;

  /// No description provided for @transportTitle.
  ///
  /// In en, this message translates to:
  /// **'Transport'**
  String get transportTitle;

  /// No description provided for @transportEntry.
  ///
  /// In en, this message translates to:
  /// **'Transport Entry'**
  String get transportEntry;

  /// No description provided for @assetEntry.
  ///
  /// In en, this message translates to:
  /// **'Asset Entry'**
  String get assetEntry;

  /// No description provided for @attentionTitle.
  ///
  /// In en, this message translates to:
  /// **'Attention'**
  String get attentionTitle;

  /// No description provided for @pendingShippingMessage.
  ///
  /// In en, this message translates to:
  /// **'This shipping is not yet delivered. You can authorize or delete the transaction after shipping is delivered.'**
  String get pendingShippingMessage;

  /// No description provided for @transportInformation.
  ///
  /// In en, this message translates to:
  /// **'Transport Information'**
  String get transportInformation;

  /// No description provided for @movingDate.
  ///
  /// In en, this message translates to:
  /// **'Moving date'**
  String get movingDate;

  /// No description provided for @arrivalDate.
  ///
  /// In en, this message translates to:
  /// **'Arrival date'**
  String get arrivalDate;

  /// No description provided for @cannotMarkDeliveredMsg.
  ///
  /// In en, this message translates to:
  /// **'Cannot mark as delivered. Payment incomplete. Paid'**
  String get cannotMarkDeliveredMsg;

  /// No description provided for @supplier.
  ///
  /// In en, this message translates to:
  /// **'Supplier'**
  String get supplier;

  /// No description provided for @purchaseEntry.
  ///
  /// In en, this message translates to:
  /// **'Purchase Entry'**
  String get purchaseEntry;

  /// No description provided for @unitPrice.
  ///
  /// In en, this message translates to:
  /// **'Unit Price'**
  String get unitPrice;

  /// No description provided for @qty.
  ///
  /// In en, this message translates to:
  /// **'QTY'**
  String get qty;

  /// No description provided for @addItem.
  ///
  /// In en, this message translates to:
  /// **'Add Item'**
  String get addItem;

  /// No description provided for @invoiceNumber.
  ///
  /// In en, this message translates to:
  /// **'Invoice #'**
  String get invoiceNumber;

  /// No description provided for @grandTotal.
  ///
  /// In en, this message translates to:
  /// **'Grand Total'**
  String get grandTotal;

  /// No description provided for @invoiceType.
  ///
  /// In en, this message translates to:
  /// **'Invoice'**
  String get invoiceType;

  /// No description provided for @totalInvoice.
  ///
  /// In en, this message translates to:
  /// **'Total Invoice'**
  String get totalInvoice;

  /// No description provided for @saleTitle.
  ///
  /// In en, this message translates to:
  /// **'Sale'**
  String get saleTitle;

  /// No description provided for @newBalance.
  ///
  /// In en, this message translates to:
  /// **'New Balance'**
  String get newBalance;

  /// No description provided for @cashPaymentSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Pay the total amount in cash.'**
  String get cashPaymentSubtitle;

  /// No description provided for @accountCredit.
  ///
  /// In en, this message translates to:
  /// **'Account Credit'**
  String get accountCredit;

  /// No description provided for @accountCreditSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Apply the full amount as account credit.”'**
  String get accountCreditSubtitle;

  /// No description provided for @combinedPayment.
  ///
  /// In en, this message translates to:
  /// **'Cash & Credit'**
  String get combinedPayment;

  /// No description provided for @combinedPaymentSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Pay using cash and account credit.'**
  String get combinedPaymentSubtitle;

  /// No description provided for @submit.
  ///
  /// In en, this message translates to:
  /// **'Submit'**
  String get submit;

  /// No description provided for @successPurchaseInvoiceMsg.
  ///
  /// In en, this message translates to:
  /// **'Purchase invoice completed successfully.'**
  String get successPurchaseInvoiceMsg;

  /// No description provided for @successTitle.
  ///
  /// In en, this message translates to:
  /// **'Success'**
  String get successTitle;

  /// No description provided for @selectCreditAccountMsg.
  ///
  /// In en, this message translates to:
  /// **'Please select an account for credit payment.'**
  String get selectCreditAccountMsg;

  /// No description provided for @totalCost.
  ///
  /// In en, this message translates to:
  /// **'Total Cost'**
  String get totalCost;

  /// No description provided for @profit.
  ///
  /// In en, this message translates to:
  /// **'Profit'**
  String get profit;

  /// No description provided for @totalSale.
  ///
  /// In en, this message translates to:
  /// **'Total Sale'**
  String get totalSale;

  /// No description provided for @salePrice.
  ///
  /// In en, this message translates to:
  /// **'Sale Price'**
  String get salePrice;

  /// No description provided for @costPrice.
  ///
  /// In en, this message translates to:
  /// **'Cost Price'**
  String get costPrice;

  /// No description provided for @purchasePrice.
  ///
  /// In en, this message translates to:
  /// **'P-AVG. Price'**
  String get purchasePrice;

  /// No description provided for @profitSummary.
  ///
  /// In en, this message translates to:
  /// **'Profit & Loss'**
  String get profitSummary;

  /// No description provided for @saleEntry.
  ///
  /// In en, this message translates to:
  /// **'Sale Entry'**
  String get saleEntry;

  /// No description provided for @salePriceBrief.
  ///
  /// In en, this message translates to:
  /// **'S. Price'**
  String get salePriceBrief;

  /// No description provided for @orderSearchHint.
  ///
  /// In en, this message translates to:
  /// **'Order ID, Reference, Oder Type'**
  String get orderSearchHint;

  /// No description provided for @userTitle.
  ///
  /// In en, this message translates to:
  /// **'User'**
  String get userTitle;

  /// No description provided for @noRecords.
  ///
  /// In en, this message translates to:
  /// **'No Records'**
  String get noRecords;

  /// No description provided for @accountingEntries.
  ///
  /// In en, this message translates to:
  /// **'Accounting Entries'**
  String get accountingEntries;

  /// No description provided for @noItems.
  ///
  /// In en, this message translates to:
  /// **'No items'**
  String get noItems;

  /// No description provided for @items.
  ///
  /// In en, this message translates to:
  /// **'Items'**
  String get items;

  /// No description provided for @notEnoughMsg.
  ///
  /// In en, this message translates to:
  /// **'Not enough item available.'**
  String get notEnoughMsg;

  /// No description provided for @paymentMismatchTotalInvoice.
  ///
  /// In en, this message translates to:
  /// **'Payment total isn\'t equal total invoice.'**
  String get paymentMismatchTotalInvoice;

  /// No description provided for @retry.
  ///
  /// In en, this message translates to:
  /// **'Retry'**
  String get retry;

  /// No description provided for @savingChanges.
  ///
  /// In en, this message translates to:
  /// **'Saving Changes ...'**
  String get savingChanges;

  /// No description provided for @remove.
  ///
  /// In en, this message translates to:
  /// **'Remove'**
  String get remove;

  /// No description provided for @removeItem.
  ///
  /// In en, this message translates to:
  /// **'Remove Item'**
  String get removeItem;

  /// No description provided for @removeItemMsg.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to remove this item?'**
  String get removeItemMsg;

  /// No description provided for @customerAndPaymentDetails.
  ///
  /// In en, this message translates to:
  /// **'Customer & Payment Details'**
  String get customerAndPaymentDetails;

  /// No description provided for @supplierAndPaymentDetails.
  ///
  /// In en, this message translates to:
  /// **'Supplier & Payment Details'**
  String get supplierAndPaymentDetails;

  /// No description provided for @orderDate.
  ///
  /// In en, this message translates to:
  /// **'Order Date'**
  String get orderDate;

  /// No description provided for @orderId.
  ///
  /// In en, this message translates to:
  /// **'Order ID'**
  String get orderId;

  /// No description provided for @invoiceDetails.
  ///
  /// In en, this message translates to:
  /// **'Invoice Details'**
  String get invoiceDetails;

  /// No description provided for @returnPurchase.
  ///
  /// In en, this message translates to:
  /// **'Purchase Return'**
  String get returnPurchase;

  /// No description provided for @saleReturn.
  ///
  /// In en, this message translates to:
  /// **'Sale Return'**
  String get saleReturn;

  /// No description provided for @findInvoice.
  ///
  /// In en, this message translates to:
  /// **'Find Invoice'**
  String get findInvoice;

  /// No description provided for @enterInvoiceNumber.
  ///
  /// In en, this message translates to:
  /// **'Enter the invoice number to proceed.'**
  String get enterInvoiceNumber;

  /// No description provided for @newPurchase.
  ///
  /// In en, this message translates to:
  /// **'New Purchase'**
  String get newPurchase;

  /// No description provided for @newSale.
  ///
  /// In en, this message translates to:
  /// **'New Sale'**
  String get newSale;

  /// No description provided for @party.
  ///
  /// In en, this message translates to:
  /// **'Party'**
  String get party;

  /// No description provided for @estimate.
  ///
  /// In en, this message translates to:
  /// **'Estimate'**
  String get estimate;

  /// No description provided for @creditPayment.
  ///
  /// In en, this message translates to:
  /// **'Credit Payment'**
  String get creditPayment;

  /// No description provided for @lastYear.
  ///
  /// In en, this message translates to:
  /// **'Last Year'**
  String get lastYear;

  /// No description provided for @profitAndLoss.
  ///
  /// In en, this message translates to:
  /// **'Profit & Loss'**
  String get profitAndLoss;

  /// No description provided for @loss.
  ///
  /// In en, this message translates to:
  /// **'Loss'**
  String get loss;

  /// No description provided for @signatory.
  ///
  /// In en, this message translates to:
  /// **'Signatory'**
  String get signatory;

  /// No description provided for @payables.
  ///
  /// In en, this message translates to:
  /// **'Payables'**
  String get payables;

  /// No description provided for @totalUpperCase.
  ///
  /// In en, this message translates to:
  /// **'TOTAL'**
  String get totalUpperCase;

  /// No description provided for @trialBalance.
  ///
  /// In en, this message translates to:
  /// **'Trial Balance'**
  String get trialBalance;

  /// No description provided for @outOfBalance.
  ///
  /// In en, this message translates to:
  /// **'Out of Balance'**
  String get outOfBalance;

  /// No description provided for @orders.
  ///
  /// In en, this message translates to:
  /// **'Orders'**
  String get orders;

  /// No description provided for @notAuthorizedYet.
  ///
  /// In en, this message translates to:
  /// **'Not Authorized'**
  String get notAuthorizedYet;

  /// No description provided for @subCategory.
  ///
  /// In en, this message translates to:
  /// **'Sub Category'**
  String get subCategory;

  /// No description provided for @glAccountsComplete.
  ///
  /// In en, this message translates to:
  /// **'General Ledger Accounts'**
  String get glAccountsComplete;

  /// No description provided for @allCurrencies.
  ///
  /// In en, this message translates to:
  /// **'All Currencies'**
  String get allCurrencies;

  /// No description provided for @newEstimate.
  ///
  /// In en, this message translates to:
  /// **'New Estimate'**
  String get newEstimate;

  /// No description provided for @optional.
  ///
  /// In en, this message translates to:
  /// **'Optional'**
  String get optional;

  /// No description provided for @customerInformation.
  ///
  /// In en, this message translates to:
  /// **'Customer Information'**
  String get customerInformation;

  /// No description provided for @productDetails.
  ///
  /// In en, this message translates to:
  /// **'Product Details'**
  String get productDetails;

  /// No description provided for @currentYear.
  ///
  /// In en, this message translates to:
  /// **'Current Year'**
  String get currentYear;

  /// No description provided for @number.
  ///
  /// In en, this message translates to:
  /// **'No'**
  String get number;

  /// No description provided for @currentAssets.
  ///
  /// In en, this message translates to:
  /// **'Current Assets'**
  String get currentAssets;

  /// No description provided for @fixedAssets.
  ///
  /// In en, this message translates to:
  /// **'Fixed Assets'**
  String get fixedAssets;

  /// No description provided for @intangibleAssets.
  ///
  /// In en, this message translates to:
  /// **'Intangible Assets'**
  String get intangibleAssets;

  /// No description provided for @currentLiabilities.
  ///
  /// In en, this message translates to:
  /// **'Current Liabilities'**
  String get currentLiabilities;

  /// No description provided for @ownerEquity.
  ///
  /// In en, this message translates to:
  /// **'Owner\'s Equity'**
  String get ownerEquity;

  /// No description provided for @totalAssets.
  ///
  /// In en, this message translates to:
  /// **'Total Assets'**
  String get totalAssets;

  /// No description provided for @totalLiabilitiesEquity.
  ///
  /// In en, this message translates to:
  /// **'Total Liabilities & Equity'**
  String get totalLiabilitiesEquity;

  /// No description provided for @assets.
  ///
  /// In en, this message translates to:
  /// **'Assets'**
  String get assets;

  /// No description provided for @liabilitiesEquity.
  ///
  /// In en, this message translates to:
  /// **'Liabilities & Equity'**
  String get liabilitiesEquity;

  /// No description provided for @netProfit.
  ///
  /// In en, this message translates to:
  /// **'Net Profit'**
  String get netProfit;

  /// No description provided for @actualBalance.
  ///
  /// In en, this message translates to:
  /// **'Actual Balance'**
  String get actualBalance;

  /// No description provided for @glStatementSingleDate.
  ///
  /// In en, this message translates to:
  /// **'GL Statement Single Date'**
  String get glStatementSingleDate;

  /// No description provided for @todayTransactionSummary.
  ///
  /// In en, this message translates to:
  /// **'Today’s Transaction Summary'**
  String get todayTransactionSummary;

  /// No description provided for @dashbordOverview.
  ///
  /// In en, this message translates to:
  /// **'Dashboard Overview'**
  String get dashbordOverview;

  /// No description provided for @noTransactionFound.
  ///
  /// In en, this message translates to:
  /// **'No Transaction Found'**
  String get noTransactionFound;

  /// No description provided for @transactionByRef.
  ///
  /// In en, this message translates to:
  /// **'Transaction By Reference'**
  String get transactionByRef;

  /// No description provided for @transactionSummary.
  ///
  /// In en, this message translates to:
  /// **'Transaction Summary'**
  String get transactionSummary;

  /// No description provided for @pandl.
  ///
  /// In en, this message translates to:
  /// **'P&L Closing'**
  String get pandl;

  /// No description provided for @retained.
  ///
  /// In en, this message translates to:
  /// **'Retained Earnings'**
  String get retained;

  /// No description provided for @expenses.
  ///
  /// In en, this message translates to:
  /// **'Expenses'**
  String get expenses;

  /// No description provided for @retainedEarnings.
  ///
  /// In en, this message translates to:
  /// **'Retained Earnings'**
  String get retainedEarnings;

  /// No description provided for @eoyClosing.
  ///
  /// In en, this message translates to:
  /// **'EOY CLOSING'**
  String get eoyClosing;

  /// No description provided for @plMessage.
  ///
  /// In en, this message translates to:
  /// **'Closing Profit & Loss will finalize all income and expense accounts for the current fiscal period.'**
  String get plMessage;

  /// No description provided for @openingBalance.
  ///
  /// In en, this message translates to:
  /// **'Opening Balance'**
  String get openingBalance;

  /// No description provided for @currencyBalances.
  ///
  /// In en, this message translates to:
  /// **'CURRENCY BALANCES'**
  String get currencyBalances;

  /// No description provided for @opening.
  ///
  /// In en, this message translates to:
  /// **'Opening'**
  String get opening;

  /// No description provided for @closing.
  ///
  /// In en, this message translates to:
  /// **'Closing'**
  String get closing;

  /// No description provided for @sys.
  ///
  /// In en, this message translates to:
  /// **'SYS'**
  String get sys;

  /// No description provided for @closingBalance.
  ///
  /// In en, this message translates to:
  /// **'Closing Balance'**
  String get closingBalance;

  /// No description provided for @systemEquivalent.
  ///
  /// In en, this message translates to:
  /// **'SYSTEM EQUIVALENT'**
  String get systemEquivalent;

  /// No description provided for @cashBalances.
  ///
  /// In en, this message translates to:
  /// **'Cash Balances'**
  String get cashBalances;

  /// No description provided for @usersHintReport.
  ///
  /// In en, this message translates to:
  /// **'Use the filters above to quickly find the users you need.'**
  String get usersHintReport;

  /// No description provided for @clearFilters.
  ///
  /// In en, this message translates to:
  /// **'Clear Filters'**
  String get clearFilters;

  /// No description provided for @outOfStock.
  ///
  /// In en, this message translates to:
  /// **'Out of stock'**
  String get outOfStock;

  /// No description provided for @available.
  ///
  /// In en, this message translates to:
  /// **'Available'**
  String get available;

  /// No description provided for @driverRegistration.
  ///
  /// In en, this message translates to:
  /// **'Driver Registration'**
  String get driverRegistration;

  /// No description provided for @verified.
  ///
  /// In en, this message translates to:
  /// **'Verified'**
  String get verified;

  /// No description provided for @fcp.
  ///
  /// In en, this message translates to:
  /// **'FCP'**
  String get fcp;

  /// No description provided for @weight.
  ///
  /// In en, this message translates to:
  /// **'Weight'**
  String get weight;

  /// No description provided for @inAndOut.
  ///
  /// In en, this message translates to:
  /// **'IN/OUT'**
  String get inAndOut;

  /// No description provided for @ongoingBalance.
  ///
  /// In en, this message translates to:
  /// **'Ongoing Balance'**
  String get ongoingBalance;

  /// No description provided for @accountsAndUsers.
  ///
  /// In en, this message translates to:
  /// **'Accounts & Users'**
  String get accountsAndUsers;

  /// No description provided for @fromStorage.
  ///
  /// In en, this message translates to:
  /// **'From Storage'**
  String get fromStorage;

  /// No description provided for @toStorage.
  ///
  /// In en, this message translates to:
  /// **'To Storage'**
  String get toStorage;

  /// No description provided for @totalItems.
  ///
  /// In en, this message translates to:
  /// **'Total Item'**
  String get totalItems;

  /// No description provided for @shiftItems.
  ///
  /// In en, this message translates to:
  /// **'Shift Items'**
  String get shiftItems;

  /// No description provided for @typeTitle.
  ///
  /// In en, this message translates to:
  /// **'Shift Type'**
  String get typeTitle;

  /// No description provided for @outTitle.
  ///
  /// In en, this message translates to:
  /// **'OUT'**
  String get outTitle;

  /// No description provided for @inTitle.
  ///
  /// In en, this message translates to:
  /// **'IN'**
  String get inTitle;

  /// No description provided for @totalProductValue.
  ///
  /// In en, this message translates to:
  /// **'Total Product Value'**
  String get totalProductValue;

  /// No description provided for @totalProductExpense.
  ///
  /// In en, this message translates to:
  /// **'Total (Product + Expense)'**
  String get totalProductExpense;

  /// No description provided for @expenseAmount.
  ///
  /// In en, this message translates to:
  /// **'Expense Amount'**
  String get expenseAmount;

  /// No description provided for @outRecords.
  ///
  /// In en, this message translates to:
  /// **'OUT Records'**
  String get outRecords;

  /// No description provided for @inRecords.
  ///
  /// In en, this message translates to:
  /// **'IN Records'**
  String get inRecords;

  /// No description provided for @accountTitle.
  ///
  /// In en, this message translates to:
  /// **'Account'**
  String get accountTitle;

  /// No description provided for @deleteMessage.
  ///
  /// In en, this message translates to:
  /// **'Do you want to delete? This action cannot be undone.”'**
  String get deleteMessage;

  /// No description provided for @deletedTitle.
  ///
  /// In en, this message translates to:
  /// **'Deleted'**
  String get deletedTitle;

  /// No description provided for @reversedTitle.
  ///
  /// In en, this message translates to:
  /// **'Reversed'**
  String get reversedTitle;

  /// No description provided for @alreadyEmployed.
  ///
  /// In en, this message translates to:
  /// **'Employee has already been employed.'**
  String get alreadyEmployed;

  /// No description provided for @entryDate.
  ///
  /// In en, this message translates to:
  /// **'Entry Date'**
  String get entryDate;

  /// No description provided for @timeOutMessage.
  ///
  /// In en, this message translates to:
  /// **'Oops! The server is taking too long to respond.'**
  String get timeOutMessage;

  /// No description provided for @requestCancelMessage.
  ///
  /// In en, this message translates to:
  /// **'The request was cancelled.'**
  String get requestCancelMessage;

  /// No description provided for @timeOutTitle.
  ///
  /// In en, this message translates to:
  /// **'Server Time Out'**
  String get timeOutTitle;

  /// No description provided for @notAllowedError.
  ///
  /// In en, this message translates to:
  /// **'This action isn\'t allowed.'**
  String get notAllowedError;

  /// No description provided for @successMessage.
  ///
  /// In en, this message translates to:
  /// **'Process completed successfully.'**
  String get successMessage;

  /// No description provided for @deleteSuccessMessage.
  ///
  /// In en, this message translates to:
  /// **'Item has been deleted successfully.'**
  String get deleteSuccessMessage;

  /// No description provided for @expenseAccount.
  ///
  /// In en, this message translates to:
  /// **'Account Name'**
  String get expenseAccount;

  /// No description provided for @averagePrice.
  ///
  /// In en, this message translates to:
  /// **'AVG. Price'**
  String get averagePrice;

  /// No description provided for @recentPrice.
  ///
  /// In en, this message translates to:
  /// **'RP. Price'**
  String get recentPrice;

  /// No description provided for @stockBalance.
  ///
  /// In en, this message translates to:
  /// **'Stock Balance'**
  String get stockBalance;

  /// No description provided for @productMovement.
  ///
  /// In en, this message translates to:
  /// **'Product Movement'**
  String get productMovement;

  /// No description provided for @accountStatus.
  ///
  /// In en, this message translates to:
  /// **'Account Status'**
  String get accountStatus;

  /// No description provided for @accountPosition.
  ///
  /// In en, this message translates to:
  /// **'Account Position'**
  String get accountPosition;

  /// No description provided for @creditor.
  ///
  /// In en, this message translates to:
  /// **'Creditor'**
  String get creditor;

  /// No description provided for @debtor.
  ///
  /// In en, this message translates to:
  /// **'Debtor'**
  String get debtor;

  /// No description provided for @stockAvailability.
  ///
  /// In en, this message translates to:
  /// **'Stock Availability'**
  String get stockAvailability;

  /// No description provided for @noBalance.
  ///
  /// In en, this message translates to:
  /// **'No Balance'**
  String get noBalance;

  /// No description provided for @balanceMessageShare.
  ///
  /// In en, this message translates to:
  /// **'Please find your account balance information below:'**
  String get balanceMessageShare;

  /// No description provided for @regardsTitle.
  ///
  /// In en, this message translates to:
  /// **'Regards'**
  String get regardsTitle;

  /// No description provided for @dearCustomer.
  ///
  /// In en, this message translates to:
  /// **'Dear Customer,'**
  String get dearCustomer;

  /// No description provided for @reminders.
  ///
  /// In en, this message translates to:
  /// **'Reminders'**
  String get reminders;

  /// No description provided for @noAlertReminders.
  ///
  /// In en, this message translates to:
  /// **'No Alert Reminders'**
  String get noAlertReminders;

  /// No description provided for @dueType.
  ///
  /// In en, this message translates to:
  /// **'Due Type'**
  String get dueType;

  /// No description provided for @payableDue.
  ///
  /// In en, this message translates to:
  /// **'Payable Due'**
  String get payableDue;

  /// No description provided for @receivableDue.
  ///
  /// In en, this message translates to:
  /// **'Receivable Due'**
  String get receivableDue;

  /// No description provided for @dueDate.
  ///
  /// In en, this message translates to:
  /// **'Due Date'**
  String get dueDate;

  /// No description provided for @setReminder.
  ///
  /// In en, this message translates to:
  /// **'Set Reminder'**
  String get setReminder;

  /// No description provided for @backupTitle.
  ///
  /// In en, this message translates to:
  /// **'Backup'**
  String get backupTitle;

  /// No description provided for @databaseBackup.
  ///
  /// In en, this message translates to:
  /// **'Database Backup'**
  String get databaseBackup;

  /// No description provided for @downloadBackupMsg.
  ///
  /// In en, this message translates to:
  /// **'Download a local copy of your database to keep your data safe.'**
  String get downloadBackupMsg;

  /// No description provided for @downloadLatestBackup.
  ///
  /// In en, this message translates to:
  /// **'Download Latest Backup'**
  String get downloadLatestBackup;

  /// No description provided for @downloading.
  ///
  /// In en, this message translates to:
  /// **'Downloading...'**
  String get downloading;

  /// No description provided for @existingBackups.
  ///
  /// In en, this message translates to:
  /// **'Existing Backups'**
  String get existingBackups;

  /// No description provided for @attendance.
  ///
  /// In en, this message translates to:
  /// **'Attendance'**
  String get attendance;

  /// No description provided for @absentTitle.
  ///
  /// In en, this message translates to:
  /// **'Absent'**
  String get absentTitle;

  /// No description provided for @lateTitle.
  ///
  /// In en, this message translates to:
  /// **'Late'**
  String get lateTitle;

  /// No description provided for @leaveTitle.
  ///
  /// In en, this message translates to:
  /// **'Leave'**
  String get leaveTitle;

  /// No description provided for @presentTitle.
  ///
  /// In en, this message translates to:
  /// **'Present'**
  String get presentTitle;

  /// No description provided for @checkIn.
  ///
  /// In en, this message translates to:
  /// **'Check IN'**
  String get checkIn;

  /// No description provided for @checkOut.
  ///
  /// In en, this message translates to:
  /// **'Check OUT'**
  String get checkOut;

  /// No description provided for @noAttendance.
  ///
  /// In en, this message translates to:
  /// **'No Attendance'**
  String get noAttendance;

  /// No description provided for @addAttendance.
  ///
  /// In en, this message translates to:
  /// **'Add Attendance'**
  String get addAttendance;

  /// No description provided for @currentValues.
  ///
  /// In en, this message translates to:
  /// **'Current Values'**
  String get currentValues;

  /// No description provided for @attendanceExist.
  ///
  /// In en, this message translates to:
  /// **'Attendance already exists for this date.'**
  String get attendanceExist;

  /// No description provided for @successAttendanceOperation.
  ///
  /// In en, this message translates to:
  /// **'A new attendance has been added successfully.'**
  String get successAttendanceOperation;

  /// No description provided for @operationFailedTitle.
  ///
  /// In en, this message translates to:
  /// **'Operation Failed'**
  String get operationFailedTitle;

  /// No description provided for @addShipmentHint.
  ///
  /// In en, this message translates to:
  /// **'Add and manage shipments.'**
  String get addShipmentHint;

  /// No description provided for @shipmentExpenseHint.
  ///
  /// In en, this message translates to:
  /// **'Record shipment expenses'**
  String get shipmentExpenseHint;

  /// No description provided for @purchaseInvoiceHint.
  ///
  /// In en, this message translates to:
  /// **'Record purchase invoice to update stock.'**
  String get purchaseInvoiceHint;

  /// No description provided for @saleInvoiceHint.
  ///
  /// In en, this message translates to:
  /// **'Create sale invoice to reduce stock.'**
  String get saleInvoiceHint;

  /// No description provided for @goodsAdjustmentHint.
  ///
  /// In en, this message translates to:
  /// **'Adjust goods to reflect shortage.'**
  String get goodsAdjustmentHint;

  /// No description provided for @estimateHint.
  ///
  /// In en, this message translates to:
  /// **'Prepare estimate for customer request.'**
  String get estimateHint;

  /// No description provided for @stockTransferHint.
  ///
  /// In en, this message translates to:
  /// **'Transfer goods from one stock to another.'**
  String get stockTransferHint;

  /// No description provided for @inventoryHint.
  ///
  /// In en, this message translates to:
  /// **'Check available stock before proceeding.'**
  String get inventoryHint;

  /// No description provided for @trackShipmentsHint.
  ///
  /// In en, this message translates to:
  /// **'Track logistics in one place.'**
  String get trackShipmentsHint;

  /// No description provided for @dismiss.
  ///
  /// In en, this message translates to:
  /// **'Dismiss'**
  String get dismiss;

  /// No description provided for @current.
  ///
  /// In en, this message translates to:
  /// **'Current'**
  String get current;

  /// No description provided for @loadPayroll.
  ///
  /// In en, this message translates to:
  /// **'Load Payroll'**
  String get loadPayroll;

  /// No description provided for @salaryAmount.
  ///
  /// In en, this message translates to:
  /// **'Salary Amount'**
  String get salaryAmount;

  /// No description provided for @overtime.
  ///
  /// In en, this message translates to:
  /// **'Overtime'**
  String get overtime;

  /// No description provided for @totalPayable.
  ///
  /// In en, this message translates to:
  /// **'Total Payable'**
  String get totalPayable;

  /// No description provided for @paidTitle.
  ///
  /// In en, this message translates to:
  /// **'Paid'**
  String get paidTitle;

  /// No description provided for @unpaidTitle.
  ///
  /// In en, this message translates to:
  /// **'Unpaid'**
  String get unpaidTitle;

  /// No description provided for @workedHours.
  ///
  /// In en, this message translates to:
  /// **'Worked Hours'**
  String get workedHours;

  /// No description provided for @workedDays.
  ///
  /// In en, this message translates to:
  /// **'Worked Days'**
  String get workedDays;

  /// No description provided for @baseHours.
  ///
  /// In en, this message translates to:
  /// **'Base Hours'**
  String get baseHours;

  /// No description provided for @disselect.
  ///
  /// In en, this message translates to:
  /// **'Disselect All'**
  String get disselect;

  /// No description provided for @postSalary.
  ///
  /// In en, this message translates to:
  /// **'Post Salary'**
  String get postSalary;

  /// No description provided for @dayTitle.
  ///
  /// In en, this message translates to:
  /// **'day'**
  String get dayTitle;

  /// No description provided for @daysTitle.
  ///
  /// In en, this message translates to:
  /// **'days'**
  String get daysTitle;

  /// No description provided for @dueIn.
  ///
  /// In en, this message translates to:
  /// **'Due in'**
  String get dueIn;

  /// No description provided for @overdueByOne.
  ///
  /// In en, this message translates to:
  /// **'Overdue by 1 days'**
  String get overdueByOne;

  /// No description provided for @overdueBy.
  ///
  /// In en, this message translates to:
  /// **'Overdue by'**
  String get overdueBy;

  /// No description provided for @dueTomorrow.
  ///
  /// In en, this message translates to:
  /// **'Due tomorrow'**
  String get dueTomorrow;

  /// No description provided for @dueToday.
  ///
  /// In en, this message translates to:
  /// **'Due today'**
  String get dueToday;

  /// No description provided for @other.
  ///
  /// In en, this message translates to:
  /// **'Other'**
  String get other;

  /// No description provided for @menuTitle.
  ///
  /// In en, this message translates to:
  /// **'Menu'**
  String get menuTitle;

  /// No description provided for @reports.
  ///
  /// In en, this message translates to:
  /// **'Reports'**
  String get reports;

  /// No description provided for @enableTitle.
  ///
  /// In en, this message translates to:
  /// **'Enabled'**
  String get enableTitle;

  /// No description provided for @disabledTitle.
  ///
  /// In en, this message translates to:
  /// **'Disabled'**
  String get disabledTitle;

  /// No description provided for @shortcuts.
  ///
  /// In en, this message translates to:
  /// **'Shortcuts'**
  String get shortcuts;

  /// No description provided for @invoiceAmount.
  ///
  /// In en, this message translates to:
  /// **'Invoice Amount'**
  String get invoiceAmount;

  /// No description provided for @inventorySubtitle.
  ///
  /// In en, this message translates to:
  /// **'All inventory operations managed in one place'**
  String get inventorySubtitle;

  /// No description provided for @journalHint.
  ///
  /// In en, this message translates to:
  /// **'Manage cash flow entries with Debit, Credit, and Amount.'**
  String get journalHint;

  /// No description provided for @changedTitle.
  ///
  /// In en, this message translates to:
  /// **'Changed'**
  String get changedTitle;

  /// No description provided for @resetPassword.
  ///
  /// In en, this message translates to:
  /// **'Reset Password'**
  String get resetPassword;

  /// No description provided for @roleAndBranch.
  ///
  /// In en, this message translates to:
  /// **'Role & Branch'**
  String get roleAndBranch;

  /// No description provided for @accountInfo.
  ///
  /// In en, this message translates to:
  /// **'Salary Account'**
  String get accountInfo;

  /// No description provided for @jobAndSalary.
  ///
  /// In en, this message translates to:
  /// **'Job Title & Salary'**
  String get jobAndSalary;

  /// No description provided for @errorTitle.
  ///
  /// In en, this message translates to:
  /// **'Operation Failed'**
  String get errorTitle;

  /// No description provided for @contactInfo.
  ///
  /// In en, this message translates to:
  /// **'Contact Information'**
  String get contactInfo;

  /// No description provided for @personalInfo.
  ///
  /// In en, this message translates to:
  /// **'Personal Information'**
  String get personalInfo;

  /// No description provided for @avbShort.
  ///
  /// In en, this message translates to:
  /// **'AVB'**
  String get avbShort;

  /// No description provided for @forgotPasswordTitle.
  ///
  /// In en, this message translates to:
  /// **'Forgot Password'**
  String get forgotPasswordTitle;

  /// No description provided for @forgotPasswordMessage.
  ///
  /// In en, this message translates to:
  /// **'Enter your email or username to reset your password'**
  String get forgotPasswordMessage;

  /// No description provided for @emailOrUsername.
  ///
  /// In en, this message translates to:
  /// **'Email or Username'**
  String get emailOrUsername;

  /// No description provided for @passwordResetTitle.
  ///
  /// In en, this message translates to:
  /// **'Password Reset'**
  String get passwordResetTitle;

  /// No description provided for @otpSendMessage.
  ///
  /// In en, this message translates to:
  /// **'Code sent to'**
  String get otpSendMessage;

  /// No description provided for @verifyOtp.
  ///
  /// In en, this message translates to:
  /// **'Verify OTP'**
  String get verifyOtp;

  /// No description provided for @continueTitle.
  ///
  /// In en, this message translates to:
  /// **'Continue'**
  String get continueTitle;

  /// No description provided for @notReceiveCode.
  ///
  /// In en, this message translates to:
  /// **'Didn\'t receive the code?'**
  String get notReceiveCode;

  /// No description provided for @resend.
  ///
  /// In en, this message translates to:
  /// **'Resend'**
  String get resend;

  /// No description provided for @remainingTime.
  ///
  /// In en, this message translates to:
  /// **'Remaining time:'**
  String get remainingTime;

  /// No description provided for @createPasswordTitle.
  ///
  /// In en, this message translates to:
  /// **'Create New Password'**
  String get createPasswordTitle;

  /// No description provided for @doneTitle.
  ///
  /// In en, this message translates to:
  /// **'Done!'**
  String get doneTitle;

  /// No description provided for @passwordResetMessage.
  ///
  /// In en, this message translates to:
  /// **'Your password has been reset successfully'**
  String get passwordResetMessage;

  /// No description provided for @loginTitle.
  ///
  /// In en, this message translates to:
  /// **'Login'**
  String get loginTitle;

  /// No description provided for @back.
  ///
  /// In en, this message translates to:
  /// **'Back'**
  String get back;

  /// No description provided for @userNotFound.
  ///
  /// In en, this message translates to:
  /// **'User not found'**
  String get userNotFound;

  /// No description provided for @invalidOtp.
  ///
  /// In en, this message translates to:
  /// **'Invalid OTP code'**
  String get invalidOtp;

  /// No description provided for @otpExpired.
  ///
  /// In en, this message translates to:
  /// **'OTP has expired'**
  String get otpExpired;

  /// No description provided for @resetFailed.
  ///
  /// In en, this message translates to:
  /// **'Password reset failed'**
  String get resetFailed;

  /// No description provided for @otpRequired.
  ///
  /// In en, this message translates to:
  /// **'Please enter the 6-digit code'**
  String get otpRequired;

  /// No description provided for @resetSuccess.
  ///
  /// In en, this message translates to:
  /// **'Password reset successful'**
  String get resetSuccess;

  /// No description provided for @otpVerified.
  ///
  /// In en, this message translates to:
  /// **'OTP verified successfully'**
  String get otpVerified;

  /// No description provided for @share.
  ///
  /// In en, this message translates to:
  /// **'Share'**
  String get share;

  /// No description provided for @printPreview.
  ///
  /// In en, this message translates to:
  /// **'Print Preview'**
  String get printPreview;

  /// No description provided for @saveTitle.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get saveTitle;

  /// No description provided for @filterReports.
  ///
  /// In en, this message translates to:
  /// **'Filter Reports'**
  String get filterReports;

  /// No description provided for @projects.
  ///
  /// In en, this message translates to:
  /// **'Projects'**
  String get projects;

  /// No description provided for @services.
  ///
  /// In en, this message translates to:
  /// **'Services'**
  String get services;

  /// No description provided for @applyFilter.
  ///
  /// In en, this message translates to:
  /// **'Apply Filter'**
  String get applyFilter;

  /// No description provided for @fromCurrency.
  ///
  /// In en, this message translates to:
  /// **'From Currency'**
  String get fromCurrency;

  /// No description provided for @toCurrencyTitle.
  ///
  /// In en, this message translates to:
  /// **'To Currency'**
  String get toCurrencyTitle;

  /// No description provided for @transactionReport.
  ///
  /// In en, this message translates to:
  /// **'Transactions Report'**
  String get transactionReport;

  /// No description provided for @newProject.
  ///
  /// In en, this message translates to:
  /// **'New Project'**
  String get newProject;

  /// No description provided for @projectName.
  ///
  /// In en, this message translates to:
  /// **'Project Name'**
  String get projectName;

  /// No description provided for @projectInformation.
  ///
  /// In en, this message translates to:
  /// **'Project Information'**
  String get projectInformation;

  /// No description provided for @deadline.
  ///
  /// In en, this message translates to:
  /// **'Deadline'**
  String get deadline;

  /// No description provided for @ownerInformation.
  ///
  /// In en, this message translates to:
  /// **'Client Information'**
  String get ownerInformation;

  /// No description provided for @ownerAccount.
  ///
  /// In en, this message translates to:
  /// **'Owner Account'**
  String get ownerAccount;

  /// No description provided for @incomeAndExpenses.
  ///
  /// In en, this message translates to:
  /// **'Payment & Expense'**
  String get incomeAndExpenses;

  /// No description provided for @inProgress.
  ///
  /// In en, this message translates to:
  /// **'In Progress'**
  String get inProgress;

  /// No description provided for @completed.
  ///
  /// In en, this message translates to:
  /// **'Completed'**
  String get completed;

  /// No description provided for @projectStatus.
  ///
  /// In en, this message translates to:
  /// **'Project Status'**
  String get projectStatus;

  /// No description provided for @addNewServices.
  ///
  /// In en, this message translates to:
  /// **'Add New Services'**
  String get addNewServices;

  /// No description provided for @projectServices.
  ///
  /// In en, this message translates to:
  /// **'Project Services'**
  String get projectServices;

  /// No description provided for @totalIncome.
  ///
  /// In en, this message translates to:
  /// **'Total Income'**
  String get totalIncome;

  /// No description provided for @projectBudget.
  ///
  /// In en, this message translates to:
  /// **'Project Budget'**
  String get projectBudget;

  /// No description provided for @totalExpense.
  ///
  /// In en, this message translates to:
  /// **'Total Expense'**
  String get totalExpense;

  /// No description provided for @totalProjects.
  ///
  /// In en, this message translates to:
  /// **'Total Project'**
  String get totalProjects;

  /// No description provided for @projectEntry.
  ///
  /// In en, this message translates to:
  /// **'Project Entry'**
  String get projectEntry;

  /// No description provided for @paymentNotMatch.
  ///
  /// In en, this message translates to:
  /// **'The payment amount does not match the project total.'**
  String get paymentNotMatch;

  /// No description provided for @totalProjectTitle.
  ///
  /// In en, this message translates to:
  /// **'Total Projects'**
  String get totalProjectTitle;

  /// No description provided for @projectDependency.
  ///
  /// In en, this message translates to:
  /// **'Project cannot be deleted. It has related services or payments.'**
  String get projectDependency;

  /// No description provided for @pAndLTitle.
  ///
  /// In en, this message translates to:
  /// **'P&L'**
  String get pAndLTitle;

  /// No description provided for @searchResultTitle.
  ///
  /// In en, this message translates to:
  /// **'Search result '**
  String get searchResultTitle;

  /// No description provided for @forTitle.
  ///
  /// In en, this message translates to:
  /// **'for'**
  String get forTitle;

  /// No description provided for @pricingInformation.
  ///
  /// In en, this message translates to:
  /// **'Pricing Information'**
  String get pricingInformation;

  /// No description provided for @averagePriceTitle.
  ///
  /// In en, this message translates to:
  /// **'Average Price'**
  String get averagePriceTitle;

  /// No description provided for @recentPriceTitle.
  ///
  /// In en, this message translates to:
  /// **'Recent Price'**
  String get recentPriceTitle;

  /// No description provided for @sellPrice.
  ///
  /// In en, this message translates to:
  /// **'Sell Price'**
  String get sellPrice;

  /// No description provided for @storageInfromation.
  ///
  /// In en, this message translates to:
  /// **'Storage Information'**
  String get storageInfromation;

  /// No description provided for @codeTitle.
  ///
  /// In en, this message translates to:
  /// **'Code'**
  String get codeTitle;

  /// No description provided for @availableTitle.
  ///
  /// In en, this message translates to:
  /// **'Available'**
  String get availableTitle;

  /// No description provided for @basicInformation.
  ///
  /// In en, this message translates to:
  /// **'Basic Information'**
  String get basicInformation;

  /// No description provided for @completeInformation.
  ///
  /// In en, this message translates to:
  /// **'Complete Information'**
  String get completeInformation;

  /// No description provided for @selectTitle.
  ///
  /// In en, this message translates to:
  /// **'Select'**
  String get selectTitle;

  /// No description provided for @closeTitle.
  ///
  /// In en, this message translates to:
  /// **'Close'**
  String get closeTitle;

  /// No description provided for @projectTxnDetails.
  ///
  /// In en, this message translates to:
  /// **'Project Transaction Details'**
  String get projectTxnDetails;

  /// No description provided for @projectId.
  ///
  /// In en, this message translates to:
  /// **'Project ID'**
  String get projectId;

  /// No description provided for @customerName.
  ///
  /// In en, this message translates to:
  /// **'Customer Name'**
  String get customerName;

  /// No description provided for @projectDetails.
  ///
  /// In en, this message translates to:
  /// **'Project Details'**
  String get projectDetails;

  /// No description provided for @projectTransaction.
  ///
  /// In en, this message translates to:
  /// **'Project Transaction'**
  String get projectTransaction;

  /// No description provided for @voucher.
  ///
  /// In en, this message translates to:
  /// **'Voucher'**
  String get voucher;

  /// No description provided for @amountInWords.
  ///
  /// In en, this message translates to:
  /// **'Amount in Words'**
  String get amountInWords;

  /// No description provided for @authorizedBy.
  ///
  /// In en, this message translates to:
  /// **'Authorized By'**
  String get authorizedBy;

  /// No description provided for @pending.
  ///
  /// In en, this message translates to:
  /// **'Pending'**
  String get pending;

  /// No description provided for @cancelled.
  ///
  /// In en, this message translates to:
  /// **'Cancelled'**
  String get cancelled;

  /// No description provided for @totalServicesValue.
  ///
  /// In en, this message translates to:
  /// **'Total Services Value'**
  String get totalServicesValue;

  /// No description provided for @beneficiary.
  ///
  /// In en, this message translates to:
  /// **'Beneficiary'**
  String get beneficiary;

  /// No description provided for @clientTitle.
  ///
  /// In en, this message translates to:
  /// **'Client'**
  String get clientTitle;

  /// No description provided for @totalServices.
  ///
  /// In en, this message translates to:
  /// **'Total Services'**
  String get totalServices;

  /// No description provided for @totalTransactions.
  ///
  /// In en, this message translates to:
  /// **'Total Transactions'**
  String get totalTransactions;

  /// No description provided for @currentPhase.
  ///
  /// In en, this message translates to:
  /// **'Ongoing Phase'**
  String get currentPhase;

  /// No description provided for @incomeAndExpense.
  ///
  /// In en, this message translates to:
  /// **'Payment & Expense'**
  String get incomeAndExpense;

  /// No description provided for @activeServices.
  ///
  /// In en, this message translates to:
  /// **'Active Services'**
  String get activeServices;

  /// No description provided for @serviceName.
  ///
  /// In en, this message translates to:
  /// **'Service Name'**
  String get serviceName;

  /// No description provided for @noServicesTitle.
  ///
  /// In en, this message translates to:
  /// **'No Services'**
  String get noServicesTitle;

  /// No description provided for @noServicesMessage.
  ///
  /// In en, this message translates to:
  /// **'No services found for this project'**
  String get noServicesMessage;

  /// No description provided for @noPandLMessage.
  ///
  /// In en, this message translates to:
  /// **'No P&L yet recorded'**
  String get noPandLMessage;

  /// No description provided for @allBalancesTitle.
  ///
  /// In en, this message translates to:
  /// **'All Balances'**
  String get allBalancesTitle;

  /// No description provided for @filterTitle.
  ///
  /// In en, this message translates to:
  /// **'Filter'**
  String get filterTitle;

  /// No description provided for @averageTitle.
  ///
  /// In en, this message translates to:
  /// **'Average Rate'**
  String get averageTitle;

  /// No description provided for @rolesAndPermissions.
  ///
  /// In en, this message translates to:
  /// **'Permissions'**
  String get rolesAndPermissions;

  /// No description provided for @profileSettings.
  ///
  /// In en, this message translates to:
  /// **'Profile Settings'**
  String get profileSettings;

  /// No description provided for @enableAll.
  ///
  /// In en, this message translates to:
  /// **'Enable all'**
  String get enableAll;

  /// No description provided for @grantAll.
  ///
  /// In en, this message translates to:
  /// **'Grant All'**
  String get grantAll;

  /// No description provided for @revokeAll.
  ///
  /// In en, this message translates to:
  /// **'Revoke All'**
  String get revokeAll;

  /// No description provided for @restoreDefault.
  ///
  /// In en, this message translates to:
  /// **'Restore Defaults'**
  String get restoreDefault;

  /// No description provided for @roleActions.
  ///
  /// In en, this message translates to:
  /// **'Role Actions'**
  String get roleActions;

  /// No description provided for @userRole.
  ///
  /// In en, this message translates to:
  /// **'User Roles'**
  String get userRole;

  /// No description provided for @roleName.
  ///
  /// In en, this message translates to:
  /// **'Role Name'**
  String get roleName;

  /// No description provided for @newRole.
  ///
  /// In en, this message translates to:
  /// **'New Role'**
  String get newRole;

  /// No description provided for @editRole.
  ///
  /// In en, this message translates to:
  /// **'Edit Role'**
  String get editRole;

  /// No description provided for @subscriptionTitle.
  ///
  /// In en, this message translates to:
  /// **'Subscription'**
  String get subscriptionTitle;

  /// No description provided for @manageSubMessage.
  ///
  /// In en, this message translates to:
  /// **'Manage your subscription details'**
  String get manageSubMessage;

  /// No description provided for @subscriptionExpired.
  ///
  /// In en, this message translates to:
  /// **'Subscription Expired'**
  String get subscriptionExpired;

  /// No description provided for @subscriptionExpiredContact.
  ///
  /// In en, this message translates to:
  /// **'Your subscription has expired. Please contact Zaitoon Technology to renew your subscription.'**
  String get subscriptionExpiredContact;

  /// No description provided for @noSubscriptionContact.
  ///
  /// In en, this message translates to:
  /// **'You don\'t have an active subscription. Please contact Zaitoon Technology to activate one.'**
  String get noSubscriptionContact;

  /// No description provided for @noSubscription.
  ///
  /// In en, this message translates to:
  /// **'No Subscription'**
  String get noSubscription;

  /// No description provided for @totalCashBalancesAllBranch.
  ///
  /// In en, this message translates to:
  /// **'Total Cash Balances - All Branches'**
  String get totalCashBalancesAllBranch;

  /// No description provided for @activeFilters.
  ///
  /// In en, this message translates to:
  /// **'Active Filters'**
  String get activeFilters;

  /// No description provided for @accountsReport.
  ///
  /// In en, this message translates to:
  /// **'Accounts Report'**
  String get accountsReport;

  /// No description provided for @editProfile.
  ///
  /// In en, this message translates to:
  /// **'Edit Profile'**
  String get editProfile;

  /// No description provided for @workInformation.
  ///
  /// In en, this message translates to:
  /// **'Work Information'**
  String get workInformation;

  /// No description provided for @memberSince.
  ///
  /// In en, this message translates to:
  /// **'Member since'**
  String get memberSince;

  /// No description provided for @securityTitle.
  ///
  /// In en, this message translates to:
  /// **'Security'**
  String get securityTitle;

  /// No description provided for @passwordChangeHint.
  ///
  /// In en, this message translates to:
  /// **'Update your password regularly'**
  String get passwordChangeHint;

  /// No description provided for @logoutHint.
  ///
  /// In en, this message translates to:
  /// **'Sign out from your account'**
  String get logoutHint;

  /// No description provided for @dailyTransactions.
  ///
  /// In en, this message translates to:
  /// **'Daily Transactions'**
  String get dailyTransactions;

  /// No description provided for @movement.
  ///
  /// In en, this message translates to:
  /// **'Movement'**
  String get movement;

  /// No description provided for @stockRecord.
  ///
  /// In en, this message translates to:
  /// **'Stock Records'**
  String get stockRecord;

  /// No description provided for @noProductSelectedTitle.
  ///
  /// In en, this message translates to:
  /// **'No Product Selected'**
  String get noProductSelectedTitle;

  /// No description provided for @noProductSelectedMsg.
  ///
  /// In en, this message translates to:
  /// **'Please select a product first to continue.'**
  String get noProductSelectedMsg;

  /// No description provided for @totalIn.
  ///
  /// In en, this message translates to:
  /// **'Total IN'**
  String get totalIn;

  /// No description provided for @totalOut.
  ///
  /// In en, this message translates to:
  /// **'Total OUT'**
  String get totalOut;

  /// No description provided for @allTime.
  ///
  /// In en, this message translates to:
  /// **'All Time'**
  String get allTime;

  /// No description provided for @thisYear.
  ///
  /// In en, this message translates to:
  /// **'This Year'**
  String get thisYear;

  /// No description provided for @tripCost.
  ///
  /// In en, this message translates to:
  /// **'Trip Costs'**
  String get tripCost;

  /// No description provided for @tripCostHint.
  ///
  /// In en, this message translates to:
  /// **'Costs during the journey (tolls, meals, parking)'**
  String get tripCostHint;

  /// No description provided for @personal.
  ///
  /// In en, this message translates to:
  /// **'Personal'**
  String get personal;

  /// No description provided for @employement.
  ///
  /// In en, this message translates to:
  /// **'Employement'**
  String get employement;

  /// No description provided for @phoneNumber.
  ///
  /// In en, this message translates to:
  /// **'Phone Number'**
  String get phoneNumber;

  /// No description provided for @noAccountFound.
  ///
  /// In en, this message translates to:
  /// **'No account found'**
  String get noAccountFound;

  /// No description provided for @positionTitle.
  ///
  /// In en, this message translates to:
  /// **'Position Title'**
  String get positionTitle;

  /// No description provided for @salaryCalculation.
  ///
  /// In en, this message translates to:
  /// **'Salary Calculation'**
  String get salaryCalculation;

  /// No description provided for @employementDetails.
  ///
  /// In en, this message translates to:
  /// **'Employement Details'**
  String get employementDetails;

  /// No description provided for @userSettings.
  ///
  /// In en, this message translates to:
  /// **'User Settings'**
  String get userSettings;

  /// No description provided for @shipmentHint.
  ///
  /// In en, this message translates to:
  /// **'Manage shipments, Drivers & Vehicles'**
  String get shipmentHint;

  /// No description provided for @paymentMethodMessage.
  ///
  /// In en, this message translates to:
  /// **'Please select a payment method to continue.'**
  String get paymentMethodMessage;

  /// No description provided for @entries.
  ///
  /// In en, this message translates to:
  /// **'Entries'**
  String get entries;

  /// No description provided for @thisMonth.
  ///
  /// In en, this message translates to:
  /// **'This Month'**
  String get thisMonth;

  /// No description provided for @lastThreeMonth.
  ///
  /// In en, this message translates to:
  /// **'Last 90 Days'**
  String get lastThreeMonth;

  /// No description provided for @invoiceProfit.
  ///
  /// In en, this message translates to:
  /// **'Profit Visibility'**
  String get invoiceProfit;

  /// No description provided for @invoiceProfitHint.
  ///
  /// In en, this message translates to:
  /// **'Show or hide profit on sale invoices'**
  String get invoiceProfitHint;

  /// No description provided for @counts.
  ///
  /// In en, this message translates to:
  /// **'Counts'**
  String get counts;

  /// No description provided for @exchangeRateGraph.
  ///
  /// In en, this message translates to:
  /// **'Exchange Rate Graph'**
  String get exchangeRateGraph;

  /// No description provided for @dailyTransactionsGraph.
  ///
  /// In en, this message translates to:
  /// **'Daily Transactions Graph'**
  String get dailyTransactionsGraph;

  /// No description provided for @dailyTransactionTotals.
  ///
  /// In en, this message translates to:
  /// **'Daily Transaction Totals'**
  String get dailyTransactionTotals;

  /// No description provided for @digitalClock.
  ///
  /// In en, this message translates to:
  /// **'Digital Clock'**
  String get digitalClock;

  /// No description provided for @exchangeRates.
  ///
  /// In en, this message translates to:
  /// **'Exchange Rates'**
  String get exchangeRates;

  /// No description provided for @profitLossGraph.
  ///
  /// In en, this message translates to:
  /// **'Profit Loss Graph'**
  String get profitLossGraph;

  /// No description provided for @reminderNotifications.
  ///
  /// In en, this message translates to:
  /// **'Reminder Notifications'**
  String get reminderNotifications;

  /// No description provided for @currencyTab.
  ///
  /// In en, this message translates to:
  /// **'Currency Tab'**
  String get currencyTab;

  /// No description provided for @currency.
  ///
  /// In en, this message translates to:
  /// **'Currency'**
  String get currency;

  /// No description provided for @payroll.
  ///
  /// In en, this message translates to:
  /// **'Payroll'**
  String get payroll;

  /// No description provided for @eoyOperation.
  ///
  /// In en, this message translates to:
  /// **'EOY Operation'**
  String get eoyOperation;

  /// No description provided for @pendingTransaction.
  ///
  /// In en, this message translates to:
  /// **'Pending Transaction'**
  String get pendingTransaction;

  /// No description provided for @cashDeposit.
  ///
  /// In en, this message translates to:
  /// **'Cash Deposit'**
  String get cashDeposit;

  /// No description provided for @cashWithdraw.
  ///
  /// In en, this message translates to:
  /// **'Cash Withdraw'**
  String get cashWithdraw;

  /// No description provided for @incomeEntry.
  ///
  /// In en, this message translates to:
  /// **'Income Entry'**
  String get incomeEntry;

  /// No description provided for @expenseEntry.
  ///
  /// In en, this message translates to:
  /// **'Expense Entry'**
  String get expenseEntry;

  /// No description provided for @glDebit.
  ///
  /// In en, this message translates to:
  /// **'GL Debit'**
  String get glDebit;

  /// No description provided for @glCredit.
  ///
  /// In en, this message translates to:
  /// **'GL Credit'**
  String get glCredit;

  /// No description provided for @ftSingleAccount.
  ///
  /// In en, this message translates to:
  /// **'FT Single Account'**
  String get ftSingleAccount;

  /// No description provided for @ftMultiAccount.
  ///
  /// In en, this message translates to:
  /// **'FT Multi Account'**
  String get ftMultiAccount;

  /// No description provided for @fxTransactions.
  ///
  /// In en, this message translates to:
  /// **'FX Transactions'**
  String get fxTransactions;

  /// No description provided for @allUsers.
  ///
  /// In en, this message translates to:
  /// **'All Users'**
  String get allUsers;

  /// No description provided for @ordersTab.
  ///
  /// In en, this message translates to:
  /// **'Orders Tab'**
  String get ordersTab;

  /// No description provided for @estimateTab.
  ///
  /// In en, this message translates to:
  /// **'Estimate Tab'**
  String get estimateTab;

  /// No description provided for @goodsShiftTab.
  ///
  /// In en, this message translates to:
  /// **'Goods Shift Tab'**
  String get goodsShiftTab;

  /// No description provided for @adjustmentTab.
  ///
  /// In en, this message translates to:
  /// **'Adjustment Tab'**
  String get adjustmentTab;

  /// No description provided for @purchase.
  ///
  /// In en, this message translates to:
  /// **'Purchase'**
  String get purchase;

  /// No description provided for @sale.
  ///
  /// In en, this message translates to:
  /// **'Sale'**
  String get sale;

  /// No description provided for @goodsShift.
  ///
  /// In en, this message translates to:
  /// **'Goods Shift'**
  String get goodsShift;

  /// No description provided for @generalTab.
  ///
  /// In en, this message translates to:
  /// **'General Tab'**
  String get generalTab;

  /// No description provided for @passwordChange.
  ///
  /// In en, this message translates to:
  /// **'Password Change'**
  String get passwordChange;

  /// No description provided for @userProfile.
  ///
  /// In en, this message translates to:
  /// **'User Profile'**
  String get userProfile;

  /// No description provided for @companyTab.
  ///
  /// In en, this message translates to:
  /// **'Company Tab'**
  String get companyTab;

  /// No description provided for @category.
  ///
  /// In en, this message translates to:
  /// **'Category'**
  String get category;

  /// No description provided for @backup.
  ///
  /// In en, this message translates to:
  /// **'Backup'**
  String get backup;

  /// No description provided for @accountStatementSingleDate.
  ///
  /// In en, this message translates to:
  /// **'Account Statement Single Date'**
  String get accountStatementSingleDate;

  /// No description provided for @glStatementPeriodicDate.
  ///
  /// In en, this message translates to:
  /// **'GL Statement Periodic Date'**
  String get glStatementPeriodicDate;

  /// No description provided for @purchaseInvoices.
  ///
  /// In en, this message translates to:
  /// **'Purchase Invoices'**
  String get purchaseInvoices;

  /// No description provided for @saleInvoices.
  ///
  /// In en, this message translates to:
  /// **'Sale Invoices'**
  String get saleInvoices;

  /// No description provided for @allInvoices.
  ///
  /// In en, this message translates to:
  /// **'All Invoices'**
  String get allInvoices;

  /// No description provided for @cashBalanceAllBranch.
  ///
  /// In en, this message translates to:
  /// **'Cash Balance All Branch'**
  String get cashBalanceAllBranch;

  /// No description provided for @cashBalanceSingleBranch.
  ///
  /// In en, this message translates to:
  /// **'Cash Balance Single Branch'**
  String get cashBalanceSingleBranch;

  /// No description provided for @transactionsReport.
  ///
  /// In en, this message translates to:
  /// **'Transactions Report'**
  String get transactionsReport;

  /// No description provided for @allBalances.
  ///
  /// In en, this message translates to:
  /// **'All Balances'**
  String get allBalances;

  /// No description provided for @userRoleAndPermission.
  ///
  /// In en, this message translates to:
  /// **'User Role and Permission'**
  String get userRoleAndPermission;

  /// No description provided for @shippings.
  ///
  /// In en, this message translates to:
  /// **'Shipping'**
  String get shippings;

  /// No description provided for @stakeholderAccount.
  ///
  /// In en, this message translates to:
  /// **'Stakeholder Account'**
  String get stakeholderAccount;

  /// No description provided for @currencies.
  ///
  /// In en, this message translates to:
  /// **'Currencies'**
  String get currencies;

  /// No description provided for @read.
  ///
  /// In en, this message translates to:
  /// **'Read'**
  String get read;

  /// No description provided for @productModel.
  ///
  /// In en, this message translates to:
  /// **'Models'**
  String get productModel;

  /// No description provided for @productBrands.
  ///
  /// In en, this message translates to:
  /// **'Brands'**
  String get productBrands;

  /// No description provided for @nameAndDescription.
  ///
  /// In en, this message translates to:
  /// **'Name & Description'**
  String get nameAndDescription;

  /// No description provided for @productImages.
  ///
  /// In en, this message translates to:
  /// **'Product Images'**
  String get productImages;

  /// No description provided for @productColor.
  ///
  /// In en, this message translates to:
  /// **'Product Color'**
  String get productColor;

  /// No description provided for @minimumStock.
  ///
  /// In en, this message translates to:
  /// **'Minimum Stock'**
  String get minimumStock;

  /// No description provided for @gradeTitle.
  ///
  /// In en, this message translates to:
  /// **'Grade'**
  String get gradeTitle;

  /// No description provided for @widthTitle.
  ///
  /// In en, this message translates to:
  /// **'Width'**
  String get widthTitle;

  /// No description provided for @lenghtTitle.
  ///
  /// In en, this message translates to:
  /// **'length'**
  String get lenghtTitle;

  /// No description provided for @breadth.
  ///
  /// In en, this message translates to:
  /// **'Breadth'**
  String get breadth;

  /// No description provided for @addImage.
  ///
  /// In en, this message translates to:
  /// **'Add Image'**
  String get addImage;

  /// No description provided for @removeLastImage.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to remove the last image?'**
  String get removeLastImage;

  /// No description provided for @noImages.
  ///
  /// In en, this message translates to:
  /// **'No images added'**
  String get noImages;

  /// No description provided for @tapToEdit.
  ///
  /// In en, this message translates to:
  /// **'Tap to edit'**
  String get tapToEdit;

  /// No description provided for @imageLoadError.
  ///
  /// In en, this message translates to:
  /// **'Failed to load image'**
  String get imageLoadError;

  /// No description provided for @imagesAdded.
  ///
  /// In en, this message translates to:
  /// **'images added'**
  String get imagesAdded;

  /// No description provided for @confirm.
  ///
  /// In en, this message translates to:
  /// **'Confirm'**
  String get confirm;

  /// No description provided for @discountTitle.
  ///
  /// In en, this message translates to:
  /// **'Discount'**
  String get discountTitle;

  /// No description provided for @pcs.
  ///
  /// In en, this message translates to:
  /// **'Pcs'**
  String get pcs;

  /// No description provided for @batchTitle.
  ///
  /// In en, this message translates to:
  /// **'Batch'**
  String get batchTitle;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['ar', 'en', 'fa'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'ar':
      return AppLocalizationsAr();
    case 'en':
      return AppLocalizationsEn();
    case 'fa':
      return AppLocalizationsFa();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}

import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_bn.dart';
import 'app_localizations_en.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
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

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
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
    Locale('bn'),
    Locale('en')
  ];

  /// App name
  ///
  /// In en, this message translates to:
  /// **'Smart IoT Interface'**
  String get app_name;

  /// Full product name
  ///
  /// In en, this message translates to:
  /// **'Smart Water Level Control BD'**
  String get product_name;

  /// Login button label
  ///
  /// In en, this message translates to:
  /// **'Login'**
  String get login;

  /// Register button label
  ///
  /// In en, this message translates to:
  /// **'Register'**
  String get register;

  /// Email field label
  ///
  /// In en, this message translates to:
  /// **'Email'**
  String get email;

  /// Password field label
  ///
  /// In en, this message translates to:
  /// **'Password'**
  String get password;

  /// Forgot password link
  ///
  /// In en, this message translates to:
  /// **'Forgot Password?'**
  String get forgot_password;

  /// Water level label
  ///
  /// In en, this message translates to:
  /// **'Water Level'**
  String get water_level;

  /// Pump status label
  ///
  /// In en, this message translates to:
  /// **'Pump Status'**
  String get pump_status;

  /// Pump on state
  ///
  /// In en, this message translates to:
  /// **'Pump ON'**
  String get pump_on;

  /// Pump off state
  ///
  /// In en, this message translates to:
  /// **'Pump OFF'**
  String get pump_off;

  /// Mode label
  ///
  /// In en, this message translates to:
  /// **'Mode'**
  String get mode;

  /// Auto mode
  ///
  /// In en, this message translates to:
  /// **'AUTO'**
  String get auto;

  /// Manual mode
  ///
  /// In en, this message translates to:
  /// **'MANUAL'**
  String get manual;

  /// On state
  ///
  /// In en, this message translates to:
  /// **'ON'**
  String get on;

  /// Off state
  ///
  /// In en, this message translates to:
  /// **'OFF'**
  String get off;

  /// Settings screen title
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settings;

  /// History screen title
  ///
  /// In en, this message translates to:
  /// **'History'**
  String get history;

  /// Logout button
  ///
  /// In en, this message translates to:
  /// **'Logout'**
  String get logout;

  /// Dark mode toggle
  ///
  /// In en, this message translates to:
  /// **'Dark Mode'**
  String get dark_mode;

  /// Language selector
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get language;

  /// About section
  ///
  /// In en, this message translates to:
  /// **'About'**
  String get about;

  /// App version label
  ///
  /// In en, this message translates to:
  /// **'Version'**
  String get version;

  /// Developer label
  ///
  /// In en, this message translates to:
  /// **'Developer'**
  String get developer;

  /// Contact label
  ///
  /// In en, this message translates to:
  /// **'Contact Us'**
  String get contact_us;

  /// YouTube subscribe button
  ///
  /// In en, this message translates to:
  /// **'Subscribe on YouTube'**
  String get subscribe;

  /// Facebook follow button
  ///
  /// In en, this message translates to:
  /// **'Follow on Facebook'**
  String get follow;

  /// Offline status banner
  ///
  /// In en, this message translates to:
  /// **'Device Offline'**
  String get offline;

  /// Last update label
  ///
  /// In en, this message translates to:
  /// **'Last Update'**
  String get last_update;

  /// Uptime label
  ///
  /// In en, this message translates to:
  /// **'Uptime'**
  String get uptime;

  /// WiFi signal label
  ///
  /// In en, this message translates to:
  /// **'Signal'**
  String get signal;

  /// BLE setup button
  ///
  /// In en, this message translates to:
  /// **'BLE Setup'**
  String get ble_setup;

  /// BLE scanning state
  ///
  /// In en, this message translates to:
  /// **'Scanning…'**
  String get scanning;

  /// Connecting state
  ///
  /// In en, this message translates to:
  /// **'Connecting…'**
  String get connecting;

  /// Success state
  ///
  /// In en, this message translates to:
  /// **'Success'**
  String get success;

  /// Failed state
  ///
  /// In en, this message translates to:
  /// **'Failed'**
  String get failed;

  /// Empty device list message
  ///
  /// In en, this message translates to:
  /// **'No devices found'**
  String get no_devices;

  /// Login subtitle
  ///
  /// In en, this message translates to:
  /// **'Sign in to your account'**
  String get sign_in_subtitle;

  /// Register subtitle
  ///
  /// In en, this message translates to:
  /// **'Join Smart IoT Interface'**
  String get join_subtitle;

  /// Display name field label
  ///
  /// In en, this message translates to:
  /// **'Display Name'**
  String get display_name;

  /// Display name hint
  ///
  /// In en, this message translates to:
  /// **'Your full name'**
  String get display_name_hint;

  /// Email address label
  ///
  /// In en, this message translates to:
  /// **'Email Address'**
  String get email_address;

  /// Email validation error
  ///
  /// In en, this message translates to:
  /// **'Email is required'**
  String get email_required;

  /// Remember me checkbox
  ///
  /// In en, this message translates to:
  /// **'Remember me'**
  String get remember_me;

  /// Sign In button
  ///
  /// In en, this message translates to:
  /// **'Sign In'**
  String get sign_in;

  /// Login screen: create account title
  ///
  /// In en, this message translates to:
  /// **'Create Account'**
  String get create_account;

  /// No account prompt
  ///
  /// In en, this message translates to:
  /// **'Don\'t have an account? '**
  String get no_account;

  /// Already have account prompt
  ///
  /// In en, this message translates to:
  /// **'Already have an account? '**
  String get already_account;

  /// Account creation success
  ///
  /// In en, this message translates to:
  /// **'Account created! Please verify your email.'**
  String get account_created;

  /// Forgot password email validation
  ///
  /// In en, this message translates to:
  /// **'Enter your email first, then tap Forgot Password.'**
  String get enter_email_first;

  /// Password reset success
  ///
  /// In en, this message translates to:
  /// **'Password reset email sent. Check your inbox.'**
  String get reset_email_sent;

  /// Password reset failure
  ///
  /// In en, this message translates to:
  /// **'Failed to send reset email.'**
  String get reset_email_failed;

  /// Sign out button
  ///
  /// In en, this message translates to:
  /// **'Sign Out'**
  String get sign_out;

  /// Sign out confirmation dialog body
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to sign out?'**
  String get sign_out_confirm;

  /// Cancel button
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancel;

  /// Confirm button
  ///
  /// In en, this message translates to:
  /// **'Confirm'**
  String get confirm;

  /// Retry button
  ///
  /// In en, this message translates to:
  /// **'Retry'**
  String get retry;

  /// Save button
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get save;

  /// Save name button
  ///
  /// In en, this message translates to:
  /// **'Save Name'**
  String get save_name;

  /// Name field hint
  ///
  /// In en, this message translates to:
  /// **'Enter your name'**
  String get enter_your_name;

  /// Name placeholder
  ///
  /// In en, this message translates to:
  /// **'Set your name'**
  String get set_your_name;

  /// Active status badge
  ///
  /// In en, this message translates to:
  /// **'Active'**
  String get active;

  /// Edit display name button
  ///
  /// In en, this message translates to:
  /// **'Edit Display Name'**
  String get edit_display_name;

  /// Profile edit menu row and sheet title
  ///
  /// In en, this message translates to:
  /// **'Edit Profile'**
  String get profile;

  /// Device management section header
  ///
  /// In en, this message translates to:
  /// **'DEVICE MANAGEMENT'**
  String get device_management;

  /// Appearance section header
  ///
  /// In en, this message translates to:
  /// **'APPEARANCE'**
  String get appearance;

  /// Support section header
  ///
  /// In en, this message translates to:
  /// **'SUPPORT & SOCIAL'**
  String get support_social;

  /// Pump schedules nav item
  ///
  /// In en, this message translates to:
  /// **'Pump Schedules'**
  String get pump_schedules;

  /// Pump schedules subtitle
  ///
  /// In en, this message translates to:
  /// **'Set automatic on/off times'**
  String get pump_schedules_sub;

  /// Device sharing nav item
  ///
  /// In en, this message translates to:
  /// **'Device Sharing'**
  String get device_sharing;

  /// Device sharing subtitle
  ///
  /// In en, this message translates to:
  /// **'Share access with others'**
  String get device_sharing_sub;

  /// YouTube subtitle
  ///
  /// In en, this message translates to:
  /// **'Subscribe to our channel'**
  String get youtube_sub;

  /// Facebook subtitle
  ///
  /// In en, this message translates to:
  /// **'Follow our page'**
  String get facebook_sub;

  /// Link open error
  ///
  /// In en, this message translates to:
  /// **'Could not open link.'**
  String get could_not_open_link;

  /// Logout dialog title
  ///
  /// In en, this message translates to:
  /// **'Logout'**
  String get logout_confirm_title;

  /// Logout confirmation message
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to logout?'**
  String get logout_confirm_msg;

  /// Display name update success
  ///
  /// In en, this message translates to:
  /// **'Display name updated!'**
  String get display_name_updated;

  /// Display name update failure
  ///
  /// In en, this message translates to:
  /// **'Failed to update name.'**
  String get display_name_failed;

  /// Made in Bangladesh footer
  ///
  /// In en, this message translates to:
  /// **'Made with Ὁ9 in Bangladesh 🇧🇩'**
  String get made_in_bd;

  /// App name info row label
  ///
  /// In en, this message translates to:
  /// **'App Name'**
  String get app_name_label;

  /// Company label
  ///
  /// In en, this message translates to:
  /// **'Company'**
  String get company;

  /// History screen header
  ///
  /// In en, this message translates to:
  /// **'History & Analytics'**
  String get history_analytics;

  /// History clear dialog title
  ///
  /// In en, this message translates to:
  /// **'Clear History?'**
  String get history_clear_title;

  /// History clear dialog message
  ///
  /// In en, this message translates to:
  /// **'All local history for this device will be cleared. Firebase critical events will not be deleted.'**
  String get history_clear_msg;

  /// History cleared success
  ///
  /// In en, this message translates to:
  /// **'Local history cleared.'**
  String get history_cleared;

  /// Delete button
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get delete;

  /// Refresh button
  ///
  /// In en, this message translates to:
  /// **'Refresh'**
  String get refresh;

  /// Clear history menu item
  ///
  /// In en, this message translates to:
  /// **'Clear History'**
  String get clear_history;

  /// Event search hint
  ///
  /// In en, this message translates to:
  /// **'Search events...'**
  String get search_events;

  /// Events chart title
  ///
  /// In en, this message translates to:
  /// **'Events — Last 30 Days'**
  String get events_last_30;

  /// Event type chart title
  ///
  /// In en, this message translates to:
  /// **'Events by Type'**
  String get event_by_type;

  /// Pump overview section title
  ///
  /// In en, this message translates to:
  /// **'Pump Overview'**
  String get pump_overview;

  /// Empty data placeholder
  ///
  /// In en, this message translates to:
  /// **'No data'**
  String get no_data;

  /// No events message
  ///
  /// In en, this message translates to:
  /// **'No events recorded yet'**
  String get no_events;

  /// Events hint text
  ///
  /// In en, this message translates to:
  /// **'Events will appear here when pump turns on/off'**
  String get events_hint;

  /// History loading text
  ///
  /// In en, this message translates to:
  /// **'Loading history...'**
  String get history_loading;

  /// Try again button
  ///
  /// In en, this message translates to:
  /// **'Try Again'**
  String get try_again;

  /// Firebase sync note
  ///
  /// In en, this message translates to:
  /// **'Critical events also sync to Firebase • Spark plan is free'**
  String get firebase_sync_note;

  /// Device setup title
  ///
  /// In en, this message translates to:
  /// **'Add New Device'**
  String get add_new_device;

  /// BLE provisioning subtitle
  ///
  /// In en, this message translates to:
  /// **'Bluetooth WiFi Provisioning'**
  String get ble_wifi_provisioning;

  /// BLE provisioning description
  ///
  /// In en, this message translates to:
  /// **'Configure ESP32 WiFi via Bluetooth\nThen auto-register on Firebase'**
  String get ble_provision_desc;

  /// BLE time estimate
  ///
  /// In en, this message translates to:
  /// **'Full process takes ~2 minutes'**
  String get ble_time_note;

  /// BLE ready message
  ///
  /// In en, this message translates to:
  /// **'All set! Start BLE Setup.'**
  String get ble_ready;

  /// Start BLE setup button
  ///
  /// In en, this message translates to:
  /// **'Start BLE Setup'**
  String get start_ble_setup;

  /// WiFi provisioning title
  ///
  /// In en, this message translates to:
  /// **'WiFi Provisioning'**
  String get wifi_provisioning_title;

  /// Unified provisioning label
  ///
  /// In en, this message translates to:
  /// **'Espressif Unified Provisioning'**
  String get unified_provisioning;

  /// Tap to scan instruction
  ///
  /// In en, this message translates to:
  /// **'Tap to connect & scan WiFi'**
  String get tap_to_scan;

  /// Refresh WiFi list button
  ///
  /// In en, this message translates to:
  /// **'Refresh WiFi list'**
  String get wifi_list_refresh;

  /// Provisioning success header
  ///
  /// In en, this message translates to:
  /// **'Provisioning complete!'**
  String get provisioning_done;

  /// Firebase registration button
  ///
  /// In en, this message translates to:
  /// **'Register on Firebase'**
  String get register_firebase;

  /// Back to dashboard button
  ///
  /// In en, this message translates to:
  /// **'Back to Dashboard'**
  String get back_to_dashboard;

  /// BLE scan in progress message
  ///
  /// In en, this message translates to:
  /// **'BLE scan in progress… (a few seconds)'**
  String get ble_scanning_msg;

  /// Reset button
  ///
  /// In en, this message translates to:
  /// **'Reset'**
  String get reset;

  /// Device registered snackbar
  ///
  /// In en, this message translates to:
  /// **'Device registered successfully!'**
  String get device_registered;

  /// Error prefix with message
  ///
  /// In en, this message translates to:
  /// **'Error: {msg}'**
  String error_colon(String msg);

  /// BLE step: scan
  ///
  /// In en, this message translates to:
  /// **'Scan'**
  String get ble_scan_step;

  /// Pump duration dialog title
  ///
  /// In en, this message translates to:
  /// **'Pump Duration'**
  String get pump_duration;

  /// Pump duration question
  ///
  /// In en, this message translates to:
  /// **'How long should the pump run?'**
  String get pump_duration_question;

  /// Schedule screen title
  ///
  /// In en, this message translates to:
  /// **'Pump Schedules'**
  String get pump_schedules_title;

  /// Add schedule button
  ///
  /// In en, this message translates to:
  /// **'Add Schedule'**
  String get add_schedule;

  /// Empty schedules message
  ///
  /// In en, this message translates to:
  /// **'No Schedules Yet'**
  String get no_schedules;

  /// Add first schedule button
  ///
  /// In en, this message translates to:
  /// **'Add First Schedule'**
  String get add_first_schedule;

  /// Schedule deleted success
  ///
  /// In en, this message translates to:
  /// **'Schedule deleted.'**
  String get schedule_deleted;

  /// Automation deleted success
  ///
  /// In en, this message translates to:
  /// **'Automation deleted.'**
  String get automation_deleted;

  /// Scene deleted success
  ///
  /// In en, this message translates to:
  /// **'Scene deleted.'**
  String get scene_deleted;

  /// Schedule delete failure
  ///
  /// In en, this message translates to:
  /// **'Failed to delete.'**
  String get schedule_delete_failed;

  /// Schedule saved success
  ///
  /// In en, this message translates to:
  /// **'Schedule saved.'**
  String get schedule_saved;

  /// Schedule save failure
  ///
  /// In en, this message translates to:
  /// **'Failed to save.'**
  String get schedule_save_failed;

  /// Sharing section title
  ///
  /// In en, this message translates to:
  /// **'Share with a user'**
  String get share_with_user;

  /// Share button
  ///
  /// In en, this message translates to:
  /// **'Share'**
  String get share;

  /// Revoke access button
  ///
  /// In en, this message translates to:
  /// **'Revoke'**
  String get revoke;

  /// Revoke access dialog title
  ///
  /// In en, this message translates to:
  /// **'Remove Access?'**
  String get revoke_access_title;

  /// Empty shared users message
  ///
  /// In en, this message translates to:
  /// **'Not shared with anyone'**
  String get not_shared;

  /// Self share error
  ///
  /// In en, this message translates to:
  /// **'Cannot share with yourself.'**
  String get cannot_share_self;

  /// Already shared error
  ///
  /// In en, this message translates to:
  /// **'Already shared with this user.'**
  String get already_shared;

  /// Access granted message
  ///
  /// In en, this message translates to:
  /// **'Access granted to {email}.'**
  String access_granted(String email);

  /// Share failure
  ///
  /// In en, this message translates to:
  /// **'Failed to share.'**
  String get share_failed;

  /// Access revoked success
  ///
  /// In en, this message translates to:
  /// **'Access revoked.'**
  String get access_revoked;

  /// Revoke failure
  ///
  /// In en, this message translates to:
  /// **'Failed to revoke.'**
  String get revoke_failed;

  /// Remove button
  ///
  /// In en, this message translates to:
  /// **'Remove'**
  String get remove;

  /// Email hint in sharing
  ///
  /// In en, this message translates to:
  /// **'user@example.com'**
  String get email_hint;

  /// English language option
  ///
  /// In en, this message translates to:
  /// **'English'**
  String get language_english;

  /// Bengali language option
  ///
  /// In en, this message translates to:
  /// **'বাংলা'**
  String get language_bengali;

  /// Firebase: user-not-found
  ///
  /// In en, this message translates to:
  /// **'No account found with this email.'**
  String get err_user_not_found;

  /// Firebase: wrong-password
  ///
  /// In en, this message translates to:
  /// **'Incorrect password. Please try again.'**
  String get err_wrong_password;

  /// Firebase: email-already-in-use
  ///
  /// In en, this message translates to:
  /// **'This email is already registered.'**
  String get err_email_in_use;

  /// Firebase: invalid-email
  ///
  /// In en, this message translates to:
  /// **'Please enter a valid email address.'**
  String get err_invalid_email;

  /// Firebase: weak-password
  ///
  /// In en, this message translates to:
  /// **'Password must be at least 6 characters.'**
  String get err_weak_password;

  /// Firebase: too-many-requests
  ///
  /// In en, this message translates to:
  /// **'Too many attempts. Please try again later.'**
  String get err_too_many_requests;

  /// Firebase: user-disabled
  ///
  /// In en, this message translates to:
  /// **'This account has been disabled.'**
  String get err_user_disabled;

  /// Firebase: network-request-failed
  ///
  /// In en, this message translates to:
  /// **'Network error. Please check your connection.'**
  String get err_network;

  /// Firebase: invalid-credential
  ///
  /// In en, this message translates to:
  /// **'Invalid email or password.'**
  String get err_invalid_credential;

  /// Firebase: operation-not-allowed
  ///
  /// In en, this message translates to:
  /// **'This operation is not allowed.'**
  String get err_operation_not_allowed;

  /// Firestore: permission-denied
  ///
  /// In en, this message translates to:
  /// **'You don\'t have permission for this action.'**
  String get err_permission_denied;

  /// Firestore: not-found
  ///
  /// In en, this message translates to:
  /// **'The requested data was not found.'**
  String get err_not_found;

  /// Generic fallback error
  ///
  /// In en, this message translates to:
  /// **'Something went wrong. Please try again.'**
  String get err_generic;

  /// BLE devices found header
  ///
  /// In en, this message translates to:
  /// **'Found ESP32 Devices ({count})'**
  String ble_found_devices(int count);

  /// WiFi credentials section title
  ///
  /// In en, this message translates to:
  /// **'Enter WiFi Details:'**
  String get ble_wifi_enter;

  /// SSID field hint
  ///
  /// In en, this message translates to:
  /// **'WiFi Name (SSID)'**
  String get ble_wifi_ssid_hint;

  /// WiFi password hint
  ///
  /// In en, this message translates to:
  /// **'Password'**
  String get ble_wifi_pass_hint;

  /// BLE sending state button label
  ///
  /// In en, this message translates to:
  /// **'Connecting…'**
  String get ble_connect_sending;

  /// WiFi connect button
  ///
  /// In en, this message translates to:
  /// **'Connect to WiFi'**
  String get ble_connect_wifi;

  /// BLE retry button
  ///
  /// In en, this message translates to:
  /// **'Try Again'**
  String get ble_retry;

  /// BLE start scan button
  ///
  /// In en, this message translates to:
  /// **'Start BLE Scan'**
  String get ble_start_scan;

  /// BLE provisioning note
  ///
  /// In en, this message translates to:
  /// **'Only works on new or factory-reset ESP32 devices. Will not work on devices already connected to WiFi. Arduino IDE → Tools → Partition Scheme → \"No OTA (2MB APP)\".'**
  String get ble_note_existing;

  /// BLE step: scanning title
  ///
  /// In en, this message translates to:
  /// **'BLE Scan in progress…'**
  String get ble_step_scanning;

  /// BLE step: scan done title
  ///
  /// In en, this message translates to:
  /// **'Device found'**
  String get ble_step_scan_done;

  /// BLE step: connecting title
  ///
  /// In en, this message translates to:
  /// **'Connecting…'**
  String get ble_step_connecting;

  /// BLE step: wifi ready title
  ///
  /// In en, this message translates to:
  /// **'Select WiFi'**
  String get ble_step_wifi_ready;

  /// BLE step: sending title
  ///
  /// In en, this message translates to:
  /// **'Sending credentials…'**
  String get ble_step_sending;

  /// BLE step: success title
  ///
  /// In en, this message translates to:
  /// **'Provisioning successful! ✅'**
  String get ble_step_success;

  /// BLE step: failed title
  ///
  /// In en, this message translates to:
  /// **'Failed'**
  String get ble_step_failed;

  /// BLE step: default title
  ///
  /// In en, this message translates to:
  /// **'Espressif WiFi Provisioning'**
  String get ble_step_default;

  /// BLE scan start message
  ///
  /// In en, this message translates to:
  /// **'Searching for \"{prefix}\" devices…'**
  String ble_svc_scanning_for(String prefix);

  /// BLE no device found error
  ///
  /// In en, this message translates to:
  /// **'No SmartIoT device found.\n\nPlease make sure:\n• ESP32 is powered ON\n• First-time or factory reset\n• Bluetooth is ON\n• You are within range (≤5m)'**
  String get ble_svc_no_device;

  /// BLE devices found count
  ///
  /// In en, this message translates to:
  /// **'{count} device(s) found. Select one.'**
  String ble_svc_found_count(int count);

  /// BLE scan failure
  ///
  /// In en, this message translates to:
  /// **'BLE scan failed: {error}\n\nSolution:\n• Grant Bluetooth permission\n• Grant Location permission (Android ≤11)\n• Settings → Apps → SmartIoT → Permissions'**
  String ble_svc_scan_failed(String error);

  /// BLE connecting message
  ///
  /// In en, this message translates to:
  /// **'Connecting to {device}…\nScanning WiFi networks…'**
  String ble_svc_connecting_to(String device);

  /// BLE no WiFi found
  ///
  /// In en, this message translates to:
  /// **'No WiFi found. Enter SSID manually.'**
  String get ble_svc_no_wifi;

  /// BLE WiFi count
  ///
  /// In en, this message translates to:
  /// **'{count} WiFi network(s) found. Select one.'**
  String ble_svc_wifi_count(int count);

  /// BLE WiFi scan failure
  ///
  /// In en, this message translates to:
  /// **'Connection/WiFi scan failed: {error}\n\nSolution:\n• Check if Proof-of-Possession matches firmware secrets.h PROV_POP\n• Check if ESP32 is still in provisioning mode\n• Re-scan and try again'**
  String ble_svc_wifi_scan_failed(String error);

  /// BLE SSID empty error
  ///
  /// In en, this message translates to:
  /// **'WiFi name (SSID) cannot be empty.'**
  String get ble_svc_ssid_empty;

  /// BLE no device selected
  ///
  /// In en, this message translates to:
  /// **'No device selected. Please scan again.'**
  String get ble_svc_no_device_selected;

  /// BLE sending credentials
  ///
  /// In en, this message translates to:
  /// **'Sending credentials to \"{ssid}\"…\nESP32 connecting to WiFi…'**
  String ble_svc_sending(String ssid);

  /// BLE provisioning success
  ///
  /// In en, this message translates to:
  /// **'✅ WiFi Provisioning successful!\n\nESP32 is connecting to \"{ssid}\".\nDashboard will show ONLINE within ~15 seconds.\n\nRegister the device on Firebase.'**
  String ble_svc_success(String ssid);

  /// BLE provisioning failure
  ///
  /// In en, this message translates to:
  /// **'Provisioning failed: {error}\n\nSolution:\n• Check SSID/password is correct\n• Use 2.4GHz WiFi (ESP32 doesn\'t support 5GHz)\n• Check ESP32 is within WiFi range'**
  String ble_svc_prov_failed(String error);

  /// BLE generic error
  ///
  /// In en, this message translates to:
  /// **'An error occurred'**
  String get ble_svc_error_occurred;

  /// BLE register device prompt
  ///
  /// In en, this message translates to:
  /// **'Register the device on Firebase.'**
  String get ble_svc_register_device;

  /// Device setup flow section label
  ///
  /// In en, this message translates to:
  /// **'How It Works'**
  String get ds_how_it_works;

  /// Device setup checklist section label
  ///
  /// In en, this message translates to:
  /// **'Before You Start'**
  String get ds_before_start;

  /// Device setup account note
  ///
  /// In en, this message translates to:
  /// **'Device will only be registered to your Firebase account'**
  String get ds_note_account;

  /// Device setup auto-register note
  ///
  /// In en, this message translates to:
  /// **'Auto-register after BLE — no extra steps needed'**
  String get ds_note_auto;

  /// Checklist: bluetooth
  ///
  /// In en, this message translates to:
  /// **'Bluetooth is ON'**
  String get ds_check_bt;

  /// Checklist: bluetooth sublabel
  ///
  /// In en, this message translates to:
  /// **'Phone Settings → Bluetooth → ON'**
  String get ds_check_bt_sub;

  /// Checklist: power
  ///
  /// In en, this message translates to:
  /// **'SmartIoT Device powered ON'**
  String get ds_check_power;

  /// Checklist: power sublabel
  ///
  /// In en, this message translates to:
  /// **'LED blinking fast = Setup mode active'**
  String get ds_check_power_sub;

  /// Checklist: no wifi
  ///
  /// In en, this message translates to:
  /// **'ESP32 not connected to any WiFi'**
  String get ds_check_nowifi;

  /// Checklist: no wifi sublabel
  ///
  /// In en, this message translates to:
  /// **'First-time setup: no credentials stored'**
  String get ds_check_nowifi_sub;

  /// Checklist: location
  ///
  /// In en, this message translates to:
  /// **'Location Permission granted'**
  String get ds_check_location;

  /// Checklist: location sublabel
  ///
  /// In en, this message translates to:
  /// **'Required for Android BLE scan'**
  String get ds_check_location_sub;

  /// Flow step: BLE scan title
  ///
  /// In en, this message translates to:
  /// **'BLE Scan'**
  String get ds_flow_ble_scan;

  /// Flow step: BLE scan desc
  ///
  /// In en, this message translates to:
  /// **'App finds nearby SmartIoT devices'**
  String get ds_flow_ble_scan_desc;

  /// Flow step: WiFi scan title
  ///
  /// In en, this message translates to:
  /// **'WiFi Scan'**
  String get ds_flow_wifi_scan;

  /// Flow step: WiFi scan desc
  ///
  /// In en, this message translates to:
  /// **'ESP32 scans all nearby WiFi networks'**
  String get ds_flow_wifi_scan_desc;

  /// Flow step: credentials title
  ///
  /// In en, this message translates to:
  /// **'Credentials'**
  String get ds_flow_credentials;

  /// Flow step: credentials desc
  ///
  /// In en, this message translates to:
  /// **'Your WiFi password is sent via encrypted BLE'**
  String get ds_flow_credentials_desc;

  /// Flow step: auto-register title
  ///
  /// In en, this message translates to:
  /// **'Auto-Register'**
  String get ds_flow_register;

  /// Flow step: auto-register desc
  ///
  /// In en, this message translates to:
  /// **'Device auto-registers on Firebase after WiFi ✅'**
  String get ds_flow_register_desc;

  /// History: no device selected error
  ///
  /// In en, this message translates to:
  /// **'No device selected.'**
  String get hist_no_device;

  /// History: scroll for more
  ///
  /// In en, this message translates to:
  /// **'Scroll for more…'**
  String get hist_scroll_more;

  /// History: all events loaded
  ///
  /// In en, this message translates to:
  /// **'All events loaded'**
  String get hist_all_seen;

  /// History stat: total
  ///
  /// In en, this message translates to:
  /// **'Total'**
  String get hist_stat_total;

  /// History stat: pump on
  ///
  /// In en, this message translates to:
  /// **'Pump ON'**
  String get hist_stat_pump_on;

  /// History stat: alert
  ///
  /// In en, this message translates to:
  /// **'Alert'**
  String get hist_stat_alert;

  /// History stat: low level
  ///
  /// In en, this message translates to:
  /// **'Low Level'**
  String get hist_stat_low;

  /// History filter: all
  ///
  /// In en, this message translates to:
  /// **'All'**
  String get hist_filter_all;

  /// History time: just now
  ///
  /// In en, this message translates to:
  /// **'Just now'**
  String get hist_just_now;

  /// History time: minutes ago
  ///
  /// In en, this message translates to:
  /// **'{m} min ago'**
  String hist_minutes_ago(int m);

  /// History time: hours ago
  ///
  /// In en, this message translates to:
  /// **'{h} hr ago'**
  String hist_hours_ago(int h);

  /// History time: days ago
  ///
  /// In en, this message translates to:
  /// **'{d} days ago'**
  String hist_days_ago(int d);

  /// History: saved locally tooltip
  ///
  /// In en, this message translates to:
  /// **'Saved on phone'**
  String get hist_saved_phone;

  /// Grid: total events
  ///
  /// In en, this message translates to:
  /// **'Total Events'**
  String get hist_grid_total;

  /// Grid: pump on
  ///
  /// In en, this message translates to:
  /// **'Pump ON'**
  String get hist_grid_pump_on;

  /// Grid: pump off
  ///
  /// In en, this message translates to:
  /// **'Pump OFF'**
  String get hist_grid_pump_off;

  /// Grid: low level
  ///
  /// In en, this message translates to:
  /// **'Low Level'**
  String get hist_grid_low;

  /// Grid: dry run
  ///
  /// In en, this message translates to:
  /// **'Dry Run'**
  String get hist_grid_dry;

  /// Grid: alarm
  ///
  /// In en, this message translates to:
  /// **'Alarm'**
  String get hist_grid_alarm;

  /// Sharing: user not found error
  ///
  /// In en, this message translates to:
  /// **'No account found with this email. Ask them to log in to the app first.'**
  String get share_user_not_found;

  /// Bottom nav: dashboard
  ///
  /// In en, this message translates to:
  /// **'Dashboard'**
  String get nav_dashboard;

  /// Bottom nav: history
  ///
  /// In en, this message translates to:
  /// **'History'**
  String get nav_history;

  /// Bottom nav: settings
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get nav_settings;

  /// History tab: events
  ///
  /// In en, this message translates to:
  /// **'Events'**
  String get tab_events;

  /// History tab: analytics
  ///
  /// In en, this message translates to:
  /// **'Analytics'**
  String get tab_analytics;

  /// History subtitle
  ///
  /// In en, this message translates to:
  /// **'{count} events • saved on phone'**
  String hist_events_saved(int count);

  /// History event count
  ///
  /// In en, this message translates to:
  /// **'{count} events saved on phone'**
  String hist_events_count(int count);

  /// History load error
  ///
  /// In en, this message translates to:
  /// **'Failed to load history: {error}'**
  String hist_load_failed(String error);

  /// Support: email
  ///
  /// In en, this message translates to:
  /// **'Email Support'**
  String get email_support;

  /// Support: call
  ///
  /// In en, this message translates to:
  /// **'Call Support'**
  String get call_support;

  /// Splash: initializing text
  ///
  /// In en, this message translates to:
  /// **'Initializing…'**
  String get initializing;

  /// Splash: made with love
  ///
  /// In en, this message translates to:
  /// **'Made with 💙 in Bangladesh 🇧🇩'**
  String get made_with_love;

  /// BLE provisioning done detail text
  ///
  /// In en, this message translates to:
  /// **'ESP32 has saved WiFi credentials.\nOpen Dashboard and register when device is ONLINE.'**
  String get ble_prov_done_detail;

  /// Device setup section header
  ///
  /// In en, this message translates to:
  /// **'How It Works'**
  String get ds_how_it_works_section;

  /// Dashboard loading state
  ///
  /// In en, this message translates to:
  /// **'Loading devices…'**
  String get loading_devices;

  /// Schedule tile summary
  ///
  /// In en, this message translates to:
  /// **'Pump ON for {duration} min  •  {status}'**
  String schedule_summary(int duration, String status);

  /// Schedule: enabled
  ///
  /// In en, this message translates to:
  /// **'Enabled'**
  String get schedule_enabled;

  /// Schedule: disabled
  ///
  /// In en, this message translates to:
  /// **'Disabled'**
  String get schedule_disabled;

  /// Revoke access confirm
  ///
  /// In en, this message translates to:
  /// **'Revoke access for {user}?'**
  String revoke_confirm_user(String user);

  /// BLE advertise note
  ///
  /// In en, this message translates to:
  /// **'ESP32 advertises as \"PROV_SmartIoT_XXXXXX\".\nThis is the BLE device name — select it from the list.'**
  String get ble_advertise_note;

  /// WiFi networks section title
  ///
  /// In en, this message translates to:
  /// **'WiFi Networks ({count})'**
  String wifi_networks_found(int count);

  /// Language button: Bengali short label
  ///
  /// In en, this message translates to:
  /// **'বাং'**
  String get lang_btn_bengali;

  /// Control panel: water pump label
  ///
  /// In en, this message translates to:
  /// **'Water Pump'**
  String get ctrl_water_pump;

  /// Control: device offline reason
  ///
  /// In en, this message translates to:
  /// **'Device is offline'**
  String get ctrl_device_offline;

  /// Control: manual mode required
  ///
  /// In en, this message translates to:
  /// **'Switch to Manual mode to control pump'**
  String get ctrl_manual_required;

  /// Control: mode label
  ///
  /// In en, this message translates to:
  /// **'Control Mode'**
  String get ctrl_mode_label;

  /// Control: auto mode sublabel
  ///
  /// In en, this message translates to:
  /// **'Automatic (ESP32-managed)'**
  String get ctrl_mode_auto_sub;

  /// Control: manual sublabel
  ///
  /// In en, this message translates to:
  /// **'Manual override'**
  String get ctrl_mode_manual_sub;

  /// Control: sending command
  ///
  /// In en, this message translates to:
  /// **'Sending command…'**
  String get ctrl_sending;

  /// Dashboard section: device info
  ///
  /// In en, this message translates to:
  /// **'DEVICE INFO'**
  String get dash_device_info;

  /// Dashboard section: pump stats
  ///
  /// In en, this message translates to:
  /// **'PUMP STATISTICS'**
  String get dash_pump_stats;

  /// Dashboard: device online label
  ///
  /// In en, this message translates to:
  /// **'Device Online'**
  String get dash_device_online;

  /// Dashboard: device offline label
  ///
  /// In en, this message translates to:
  /// **'Device Offline'**
  String get dash_device_offline;

  /// Dashboard: dry run badge
  ///
  /// In en, this message translates to:
  /// **'DRY RUN'**
  String get dash_dry_run;

  /// Dashboard: alarm badge
  ///
  /// In en, this message translates to:
  /// **'ALARM'**
  String get dash_alarm;

  /// Dashboard info: last update
  ///
  /// In en, this message translates to:
  /// **'LAST UPDATE'**
  String get dash_last_update;

  /// Dashboard info: sensor mode
  ///
  /// In en, this message translates to:
  /// **'SENSOR MODE'**
  String get dash_sensor_mode;

  /// Dashboard info: uptime
  ///
  /// In en, this message translates to:
  /// **'UPTIME'**
  String get dash_uptime_label;

  /// Dashboard info: cycles
  ///
  /// In en, this message translates to:
  /// **'CYCLES'**
  String get dash_cycles;

  /// Dashboard info: total run
  ///
  /// In en, this message translates to:
  /// **'TOTAL RUN'**
  String get dash_total_run;

  /// Dashboard info: signal
  ///
  /// In en, this message translates to:
  /// **'SIGNAL'**
  String get dash_signal_label;

  /// Dashboard alert: dry run
  ///
  /// In en, this message translates to:
  /// **'Dry Run Protection'**
  String get dash_dry_run_alert;

  /// Dashboard alert: critical
  ///
  /// In en, this message translates to:
  /// **'Critical Alert'**
  String get dash_critical_alert;

  /// Dashboard: no device empty state
  ///
  /// In en, this message translates to:
  /// **'No Device Found'**
  String get dash_no_device;

  /// Dashboard: add device button
  ///
  /// In en, this message translates to:
  /// **'Add Device'**
  String get dash_add_device;

  /// Dashboard: theme toggle tooltip
  ///
  /// In en, this message translates to:
  /// **'Toggle theme'**
  String get dash_toggle_theme;

  /// Dashboard: add device tooltip
  ///
  /// In en, this message translates to:
  /// **'Add device'**
  String get dash_add_device_tooltip;

  /// Water level: full
  ///
  /// In en, this message translates to:
  /// **'Full'**
  String get level_full;

  /// Water level: medium
  ///
  /// In en, this message translates to:
  /// **'Medium'**
  String get level_mid;

  /// Water level: low
  ///
  /// In en, this message translates to:
  /// **'Low'**
  String get level_low;

  /// Water level: empty
  ///
  /// In en, this message translates to:
  /// **'Empty'**
  String get level_empty;

  /// Water level: unknown
  ///
  /// In en, this message translates to:
  /// **'Unknown'**
  String get level_unknown;

  /// Auth: no account
  ///
  /// In en, this message translates to:
  /// **'No account found with this email.'**
  String get auth_err_no_account;

  /// Auth: wrong password
  ///
  /// In en, this message translates to:
  /// **'Incorrect email or password.'**
  String get auth_err_wrong_password;

  /// Auth: invalid email
  ///
  /// In en, this message translates to:
  /// **'Please enter a valid email address.'**
  String get auth_err_invalid_email;

  /// Auth: account disabled
  ///
  /// In en, this message translates to:
  /// **'This account has been disabled. Contact support.'**
  String get auth_err_disabled;

  /// Auth: email in use
  ///
  /// In en, this message translates to:
  /// **'An account already exists with this email. Please login.'**
  String get auth_err_email_in_use;

  /// Auth: weak password
  ///
  /// In en, this message translates to:
  /// **'Password is too weak. Use at least 8 characters with numbers.'**
  String get auth_err_weak_password;

  /// Auth: not allowed
  ///
  /// In en, this message translates to:
  /// **'Email/Password sign-in is not enabled.'**
  String get auth_err_not_allowed;

  /// Auth: network error
  ///
  /// In en, this message translates to:
  /// **'No internet connection. Please check your network.'**
  String get auth_err_network;

  /// Auth: too many requests
  ///
  /// In en, this message translates to:
  /// **'Too many attempts. Please wait a moment and try again.'**
  String get auth_err_too_many;

  /// Auth: generic error
  ///
  /// In en, this message translates to:
  /// **'Authentication error. Please try again.'**
  String get auth_err_generic;

  /// Auth: unexpected
  ///
  /// In en, this message translates to:
  /// **'Unexpected error. Please try again.'**
  String get auth_err_unexpected;

  /// Password: min 8 chars
  ///
  /// In en, this message translates to:
  /// **'Minimum 8 characters required'**
  String get pwd_min_8;

  /// Password: needs number
  ///
  /// In en, this message translates to:
  /// **'Must contain a number'**
  String get pwd_need_number;

  /// Notification: dry run title
  ///
  /// In en, this message translates to:
  /// **'⚠️ Dry Run Alert!'**
  String get notif_dry_run_title;

  /// Notification: dry run body
  ///
  /// In en, this message translates to:
  /// **'{name}: Pump running without water! Level: {pct}%'**
  String notif_dry_run_body(String name, int pct);

  /// Notification: alarm title
  ///
  /// In en, this message translates to:
  /// **'🚨 Alarm Active'**
  String get notif_alarm_title;

  /// Notification: alarm body
  ///
  /// In en, this message translates to:
  /// **'{name}: Alert active! Water level: {level} ({pct}%)'**
  String notif_alarm_body(String name, String level, int pct);

  /// Notification: pump on title
  ///
  /// In en, this message translates to:
  /// **'💧 Pump Started'**
  String get notif_pump_on_title;

  /// Notification: pump on body
  ///
  /// In en, this message translates to:
  /// **'{name}: Pump running. Water level: {pct}%'**
  String notif_pump_on_body(String name, int pct);

  /// Notification: pump off title
  ///
  /// In en, this message translates to:
  /// **'✅ Pump Stopped'**
  String get notif_pump_off_title;

  /// Notification: pump off body
  ///
  /// In en, this message translates to:
  /// **'{name}: Pump stopped. Water level: {pct}%'**
  String notif_pump_off_body(String name, int pct);

  /// Notification: low water title
  ///
  /// In en, this message translates to:
  /// **'🪣 Water Low!'**
  String get notif_low_title;

  /// Notification: low water body
  ///
  /// In en, this message translates to:
  /// **'{name}: Water level dangerously low ({pct}%)'**
  String notif_low_body(String name, int pct);

  /// Notification: tank full title
  ///
  /// In en, this message translates to:
  /// **'🎉 Tank Full!'**
  String get notif_full_title;

  /// Notification: tank full body
  ///
  /// In en, this message translates to:
  /// **'{name}: Tank is full ({pct}%)'**
  String notif_full_body(String name, int pct);

  /// Device service: reconnecting message
  ///
  /// In en, this message translates to:
  /// **'Connection interrupted. Reconnecting…'**
  String get svc_reconnecting;

  /// Login footer: secure text
  ///
  /// In en, this message translates to:
  /// **'Secure & Encrypted'**
  String get brand_secure;

  /// No description provided for @calib_title.
  ///
  /// In en, this message translates to:
  /// **'Sensor Calibration'**
  String get calib_title;

  /// No description provided for @calib_info.
  ///
  /// In en, this message translates to:
  /// **'Enter your tank dimensions so the app can calculate exact water volume in liters.'**
  String get calib_info;

  /// No description provided for @calib_tank_dimensions.
  ///
  /// In en, this message translates to:
  /// **'TANK DIMENSIONS'**
  String get calib_tank_dimensions;

  /// No description provided for @calib_sensor_distances.
  ///
  /// In en, this message translates to:
  /// **'SENSOR DISTANCES'**
  String get calib_sensor_distances;

  /// No description provided for @calib_sensor_hint.
  ///
  /// In en, this message translates to:
  /// **'Measure from sensor (mounted at top) to water surface when tank is empty or full.'**
  String get calib_sensor_hint;

  /// No description provided for @calib_tank_height.
  ///
  /// In en, this message translates to:
  /// **'Tank Height'**
  String get calib_tank_height;

  /// No description provided for @calib_capacity.
  ///
  /// In en, this message translates to:
  /// **'Tank Capacity'**
  String get calib_capacity;

  /// No description provided for @calib_empty_distance.
  ///
  /// In en, this message translates to:
  /// **'Distance when Empty'**
  String get calib_empty_distance;

  /// No description provided for @calib_full_distance.
  ///
  /// In en, this message translates to:
  /// **'Distance when Full'**
  String get calib_full_distance;

  /// No description provided for @calib_err_positive.
  ///
  /// In en, this message translates to:
  /// **'Must be a positive number'**
  String get calib_err_positive;

  /// No description provided for @calib_err_nonneg.
  ///
  /// In en, this message translates to:
  /// **'Must be 0 or more'**
  String get calib_err_nonneg;

  /// No description provided for @calib_err_exceeds_height.
  ///
  /// In en, this message translates to:
  /// **'Cannot exceed tank height'**
  String get calib_err_exceeds_height;

  /// No description provided for @calib_err_full_less_empty.
  ///
  /// In en, this message translates to:
  /// **'Must be less than empty distance'**
  String get calib_err_full_less_empty;

  /// No description provided for @calib_current_water.
  ///
  /// In en, this message translates to:
  /// **'Current water'**
  String get calib_current_water;

  /// No description provided for @calib_saved.
  ///
  /// In en, this message translates to:
  /// **'Calibration saved.'**
  String get calib_saved;

  /// No description provided for @calib_save_failed.
  ///
  /// In en, this message translates to:
  /// **'Failed to save calibration.'**
  String get calib_save_failed;

  /// No description provided for @calib_save.
  ///
  /// In en, this message translates to:
  /// **'Save Calibration'**
  String get calib_save;

  /// No description provided for @thresh_title.
  ///
  /// In en, this message translates to:
  /// **'Alarm Thresholds'**
  String get thresh_title;

  /// No description provided for @thresh_current_level.
  ///
  /// In en, this message translates to:
  /// **'Current level'**
  String get thresh_current_level;

  /// No description provided for @thresh_pump_control.
  ///
  /// In en, this message translates to:
  /// **'PUMP CONTROL'**
  String get thresh_pump_control;

  /// No description provided for @thresh_alerts.
  ///
  /// In en, this message translates to:
  /// **'ALERT TRIGGERS'**
  String get thresh_alerts;

  /// No description provided for @thresh_pump_start.
  ///
  /// In en, this message translates to:
  /// **'Pump Start Level'**
  String get thresh_pump_start;

  /// No description provided for @thresh_pump_start_sub.
  ///
  /// In en, this message translates to:
  /// **'Pump turns ON when water drops below this'**
  String get thresh_pump_start_sub;

  /// No description provided for @thresh_pump_stop.
  ///
  /// In en, this message translates to:
  /// **'Pump Stop Level'**
  String get thresh_pump_stop;

  /// No description provided for @thresh_pump_stop_sub.
  ///
  /// In en, this message translates to:
  /// **'Pump turns OFF when water rises above this'**
  String get thresh_pump_stop_sub;

  /// No description provided for @thresh_low_alert.
  ///
  /// In en, this message translates to:
  /// **'Low Water Alert'**
  String get thresh_low_alert;

  /// No description provided for @thresh_low_alert_sub.
  ///
  /// In en, this message translates to:
  /// **'Notification when water falls below this'**
  String get thresh_low_alert_sub;

  /// No description provided for @thresh_dry_run.
  ///
  /// In en, this message translates to:
  /// **'Dry-Run Alarm'**
  String get thresh_dry_run;

  /// No description provided for @thresh_dry_run_sub.
  ///
  /// In en, this message translates to:
  /// **'Emergency stop — pump on but tank is empty'**
  String get thresh_dry_run_sub;

  /// No description provided for @thresh_warn_order.
  ///
  /// In en, this message translates to:
  /// **'Pump start level must be higher than dry-run threshold.'**
  String get thresh_warn_order;

  /// No description provided for @thresh_saved.
  ///
  /// In en, this message translates to:
  /// **'Thresholds saved and pushed to device.'**
  String get thresh_saved;

  /// No description provided for @thresh_save_failed.
  ///
  /// In en, this message translates to:
  /// **'Failed to save thresholds.'**
  String get thresh_save_failed;

  /// No description provided for @thresh_save.
  ///
  /// In en, this message translates to:
  /// **'Save Thresholds'**
  String get thresh_save;

  /// No description provided for @usage_title.
  ///
  /// In en, this message translates to:
  /// **'Water Usage'**
  String get usage_title;

  /// No description provided for @usage_tab_week.
  ///
  /// In en, this message translates to:
  /// **'This Week'**
  String get usage_tab_week;

  /// No description provided for @usage_tab_month.
  ///
  /// In en, this message translates to:
  /// **'This Month'**
  String get usage_tab_month;

  /// No description provided for @usage_today.
  ///
  /// In en, this message translates to:
  /// **'Today'**
  String get usage_today;

  /// No description provided for @usage_this_week.
  ///
  /// In en, this message translates to:
  /// **'This Week'**
  String get usage_this_week;

  /// No description provided for @usage_this_month.
  ///
  /// In en, this message translates to:
  /// **'This Month'**
  String get usage_this_month;

  /// No description provided for @usage_total.
  ///
  /// In en, this message translates to:
  /// **'All Time'**
  String get usage_total;

  /// No description provided for @usage_flow_rate.
  ///
  /// In en, this message translates to:
  /// **'Flow Rate'**
  String get usage_flow_rate;

  /// No description provided for @usage_flow_rate_title.
  ///
  /// In en, this message translates to:
  /// **'Set Pump Flow Rate'**
  String get usage_flow_rate_title;

  /// No description provided for @usage_flow_rate_label.
  ///
  /// In en, this message translates to:
  /// **'Flow rate'**
  String get usage_flow_rate_label;

  /// No description provided for @usage_flow_rate_hint.
  ///
  /// In en, this message translates to:
  /// **'Check your pump label or measure manually. This is used to estimate liters from pump runtime.'**
  String get usage_flow_rate_hint;

  /// No description provided for @usage_daily_chart.
  ///
  /// In en, this message translates to:
  /// **'Daily Usage (Liters)'**
  String get usage_daily_chart;

  /// No description provided for @usage_tank_fills.
  ///
  /// In en, this message translates to:
  /// **'Estimated tank fills'**
  String get usage_tank_fills;

  /// No description provided for @usage_estimate_note.
  ///
  /// In en, this message translates to:
  /// **'Estimates based on pump runtime × flow rate. Set your pump\'s flow rate for accuracy.'**
  String get usage_estimate_note;

  /// No description provided for @saving.
  ///
  /// In en, this message translates to:
  /// **'Saving...'**
  String get saving;

  /// Google sign-in button label
  ///
  /// In en, this message translates to:
  /// **'Continue with Google'**
  String get sign_in_google;

  /// Divider between email and social login
  ///
  /// In en, this message translates to:
  /// **'or continue with'**
  String get or_continue_with;

  /// Error when Google Sign-In fails
  ///
  /// In en, this message translates to:
  /// **'Google Sign-In failed. Please try again.'**
  String get auth_err_google_failed;

  /// Error when account exists with different credential
  ///
  /// In en, this message translates to:
  /// **'An account already exists with this email using a different sign-in method.'**
  String get auth_err_account_exists;

  /// Message when user cancels Google Sign-In
  ///
  /// In en, this message translates to:
  /// **'Google Sign-In was cancelled.'**
  String get google_sign_in_cancelled;

  /// Password required validation message
  ///
  /// In en, this message translates to:
  /// **'Password is required'**
  String get pwd_required;

  /// Password uppercase validation message
  ///
  /// In en, this message translates to:
  /// **'Must contain an uppercase letter'**
  String get pwd_need_upper;

  /// No description provided for @ble_step_connect.
  ///
  /// In en, this message translates to:
  /// **'Connect'**
  String get ble_step_connect;

  /// No description provided for @ble_step_wifi.
  ///
  /// In en, this message translates to:
  /// **'WiFi'**
  String get ble_step_wifi;

  /// Settings: notifications menu label
  ///
  /// In en, this message translates to:
  /// **'Notifications'**
  String get notifications;

  /// Settings: water usage sublabel
  ///
  /// In en, this message translates to:
  /// **'Track water consumption'**
  String get trackConsumption;

  /// Settings: history sublabel
  ///
  /// In en, this message translates to:
  /// **'Events & Analytics'**
  String get eventsAnalytics;

  /// Settings: YouTube social link label
  ///
  /// In en, this message translates to:
  /// **'YouTube'**
  String get youtube;

  /// Settings: YouTube sublabel
  ///
  /// In en, this message translates to:
  /// **'Subscribe to our channel'**
  String get youtubeDesc;

  /// Settings: Facebook social link label
  ///
  /// In en, this message translates to:
  /// **'Facebook'**
  String get facebook;

  /// Settings: Facebook sublabel
  ///
  /// In en, this message translates to:
  /// **'Follow our page'**
  String get facebookDesc;

  /// Settings: voice service menu label
  ///
  /// In en, this message translates to:
  /// **'Voice Service'**
  String get voice_service;

  /// Settings: voice service coming soon snackbar
  ///
  /// In en, this message translates to:
  /// **'Voice Service — Coming Soon'**
  String get voice_service_coming_soon;

  /// Settings: calibration sublabel
  ///
  /// In en, this message translates to:
  /// **'Tank dimensions & sensor'**
  String get calib_sub;

  /// Settings: threshold sublabel
  ///
  /// In en, this message translates to:
  /// **'Pump & alert levels'**
  String get thresh_sub;

  /// Login screen: welcome back title
  ///
  /// In en, this message translates to:
  /// **'Welcome Back'**
  String get welcome_back;

  /// Login form: invalid email validation message
  ///
  /// In en, this message translates to:
  /// **'Enter a valid email address'**
  String get email_invalid;

  /// Login screen: email verification banner text
  ///
  /// In en, this message translates to:
  /// **'Please verify your email before signing in. Check your inbox for a verification link.'**
  String get verify_email_banner;

  /// Auth error: email not verified message
  ///
  /// In en, this message translates to:
  /// **'Email not verified. Check your inbox and click the verification link.'**
  String get email_not_verified_msg;

  /// Login screen: create account submit button
  ///
  /// In en, this message translates to:
  /// **'Create Account'**
  String get create_account_btn;

  /// Login screen: phone sign-in button label
  ///
  /// In en, this message translates to:
  /// **'Sign in with Phone'**
  String get phone_sign_in;

  /// Login screen: phone sign-in subtitle
  ///
  /// In en, this message translates to:
  /// **'Sign in using your mobile number'**
  String get phone_sign_in_subtitle;

  /// Login screen: phone number field label
  ///
  /// In en, this message translates to:
  /// **'Phone Number'**
  String get phone_number;

  /// Login screen: phone number field hint
  ///
  /// In en, this message translates to:
  /// **'+880 1XXX XXXXXX'**
  String get phone_number_hint;

  /// Login screen: phone number required validation
  ///
  /// In en, this message translates to:
  /// **'Phone number is required'**
  String get phone_number_required;

  /// Login screen: phone number invalid validation
  ///
  /// In en, this message translates to:
  /// **'Enter a valid phone number with country code'**
  String get phone_number_invalid;

  /// Login screen: phone country code hint
  ///
  /// In en, this message translates to:
  /// **'Include country code, e.g. +880 for Bangladesh'**
  String get phone_country_hint;

  /// Login screen: send OTP button label
  ///
  /// In en, this message translates to:
  /// **'Send OTP'**
  String get send_otp;

  /// Login screen: OTP input field label
  ///
  /// In en, this message translates to:
  /// **'OTP Code'**
  String get otp_code;

  /// Login screen: OTP field hint
  ///
  /// In en, this message translates to:
  /// **'6-digit code'**
  String get otp_hint;

  /// Login screen: verify OTP button label
  ///
  /// In en, this message translates to:
  /// **'Verify'**
  String get verify_otp;

  /// Login screen: OTP sent confirmation (followed by phone number)
  ///
  /// In en, this message translates to:
  /// **'OTP sent to'**
  String get otp_sent;

  /// Login screen: resend OTP link
  ///
  /// In en, this message translates to:
  /// **'Resend OTP'**
  String get resend_otp;

  /// Login screen: change phone number link
  ///
  /// In en, this message translates to:
  /// **'Change Number'**
  String get change_number;

  /// Login screen: OTP entry card title
  ///
  /// In en, this message translates to:
  /// **'Enter OTP'**
  String get enter_otp_title;

  /// Login screen: OTP entry subtitle
  ///
  /// In en, this message translates to:
  /// **'Enter the 6-digit code sent to your phone'**
  String get enter_otp_subtitle;

  /// Login screen: OTP required validation
  ///
  /// In en, this message translates to:
  /// **'Please enter the OTP'**
  String get otp_required;

  /// Login screen: OTP length validation
  ///
  /// In en, this message translates to:
  /// **'OTP must be 6 digits'**
  String get otp_invalid_length;

  /// Login screen: back to email button
  ///
  /// In en, this message translates to:
  /// **'Use email instead'**
  String get use_email_instead;

  /// Auth error: invalid phone number
  ///
  /// In en, this message translates to:
  /// **'Invalid phone number. Include country code (e.g. +880).'**
  String get auth_err_invalid_phone;

  /// Auth error: invalid OTP
  ///
  /// In en, this message translates to:
  /// **'Invalid OTP code. Please try again.'**
  String get auth_err_invalid_otp;

  /// Auth error: OTP session expired
  ///
  /// In en, this message translates to:
  /// **'OTP has expired. Please request a new one.'**
  String get auth_err_otp_expired;

  /// Auth error: generic phone sign-in failure
  ///
  /// In en, this message translates to:
  /// **'Phone sign-in failed. Please try again.'**
  String get auth_err_phone_failed;

  /// Login toggle row: already registered prompt
  ///
  /// In en, this message translates to:
  /// **'Already have an account? '**
  String get have_account;

  /// Login toggle row: sign-in link text
  ///
  /// In en, this message translates to:
  /// **'Sign In'**
  String get sign_in_now;

  /// Login toggle row: register link text
  ///
  /// In en, this message translates to:
  /// **'Register'**
  String get register_now;

  /// Automations screen: new rule sheet title
  ///
  /// In en, this message translates to:
  /// **'New Automation'**
  String get auto_new_title;

  /// Automations screen: IF section header
  ///
  /// In en, this message translates to:
  /// **'IF — Trigger'**
  String get auto_if_trigger;

  /// Automations screen: THEN section header
  ///
  /// In en, this message translates to:
  /// **'THEN — Action'**
  String get auto_then_action;

  /// Automations screen: save button
  ///
  /// In en, this message translates to:
  /// **'Save Automation'**
  String get auto_save;

  /// Automations screen: empty state title
  ///
  /// In en, this message translates to:
  /// **'No Automations'**
  String get auto_empty_title;

  /// Automations screen: empty state subtitle
  ///
  /// In en, this message translates to:
  /// **'Create IF→THEN rules that run automatically on your ESP32.'**
  String get auto_empty_sub;

  /// Automations screen: empty state CTA button
  ///
  /// In en, this message translates to:
  /// **'Add First Rule'**
  String get auto_add_first;

  /// Automations screen: IF trigger label
  ///
  /// In en, this message translates to:
  /// **'IF  {label}'**
  String auto_if_label(String label);

  /// Automations screen: THEN action label
  ///
  /// In en, this message translates to:
  /// **'THEN  {label}'**
  String auto_then_label(String label);

  /// Scenes screen: new scene sheet title
  ///
  /// In en, this message translates to:
  /// **'New Scene'**
  String get scene_new_title;

  /// Scenes screen: icon section label
  ///
  /// In en, this message translates to:
  /// **'Icon'**
  String get scene_icon_label;

  /// Scenes screen: pump section label
  ///
  /// In en, this message translates to:
  /// **'Pump'**
  String get scene_pump_label;

  /// Scenes screen: mode section label
  ///
  /// In en, this message translates to:
  /// **'Mode'**
  String get scene_mode_label;

  /// Scenes screen: color section label
  ///
  /// In en, this message translates to:
  /// **'Color'**
  String get scene_color_label;

  /// Scenes screen: save button
  ///
  /// In en, this message translates to:
  /// **'Save Scene'**
  String get scene_save;

  /// Scenes screen: empty state title
  ///
  /// In en, this message translates to:
  /// **'No Scenes Yet'**
  String get scene_empty_title;

  /// Scenes screen: empty state subtitle
  ///
  /// In en, this message translates to:
  /// **'Tap + to create a scene, or add defaults.'**
  String get scene_empty_sub;

  /// Scenes screen: add defaults button
  ///
  /// In en, this message translates to:
  /// **'Add Default Scenes'**
  String get scene_add_defaults;

  /// Water usage: flow rate guide text
  ///
  /// In en, this message translates to:
  /// **'5 L/min = Standard pump\n15 L/min = 0.5HP pump\n25 L/min = 1HP pump'**
  String get usage_flow_hint;

  /// Hint text on swipeable list items
  ///
  /// In en, this message translates to:
  /// **'Swipe left to delete'**
  String get swipe_to_delete;

  /// Login screen: shows auto-detected country dial code
  ///
  /// In en, this message translates to:
  /// **'Auto-detected: {code}'**
  String country_code_auto_label(String code);

  /// Login screen: E.164 format hint for phone number
  ///
  /// In en, this message translates to:
  /// **'E.g. +8801711000000'**
  String get phone_e164_hint;
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
      <String>['bn', 'en'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'bn':
      return AppLocalizationsBn();
    case 'en':
      return AppLocalizationsEn();
  }

  throw FlutterError(
      'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
      'an issue with the localizations generation tool. Please file an issue '
      'on GitHub with a reproducible sample app and the gen-l10n configuration '
      'that was used.');
}

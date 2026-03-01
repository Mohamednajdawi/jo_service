import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_ar.dart';
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
    Locale('en')
  ];

  /// No description provided for @appTitle.
  ///
  /// In en, this message translates to:
  /// **'JO Service'**
  String get appTitle;

  /// No description provided for @welcome.
  ///
  /// In en, this message translates to:
  /// **'Welcome'**
  String get welcome;

  /// No description provided for @login.
  ///
  /// In en, this message translates to:
  /// **'Login'**
  String get login;

  /// No description provided for @signup.
  ///
  /// In en, this message translates to:
  /// **'Sign Up'**
  String get signup;

  /// No description provided for @email.
  ///
  /// In en, this message translates to:
  /// **'Email'**
  String get email;

  /// No description provided for @password.
  ///
  /// In en, this message translates to:
  /// **'Password'**
  String get password;

  /// No description provided for @fullName.
  ///
  /// In en, this message translates to:
  /// **'Full Name'**
  String get fullName;

  /// No description provided for @phoneNumber.
  ///
  /// In en, this message translates to:
  /// **'Phone Number'**
  String get phoneNumber;

  /// No description provided for @confirmPassword.
  ///
  /// In en, this message translates to:
  /// **'Confirm Password'**
  String get confirmPassword;

  /// No description provided for @forgotPassword.
  ///
  /// In en, this message translates to:
  /// **'Forgot Password?'**
  String get forgotPassword;

  /// No description provided for @dontHaveAccount.
  ///
  /// In en, this message translates to:
  /// **'Don\'t have an account?'**
  String get dontHaveAccount;

  /// No description provided for @alreadyHaveAccount.
  ///
  /// In en, this message translates to:
  /// **'Already have an account?'**
  String get alreadyHaveAccount;

  /// No description provided for @createAccount.
  ///
  /// In en, this message translates to:
  /// **'Create Account'**
  String get createAccount;

  /// No description provided for @signInToAccount.
  ///
  /// In en, this message translates to:
  /// **'Sign in to your account'**
  String get signInToAccount;

  /// No description provided for @roleSelection.
  ///
  /// In en, this message translates to:
  /// **'Select Your Role'**
  String get roleSelection;

  /// No description provided for @customer.
  ///
  /// In en, this message translates to:
  /// **'Customer'**
  String get customer;

  /// No description provided for @serviceProvider.
  ///
  /// In en, this message translates to:
  /// **'Service Provider'**
  String get serviceProvider;

  /// No description provided for @administrator.
  ///
  /// In en, this message translates to:
  /// **'Administrator'**
  String get administrator;

  /// No description provided for @customerDescription.
  ///
  /// In en, this message translates to:
  /// **'Book services from providers'**
  String get customerDescription;

  /// No description provided for @providerDescription.
  ///
  /// In en, this message translates to:
  /// **'Provide services to customers'**
  String get providerDescription;

  /// No description provided for @adminDescription.
  ///
  /// In en, this message translates to:
  /// **'Service providers are managed through the admin panel - tap the admin icon above'**
  String get adminDescription;

  /// No description provided for @home.
  ///
  /// In en, this message translates to:
  /// **'Home'**
  String get home;

  /// No description provided for @profile.
  ///
  /// In en, this message translates to:
  /// **'Profile'**
  String get profile;

  /// No description provided for @bookings.
  ///
  /// In en, this message translates to:
  /// **'Bookings'**
  String get bookings;

  /// No description provided for @messages.
  ///
  /// In en, this message translates to:
  /// **'Messages'**
  String get messages;

  /// No description provided for @favorites.
  ///
  /// In en, this message translates to:
  /// **'Favorites'**
  String get favorites;

  /// No description provided for @settings.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settings;

  /// No description provided for @dashboard.
  ///
  /// In en, this message translates to:
  /// **'Dashboard'**
  String get dashboard;

  /// No description provided for @findServices.
  ///
  /// In en, this message translates to:
  /// **'Find Services'**
  String get findServices;

  /// No description provided for @searchForServices.
  ///
  /// In en, this message translates to:
  /// **'Search for services...'**
  String get searchForServices;

  /// No description provided for @nearbyProviders.
  ///
  /// In en, this message translates to:
  /// **'Nearby Providers'**
  String get nearbyProviders;

  /// No description provided for @topRated.
  ///
  /// In en, this message translates to:
  /// **'Top Rated'**
  String get topRated;

  /// No description provided for @categories.
  ///
  /// In en, this message translates to:
  /// **'Categories'**
  String get categories;

  /// No description provided for @viewAll.
  ///
  /// In en, this message translates to:
  /// **'View All'**
  String get viewAll;

  /// No description provided for @providerDetails.
  ///
  /// In en, this message translates to:
  /// **'Provider Details'**
  String get providerDetails;

  /// No description provided for @about.
  ///
  /// In en, this message translates to:
  /// **'About'**
  String get about;

  /// No description provided for @services.
  ///
  /// In en, this message translates to:
  /// **'Services (comma separated)'**
  String get services;

  /// No description provided for @reviews.
  ///
  /// In en, this message translates to:
  /// **'Reviews'**
  String get reviews;

  /// No description provided for @availability.
  ///
  /// In en, this message translates to:
  /// **'Availability'**
  String get availability;

  /// No description provided for @hourlyRate.
  ///
  /// In en, this message translates to:
  /// **'Hourly Rate (\$)'**
  String get hourlyRate;

  /// No description provided for @rating.
  ///
  /// In en, this message translates to:
  /// **'Rating'**
  String get rating;

  /// No description provided for @totalReviews.
  ///
  /// In en, this message translates to:
  /// **'Total Reviews'**
  String get totalReviews;

  /// No description provided for @bookNow.
  ///
  /// In en, this message translates to:
  /// **'Book Now'**
  String get bookNow;

  /// No description provided for @sendMessage.
  ///
  /// In en, this message translates to:
  /// **'Send Message'**
  String get sendMessage;

  /// No description provided for @addToFavorites.
  ///
  /// In en, this message translates to:
  /// **'Add to Favorites'**
  String get addToFavorites;

  /// No description provided for @removeFromFavorites.
  ///
  /// In en, this message translates to:
  /// **'Remove from Favorites'**
  String get removeFromFavorites;

  /// No description provided for @bookingDetails.
  ///
  /// In en, this message translates to:
  /// **'Booking Details'**
  String get bookingDetails;

  /// No description provided for @serviceDate.
  ///
  /// In en, this message translates to:
  /// **'Service Date'**
  String get serviceDate;

  /// No description provided for @serviceTime.
  ///
  /// In en, this message translates to:
  /// **'Service Time'**
  String get serviceTime;

  /// No description provided for @location.
  ///
  /// In en, this message translates to:
  /// **'Location'**
  String get location;

  /// No description provided for @notes.
  ///
  /// In en, this message translates to:
  /// **'Notes'**
  String get notes;

  /// No description provided for @photos.
  ///
  /// In en, this message translates to:
  /// **'Photos'**
  String get photos;

  /// No description provided for @addPhotos.
  ///
  /// In en, this message translates to:
  /// **'Add Photos'**
  String get addPhotos;

  /// No description provided for @bookingStatus.
  ///
  /// In en, this message translates to:
  /// **'Booking Status'**
  String get bookingStatus;

  /// No description provided for @pending.
  ///
  /// In en, this message translates to:
  /// **'Pending'**
  String get pending;

  /// No description provided for @accepted.
  ///
  /// In en, this message translates to:
  /// **'accepted'**
  String get accepted;

  /// No description provided for @declined.
  ///
  /// In en, this message translates to:
  /// **'declined'**
  String get declined;

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

  /// No description provided for @cancelled.
  ///
  /// In en, this message translates to:
  /// **'cancelled'**
  String get cancelled;

  /// No description provided for @createBooking.
  ///
  /// In en, this message translates to:
  /// **'Create Booking'**
  String get createBooking;

  /// No description provided for @selectDate.
  ///
  /// In en, this message translates to:
  /// **'Select Date'**
  String get selectDate;

  /// No description provided for @selectTime.
  ///
  /// In en, this message translates to:
  /// **'Select Time'**
  String get selectTime;

  /// No description provided for @enterLocation.
  ///
  /// In en, this message translates to:
  /// **'Enter Location'**
  String get enterLocation;

  /// No description provided for @addNotes.
  ///
  /// In en, this message translates to:
  /// **'Add Notes'**
  String get addNotes;

  /// No description provided for @submitBooking.
  ///
  /// In en, this message translates to:
  /// **'Submit Booking'**
  String get submitBooking;

  /// No description provided for @myBookings.
  ///
  /// In en, this message translates to:
  /// **'My Bookings'**
  String get myBookings;

  /// No description provided for @upcomingBookings.
  ///
  /// In en, this message translates to:
  /// **'Upcoming Bookings'**
  String get upcomingBookings;

  /// No description provided for @pastBookings.
  ///
  /// In en, this message translates to:
  /// **'Past Bookings'**
  String get pastBookings;

  /// No description provided for @noBookings.
  ///
  /// In en, this message translates to:
  /// **'No bookings found'**
  String get noBookings;

  /// No description provided for @viewDetails.
  ///
  /// In en, this message translates to:
  /// **'View Details'**
  String get viewDetails;

  /// No description provided for @cancelBooking.
  ///
  /// In en, this message translates to:
  /// **'Cancel Booking'**
  String get cancelBooking;

  /// No description provided for @acceptBooking.
  ///
  /// In en, this message translates to:
  /// **'Accept Booking'**
  String get acceptBooking;

  /// No description provided for @declineBooking.
  ///
  /// In en, this message translates to:
  /// **'Decline Booking'**
  String get declineBooking;

  /// No description provided for @startService.
  ///
  /// In en, this message translates to:
  /// **'Start Service'**
  String get startService;

  /// No description provided for @completeService.
  ///
  /// In en, this message translates to:
  /// **'Complete Service'**
  String get completeService;

  /// No description provided for @chat.
  ///
  /// In en, this message translates to:
  /// **'Chat'**
  String get chat;

  /// No description provided for @typeMessage.
  ///
  /// In en, this message translates to:
  /// **'Type a message...'**
  String get typeMessage;

  /// No description provided for @send.
  ///
  /// In en, this message translates to:
  /// **'Send'**
  String get send;

  /// No description provided for @online.
  ///
  /// In en, this message translates to:
  /// **'Online'**
  String get online;

  /// No description provided for @offline.
  ///
  /// In en, this message translates to:
  /// **'Offline'**
  String get offline;

  /// No description provided for @noMessages.
  ///
  /// In en, this message translates to:
  /// **'No messages yet'**
  String get noMessages;

  /// No description provided for @sendImage.
  ///
  /// In en, this message translates to:
  /// **'Send Image'**
  String get sendImage;

  /// No description provided for @rateProvider.
  ///
  /// In en, this message translates to:
  /// **'Rate Provider'**
  String get rateProvider;

  /// No description provided for @yourRating.
  ///
  /// In en, this message translates to:
  /// **'Your Rating'**
  String get yourRating;

  /// No description provided for @writeReview.
  ///
  /// In en, this message translates to:
  /// **'Write a review...'**
  String get writeReview;

  /// No description provided for @submitRating.
  ///
  /// In en, this message translates to:
  /// **'Submit Rating'**
  String get submitRating;

  /// No description provided for @punctuality.
  ///
  /// In en, this message translates to:
  /// **'Punctuality'**
  String get punctuality;

  /// No description provided for @notificationSettings.
  ///
  /// In en, this message translates to:
  /// **'Notification Settings'**
  String get notificationSettings;

  /// No description provided for @notificationPreferences.
  ///
  /// In en, this message translates to:
  /// **'Notification Preferences'**
  String get notificationPreferences;

  /// No description provided for @notificationPreferencesDescription.
  ///
  /// In en, this message translates to:
  /// **'Choose which notifications you want to receive'**
  String get notificationPreferencesDescription;

  /// No description provided for @bookingUpdates.
  ///
  /// In en, this message translates to:
  /// **'Booking Updates'**
  String get bookingUpdates;

  /// No description provided for @bookingUpdatesDescription.
  ///
  /// In en, this message translates to:
  /// **'Receive notifications about booking status changes'**
  String get bookingUpdatesDescription;

  /// No description provided for @chatMessages.
  ///
  /// In en, this message translates to:
  /// **'Chat Messages'**
  String get chatMessages;

  /// No description provided for @chatMessagesDescription.
  ///
  /// In en, this message translates to:
  /// **'Receive notifications for new chat messages'**
  String get chatMessagesDescription;

  /// No description provided for @ratings.
  ///
  /// In en, this message translates to:
  /// **'Ratings'**
  String get ratings;

  /// No description provided for @ratingsDescription.
  ///
  /// In en, this message translates to:
  /// **'Receive notifications for new ratings and reviews'**
  String get ratingsDescription;

  /// No description provided for @promotions.
  ///
  /// In en, this message translates to:
  /// **'Promotions'**
  String get promotions;

  /// No description provided for @promotionsDescription.
  ///
  /// In en, this message translates to:
  /// **'Receive notifications about special offers and promotions'**
  String get promotionsDescription;

  /// No description provided for @saveSettings.
  ///
  /// In en, this message translates to:
  /// **'Save Settings'**
  String get saveSettings;

  /// No description provided for @testNotificationSent.
  ///
  /// In en, this message translates to:
  /// **'Test notification sent successfully'**
  String get testNotificationSent;

  /// No description provided for @errorSendingTestNotification.
  ///
  /// In en, this message translates to:
  /// **'Error sending test notification'**
  String get errorSendingTestNotification;

  /// No description provided for @settingsSaved.
  ///
  /// In en, this message translates to:
  /// **'Settings saved successfully'**
  String get settingsSaved;

  /// No description provided for @errorSavingSettings.
  ///
  /// In en, this message translates to:
  /// **'Error saving settings'**
  String get errorSavingSettings;

  /// No description provided for @sendTestNotification.
  ///
  /// In en, this message translates to:
  /// **'Send Test Notification'**
  String get sendTestNotification;

  /// No description provided for @notificationInfo.
  ///
  /// In en, this message translates to:
  /// **'Notification Information'**
  String get notificationInfo;

  /// No description provided for @notificationInfoDescription.
  ///
  /// In en, this message translates to:
  /// **'You can control which notifications you receive. Disabling notifications may cause you to miss important updates about your bookings and messages.'**
  String get notificationInfoDescription;

  /// No description provided for @workQuality.
  ///
  /// In en, this message translates to:
  /// **'Work Quality'**
  String get workQuality;

  /// No description provided for @speedEfficiency.
  ///
  /// In en, this message translates to:
  /// **'Speed & Efficiency'**
  String get speedEfficiency;

  /// No description provided for @cleanliness.
  ///
  /// In en, this message translates to:
  /// **'Cleanliness'**
  String get cleanliness;

  /// No description provided for @overallRating.
  ///
  /// In en, this message translates to:
  /// **'Overall Rating'**
  String get overallRating;

  /// No description provided for @notifications.
  ///
  /// In en, this message translates to:
  /// **'Notifications'**
  String get notifications;

  /// No description provided for @noNotifications.
  ///
  /// In en, this message translates to:
  /// **'No notifications'**
  String get noNotifications;

  /// No description provided for @markAllRead.
  ///
  /// In en, this message translates to:
  /// **'Mark All Read'**
  String get markAllRead;

  /// No description provided for @language.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get language;

  /// No description provided for @changeLanguage.
  ///
  /// In en, this message translates to:
  /// **'Change Language'**
  String get changeLanguage;

  /// No description provided for @english.
  ///
  /// In en, this message translates to:
  /// **'English'**
  String get english;

  /// No description provided for @arabic.
  ///
  /// In en, this message translates to:
  /// **'العربية'**
  String get arabic;

  /// No description provided for @loading.
  ///
  /// In en, this message translates to:
  /// **'Loading...'**
  String get loading;

  /// No description provided for @error.
  ///
  /// In en, this message translates to:
  /// **'Error'**
  String get error;

  /// No description provided for @success.
  ///
  /// In en, this message translates to:
  /// **'Success'**
  String get success;

  /// No description provided for @retry.
  ///
  /// In en, this message translates to:
  /// **'Retry'**
  String get retry;

  /// No description provided for @cancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancel;

  /// No description provided for @save.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get save;

  /// No description provided for @delete.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get delete;

  /// No description provided for @edit.
  ///
  /// In en, this message translates to:
  /// **'Edit'**
  String get edit;

  /// No description provided for @update.
  ///
  /// In en, this message translates to:
  /// **'Update'**
  String get update;

  /// No description provided for @confirm.
  ///
  /// In en, this message translates to:
  /// **'Confirm'**
  String get confirm;

  /// No description provided for @yes.
  ///
  /// In en, this message translates to:
  /// **'Yes'**
  String get yes;

  /// No description provided for @no.
  ///
  /// In en, this message translates to:
  /// **'No'**
  String get no;

  /// No description provided for @ok.
  ///
  /// In en, this message translates to:
  /// **'OK'**
  String get ok;

  /// No description provided for @logout.
  ///
  /// In en, this message translates to:
  /// **'Logout'**
  String get logout;

  /// No description provided for @logoutConfirmation.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to logout?'**
  String get logoutConfirmation;

  /// No description provided for @adminPanel.
  ///
  /// In en, this message translates to:
  /// **'Admin Panel'**
  String get adminPanel;

  /// No description provided for @providerManagement.
  ///
  /// In en, this message translates to:
  /// **'Provider Management'**
  String get providerManagement;

  /// No description provided for @userManagement.
  ///
  /// In en, this message translates to:
  /// **'User Management'**
  String get userManagement;

  /// No description provided for @systemStats.
  ///
  /// In en, this message translates to:
  /// **'System Statistics'**
  String get systemStats;

  /// No description provided for @pendingProviders.
  ///
  /// In en, this message translates to:
  /// **'Pending Providers'**
  String get pendingProviders;

  /// No description provided for @verifiedProviders.
  ///
  /// In en, this message translates to:
  /// **'Verified Providers'**
  String get verifiedProviders;

  /// No description provided for @rejectedProviders.
  ///
  /// In en, this message translates to:
  /// **'Rejected Providers'**
  String get rejectedProviders;

  /// No description provided for @verifyProvider.
  ///
  /// In en, this message translates to:
  /// **'Verify Provider'**
  String get verifyProvider;

  /// No description provided for @resendVerification.
  ///
  /// In en, this message translates to:
  /// **'Resend Verification'**
  String get resendVerification;

  /// No description provided for @resendVerificationEmail.
  ///
  /// In en, this message translates to:
  /// **'Resend Verification Email'**
  String get resendVerificationEmail;

  /// No description provided for @verificationEmailSent.
  ///
  /// In en, this message translates to:
  /// **'Verification email sent!'**
  String get verificationEmailSent;

  /// No description provided for @accountNotVerified.
  ///
  /// In en, this message translates to:
  /// **'Account not verified'**
  String get accountNotVerified;

  /// No description provided for @pleaseVerifyAccount.
  ///
  /// In en, this message translates to:
  /// **'Please verify your email and phone number before logging in.'**
  String get pleaseVerifyAccount;

  /// No description provided for @verifyAccount.
  ///
  /// In en, this message translates to:
  /// **'Verify Account'**
  String get verifyAccount;

  /// No description provided for @rejectProvider.
  ///
  /// In en, this message translates to:
  /// **'Reject Provider'**
  String get rejectProvider;

  /// No description provided for @totalUsers.
  ///
  /// In en, this message translates to:
  /// **'Total Users'**
  String get totalUsers;

  /// No description provided for @totalProviders.
  ///
  /// In en, this message translates to:
  /// **'Total Providers'**
  String get totalProviders;

  /// No description provided for @totalBookings.
  ///
  /// In en, this message translates to:
  /// **'Total Bookings'**
  String get totalBookings;

  /// No description provided for @invalidEmail.
  ///
  /// In en, this message translates to:
  /// **'Please enter a valid email address'**
  String get invalidEmail;

  /// No description provided for @passwordTooShort.
  ///
  /// In en, this message translates to:
  /// **'Password must be at least 6 characters'**
  String get passwordTooShort;

  /// No description provided for @passwordsDoNotMatch.
  ///
  /// In en, this message translates to:
  /// **'Passwords do not match'**
  String get passwordsDoNotMatch;

  /// No description provided for @fieldRequired.
  ///
  /// In en, this message translates to:
  /// **'This field is required'**
  String get fieldRequired;

  /// No description provided for @loginFailed.
  ///
  /// In en, this message translates to:
  /// **'Login failed. Please check your credentials'**
  String get loginFailed;

  /// No description provided for @networkError.
  ///
  /// In en, this message translates to:
  /// **'Network error. Please check your connection'**
  String get networkError;

  /// No description provided for @bookingFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed to create booking. Please try again'**
  String get bookingFailed;

  /// No description provided for @ratingFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed to submit rating. Please try again'**
  String get ratingFailed;

  /// No description provided for @welcomeBack.
  ///
  /// In en, this message translates to:
  /// **'Welcome back!'**
  String get welcomeBack;

  /// No description provided for @readyToServe.
  ///
  /// In en, this message translates to:
  /// **'Ready to serve?'**
  String get readyToServe;

  /// No description provided for @jordanServiceProvider.
  ///
  /// In en, this message translates to:
  /// **'Jordan Service Provider'**
  String get jordanServiceProvider;

  /// No description provided for @findPerfectService.
  ///
  /// In en, this message translates to:
  /// **'Find the perfect service provider for your needs'**
  String get findPerfectService;

  /// No description provided for @quickActions.
  ///
  /// In en, this message translates to:
  /// **'Quick Actions'**
  String get quickActions;

  /// No description provided for @browseProviders.
  ///
  /// In en, this message translates to:
  /// **'Browse providers'**
  String get browseProviders;

  /// No description provided for @viewAppointments.
  ///
  /// In en, this message translates to:
  /// **'View appointments'**
  String get viewAppointments;

  /// No description provided for @savedProviders.
  ///
  /// In en, this message translates to:
  /// **'Saved providers'**
  String get savedProviders;

  /// No description provided for @manageAccount.
  ///
  /// In en, this message translates to:
  /// **'Manage account'**
  String get manageAccount;

  /// No description provided for @recentProviders.
  ///
  /// In en, this message translates to:
  /// **'Recent Providers'**
  String get recentProviders;

  /// No description provided for @seeAll.
  ///
  /// In en, this message translates to:
  /// **'See All'**
  String get seeAll;

  /// No description provided for @errorLoadingProviders.
  ///
  /// In en, this message translates to:
  /// **'Error loading providers'**
  String get errorLoadingProviders;

  /// No description provided for @noProvidersFound.
  ///
  /// In en, this message translates to:
  /// **'No providers found'**
  String get noProvidersFound;

  /// No description provided for @unknown.
  ///
  /// In en, this message translates to:
  /// **'Unknown'**
  String get unknown;

  /// No description provided for @service.
  ///
  /// In en, this message translates to:
  /// **'Service'**
  String get service;

  /// No description provided for @yourActivity.
  ///
  /// In en, this message translates to:
  /// **'Your Activity'**
  String get yourActivity;

  /// No description provided for @activeBookings.
  ///
  /// In en, this message translates to:
  /// **'Active Bookings'**
  String get activeBookings;

  /// No description provided for @completedThisMonth.
  ///
  /// In en, this message translates to:
  /// **'Completed This Month'**
  String get completedThisMonth;

  /// No description provided for @manageProfile.
  ///
  /// In en, this message translates to:
  /// **'Manage Profile'**
  String get manageProfile;

  /// No description provided for @updateServicesRates.
  ///
  /// In en, this message translates to:
  /// **'Update your services, rates, and availability'**
  String get updateServicesRates;

  /// No description provided for @manageBookings.
  ///
  /// In en, this message translates to:
  /// **'Manage Bookings'**
  String get manageBookings;

  /// No description provided for @viewRespondBookings.
  ///
  /// In en, this message translates to:
  /// **'View and respond to booking requests'**
  String get viewRespondBookings;

  /// No description provided for @viewRespondMessages.
  ///
  /// In en, this message translates to:
  /// **'View and respond to customer messages'**
  String get viewRespondMessages;

  /// No description provided for @signOut.
  ///
  /// In en, this message translates to:
  /// **'Sign Out'**
  String get signOut;

  /// No description provided for @signOutConfirmation.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to sign out?'**
  String get signOutConfirmation;

  /// No description provided for @autoRefreshEnabled.
  ///
  /// In en, this message translates to:
  /// **'Auto-refresh enabled'**
  String get autoRefreshEnabled;

  /// No description provided for @autoRefreshDisabled.
  ///
  /// In en, this message translates to:
  /// **'Auto-refresh disabled'**
  String get autoRefreshDisabled;

  /// No description provided for @view.
  ///
  /// In en, this message translates to:
  /// **'View'**
  String get view;

  /// No description provided for @newBookingNotification.
  ///
  /// In en, this message translates to:
  /// **'You have {count} new booking{plural}!'**
  String newBookingNotification(int count, String plural);

  /// No description provided for @providerSignup.
  ///
  /// In en, this message translates to:
  /// **'Provider Sign Up'**
  String get providerSignup;

  /// No description provided for @joinAsProvider.
  ///
  /// In en, this message translates to:
  /// **'Join as provider'**
  String get joinAsProvider;

  /// No description provided for @startOfferingServices.
  ///
  /// In en, this message translates to:
  /// **'Start offering your services today'**
  String get startOfferingServices;

  /// No description provided for @personalInformation.
  ///
  /// In en, this message translates to:
  /// **'Personal Information'**
  String get personalInformation;

  /// No description provided for @businessInformation.
  ///
  /// In en, this message translates to:
  /// **'Business Information'**
  String get businessInformation;

  /// No description provided for @enterFullName.
  ///
  /// In en, this message translates to:
  /// **'Enter your full name'**
  String get enterFullName;

  /// No description provided for @enterEmail.
  ///
  /// In en, this message translates to:
  /// **'Enter your email'**
  String get enterEmail;

  /// No description provided for @enterPassword.
  ///
  /// In en, this message translates to:
  /// **'Enter your password'**
  String get enterPassword;

  /// No description provided for @confirmYourPassword.
  ///
  /// In en, this message translates to:
  /// **'Confirm your password'**
  String get confirmYourPassword;

  /// No description provided for @companyName.
  ///
  /// In en, this message translates to:
  /// **'Company name'**
  String get companyName;

  /// No description provided for @enterCompanyName.
  ///
  /// In en, this message translates to:
  /// **'Enter your company name'**
  String get enterCompanyName;

  /// No description provided for @serviceType.
  ///
  /// In en, this message translates to:
  /// **'Service type'**
  String get serviceType;

  /// No description provided for @enterServiceType.
  ///
  /// In en, this message translates to:
  /// **'Enter your service type'**
  String get enterServiceType;

  /// No description provided for @enterHourlyRate.
  ///
  /// In en, this message translates to:
  /// **'Enter your hourly rate'**
  String get enterHourlyRate;

  /// No description provided for @city.
  ///
  /// In en, this message translates to:
  /// **'City'**
  String get city;

  /// No description provided for @address.
  ///
  /// In en, this message translates to:
  /// **'Address'**
  String get address;

  /// No description provided for @enterDetailedAddress.
  ///
  /// In en, this message translates to:
  /// **'Enter your detailed address'**
  String get enterDetailedAddress;

  /// No description provided for @createProviderAccount.
  ///
  /// In en, this message translates to:
  /// **'Create provider account'**
  String get createProviderAccount;

  /// No description provided for @emailRequired.
  ///
  /// In en, this message translates to:
  /// **'Email is required'**
  String get emailRequired;

  /// No description provided for @enterValidEmail.
  ///
  /// In en, this message translates to:
  /// **'Enter a valid email address'**
  String get enterValidEmail;

  /// No description provided for @passwordRequired.
  ///
  /// In en, this message translates to:
  /// **'Password is required'**
  String get passwordRequired;

  /// No description provided for @passwordMinLength.
  ///
  /// In en, this message translates to:
  /// **'Password must be at least 6 characters'**
  String get passwordMinLength;

  /// No description provided for @confirmPasswordRequired.
  ///
  /// In en, this message translates to:
  /// **'Please confirm your password'**
  String get confirmPasswordRequired;

  /// No description provided for @hourlyRateRequired.
  ///
  /// In en, this message translates to:
  /// **'Hourly rate is required'**
  String get hourlyRateRequired;

  /// No description provided for @enterValidRate.
  ///
  /// In en, this message translates to:
  /// **'Enter a valid hourly rate'**
  String get enterValidRate;

  /// No description provided for @unknownProvider.
  ///
  /// In en, this message translates to:
  /// **'Unknown Provider'**
  String get unknownProvider;

  /// No description provided for @unknownService.
  ///
  /// In en, this message translates to:
  /// **'Unknown Service'**
  String get unknownService;

  /// No description provided for @rate.
  ///
  /// In en, this message translates to:
  /// **'Rate'**
  String get rate;

  /// No description provided for @per.
  ///
  /// In en, this message translates to:
  /// **'per'**
  String get per;

  /// No description provided for @hour.
  ///
  /// In en, this message translates to:
  /// **'hour'**
  String get hour;

  /// No description provided for @mapView.
  ///
  /// In en, this message translates to:
  /// **'Map View'**
  String get mapView;

  /// No description provided for @mapFunctionalityDisabled.
  ///
  /// In en, this message translates to:
  /// **'Map functionality temporarily disabled'**
  String get mapFunctionalityDisabled;

  /// No description provided for @errorRequestingPermission.
  ///
  /// In en, this message translates to:
  /// **'Error requesting permission'**
  String get errorRequestingPermission;

  /// No description provided for @userSignup.
  ///
  /// In en, this message translates to:
  /// **'User Sign Up'**
  String get userSignup;

  /// No description provided for @createYourAccount.
  ///
  /// In en, this message translates to:
  /// **'Create your account'**
  String get createYourAccount;

  /// No description provided for @getStartedToday.
  ///
  /// In en, this message translates to:
  /// **'Get started today'**
  String get getStartedToday;

  /// No description provided for @enterPhoneNumber.
  ///
  /// In en, this message translates to:
  /// **'Enter your phone number'**
  String get enterPhoneNumber;

  /// No description provided for @createUserAccount.
  ///
  /// In en, this message translates to:
  /// **'Create user account'**
  String get createUserAccount;

  /// No description provided for @adminLogin.
  ///
  /// In en, this message translates to:
  /// **'Admin Login'**
  String get adminLogin;

  /// No description provided for @adminPortal.
  ///
  /// In en, this message translates to:
  /// **'Admin Portal'**
  String get adminPortal;

  /// No description provided for @secureAccess.
  ///
  /// In en, this message translates to:
  /// **'Secure access to system management'**
  String get secureAccess;

  /// No description provided for @loginAsAdmin.
  ///
  /// In en, this message translates to:
  /// **'Login as admin'**
  String get loginAsAdmin;

  /// No description provided for @providerLogin.
  ///
  /// In en, this message translates to:
  /// **'Provider Login'**
  String get providerLogin;

  /// No description provided for @providerPortal.
  ///
  /// In en, this message translates to:
  /// **'Provider Portal'**
  String get providerPortal;

  /// No description provided for @accessYourServices.
  ///
  /// In en, this message translates to:
  /// **'Access your services and bookings'**
  String get accessYourServices;

  /// No description provided for @loginAsProvider.
  ///
  /// In en, this message translates to:
  /// **'Login as provider'**
  String get loginAsProvider;

  /// No description provided for @bookingFor.
  ///
  /// In en, this message translates to:
  /// **'Booking for'**
  String get bookingFor;

  /// No description provided for @selectDateAndTime.
  ///
  /// In en, this message translates to:
  /// **'Select Date and Time'**
  String get selectDateAndTime;

  /// No description provided for @bookingDate.
  ///
  /// In en, this message translates to:
  /// **'Booking Date'**
  String get bookingDate;

  /// No description provided for @bookingTime.
  ///
  /// In en, this message translates to:
  /// **'Booking Time'**
  String get bookingTime;

  /// No description provided for @locationDetails.
  ///
  /// In en, this message translates to:
  /// **'Location Details'**
  String get locationDetails;

  /// No description provided for @additionalNotes.
  ///
  /// In en, this message translates to:
  /// **'Additional Notes'**
  String get additionalNotes;

  /// No description provided for @optionalNotes.
  ///
  /// In en, this message translates to:
  /// **'Optional notes about your service request'**
  String get optionalNotes;

  /// No description provided for @attachPhotos.
  ///
  /// In en, this message translates to:
  /// **'Attach Photos'**
  String get attachPhotos;

  /// No description provided for @attachRelevantPhotos.
  ///
  /// In en, this message translates to:
  /// **'Attach relevant photos (optional)'**
  String get attachRelevantPhotos;

  /// No description provided for @takePhoto.
  ///
  /// In en, this message translates to:
  /// **'Take Photo'**
  String get takePhoto;

  /// No description provided for @chooseFromGallery.
  ///
  /// In en, this message translates to:
  /// **'Choose from Gallery'**
  String get chooseFromGallery;

  /// No description provided for @bookingSubmitted.
  ///
  /// In en, this message translates to:
  /// **'Booking submitted successfully!'**
  String get bookingSubmitted;

  /// No description provided for @errorSubmittingBooking.
  ///
  /// In en, this message translates to:
  /// **'Error submitting booking'**
  String get errorSubmittingBooking;

  /// No description provided for @chatWith.
  ///
  /// In en, this message translates to:
  /// **'Chat with'**
  String chatWith(String name);

  /// No description provided for @startTyping.
  ///
  /// In en, this message translates to:
  /// **'Start typing...'**
  String get startTyping;

  /// No description provided for @enterMessage.
  ///
  /// In en, this message translates to:
  /// **'Enter your message'**
  String get enterMessage;

  /// No description provided for @failedToSendMessage.
  ///
  /// In en, this message translates to:
  /// **'Failed to send message. Please try again.'**
  String get failedToSendMessage;

  /// No description provided for @selectImage.
  ///
  /// In en, this message translates to:
  /// **'Select Image'**
  String get selectImage;

  /// No description provided for @camera.
  ///
  /// In en, this message translates to:
  /// **'Camera'**
  String get camera;

  /// No description provided for @gallery.
  ///
  /// In en, this message translates to:
  /// **'Gallery'**
  String get gallery;

  /// No description provided for @all.
  ///
  /// In en, this message translates to:
  /// **'All'**
  String get all;

  /// No description provided for @noBookingsFound.
  ///
  /// In en, this message translates to:
  /// **'No bookings found'**
  String get noBookingsFound;

  /// No description provided for @scheduleNewService.
  ///
  /// In en, this message translates to:
  /// **'Schedule a new service to see bookings here'**
  String get scheduleNewService;

  /// No description provided for @errorLoadingBookings.
  ///
  /// In en, this message translates to:
  /// **'Error loading bookings'**
  String get errorLoadingBookings;

  /// No description provided for @errorLoadingMoreBookings.
  ///
  /// In en, this message translates to:
  /// **'Error loading more bookings'**
  String get errorLoadingMoreBookings;

  /// No description provided for @errorCancellingBooking.
  ///
  /// In en, this message translates to:
  /// **'Error cancelling booking'**
  String get errorCancellingBooking;

  /// No description provided for @areYouSureCancelBooking.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to cancel this booking?'**
  String get areYouSureCancelBooking;

  /// No description provided for @advancedSearch.
  ///
  /// In en, this message translates to:
  /// **'Advanced Search'**
  String get advancedSearch;

  /// No description provided for @filters.
  ///
  /// In en, this message translates to:
  /// **'Filters'**
  String get filters;

  /// No description provided for @clearAll.
  ///
  /// In en, this message translates to:
  /// **'Clear All'**
  String get clearAll;

  /// No description provided for @category.
  ///
  /// In en, this message translates to:
  /// **'Category'**
  String get category;

  /// No description provided for @minimumRating.
  ///
  /// In en, this message translates to:
  /// **'Minimum Rating'**
  String get minimumRating;

  /// No description provided for @maxPrice.
  ///
  /// In en, this message translates to:
  /// **'Max Price'**
  String get maxPrice;

  /// No description provided for @maxDistance.
  ///
  /// In en, this message translates to:
  /// **'Max Distance'**
  String get maxDistance;

  /// No description provided for @onlyAvailable.
  ///
  /// In en, this message translates to:
  /// **'Only Available'**
  String get onlyAvailable;

  /// No description provided for @serviceTags.
  ///
  /// In en, this message translates to:
  /// **'Service Tags'**
  String get serviceTags;

  /// No description provided for @sortBy.
  ///
  /// In en, this message translates to:
  /// **'Sort By'**
  String get sortBy;

  /// No description provided for @order.
  ///
  /// In en, this message translates to:
  /// **'Order'**
  String get order;

  /// No description provided for @ascending.
  ///
  /// In en, this message translates to:
  /// **'Ascending'**
  String get ascending;

  /// No description provided for @descending.
  ///
  /// In en, this message translates to:
  /// **'Descending'**
  String get descending;

  /// No description provided for @price.
  ///
  /// In en, this message translates to:
  /// **'Price'**
  String get price;

  /// No description provided for @distance.
  ///
  /// In en, this message translates to:
  /// **'Distance'**
  String get distance;

  /// No description provided for @results.
  ///
  /// In en, this message translates to:
  /// **'Results'**
  String get results;

  /// No description provided for @page.
  ///
  /// In en, this message translates to:
  /// **'Page'**
  String get page;

  /// No description provided for @searching.
  ///
  /// In en, this message translates to:
  /// **'Searching...'**
  String get searching;

  /// No description provided for @tryAdjustingFilters.
  ///
  /// In en, this message translates to:
  /// **'Try adjusting your filters'**
  String get tryAdjustingFilters;

  /// No description provided for @searchProviders.
  ///
  /// In en, this message translates to:
  /// **'Search Providers'**
  String get searchProviders;

  /// No description provided for @useMyLocation.
  ///
  /// In en, this message translates to:
  /// **'Use My Location'**
  String get useMyLocation;

  /// No description provided for @locationNotAvailable.
  ///
  /// In en, this message translates to:
  /// **'Location not available'**
  String get locationNotAvailable;

  /// No description provided for @unknownStatus.
  ///
  /// In en, this message translates to:
  /// **'Unknown'**
  String get unknownStatus;

  /// No description provided for @plumbing.
  ///
  /// In en, this message translates to:
  /// **'Plumbing'**
  String get plumbing;

  /// No description provided for @electrical.
  ///
  /// In en, this message translates to:
  /// **'Electrical'**
  String get electrical;

  /// No description provided for @cleaning.
  ///
  /// In en, this message translates to:
  /// **'Cleaning'**
  String get cleaning;

  /// No description provided for @gardening.
  ///
  /// In en, this message translates to:
  /// **'Gardening'**
  String get gardening;

  /// No description provided for @painting.
  ///
  /// In en, this message translates to:
  /// **'Painting'**
  String get painting;

  /// No description provided for @carpentry.
  ///
  /// In en, this message translates to:
  /// **'Carpentry'**
  String get carpentry;

  /// No description provided for @userProfile.
  ///
  /// In en, this message translates to:
  /// **'User Profile'**
  String get userProfile;

  /// No description provided for @editProfile.
  ///
  /// In en, this message translates to:
  /// **'Edit Profile'**
  String get editProfile;

  /// No description provided for @personalInfo.
  ///
  /// In en, this message translates to:
  /// **'Personal Info'**
  String get personalInfo;

  /// No description provided for @contactInfo.
  ///
  /// In en, this message translates to:
  /// **'Contact Info'**
  String get contactInfo;

  /// No description provided for @preferences.
  ///
  /// In en, this message translates to:
  /// **'Preferences'**
  String get preferences;

  /// No description provided for @aboutApp.
  ///
  /// In en, this message translates to:
  /// **'About App'**
  String get aboutApp;

  /// No description provided for @version.
  ///
  /// In en, this message translates to:
  /// **'Version'**
  String get version;

  /// No description provided for @termsOfService.
  ///
  /// In en, this message translates to:
  /// **'Terms of Service'**
  String get termsOfService;

  /// No description provided for @privacyPolicy.
  ///
  /// In en, this message translates to:
  /// **'Privacy Policy'**
  String get privacyPolicy;

  /// No description provided for @contactSupport.
  ///
  /// In en, this message translates to:
  /// **'Contact Support'**
  String get contactSupport;

  /// No description provided for @contactSupportDescription.
  ///
  /// In en, this message translates to:
  /// **'Having an issue or want to report something? Contact us directly'**
  String get contactSupportDescription;

  /// No description provided for @callUs.
  ///
  /// In en, this message translates to:
  /// **'Call Us'**
  String get callUs;

  /// No description provided for @supportMessage.
  ///
  /// In en, this message translates to:
  /// **'Support Message'**
  String get supportMessage;

  /// No description provided for @describeYourIssue.
  ///
  /// In en, this message translates to:
  /// **'Describe your issue or concern...'**
  String get describeYourIssue;

  /// No description provided for @issueWithProvider.
  ///
  /// In en, this message translates to:
  /// **'Issue with Provider'**
  String get issueWithProvider;

  /// No description provided for @generalInquiry.
  ///
  /// In en, this message translates to:
  /// **'General Inquiry'**
  String get generalInquiry;

  /// No description provided for @technicalProblem.
  ///
  /// In en, this message translates to:
  /// **'Technical Problem'**
  String get technicalProblem;

  /// No description provided for @billingIssue.
  ///
  /// In en, this message translates to:
  /// **'Billing Issue'**
  String get billingIssue;

  /// No description provided for @other.
  ///
  /// In en, this message translates to:
  /// **'Other'**
  String get other;

  /// No description provided for @selectIssueType.
  ///
  /// In en, this message translates to:
  /// **'Select Issue Type'**
  String get selectIssueType;

  /// No description provided for @messageSentSuccessfully.
  ///
  /// In en, this message translates to:
  /// **'Message sent successfully! We\'ll get back to you soon.'**
  String get messageSentSuccessfully;

  /// No description provided for @areYouSureSignOut.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to sign out?'**
  String get areYouSureSignOut;

  /// No description provided for @languageSettings.
  ///
  /// In en, this message translates to:
  /// **'Language Settings'**
  String get languageSettings;

  /// No description provided for @selectLanguage.
  ///
  /// In en, this message translates to:
  /// **'Select Language'**
  String get selectLanguage;

  /// No description provided for @darkMode.
  ///
  /// In en, this message translates to:
  /// **'Dark Mode'**
  String get darkMode;

  /// No description provided for @pushNotifications.
  ///
  /// In en, this message translates to:
  /// **'Push Notifications'**
  String get pushNotifications;

  /// No description provided for @emailNotifications.
  ///
  /// In en, this message translates to:
  /// **'Email Notifications'**
  String get emailNotifications;

  /// No description provided for @soundEnabled.
  ///
  /// In en, this message translates to:
  /// **'Sound Enabled'**
  String get soundEnabled;

  /// No description provided for @favoriteProviders.
  ///
  /// In en, this message translates to:
  /// **'Favorite Providers'**
  String get favoriteProviders;

  /// No description provided for @noFavorites.
  ///
  /// In en, this message translates to:
  /// **'No favorites yet'**
  String get noFavorites;

  /// No description provided for @addFavoritesMessage.
  ///
  /// In en, this message translates to:
  /// **'Save providers you like to see them here'**
  String get addFavoritesMessage;

  /// No description provided for @viewProfile.
  ///
  /// In en, this message translates to:
  /// **'View Profile'**
  String get viewProfile;

  /// No description provided for @bookService.
  ///
  /// In en, this message translates to:
  /// **'Book Service'**
  String get bookService;

  /// No description provided for @noMessagesYet.
  ///
  /// In en, this message translates to:
  /// **'No messages yet'**
  String get noMessagesYet;

  /// No description provided for @startConversation.
  ///
  /// In en, this message translates to:
  /// **'Start conversation'**
  String get startConversation;

  /// No description provided for @searchMessages.
  ///
  /// In en, this message translates to:
  /// **'Search messages'**
  String get searchMessages;

  /// No description provided for @lastSeen.
  ///
  /// In en, this message translates to:
  /// **'Last seen'**
  String get lastSeen;

  /// No description provided for @typing.
  ///
  /// In en, this message translates to:
  /// **'Typing...'**
  String get typing;

  /// No description provided for @myFavorites.
  ///
  /// In en, this message translates to:
  /// **'My Favorites'**
  String get myFavorites;

  /// No description provided for @errorLoadingFavorites.
  ///
  /// In en, this message translates to:
  /// **'Error loading favorites:'**
  String get errorLoadingFavorites;

  /// No description provided for @noFavoritesYet.
  ///
  /// In en, this message translates to:
  /// **'No favorites yet'**
  String get noFavoritesYet;

  /// No description provided for @addServiceProvidersToFavorites.
  ///
  /// In en, this message translates to:
  /// **'Add service providers to your favorites'**
  String get addServiceProvidersToFavorites;

  /// No description provided for @removedFromFavorites.
  ///
  /// In en, this message translates to:
  /// **'Removed from favorites'**
  String get removedFromFavorites;

  /// No description provided for @generalService.
  ///
  /// In en, this message translates to:
  /// **'General Service'**
  String get generalService;

  /// No description provided for @myChats.
  ///
  /// In en, this message translates to:
  /// **'My Chats'**
  String get myChats;

  /// No description provided for @noChatsYet.
  ///
  /// In en, this message translates to:
  /// **'No chats yet'**
  String get noChatsYet;

  /// No description provided for @bookServiceToChat.
  ///
  /// In en, this message translates to:
  /// **'Book a service to start chatting with providers'**
  String get bookServiceToChat;

  /// No description provided for @authenticationRequired.
  ///
  /// In en, this message translates to:
  /// **'Authentication required'**
  String get authenticationRequired;

  /// No description provided for @failedToLoadChats.
  ///
  /// In en, this message translates to:
  /// **'Failed to load chats'**
  String get failedToLoadChats;

  /// No description provided for @provider.
  ///
  /// In en, this message translates to:
  /// **'Provider'**
  String get provider;

  /// No description provided for @bookingRequestSent.
  ///
  /// In en, this message translates to:
  /// **'Booking request sent - waiting for response'**
  String get bookingRequestSent;

  /// No description provided for @bookingConfirmed.
  ///
  /// In en, this message translates to:
  /// **'Booking confirmed! Start chatting to coordinate'**
  String get bookingConfirmed;

  /// No description provided for @serviceInProgress.
  ///
  /// In en, this message translates to:
  /// **'Service in progress'**
  String get serviceInProgress;

  /// No description provided for @bookingDeclined.
  ///
  /// In en, this message translates to:
  /// **'Booking declined by provider'**
  String get bookingDeclined;

  /// No description provided for @bookingCancelled.
  ///
  /// In en, this message translates to:
  /// **'Booking cancelled'**
  String get bookingCancelled;

  /// No description provided for @tapToStartChatting.
  ///
  /// In en, this message translates to:
  /// **'Tap to start chatting'**
  String get tapToStartChatting;

  /// No description provided for @signInToYourProviderAccount.
  ///
  /// In en, this message translates to:
  /// **'Sign in to your provider account'**
  String get signInToYourProviderAccount;

  /// No description provided for @emailAddress.
  ///
  /// In en, this message translates to:
  /// **'Email address'**
  String get emailAddress;

  /// No description provided for @enterYourEmail.
  ///
  /// In en, this message translates to:
  /// **'Enter your email'**
  String get enterYourEmail;

  /// No description provided for @enterYourPassword.
  ///
  /// In en, this message translates to:
  /// **'Enter your password'**
  String get enterYourPassword;

  /// No description provided for @signIn.
  ///
  /// In en, this message translates to:
  /// **'Sign in'**
  String get signIn;

  /// No description provided for @dontHaveAnAccount.
  ///
  /// In en, this message translates to:
  /// **'Don\'t have an account? '**
  String get dontHaveAnAccount;

  /// No description provided for @signUp.
  ///
  /// In en, this message translates to:
  /// **'Sign up'**
  String get signUp;

  /// No description provided for @exitApp.
  ///
  /// In en, this message translates to:
  /// **'Exit App'**
  String get exitApp;

  /// No description provided for @exit.
  ///
  /// In en, this message translates to:
  /// **'Exit'**
  String get exit;

  /// No description provided for @electrician.
  ///
  /// In en, this message translates to:
  /// **'Electrician'**
  String get electrician;

  /// No description provided for @plumber.
  ///
  /// In en, this message translates to:
  /// **'Plumber'**
  String get plumber;

  /// No description provided for @painter.
  ///
  /// In en, this message translates to:
  /// **'Painter'**
  String get painter;

  /// No description provided for @cleaner.
  ///
  /// In en, this message translates to:
  /// **'Cleaner'**
  String get cleaner;

  /// No description provided for @carpenter.
  ///
  /// In en, this message translates to:
  /// **'Carpenter'**
  String get carpenter;

  /// No description provided for @gardener.
  ///
  /// In en, this message translates to:
  /// **'Gardener'**
  String get gardener;

  /// No description provided for @mechanic.
  ///
  /// In en, this message translates to:
  /// **'Mechanic'**
  String get mechanic;

  /// No description provided for @airConditioningTechnician.
  ///
  /// In en, this message translates to:
  /// **'Air Conditioning Technician'**
  String get airConditioningTechnician;

  /// No description provided for @generalMaintenance.
  ///
  /// In en, this message translates to:
  /// **'General Maintenance'**
  String get generalMaintenance;

  /// No description provided for @housekeeper.
  ///
  /// In en, this message translates to:
  /// **'Housekeeper'**
  String get housekeeper;

  /// No description provided for @serviceProviders.
  ///
  /// In en, this message translates to:
  /// **'Service Providers'**
  String get serviceProviders;

  /// No description provided for @providersIn.
  ///
  /// In en, this message translates to:
  /// **'Providers in {location}'**
  String providersIn(String location);

  /// No description provided for @resultsFor.
  ///
  /// In en, this message translates to:
  /// **'Results for \"{query}\"'**
  String resultsFor(String query);

  /// No description provided for @viewFavorites.
  ///
  /// In en, this message translates to:
  /// **'View Favorites'**
  String get viewFavorites;

  /// No description provided for @clearFilters.
  ///
  /// In en, this message translates to:
  /// **'Clear Filters'**
  String get clearFilters;

  /// No description provided for @refreshList.
  ///
  /// In en, this message translates to:
  /// **'Refresh List'**
  String get refreshList;

  /// No description provided for @createSampleData.
  ///
  /// In en, this message translates to:
  /// **'Create Sample Data'**
  String get createSampleData;

  /// No description provided for @cityLabel.
  ///
  /// In en, this message translates to:
  /// **'City: {city}'**
  String cityLabel(String city);

  /// No description provided for @searchByNameOrService.
  ///
  /// In en, this message translates to:
  /// **'Search by name or service type...'**
  String get searchByNameOrService;

  /// No description provided for @errorLoadingPage.
  ///
  /// In en, this message translates to:
  /// **'Error loading page: {error}'**
  String errorLoadingPage(String error);

  /// No description provided for @errorLoadingProvidersMessage.
  ///
  /// In en, this message translates to:
  /// **'Error loading providers: {error}.\nMake sure your backend server is running and accessible.'**
  String errorLoadingProvidersMessage(String error);

  /// No description provided for @noResultsMatch.
  ///
  /// In en, this message translates to:
  /// **'No results match \"{query}\"'**
  String noResultsMatch(String query);

  /// No description provided for @noProvidersInCategory.
  ///
  /// In en, this message translates to:
  /// **'No providers in {category} category'**
  String noProvidersInCategory(String category);

  /// No description provided for @addSomeViaApi.
  ///
  /// In en, this message translates to:
  /// **'Add some via your API or try refreshing'**
  String get addSomeViaApi;

  /// No description provided for @selectCity.
  ///
  /// In en, this message translates to:
  /// **'Select City'**
  String get selectCity;

  /// No description provided for @clearFilter.
  ///
  /// In en, this message translates to:
  /// **'Clear Filter'**
  String get clearFilter;

  /// No description provided for @sampleDataMode.
  ///
  /// In en, this message translates to:
  /// **'Sample Data Mode'**
  String get sampleDataMode;

  /// No description provided for @sampleDataDescription.
  ///
  /// In en, this message translates to:
  /// **'This will display sample data for testing purposes. The data is not real and not saved.'**
  String get sampleDataDescription;

  /// No description provided for @showSampleData.
  ///
  /// In en, this message translates to:
  /// **'Show Sample Data'**
  String get showSampleData;

  /// No description provided for @addedToFavorites.
  ///
  /// In en, this message translates to:
  /// **'Added to favorites'**
  String get addedToFavorites;

  /// No description provided for @locationNotSpecified.
  ///
  /// In en, this message translates to:
  /// **'Location not specified'**
  String get locationNotSpecified;

  /// No description provided for @previousPage.
  ///
  /// In en, this message translates to:
  /// **'Previous Page'**
  String get previousPage;

  /// No description provided for @nextPage.
  ///
  /// In en, this message translates to:
  /// **'Next Page'**
  String get nextPage;

  /// No description provided for @pageOf.
  ///
  /// In en, this message translates to:
  /// **'Page {current} of {total}'**
  String pageOf(int current, int total);

  /// No description provided for @generalServices.
  ///
  /// In en, this message translates to:
  /// **'General Services'**
  String get generalServices;

  /// No description provided for @selectDateTime.
  ///
  /// In en, this message translates to:
  /// **'Select Date & Time'**
  String get selectDateTime;

  /// No description provided for @serviceLocation.
  ///
  /// In en, this message translates to:
  /// **'Service Location'**
  String get serviceLocation;

  /// No description provided for @additionalNotesOptional.
  ///
  /// In en, this message translates to:
  /// **'Additional Notes (Optional)'**
  String get additionalNotesOptional;

  /// No description provided for @confirmLogout.
  ///
  /// In en, this message translates to:
  /// **'Confirm Logout'**
  String get confirmLogout;

  /// No description provided for @profileUpdatedSuccessfully.
  ///
  /// In en, this message translates to:
  /// **'Profile updated successfully!'**
  String get profileUpdatedSuccessfully;

  /// No description provided for @authenticationError.
  ///
  /// In en, this message translates to:
  /// **'Authentication error. Cannot save profile.'**
  String get authenticationError;

  /// No description provided for @bookingRequestSubmitted.
  ///
  /// In en, this message translates to:
  /// **'Booking request submitted successfully!'**
  String get bookingRequestSubmitted;

  /// No description provided for @errorCreatingBooking.
  ///
  /// In en, this message translates to:
  /// **'Error creating booking'**
  String get errorCreatingBooking;

  /// No description provided for @addPhoto.
  ///
  /// In en, this message translates to:
  /// **'Add Photo'**
  String get addPhoto;

  /// No description provided for @photosSelected.
  ///
  /// In en, this message translates to:
  /// **'photo(s) selected'**
  String get photosSelected;

  /// No description provided for @submitBookingRequest.
  ///
  /// In en, this message translates to:
  /// **'Submit Booking Request'**
  String get submitBookingRequest;

  /// No description provided for @enterServiceLocationDetails.
  ///
  /// In en, this message translates to:
  /// **'Enter service location details'**
  String get enterServiceLocationDetails;

  /// No description provided for @pickLocationOnMap.
  ///
  /// In en, this message translates to:
  /// **'Pick location on map'**
  String get pickLocationOnMap;

  /// No description provided for @anySpecialRequests.
  ///
  /// In en, this message translates to:
  /// **'Any special requests or information?'**
  String get anySpecialRequests;

  /// No description provided for @errorPickingImage.
  ///
  /// In en, this message translates to:
  /// **'Error picking image'**
  String get errorPickingImage;

  /// No description provided for @errorOpeningLocationPicker.
  ///
  /// In en, this message translates to:
  /// **'Error opening location picker'**
  String get errorOpeningLocationPicker;

  /// No description provided for @searchByNameOrServiceType.
  ///
  /// In en, this message translates to:
  /// **'Search by name or service type...'**
  String get searchByNameOrServiceType;

  /// No description provided for @accountSettings.
  ///
  /// In en, this message translates to:
  /// **'Account Settings'**
  String get accountSettings;

  /// No description provided for @locationServices.
  ///
  /// In en, this message translates to:
  /// **'Location Services'**
  String get locationServices;

  /// No description provided for @enterYourFullName.
  ///
  /// In en, this message translates to:
  /// **'Enter your full name'**
  String get enterYourFullName;

  /// No description provided for @pleaseEnterYourName.
  ///
  /// In en, this message translates to:
  /// **'Please enter your name'**
  String get pleaseEnterYourName;

  /// No description provided for @enterYourPhoneNumber.
  ///
  /// In en, this message translates to:
  /// **'Enter your phone number'**
  String get enterYourPhoneNumber;

  /// No description provided for @imageUploadNotSupported.
  ///
  /// In en, this message translates to:
  /// **'Image upload is not supported in web mode. Please use the mobile app.'**
  String get imageUploadNotSupported;

  /// No description provided for @authenticationErrorCannotUpload.
  ///
  /// In en, this message translates to:
  /// **'Authentication error. Cannot upload image.'**
  String get authenticationErrorCannotUpload;

  /// No description provided for @profilePictureUploadedSuccessfully.
  ///
  /// In en, this message translates to:
  /// **'Profile picture uploaded successfully!'**
  String get profilePictureUploadedSuccessfully;

  /// No description provided for @failedToUploadProfilePicture.
  ///
  /// In en, this message translates to:
  /// **'Failed to upload profile picture'**
  String get failedToUploadProfilePicture;

  /// No description provided for @areYouSureLogout.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to log out?'**
  String get areYouSureLogout;

  /// No description provided for @noPhoneNumber.
  ///
  /// In en, this message translates to:
  /// **'No phone number'**
  String get noPhoneNumber;

  /// No description provided for @couldNotLoadUserProfile.
  ///
  /// In en, this message translates to:
  /// **'Could not load user profile.'**
  String get couldNotLoadUserProfile;

  /// No description provided for @errorLoadingProfile.
  ///
  /// In en, this message translates to:
  /// **'Error loading profile'**
  String get errorLoadingProfile;

  /// No description provided for @authenticationTokenNotFound.
  ///
  /// In en, this message translates to:
  /// **'Authentication token not found. Please log in.'**
  String get authenticationTokenNotFound;

  /// No description provided for @authenticationErrorCannotSave.
  ///
  /// In en, this message translates to:
  /// **'Authentication error. Cannot save profile.'**
  String get authenticationErrorCannotSave;

  /// No description provided for @failedToUpdateProfile.
  ///
  /// In en, this message translates to:
  /// **'Failed to update profile'**
  String get failedToUpdateProfile;

  /// No description provided for @imageUploadNotSupportedWeb.
  ///
  /// In en, this message translates to:
  /// **'Image upload is not supported in web mode. Please use the mobile app.'**
  String get imageUploadNotSupportedWeb;

  /// No description provided for @errorPickingImageProfile.
  ///
  /// In en, this message translates to:
  /// **'Error picking image'**
  String get errorPickingImageProfile;

  /// No description provided for @authenticationErrorPleaseLogin.
  ///
  /// In en, this message translates to:
  /// **'Authentication error. Please login again.'**
  String get authenticationErrorPleaseLogin;

  /// No description provided for @user.
  ///
  /// In en, this message translates to:
  /// **'User'**
  String get user;

  /// No description provided for @serviceDetails.
  ///
  /// In en, this message translates to:
  /// **'Service Details'**
  String get serviceDetails;

  /// No description provided for @description.
  ///
  /// In en, this message translates to:
  /// **'Description'**
  String get description;

  /// No description provided for @noDescriptionProvided.
  ///
  /// In en, this message translates to:
  /// **'No description provided.'**
  String get noDescriptionProvided;

  /// No description provided for @locationAndContact.
  ///
  /// In en, this message translates to:
  /// **'Location & Contact'**
  String get locationAndContact;

  /// No description provided for @notSpecified.
  ///
  /// In en, this message translates to:
  /// **'Not specified'**
  String get notSpecified;

  /// No description provided for @phone.
  ///
  /// In en, this message translates to:
  /// **'Phone'**
  String get phone;

  /// No description provided for @ratingsText.
  ///
  /// In en, this message translates to:
  /// **'ratings'**
  String get ratingsText;

  /// No description provided for @noRatingsYet.
  ///
  /// In en, this message translates to:
  /// **'No ratings yet'**
  String get noRatingsYet;

  /// No description provided for @deleteAccount.
  ///
  /// In en, this message translates to:
  /// **'Delete Account'**
  String get deleteAccount;

  /// No description provided for @deleteAccountConfirmation.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to delete your account?'**
  String get deleteAccountConfirmation;

  /// No description provided for @deleteAccountWarning.
  ///
  /// In en, this message translates to:
  /// **'This action cannot be undone. All your data will be permanently deleted.'**
  String get deleteAccountWarning;

  /// No description provided for @accountDeleted.
  ///
  /// In en, this message translates to:
  /// **'Account deleted successfully'**
  String get accountDeleted;

  /// No description provided for @failedToDeleteAccount.
  ///
  /// In en, this message translates to:
  /// **'Failed to delete account'**
  String get failedToDeleteAccount;

  /// No description provided for @couldNotLoadProfile.
  ///
  /// In en, this message translates to:
  /// **'Could not load user profile.'**
  String get couldNotLoadProfile;

  /// No description provided for @deletingAccount.
  ///
  /// In en, this message translates to:
  /// **'Deleting account...'**
  String get deletingAccount;

  /// No description provided for @languageChanged.
  ///
  /// In en, this message translates to:
  /// **'Language changed successfully'**
  String get languageChanged;

  /// No description provided for @refresh.
  ///
  /// In en, this message translates to:
  /// **'Refresh'**
  String get refresh;

  /// No description provided for @authenticationTokenMissing.
  ///
  /// In en, this message translates to:
  /// **'Authentication token missing'**
  String get authenticationTokenMissing;

  /// No description provided for @failedToLoadConversations.
  ///
  /// In en, this message translates to:
  /// **'Failed to load conversations'**
  String get failedToLoadConversations;

  /// No description provided for @errorUploadingProfilePicture.
  ///
  /// In en, this message translates to:
  /// **'Error uploading profile picture'**
  String get errorUploadingProfilePicture;

  /// No description provided for @errorUpdatingProfile.
  ///
  /// In en, this message translates to:
  /// **'Error updating profile'**
  String get errorUpdatingProfile;

  /// No description provided for @failedToOpenNavigation.
  ///
  /// In en, this message translates to:
  /// **'Failed to open navigation'**
  String get failedToOpenNavigation;

  /// No description provided for @bookingStatusUpdatedTo.
  ///
  /// In en, this message translates to:
  /// **'Booking status updated to {status}'**
  String bookingStatusUpdatedTo(String status);

  /// No description provided for @errorUpdatingBookingStatus.
  ///
  /// In en, this message translates to:
  /// **'Error updating booking status'**
  String get errorUpdatingBookingStatus;

  /// No description provided for @editProfileAuthenticationError.
  ///
  /// In en, this message translates to:
  /// **'Authentication error. Please login again.'**
  String get editProfileAuthenticationError;

  /// No description provided for @editProfileErrorLoading.
  ///
  /// In en, this message translates to:
  /// **'Error loading profile: {error}'**
  String editProfileErrorLoading(String error);

  /// No description provided for @editProfileImageUploadWebNotSupported.
  ///
  /// In en, this message translates to:
  /// **'Image upload is not supported on web. Please use the mobile app.'**
  String get editProfileImageUploadWebNotSupported;

  /// No description provided for @editProfileErrorPickingImage.
  ///
  /// In en, this message translates to:
  /// **'Error picking image: {error}'**
  String editProfileErrorPickingImage(String error);

  /// No description provided for @editProfileCameraWebNotSupported.
  ///
  /// In en, this message translates to:
  /// **'Camera is not supported on web. Please use the mobile app.'**
  String get editProfileCameraWebNotSupported;

  /// No description provided for @editProfileErrorTakingPhoto.
  ///
  /// In en, this message translates to:
  /// **'Error taking photo: {error}'**
  String editProfileErrorTakingPhoto(String error);

  /// No description provided for @editProfileBusinessProfile.
  ///
  /// In en, this message translates to:
  /// **'Business Profile'**
  String get editProfileBusinessProfile;

  /// No description provided for @editProfileUpdateBusinessInfo.
  ///
  /// In en, this message translates to:
  /// **'Update your business information and photo'**
  String get editProfileUpdateBusinessInfo;

  /// No description provided for @editProfileUploadPhoto.
  ///
  /// In en, this message translates to:
  /// **'Upload Photo'**
  String get editProfileUploadPhoto;

  /// No description provided for @editProfileBusinessName.
  ///
  /// In en, this message translates to:
  /// **'Business Name'**
  String get editProfileBusinessName;

  /// No description provided for @editProfileBusinessNameRequired.
  ///
  /// In en, this message translates to:
  /// **'Business name is required'**
  String get editProfileBusinessNameRequired;

  /// No description provided for @editProfileDescription.
  ///
  /// In en, this message translates to:
  /// **'Description'**
  String get editProfileDescription;

  /// No description provided for @editProfileDescriptionRequired.
  ///
  /// In en, this message translates to:
  /// **'Description is required'**
  String get editProfileDescriptionRequired;

  /// No description provided for @editProfileServices.
  ///
  /// In en, this message translates to:
  /// **'Services (comma separated)'**
  String get editProfileServices;

  /// No description provided for @editProfileServicesRequired.
  ///
  /// In en, this message translates to:
  /// **'Services are required'**
  String get editProfileServicesRequired;

  /// No description provided for @editProfileHourlyRate.
  ///
  /// In en, this message translates to:
  /// **'Hourly Rate (\$)'**
  String get editProfileHourlyRate;

  /// No description provided for @editProfileHourlyRateRequired.
  ///
  /// In en, this message translates to:
  /// **'Hourly rate is required'**
  String get editProfileHourlyRateRequired;

  /// No description provided for @editProfileEnterValidNumber.
  ///
  /// In en, this message translates to:
  /// **'Please enter a valid number'**
  String get editProfileEnterValidNumber;

  /// No description provided for @editProfilePhoneNumber.
  ///
  /// In en, this message translates to:
  /// **'Phone Number'**
  String get editProfilePhoneNumber;

  /// No description provided for @editProfilePhoneRequired.
  ///
  /// In en, this message translates to:
  /// **'Phone number is required'**
  String get editProfilePhoneRequired;

  /// No description provided for @editProfileAddress.
  ///
  /// In en, this message translates to:
  /// **'Address'**
  String get editProfileAddress;

  /// No description provided for @editProfileAddressRequired.
  ///
  /// In en, this message translates to:
  /// **'Address is required'**
  String get editProfileAddressRequired;

  /// No description provided for @editProfileSaveChanges.
  ///
  /// In en, this message translates to:
  /// **'Save Changes'**
  String get editProfileSaveChanges;

  /// No description provided for @nowAvailable.
  ///
  /// In en, this message translates to:
  /// **'You are now available for bookings'**
  String get nowAvailable;

  /// No description provided for @nowUnavailable.
  ///
  /// In en, this message translates to:
  /// **'You are now unavailable for bookings'**
  String get nowUnavailable;

  /// No description provided for @availabilityStatus.
  ///
  /// In en, this message translates to:
  /// **'Availability Status'**
  String get availabilityStatus;

  /// No description provided for @availableForBookings.
  ///
  /// In en, this message translates to:
  /// **'You are available for new bookings'**
  String get availableForBookings;

  /// No description provided for @currentlyUnavailable.
  ///
  /// In en, this message translates to:
  /// **'You are currently unavailable'**
  String get currentlyUnavailable;

  /// No description provided for @providerBookingsTitle.
  ///
  /// In en, this message translates to:
  /// **'Manage Bookings'**
  String get providerBookingsTitle;

  /// No description provided for @allBookings.
  ///
  /// In en, this message translates to:
  /// **'All Bookings'**
  String get allBookings;

  /// No description provided for @pendingBookings.
  ///
  /// In en, this message translates to:
  /// **'Pending'**
  String get pendingBookings;

  /// No description provided for @acceptedBookings.
  ///
  /// In en, this message translates to:
  /// **'Accepted'**
  String get acceptedBookings;

  /// No description provided for @inProgressBookings.
  ///
  /// In en, this message translates to:
  /// **'In Progress'**
  String get inProgressBookings;

  /// No description provided for @completedBookings.
  ///
  /// In en, this message translates to:
  /// **'Completed'**
  String get completedBookings;

  /// No description provided for @cancelledBookings.
  ///
  /// In en, this message translates to:
  /// **'Cancelled'**
  String get cancelledBookings;

  /// No description provided for @rejectedBookings.
  ///
  /// In en, this message translates to:
  /// **'Rejected'**
  String get rejectedBookings;

  /// No description provided for @noBookingsMessage.
  ///
  /// In en, this message translates to:
  /// **'No bookings found for this filter'**
  String get noBookingsMessage;

  /// No description provided for @loadingBookings.
  ///
  /// In en, this message translates to:
  /// **'Loading bookings...'**
  String get loadingBookings;

  /// No description provided for @refreshBookings.
  ///
  /// In en, this message translates to:
  /// **'Refresh Bookings'**
  String get refreshBookings;

  /// No description provided for @newBookingsReceived.
  ///
  /// In en, this message translates to:
  /// **'{count} new booking(s) received!'**
  String newBookingsReceived(int count);

  /// No description provided for @bookingFrom.
  ///
  /// In en, this message translates to:
  /// **'Booking from'**
  String get bookingFrom;

  /// No description provided for @requestedOn.
  ///
  /// In en, this message translates to:
  /// **'Requested on'**
  String get requestedOn;

  /// No description provided for @scheduledFor.
  ///
  /// In en, this message translates to:
  /// **'Scheduled for'**
  String get scheduledFor;

  /// No description provided for @estimatedDuration.
  ///
  /// In en, this message translates to:
  /// **'Estimated Duration'**
  String get estimatedDuration;

  /// No description provided for @totalAmount.
  ///
  /// In en, this message translates to:
  /// **'Total Amount'**
  String get totalAmount;

  /// No description provided for @rejectBooking.
  ///
  /// In en, this message translates to:
  /// **'Reject Booking'**
  String get rejectBooking;

  /// No description provided for @markInProgress.
  ///
  /// In en, this message translates to:
  /// **'Start Work'**
  String get markInProgress;

  /// No description provided for @markCompleted.
  ///
  /// In en, this message translates to:
  /// **'Complete Work'**
  String get markCompleted;

  /// No description provided for @bookingAccepted.
  ///
  /// In en, this message translates to:
  /// **'Booking accepted'**
  String get bookingAccepted;

  /// No description provided for @bookingRejected.
  ///
  /// In en, this message translates to:
  /// **'Booking rejected'**
  String get bookingRejected;

  /// No description provided for @bookingMarkedInProgress.
  ///
  /// In en, this message translates to:
  /// **'Work started'**
  String get bookingMarkedInProgress;

  /// No description provided for @bookingMarkedCompleted.
  ///
  /// In en, this message translates to:
  /// **'Work completed'**
  String get bookingMarkedCompleted;

  /// No description provided for @errorUpdatingBooking.
  ///
  /// In en, this message translates to:
  /// **'Error updating booking'**
  String get errorUpdatingBooking;

  /// No description provided for @loadMore.
  ///
  /// In en, this message translates to:
  /// **'Load More'**
  String get loadMore;

  /// No description provided for @noMoreBookings.
  ///
  /// In en, this message translates to:
  /// **'No more bookings'**
  String get noMoreBookings;

  /// No description provided for @providerMessagesTitle.
  ///
  /// In en, this message translates to:
  /// **'Messages'**
  String get providerMessagesTitle;

  /// No description provided for @conversations.
  ///
  /// In en, this message translates to:
  /// **'Conversations'**
  String get conversations;

  /// No description provided for @noConversationsFound.
  ///
  /// In en, this message translates to:
  /// **'No conversations found'**
  String get noConversationsFound;

  /// No description provided for @noConversationsMessage.
  ///
  /// In en, this message translates to:
  /// **'No conversations started yet. Customer messages will appear here.'**
  String get noConversationsMessage;

  /// No description provided for @loadingConversations.
  ///
  /// In en, this message translates to:
  /// **'Loading conversations...'**
  String get loadingConversations;

  /// No description provided for @errorLoadingConversations.
  ///
  /// In en, this message translates to:
  /// **'Error loading conversations'**
  String get errorLoadingConversations;

  /// No description provided for @lastMessage.
  ///
  /// In en, this message translates to:
  /// **'Last message'**
  String get lastMessage;

  /// No description provided for @newMessage.
  ///
  /// In en, this message translates to:
  /// **'New message'**
  String get newMessage;

  /// No description provided for @unreadMessages.
  ///
  /// In en, this message translates to:
  /// **'Unread messages'**
  String get unreadMessages;

  /// No description provided for @openChat.
  ///
  /// In en, this message translates to:
  /// **'Open Chat'**
  String get openChat;

  /// No description provided for @messagePreview.
  ///
  /// In en, this message translates to:
  /// **'Message preview'**
  String get messagePreview;

  /// No description provided for @editProviderProfileTitle.
  ///
  /// In en, this message translates to:
  /// **'Edit Profile'**
  String get editProviderProfileTitle;

  /// No description provided for @businessProfile.
  ///
  /// In en, this message translates to:
  /// **'Business Profile'**
  String get businessProfile;

  /// No description provided for @updateBusinessInfo.
  ///
  /// In en, this message translates to:
  /// **'Update your business information and photo'**
  String get updateBusinessInfo;

  /// No description provided for @uploadPhoto.
  ///
  /// In en, this message translates to:
  /// **'Upload Photo'**
  String get uploadPhoto;

  /// No description provided for @businessName.
  ///
  /// In en, this message translates to:
  /// **'Business Name'**
  String get businessName;

  /// No description provided for @businessNameRequired.
  ///
  /// In en, this message translates to:
  /// **'Business name is required'**
  String get businessNameRequired;

  /// No description provided for @descriptionRequired.
  ///
  /// In en, this message translates to:
  /// **'Description is required'**
  String get descriptionRequired;

  /// No description provided for @servicesRequired.
  ///
  /// In en, this message translates to:
  /// **'Services are required'**
  String get servicesRequired;

  /// No description provided for @enterValidNumber.
  ///
  /// In en, this message translates to:
  /// **'Please enter a valid number'**
  String get enterValidNumber;

  /// No description provided for @phoneRequired.
  ///
  /// In en, this message translates to:
  /// **'Phone number is required'**
  String get phoneRequired;

  /// No description provided for @addressRequired.
  ///
  /// In en, this message translates to:
  /// **'Address is required'**
  String get addressRequired;

  /// No description provided for @saveChanges.
  ///
  /// In en, this message translates to:
  /// **'Save Changes'**
  String get saveChanges;

  /// No description provided for @imageUploadWebNotSupported.
  ///
  /// In en, this message translates to:
  /// **'Image upload is not supported on web. Please use the mobile app.'**
  String get imageUploadWebNotSupported;

  /// No description provided for @cameraWebNotSupported.
  ///
  /// In en, this message translates to:
  /// **'Camera is not supported on web. Please use the mobile app.'**
  String get cameraWebNotSupported;

  /// No description provided for @errorTakingPhoto.
  ///
  /// In en, this message translates to:
  /// **'Error taking photo'**
  String get errorTakingPhoto;

  /// No description provided for @openInGoogleMaps.
  ///
  /// In en, this message translates to:
  /// **'Open in Google Maps'**
  String get openInGoogleMaps;

  /// No description provided for @accept.
  ///
  /// In en, this message translates to:
  /// **'Accept'**
  String get accept;

  /// No description provided for @decline.
  ///
  /// In en, this message translates to:
  /// **'Decline'**
  String get decline;

  /// No description provided for @errorLoadingBookingDetails.
  ///
  /// In en, this message translates to:
  /// **'Error loading booking details'**
  String get errorLoadingBookingDetails;

  /// No description provided for @providerInformationNotAvailable.
  ///
  /// In en, this message translates to:
  /// **'Provider information not available'**
  String get providerInformationNotAvailable;

  /// No description provided for @pleaseSelectRating.
  ///
  /// In en, this message translates to:
  /// **'Please select a rating'**
  String get pleaseSelectRating;

  /// No description provided for @ratingSubmittedSuccessfully.
  ///
  /// In en, this message translates to:
  /// **'Rating submitted successfully'**
  String get ratingSubmittedSuccessfully;

  /// No description provided for @errorSubmittingRating.
  ///
  /// In en, this message translates to:
  /// **'Error submitting rating'**
  String get errorSubmittingRating;

  /// No description provided for @confirmAction.
  ///
  /// In en, this message translates to:
  /// **'Confirm {action}'**
  String confirmAction(String action);

  /// No description provided for @areYouSureActionBooking.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to {action} this booking?'**
  String areYouSureActionBooking(String action);

  /// No description provided for @bookingActionSuccessfully.
  ///
  /// In en, this message translates to:
  /// **'Booking {action} successfully.'**
  String bookingActionSuccessfully(String action);

  /// No description provided for @markedAsInProgress.
  ///
  /// In en, this message translates to:
  /// **'marked as in progress'**
  String get markedAsInProgress;

  /// No description provided for @markedAsCompleted.
  ///
  /// In en, this message translates to:
  /// **'marked as completed'**
  String get markedAsCompleted;

  /// No description provided for @updated.
  ///
  /// In en, this message translates to:
  /// **'updated'**
  String get updated;

  /// No description provided for @cancelledByUser.
  ///
  /// In en, this message translates to:
  /// **'Cancelled by User'**
  String get cancelledByUser;

  /// No description provided for @cancelledByProvider.
  ///
  /// In en, this message translates to:
  /// **'Cancelled by Provider'**
  String get cancelledByProvider;

  /// No description provided for @declinedByProvider.
  ///
  /// In en, this message translates to:
  /// **'Declined by Provider'**
  String get declinedByProvider;

  /// No description provided for @providerStatusUpdatedTo.
  ///
  /// In en, this message translates to:
  /// **'Provider status updated to'**
  String get providerStatusUpdatedTo;

  /// No description provided for @selectLocation.
  ///
  /// In en, this message translates to:
  /// **'Select Location'**
  String get selectLocation;

  /// No description provided for @locationPickerTitle.
  ///
  /// In en, this message translates to:
  /// **'Choose Your Location'**
  String get locationPickerTitle;

  /// No description provided for @locationPickerSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Tap on the map to set your exact location'**
  String get locationPickerSubtitle;

  /// No description provided for @currentLocation.
  ///
  /// In en, this message translates to:
  /// **'Current Location'**
  String get currentLocation;

  /// No description provided for @searchLocation.
  ///
  /// In en, this message translates to:
  /// **'Search for a location'**
  String get searchLocation;

  /// No description provided for @locationSelected.
  ///
  /// In en, this message translates to:
  /// **'Location selected successfully'**
  String get locationSelected;

  /// No description provided for @locationError.
  ///
  /// In en, this message translates to:
  /// **'Error getting location'**
  String get locationError;
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
      <String>['ar', 'en'].contains(locale.languageCode);

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
  }

  throw FlutterError(
      'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
      'an issue with the localizations generation tool. Please file an issue '
      'on GitHub with a reproducible sample app and the gen-l10n configuration '
      'that was used.');
}

import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_hi.dart';

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
    Locale('en'),
    Locale('hi'),
  ];

  /// The title of the application
  ///
  /// In en, this message translates to:
  /// **'Karmasu'**
  String get appTitle;

  /// Welcome message for returning users
  ///
  /// In en, this message translates to:
  /// **'Welcome back'**
  String get welcomeBack;

  /// Message for new user registration
  ///
  /// In en, this message translates to:
  /// **'Create your account'**
  String get createAccount;

  /// Label for full name input field
  ///
  /// In en, this message translates to:
  /// **'Full Name'**
  String get fullName;

  /// Label for email input field
  ///
  /// In en, this message translates to:
  /// **'Email'**
  String get email;

  /// Label for phone number input field
  ///
  /// In en, this message translates to:
  /// **'Phone Number'**
  String get phoneNumber;

  /// Label for password input field
  ///
  /// In en, this message translates to:
  /// **'Password'**
  String get password;

  /// Label for confirm password input field
  ///
  /// In en, this message translates to:
  /// **'Confirm Password'**
  String get confirmPassword;

  /// Sign in button text
  ///
  /// In en, this message translates to:
  /// **'Sign In'**
  String get signIn;

  /// Sign up button text
  ///
  /// In en, this message translates to:
  /// **'Sign Up'**
  String get signUp;

  /// Text for existing users
  ///
  /// In en, this message translates to:
  /// **'Already have an account? '**
  String get alreadyHaveAccount;

  /// Text for new users
  ///
  /// In en, this message translates to:
  /// **'Don\'t have an account? '**
  String get dontHaveAccount;

  /// Validation message for name field
  ///
  /// In en, this message translates to:
  /// **'Name is required'**
  String get nameRequired;

  /// Validation message for name minimum length
  ///
  /// In en, this message translates to:
  /// **'Name must be at least 2 characters'**
  String get nameMinLength;

  /// Validation message for email field
  ///
  /// In en, this message translates to:
  /// **'Email is required'**
  String get emailRequired;

  /// Validation message for invalid email
  ///
  /// In en, this message translates to:
  /// **'Please enter a valid email'**
  String get emailInvalid;

  /// Validation message for phone field
  ///
  /// In en, this message translates to:
  /// **'Phone number is required'**
  String get phoneRequired;

  /// Validation message for invalid phone
  ///
  /// In en, this message translates to:
  /// **'Please enter a valid phone number'**
  String get phoneInvalid;

  /// Validation message for password field
  ///
  /// In en, this message translates to:
  /// **'Password is required'**
  String get passwordRequired;

  /// Validation message for password minimum length
  ///
  /// In en, this message translates to:
  /// **'Password must be at least 6 characters'**
  String get passwordMinLength;

  /// Validation message for confirm password field
  ///
  /// In en, this message translates to:
  /// **'Please confirm your password'**
  String get confirmPasswordRequired;

  /// Validation message for password mismatch
  ///
  /// In en, this message translates to:
  /// **'Passwords do not match'**
  String get passwordsDoNotMatch;

  /// Success message for account creation
  ///
  /// In en, this message translates to:
  /// **'Account created successfully! Welcome to Karmasu.'**
  String get accountCreatedSuccess;

  /// Success message for sign in
  ///
  /// In en, this message translates to:
  /// **'Signed in successfully!'**
  String get signedInSuccess;

  /// No description provided for @errorSaving.
  ///
  /// In en, this message translates to:
  /// **'Error saving'**
  String get errorSaving;

  /// No description provided for @writeRamRamHere.
  ///
  /// In en, this message translates to:
  /// **'Write Ram Ram here...'**
  String get writeRamRamHere;

  /// No description provided for @writingSavedFor.
  ///
  /// In en, this message translates to:
  /// **'Writing saved for {deityName}'**
  String writingSavedFor(String deityName);

  /// Generic error message
  ///
  /// In en, this message translates to:
  /// **'Error: {errorMessage}'**
  String error(String errorMessage);

  /// Home tab label
  ///
  /// In en, this message translates to:
  /// **'Home'**
  String get home;

  /// Explore tab label
  ///
  /// In en, this message translates to:
  /// **'Explore'**
  String get explore;

  /// Quiz tab label
  ///
  /// In en, this message translates to:
  /// **'Quiz'**
  String get quiz;

  /// Sadhna tab label
  ///
  /// In en, this message translates to:
  /// **'Sadhna'**
  String get sadhna;

  /// Profile tab label
  ///
  /// In en, this message translates to:
  /// **'Profile'**
  String get profile;

  /// Pooja Sadhna feature title
  ///
  /// In en, this message translates to:
  /// **'Pooja Sadhna'**
  String get poojaSadhna;

  /// Naam japa feature title
  ///
  /// In en, this message translates to:
  /// **'Naam japa'**
  String get ramnamLekhan;

  /// Astrologer feature title
  ///
  /// In en, this message translates to:
  /// **'Astrologer'**
  String get astrologer;

  /// More features title
  ///
  /// In en, this message translates to:
  /// **'More Features'**
  String get moreFeatures;

  /// Explore screen placeholder text
  ///
  /// In en, this message translates to:
  /// **'Spiritual Services'**
  String get exploreScreen;

  /// Quiz screen placeholder text
  ///
  /// In en, this message translates to:
  /// **'Quiz Zone - Coming Soon!'**
  String get quizZone;

  /// Sadhna screen placeholder text
  ///
  /// In en, this message translates to:
  /// **'Sadhna Tracker - Coming Soon!'**
  String get sadhnaTracker;

  /// My courses option in profile
  ///
  /// In en, this message translates to:
  /// **'My Courses'**
  String get myCourses;

  /// My bookings option in profile
  ///
  /// In en, this message translates to:
  /// **'My Bookings'**
  String get myBookings;

  /// Jaap history option in profile
  ///
  /// In en, this message translates to:
  /// **'Jaap History'**
  String get jaapHistory;

  /// Karmic score option in profile
  ///
  /// In en, this message translates to:
  /// **'Karmic Score'**
  String get karmicScore;

  /// Settings option in profile
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settings;

  /// Support option in profile
  ///
  /// In en, this message translates to:
  /// **'Support'**
  String get support;

  /// Language option in profile
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get language;

  /// English language option
  ///
  /// In en, this message translates to:
  /// **'English'**
  String get english;

  /// Hindi language option
  ///
  /// In en, this message translates to:
  /// **'हिंदी'**
  String get hindi;

  /// Default text when phone is not provided
  ///
  /// In en, this message translates to:
  /// **'Phone: Not provided'**
  String get phoneNotProvided;

  /// Daily Panchang section title
  ///
  /// In en, this message translates to:
  /// **'Daily Panchang'**
  String get dailyPanchang;

  /// Today's date label
  ///
  /// In en, this message translates to:
  /// **'Today\'s Date'**
  String get todayDate;

  /// Tithi label
  ///
  /// In en, this message translates to:
  /// **'Tithi'**
  String get tithi;

  /// Nakshatra label
  ///
  /// In en, this message translates to:
  /// **'Nakshatra'**
  String get nakshatra;

  /// Yoga label
  ///
  /// In en, this message translates to:
  /// **'Yoga'**
  String get yoga;

  /// Karana label
  ///
  /// In en, this message translates to:
  /// **'Karana'**
  String get karana;

  /// Sunrise time label
  ///
  /// In en, this message translates to:
  /// **'Sunrise'**
  String get sunrise;

  /// Sunset time label
  ///
  /// In en, this message translates to:
  /// **'Sunset'**
  String get sunset;

  /// Upcoming festival banner title
  ///
  /// In en, this message translates to:
  /// **'Upcoming Festival'**
  String get upcomingFestival;

  /// Featured highlights section title
  ///
  /// In en, this message translates to:
  /// **'Featured Highlights'**
  String get featuredHighlights;

  /// Courses feature title
  ///
  /// In en, this message translates to:
  /// **'Courses'**
  String get courses;

  /// Book Puja feature title
  ///
  /// In en, this message translates to:
  /// **'Book Puja'**
  String get bookPuja;

  /// Ask Guruji feature title
  ///
  /// In en, this message translates to:
  /// **'Ask Guruji'**
  String get askGuruji;

  /// Dharma Store feature title
  ///
  /// In en, this message translates to:
  /// **'Dharma Store'**
  String get dharmaStore;

  /// View all button text
  ///
  /// In en, this message translates to:
  /// **'View All'**
  String get viewAll;

  /// Admin panel title
  ///
  /// In en, this message translates to:
  /// **'Admin Panel'**
  String get adminPanel;

  /// Manage daily panchang option
  ///
  /// In en, this message translates to:
  /// **'Manage Daily Panchang'**
  String get manageDailyPanchang;

  /// Manage courses option
  ///
  /// In en, this message translates to:
  /// **'Manage Courses'**
  String get manageCourses;

  /// Manage pooja bookings option
  ///
  /// In en, this message translates to:
  /// **'Manage Pooja Bookings'**
  String get managePoojaBookings;

  /// Manage e-bookings option
  ///
  /// In en, this message translates to:
  /// **'Manage E-Bookings'**
  String get manageEBookings;

  /// Manage pandits option
  ///
  /// In en, this message translates to:
  /// **'Manage Pandits'**
  String get managePandits;

  /// Manage astrologers option
  ///
  /// In en, this message translates to:
  /// **'Manage Astrologers'**
  String get manageAstrologers;

  /// Add new button text
  ///
  /// In en, this message translates to:
  /// **'Add New'**
  String get addNew;

  /// Edit button text
  ///
  /// In en, this message translates to:
  /// **'Edit'**
  String get edit;

  /// Delete button text
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get delete;

  /// Save button text in English
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get save;

  /// Cancel button text
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancel;

  /// Durga Ji deity name
  ///
  /// In en, this message translates to:
  /// **'Durga Ji'**
  String get durgaJi;

  /// Ganesha Ji deity name
  ///
  /// In en, this message translates to:
  /// **'Ganesha Ji'**
  String get ganeshaJi;

  /// Hanuman Ji deity name
  ///
  /// In en, this message translates to:
  /// **'Hanuman Ji'**
  String get hanumanJi;

  /// Krishna Ji deity name
  ///
  /// In en, this message translates to:
  /// **'Krishna Ji'**
  String get krishnaJi;

  /// Lakshmi Ji deity name
  ///
  /// In en, this message translates to:
  /// **'Lakshmi Ji'**
  String get lakshmiJi;

  /// Narasimha Ji deity name
  ///
  /// In en, this message translates to:
  /// **'Narasimha Ji'**
  String get narasimhaJi;

  /// Parvati Ji deity name
  ///
  /// In en, this message translates to:
  /// **'Parvati Ji'**
  String get parvatiJi;

  /// Radha Ji deity name
  ///
  /// In en, this message translates to:
  /// **'Radha Ji'**
  String get radhaJi;

  /// Ram Ji deity name
  ///
  /// In en, this message translates to:
  /// **'Ram Ji'**
  String get ramJi;

  /// Saraswati Ji deity name
  ///
  /// In en, this message translates to:
  /// **'Saraswati Ji'**
  String get saraswatiJi;

  /// Shani Ji deity name
  ///
  /// In en, this message translates to:
  /// **'Shani Ji'**
  String get shaniJi;

  /// Shiv Ji deity name
  ///
  /// In en, this message translates to:
  /// **'Shiv Ji'**
  String get shivJi;

  /// Sita Ji deity name
  ///
  /// In en, this message translates to:
  /// **'Sita Ji'**
  String get sitaJi;

  /// Vishnu Ji deity name
  ///
  /// In en, this message translates to:
  /// **'Vishnu Ji'**
  String get vishnuJi;

  /// Search placeholder for deities
  ///
  /// In en, this message translates to:
  /// **'Search Deities'**
  String get searchDeities;

  /// Favorites section title
  ///
  /// In en, this message translates to:
  /// **'Favorites'**
  String get favorites;

  /// Daily targets section title
  ///
  /// In en, this message translates to:
  /// **'Daily Targets'**
  String get dailyTargets;

  /// Set target button text
  ///
  /// In en, this message translates to:
  /// **'Set Target'**
  String get setTarget;

  /// Current streak label
  ///
  /// In en, this message translates to:
  /// **'Current Streak'**
  String get currentStreak;

  /// Longest streak label
  ///
  /// In en, this message translates to:
  /// **'Longest Streak'**
  String get longestStreak;

  /// Today's progress label
  ///
  /// In en, this message translates to:
  /// **'Today\'s Progress'**
  String get todayProgress;

  /// Target met message
  ///
  /// In en, this message translates to:
  /// **'Target Met!'**
  String get targetMet;

  /// Target not met message
  ///
  /// In en, this message translates to:
  /// **'Target Not Met'**
  String get targetNotMet;

  /// Leaderboard section title
  ///
  /// In en, this message translates to:
  /// **'Leaderboard'**
  String get leaderboard;

  /// Daily ranking title
  ///
  /// In en, this message translates to:
  /// **'Daily Ranking'**
  String get dailyRanking;

  /// Your rank label
  ///
  /// In en, this message translates to:
  /// **'Your Rank'**
  String get yourRank;

  /// Total japa count label
  ///
  /// In en, this message translates to:
  /// **'Total Japa'**
  String get totalJapa;

  /// Participants count label
  ///
  /// In en, this message translates to:
  /// **'Participants'**
  String get participants;

  /// Refresh button text
  ///
  /// In en, this message translates to:
  /// **'Refresh'**
  String get refresh;

  /// Japa count label
  ///
  /// In en, this message translates to:
  /// **'Japa Count'**
  String get japaCount;

  /// Days label in English
  ///
  /// In en, this message translates to:
  /// **'Days'**
  String get days;

  /// Streak label
  ///
  /// In en, this message translates to:
  /// **'Streak'**
  String get streak;

  /// Naam japa title in English
  ///
  /// In en, this message translates to:
  /// **'Naam japa'**
  String get ramRamLekhan;

  /// Subtitle for deity selection in English
  ///
  /// In en, this message translates to:
  /// **'Select your preferred deity'**
  String get selectPreferredDeity;

  /// Search placeholder text in English
  ///
  /// In en, this message translates to:
  /// **'Search deities...'**
  String get searchDeitiesPlaceholder;

  /// No search results message in English
  ///
  /// In en, this message translates to:
  /// **'No deities found'**
  String get noDeitiesFound;

  /// Search suggestion message in English
  ///
  /// In en, this message translates to:
  /// **'Try changing your search terms'**
  String get tryChangingSearchTerms;

  /// Words label in English
  ///
  /// In en, this message translates to:
  /// **'Words'**
  String get words;

  /// Time label in English
  ///
  /// In en, this message translates to:
  /// **'Time'**
  String get time;

  /// Clear button text in English
  ///
  /// In en, this message translates to:
  /// **'Clear'**
  String get clear;

  /// Sadhna card title
  ///
  /// In en, this message translates to:
  /// **'Sadhna'**
  String get sadhnaTitle;

  /// Sadhna card subtitle
  ///
  /// In en, this message translates to:
  /// **'Daily naam japa for peace'**
  String get sadhnaSubtitle;

  /// Puja/Paath card title
  ///
  /// In en, this message translates to:
  /// **'Puja/Paath'**
  String get pujaPaathTitle;

  /// Puja/Paath card subtitle
  ///
  /// In en, this message translates to:
  /// **'Your puja Your paath our responsibility'**
  String get pujaPaathSubtitle;

  /// Vedalay card title
  ///
  /// In en, this message translates to:
  /// **'Vedalay'**
  String get vedalayTitle;

  /// Vedalay card subtitle
  ///
  /// In en, this message translates to:
  /// **'Your puja Your paath our responsibility'**
  String get vedalaySubtitle;

  /// Panchang card title
  ///
  /// In en, this message translates to:
  /// **'Panchang'**
  String get panchangTitle;

  /// Panchang card subtitle
  ///
  /// In en, this message translates to:
  /// **'Daily naam japa for peace'**
  String get panchangSubtitle;

  /// Samagri card title
  ///
  /// In en, this message translates to:
  /// **'Samagri'**
  String get samagriTitle;

  /// Samagri card subtitle
  ///
  /// In en, this message translates to:
  /// **'Daily naam japa for peace'**
  String get samagriSubtitle;

  /// Banner start text
  ///
  /// In en, this message translates to:
  /// **'start your day with'**
  String get startYourDayWith;

  /// Banner main text
  ///
  /// In en, this message translates to:
  /// **'Naam japa'**
  String get naamJapa;

  /// Banner subtitle
  ///
  /// In en, this message translates to:
  /// **'Your puja Your paath our responsibility'**
  String get bannerSubtitle;

  /// Search bar placeholder
  ///
  /// In en, this message translates to:
  /// **'Search...'**
  String get searchPlaceholder;

  /// Greeting subtitle
  ///
  /// In en, this message translates to:
  /// **'Radhe Radhe'**
  String get radheRadhe;

  /// About tab title
  ///
  /// In en, this message translates to:
  /// **'About'**
  String get about;

  /// Benefits tab title
  ///
  /// In en, this message translates to:
  /// **'Benefits'**
  String get benefits;

  /// Process tab title
  ///
  /// In en, this message translates to:
  /// **'Process'**
  String get process;

  /// Temple tab title
  ///
  /// In en, this message translates to:
  /// **'Temple'**
  String get temple;

  /// Packages tab title
  ///
  /// In en, this message translates to:
  /// **'Packages'**
  String get packages;

  /// Reviews tab title
  ///
  /// In en, this message translates to:
  /// **'Reviews'**
  String get reviews;

  /// About puja section title
  ///
  /// In en, this message translates to:
  /// **'About Puja'**
  String get aboutPuja;

  /// Available packages section title
  ///
  /// In en, this message translates to:
  /// **'Available Packages'**
  String get availablePackages;

  /// Website section title
  ///
  /// In en, this message translates to:
  /// **'Website'**
  String get website;

  /// Selected package label
  ///
  /// In en, this message translates to:
  /// **'Selected Package'**
  String get selectedPackage;

  /// Book now button text
  ///
  /// In en, this message translates to:
  /// **'Book Now'**
  String get bookNow;

  /// Devotees label
  ///
  /// In en, this message translates to:
  /// **'Devotees'**
  String get devotees;

  /// Devotee participation message
  ///
  /// In en, this message translates to:
  /// **'Till now {count} Devotees have taken their vow through KARMASU.'**
  String tillNowDevoteesParticipated(String count);

  /// Booking closes message
  ///
  /// In en, this message translates to:
  /// **'Booking closes: {time}'**
  String bookingCloses(String time);

  /// Starting from price label
  ///
  /// In en, this message translates to:
  /// **'Starting from'**
  String get startingFrom;

  /// Dakshina (Amount) label
  ///
  /// In en, this message translates to:
  /// **'Dakshina'**
  String get dakshina;

  /// Amount label
  ///
  /// In en, this message translates to:
  /// **'Amount'**
  String get amount;

  /// Sankalp Now (Book Now) button text
  ///
  /// In en, this message translates to:
  /// **'Sankalp Now'**
  String get sankalpNow;

  /// My Sankalp (My Bookings) label
  ///
  /// In en, this message translates to:
  /// **'My Sankalp'**
  String get mySankalp;

  /// Name field label
  ///
  /// In en, this message translates to:
  /// **'Name'**
  String get name;

  /// Bio field label
  ///
  /// In en, this message translates to:
  /// **'Bio'**
  String get bio;

  /// Location field label
  ///
  /// In en, this message translates to:
  /// **'Location'**
  String get location;

  /// Name field placeholder
  ///
  /// In en, this message translates to:
  /// **'Enter your name'**
  String get enterName;

  /// Email field placeholder
  ///
  /// In en, this message translates to:
  /// **'Enter your email'**
  String get enterEmail;

  /// Phone field placeholder
  ///
  /// In en, this message translates to:
  /// **'Enter your phone number'**
  String get enterPhone;

  /// Bio field placeholder
  ///
  /// In en, this message translates to:
  /// **'Tell us about yourself...'**
  String get enterBio;

  /// Location field placeholder
  ///
  /// In en, this message translates to:
  /// **'Your location...'**
  String get enterLocation;

  /// Default text when field is empty
  ///
  /// In en, this message translates to:
  /// **'Not provided'**
  String get notProvided;

  /// Profile information section title
  ///
  /// In en, this message translates to:
  /// **'Profile Information'**
  String get profileInformation;

  /// Learning and activities section title
  ///
  /// In en, this message translates to:
  /// **'Learning & Activities'**
  String get learningActivities;

  /// Spiritual journey section title
  ///
  /// In en, this message translates to:
  /// **'Spiritual Journey'**
  String get spiritualJourney;

  /// Select astrologer section title
  ///
  /// In en, this message translates to:
  /// **'Select Astrologer'**
  String get selectAstrologer;

  /// Our kundli reports section title
  ///
  /// In en, this message translates to:
  /// **'Our Kundli Reports'**
  String get ourKundliReports;

  /// Loading astrologers message
  ///
  /// In en, this message translates to:
  /// **'Loading astrologers...'**
  String get loadingAstrologers;

  /// View all astrologers button text
  ///
  /// In en, this message translates to:
  /// **'View All Astrologers'**
  String get viewAllAstrologers;

  /// Your astrologers section title
  ///
  /// In en, this message translates to:
  /// **'Your Astrologers'**
  String get yourAstrologers;

  /// View your astrologers button text
  ///
  /// In en, this message translates to:
  /// **'View Your Astrologers'**
  String get viewYourAstrologers;

  /// View your booked astrologers description
  ///
  /// In en, this message translates to:
  /// **'View your booked astrologers and contact them directly'**
  String get viewYourBookedAstrologers;

  /// No astrologers available message
  ///
  /// In en, this message translates to:
  /// **'No astrologers available'**
  String get noAstrologersAvailable;

  /// Book button text
  ///
  /// In en, this message translates to:
  /// **'Book'**
  String get book;

  /// About astrologer section title
  ///
  /// In en, this message translates to:
  /// **'About {astrologerName}'**
  String aboutAstrologer(String astrologerName);

  /// Book a session section title
  ///
  /// In en, this message translates to:
  /// **'Book a Session'**
  String get bookASession;

  /// Choose booking type section title
  ///
  /// In en, this message translates to:
  /// **'Choose Booking Type'**
  String get chooseBookingType;

  /// Per minute booking type
  ///
  /// In en, this message translates to:
  /// **'Per Minute'**
  String get perMinute;

  /// Per month unit
  ///
  /// In en, this message translates to:
  /// **'/month'**
  String get perMonth;

  /// Book per minute button text
  ///
  /// In en, this message translates to:
  /// **'Book Per Minute'**
  String get bookPerMinute;

  /// Book per month button text
  ///
  /// In en, this message translates to:
  /// **'Book Per Month'**
  String get bookPerMonth;

  /// Booking options not available message
  ///
  /// In en, this message translates to:
  /// **'Booking options are not available at the moment'**
  String get bookingOptionsNotAvailable;

  /// Book per minute session dialog title
  ///
  /// In en, this message translates to:
  /// **'Book Per Minute Session'**
  String get bookPerMinuteSession;

  /// Enter number of minutes instruction
  ///
  /// In en, this message translates to:
  /// **'Enter number of minutes for your consultation:'**
  String get enterNumberOfMinutes;

  /// Number of minutes field label
  ///
  /// In en, this message translates to:
  /// **'Number of Minutes'**
  String get numberOfMinutes;

  /// Minutes example placeholder
  ///
  /// In en, this message translates to:
  /// **'e.g., 15, 30, 60'**
  String get minutesExample;

  /// Communication mode label
  ///
  /// In en, this message translates to:
  /// **'Communication Mode:'**
  String get communicationMode;

  /// Chat communication mode
  ///
  /// In en, this message translates to:
  /// **'Chat'**
  String get chat;

  /// Call communication mode
  ///
  /// In en, this message translates to:
  /// **'Call'**
  String get call;

  /// Total amount label
  ///
  /// In en, this message translates to:
  /// **'Total Amount:'**
  String get totalAmount;

  /// Pay now button text
  ///
  /// In en, this message translates to:
  /// **'Pay Now'**
  String get payNow;

  /// No astrologers or kundli reports available message
  ///
  /// In en, this message translates to:
  /// **'No astrologers or kundli reports available'**
  String get noAstrologersOrKundliReportsAvailable;

  /// Retry button text
  ///
  /// In en, this message translates to:
  /// **'Retry'**
  String get retry;

  /// All astrologers screen title
  ///
  /// In en, this message translates to:
  /// **'All Astrologers'**
  String get allAstrologers;

  /// Search astrologers placeholder
  ///
  /// In en, this message translates to:
  /// **'Search astrologers...'**
  String get searchAstrologers;

  /// No astrologers found message
  ///
  /// In en, this message translates to:
  /// **'No astrologers found'**
  String get noAstrologersFound;

  /// No astrologers found for search term
  ///
  /// In en, this message translates to:
  /// **'No astrologers found for \"{searchTerm}\"'**
  String noAstrologersFoundFor(String searchTerm);

  /// Clear search button text
  ///
  /// In en, this message translates to:
  /// **'Clear Search'**
  String get clearSearch;

  /// Downloading message
  ///
  /// In en, this message translates to:
  /// **'Downloading {title}...'**
  String downloading(String title);

  /// Please enter number of minutes validation message
  ///
  /// In en, this message translates to:
  /// **'Please enter number of minutes'**
  String get pleaseEnterNumberOfMinutes;

  /// Minutes must be positive validation message
  ///
  /// In en, this message translates to:
  /// **'Minutes must be a positive number'**
  String get minutesMustBePositive;

  /// Calculated amount is zero validation message
  ///
  /// In en, this message translates to:
  /// **'Calculated amount is zero. Cannot proceed.'**
  String get calculatedAmountIsZero;

  /// Please login to continue message
  ///
  /// In en, this message translates to:
  /// **'Please login to continue'**
  String get pleaseLoginToContinue;

  /// Monthly charge not available message
  ///
  /// In en, this message translates to:
  /// **'Monthly charge is not available. Cannot proceed.'**
  String get monthlyChargeNotAvailable;

  /// Error processing payment message
  ///
  /// In en, this message translates to:
  /// **'Error processing payment: {error}'**
  String errorProcessingPayment(String error);

  /// Payment successful message
  ///
  /// In en, this message translates to:
  /// **'Payment Successful! Your booking is confirmed and saved.'**
  String get paymentSuccessful;

  /// Payment successful but failed to save booking message
  ///
  /// In en, this message translates to:
  /// **'Payment successful but failed to save booking. Please contact support.'**
  String get paymentSuccessfulButFailedToSave;

  /// Payment successful but missing data message
  ///
  /// In en, this message translates to:
  /// **'Payment successful but missing required data. Please contact support.'**
  String get paymentSuccessfulButMissingData;

  /// Payment successful but error occurred message
  ///
  /// In en, this message translates to:
  /// **'Payment successful but error occurred. Please contact support.'**
  String get paymentSuccessfulButErrorOccurred;

  /// Payment failed message
  ///
  /// In en, this message translates to:
  /// **'Payment Failed: {error}'**
  String paymentFailed(String error);

  /// Redirecting to external wallet message
  ///
  /// In en, this message translates to:
  /// **'Redirecting to {walletName}'**
  String redirectingToExternalWallet(String walletName);

  /// Minutes unit
  ///
  /// In en, this message translates to:
  /// **'minutes'**
  String get minutes;

  /// Month unit
  ///
  /// In en, this message translates to:
  /// **'month'**
  String get month;

  /// Per minute unit
  ///
  /// In en, this message translates to:
  /// **'/min'**
  String get perMin;

  /// Pandit section title
  ///
  /// In en, this message translates to:
  /// **'Pandit'**
  String get pandit;

  /// Spiritual services section title
  ///
  /// In en, this message translates to:
  /// **'Spiritual Services'**
  String get spiritualServices;

  /// Book Pandit Ji card title
  ///
  /// In en, this message translates to:
  /// **'Book Pandit Ji'**
  String get bookPanditJi;

  /// Book Pandit Ji card description
  ///
  /// In en, this message translates to:
  /// **'Connect with your spiritual guide'**
  String get connectWithSpiritualGuide;

  /// Spiritual Diary card title
  ///
  /// In en, this message translates to:
  /// **'Spiritual Diary'**
  String get spiritualDiary;

  /// Spiritual Diary card description
  ///
  /// In en, this message translates to:
  /// **'Track your spiritual journey'**
  String get trackSpiritualJourney;

  /// Today's Puja Suggestion card title
  ///
  /// In en, this message translates to:
  /// **'Today\'s Puja Suggestion'**
  String get todaysPujaSuggestion;

  /// Today's Puja Suggestion card description
  ///
  /// In en, this message translates to:
  /// **'Discover today\'s auspicious pujas'**
  String get discoverTodaysAuspiciousPujas;

  /// My Family Pandit card title
  ///
  /// In en, this message translates to:
  /// **'My Family Pandit'**
  String get myFamilyPandit;

  /// My Family Pandit card description
  ///
  /// In en, this message translates to:
  /// **'View your assigned pandit details'**
  String get viewAssignedPanditDetails;

  /// Forgot password button text
  ///
  /// In en, this message translates to:
  /// **'Forgot Password?'**
  String get forgotPassword;

  /// Reset password dialog title
  ///
  /// In en, this message translates to:
  /// **'Reset Password'**
  String get resetPassword;

  /// Instruction for password reset
  ///
  /// In en, this message translates to:
  /// **'Enter your email to reset password'**
  String get enterEmailToReset;

  /// Button to send reset link
  ///
  /// In en, this message translates to:
  /// **'Send Reset Link'**
  String get sendResetLink;

  /// Success message for password reset code sent
  ///
  /// In en, this message translates to:
  /// **'Password reset code sent! Check your email.'**
  String get passwordResetEmailSent;

  /// OTP code field label
  ///
  /// In en, this message translates to:
  /// **'Enter OTP Code'**
  String get enterOtpCode;

  /// Hint for OTP code field
  ///
  /// In en, this message translates to:
  /// **'6-digit code from email'**
  String get otpCodeHint;

  /// OTP required validation message
  ///
  /// In en, this message translates to:
  /// **'OTP code is required'**
  String get otpRequired;

  /// OTP invalid validation message
  ///
  /// In en, this message translates to:
  /// **'OTP must be 6 digits'**
  String get otpInvalid;

  /// Resend code button text
  ///
  /// In en, this message translates to:
  /// **'Resend Code'**
  String get resendCode;

  /// Code resent success message
  ///
  /// In en, this message translates to:
  /// **'Verification code resent successfully'**
  String get codeResentSuccess;

  /// Invalid OTP error message
  ///
  /// In en, this message translates to:
  /// **'Invalid or expired OTP code'**
  String get invalidOtpCode;

  /// Password reset success message
  ///
  /// In en, this message translates to:
  /// **'Password reset successful! You can now login with your new password.'**
  String get passwordResetSuccess;

  /// Acharya section heading
  ///
  /// In en, this message translates to:
  /// **'Gurukul'**
  String get acharya;

  /// Gururkul bottom nav label
  ///
  /// In en, this message translates to:
  /// **'Gururkul'**
  String get gururkul;

  /// Store bottom nav label
  ///
  /// In en, this message translates to:
  /// **'Store'**
  String get store;

  /// Puja/Path bottom nav label
  ///
  /// In en, this message translates to:
  /// **'Puja/Path'**
  String get pujaPath;

  /// Our Courses section title
  ///
  /// In en, this message translates to:
  /// **'Our Courses'**
  String get ourCourses;

  /// Upcoming Webinars section title
  ///
  /// In en, this message translates to:
  /// **'Upcoming Webinars'**
  String get upcomingWebinars;

  /// Quizzes section title
  ///
  /// In en, this message translates to:
  /// **'Quizzes'**
  String get quizzes;

  /// View More button text
  ///
  /// In en, this message translates to:
  /// **'View More'**
  String get viewMore;

  /// No quizzes available message
  ///
  /// In en, this message translates to:
  /// **'No quizzes available'**
  String get noQuizzesAvailable;

  /// No description provided for @mantrasTitle.
  ///
  /// In en, this message translates to:
  /// **'Mantras'**
  String get mantrasTitle;

  /// No description provided for @mantrasLoading.
  ///
  /// In en, this message translates to:
  /// **'Loading mantras...'**
  String get mantrasLoading;

  /// No description provided for @noInternetConnection.
  ///
  /// In en, this message translates to:
  /// **'No Internet Connection'**
  String get noInternetConnection;

  /// No description provided for @sadhakProfile.
  ///
  /// In en, this message translates to:
  /// **'Sadhak Profile'**
  String get sadhakProfile;

  /// No description provided for @divineMantras.
  ///
  /// In en, this message translates to:
  /// **'Divine Mantras'**
  String get divineMantras;

  /// No description provided for @discoverFavoriteMantras.
  ///
  /// In en, this message translates to:
  /// **'Discover and learn your favorite mantras'**
  String get discoverFavoriteMantras;

  /// No description provided for @searchMantrasHint.
  ///
  /// In en, this message translates to:
  /// **'Search mantras...'**
  String get searchMantrasHint;

  /// No description provided for @mantrasLoadFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed to load mantras. Please check your internet connection.'**
  String get mantrasLoadFailed;

  /// No description provided for @noMantrasFound.
  ///
  /// In en, this message translates to:
  /// **'No mantras found'**
  String get noMantrasFound;

  /// No description provided for @favoriteMantras.
  ///
  /// In en, this message translates to:
  /// **'Favorite Mantras'**
  String get favoriteMantras;
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
      <String>['en', 'hi'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'hi':
      return AppLocalizationsHi();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}

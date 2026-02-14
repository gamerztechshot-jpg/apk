// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Hindi (`hi`).
class AppLocalizationsHi extends AppLocalizations {
  AppLocalizationsHi([String locale = 'hi']) : super(locale);

  @override
  String get appTitle => 'कर्मसु';

  @override
  String get welcomeBack => 'वापस स्वागत है';

  @override
  String get createAccount => 'अपना खाता बनाएं';

  @override
  String get fullName => 'पूरा नाम';

  @override
  String get email => 'ईमेल';

  @override
  String get phoneNumber => 'फोन नंबर';

  @override
  String get password => 'पासवर्ड';

  @override
  String get confirmPassword => 'पासवर्ड की पुष्टि करें';

  @override
  String get signIn => 'साइन इन';

  @override
  String get signUp => 'साइन अप';

  @override
  String get alreadyHaveAccount => 'पहले से खाता है? ';

  @override
  String get dontHaveAccount => 'खाता नहीं है? ';

  @override
  String get nameRequired => 'नाम आवश्यक है';

  @override
  String get nameMinLength => 'नाम कम से कम 2 अक्षर का होना चाहिए';

  @override
  String get emailRequired => 'ईमेल आवश्यक है';

  @override
  String get emailInvalid => 'कृपया एक वैध ईमेल दर्ज करें';

  @override
  String get phoneRequired => 'फोन नंबर आवश्यक है';

  @override
  String get phoneInvalid => 'कृपया एक वैध फोन नंबर दर्ज करें';

  @override
  String get passwordRequired => 'पासवर्ड आवश्यक है';

  @override
  String get passwordMinLength => 'पासवर्ड कम से कम 6 अक्षर का होना चाहिए';

  @override
  String get confirmPasswordRequired => 'कृपया अपने पासवर्ड की पुष्टि करें';

  @override
  String get passwordsDoNotMatch => 'पासवर्ड मेल नहीं खाते';

  @override
  String get accountCreatedSuccess =>
      'खाता सफलतापूर्वक बनाया गया! कर्मसु में आपका स्वागत है।';

  @override
  String get signedInSuccess => 'सफलतापूर्वक साइन इन किया गया!';

  @override
  String get errorSaving => 'सहेजने में त्रुटि';

  @override
  String get writeRamRamHere => 'यहाँ राम राम लिखें...';

  @override
  String writingSavedFor(String deityName) {
    return '$deityName के लिए लिखावट सहेजी गई';
  }

  @override
  String error(String errorMessage) {
    return 'त्रुटि: $errorMessage';
  }

  @override
  String get home => 'होम';

  @override
  String get explore => 'एक्सप्लोर';

  @override
  String get quiz => 'क्विज़';

  @override
  String get sadhna => 'साधना';

  @override
  String get profile => 'प्रोफाइल';

  @override
  String get poojaSadhna => 'पूजा साधना';

  @override
  String get ramnamLekhan => 'नाम जप';

  @override
  String get astrologer => 'ज्योतिषी';

  @override
  String get moreFeatures => 'और सुविधाएं';

  @override
  String get exploreScreen => 'आध्यात्मिक सेवाएं';

  @override
  String get quizZone => 'क्विज़ जोन - जल्द आ रहा है!';

  @override
  String get sadhnaTracker => 'साधना ट्रैकर - जल्द आ रहा है!';

  @override
  String get myCourses => 'मेरे कोर्स';

  @override
  String get myBookings => 'मेरी बुकिंग्स';

  @override
  String get jaapHistory => 'जाप इतिहास';

  @override
  String get karmicScore => 'कर्म स्कोर';

  @override
  String get settings => 'सेटिंग्स';

  @override
  String get support => 'सहायता';

  @override
  String get language => 'भाषा';

  @override
  String get english => 'English';

  @override
  String get hindi => 'हिंदी';

  @override
  String get phoneNotProvided => 'फोन: प्रदान नहीं किया गया';

  @override
  String get dailyPanchang => 'दैनिक पंचांग';

  @override
  String get todayDate => 'आज की तारीख';

  @override
  String get tithi => 'तिथि';

  @override
  String get nakshatra => 'नक्षत्र';

  @override
  String get yoga => 'योग';

  @override
  String get karana => 'करण';

  @override
  String get sunrise => 'सूर्योदय';

  @override
  String get sunset => 'सूर्यास्त';

  @override
  String get upcomingFestival => 'आगामी त्योहार';

  @override
  String get featuredHighlights => 'विशेष रुप से प्रदर्शित';

  @override
  String get courses => 'कोर्स';

  @override
  String get bookPuja => 'पूजा बुक करें';

  @override
  String get askGuruji => 'गुरुजी से पूछें';

  @override
  String get dharmaStore => 'धर्म स्टोर';

  @override
  String get viewAll => 'सभी देखें';

  @override
  String get adminPanel => 'एडमिन पैनल';

  @override
  String get manageDailyPanchang => 'दैनिक पंचांग प्रबंधित करें';

  @override
  String get manageCourses => 'कोर्स प्रबंधित करें';

  @override
  String get managePoojaBookings => 'पूजा बुकिंग प्रबंधित करें';

  @override
  String get manageEBookings => 'ई-बुकिंग प्रबंधित करें';

  @override
  String get managePandits => 'पंडित प्रबंधित करें';

  @override
  String get manageAstrologers => 'ज्योतिषी प्रबंधित करें';

  @override
  String get addNew => 'नया जोड़ें';

  @override
  String get edit => 'संपादित करें';

  @override
  String get delete => 'हटाएं';

  @override
  String get save => 'सहेजें';

  @override
  String get cancel => 'रद्द करें';

  @override
  String get durgaJi => 'दुर्गा जी';

  @override
  String get ganeshaJi => 'गणेश जी';

  @override
  String get hanumanJi => 'हनुमान जी';

  @override
  String get krishnaJi => 'कृष्ण जी';

  @override
  String get lakshmiJi => 'लक्ष्मी जी';

  @override
  String get narasimhaJi => 'नरसिंह जी';

  @override
  String get parvatiJi => 'पार्वती जी';

  @override
  String get radhaJi => 'राधा जी';

  @override
  String get ramJi => 'राम जी';

  @override
  String get saraswatiJi => 'सरस्वती जी';

  @override
  String get shaniJi => 'शनि जी';

  @override
  String get shivJi => 'शिव जी';

  @override
  String get sitaJi => 'सीता जी';

  @override
  String get vishnuJi => 'विष्णु जी';

  @override
  String get searchDeities => 'देवताओं को खोजें';

  @override
  String get favorites => 'पसंदीदा';

  @override
  String get dailyTargets => 'दैनिक लक्ष्य';

  @override
  String get setTarget => 'लक्ष्य निर्धारित करें';

  @override
  String get currentStreak => 'वर्तमान स्ट्रीक';

  @override
  String get longestStreak => 'सबसे लंबा स्ट्रीक';

  @override
  String get todayProgress => 'आज की प्रगति';

  @override
  String get targetMet => 'लक्ष्य पूरा!';

  @override
  String get targetNotMet => 'लक्ष्य पूरा नहीं';

  @override
  String get leaderboard => 'लीडरबोर्ड';

  @override
  String get dailyRanking => 'दैनिक रैंकिंग';

  @override
  String get yourRank => 'आपकी रैंक';

  @override
  String get totalJapa => 'कुल जाप';

  @override
  String get participants => 'प्रतिभागी';

  @override
  String get refresh => 'रिफ्रेश करें';

  @override
  String get japaCount => 'जाप गिनती';

  @override
  String get days => 'दिन';

  @override
  String get streak => 'स्ट्रीक';

  @override
  String get ramRamLekhan => 'नाम जप';

  @override
  String get selectPreferredDeity => 'अपने पसंदीदा देवता का चयन करें';

  @override
  String get searchDeitiesPlaceholder => 'देवताओं को खोजें...';

  @override
  String get noDeitiesFound => 'कोई देवता नहीं मिला';

  @override
  String get tryChangingSearchTerms => 'अपने खोज शब्द बदलने का प्रयास करें';

  @override
  String get words => 'शब्द';

  @override
  String get time => 'समय';

  @override
  String get clear => 'साफ़ करें';

  @override
  String get sadhnaTitle => 'साधना';

  @override
  String get sadhnaSubtitle => 'शांति के लिए दैनिक नाम जप';

  @override
  String get pujaPaathTitle => 'पूजा/पाठ';

  @override
  String get pujaPaathSubtitle => 'आपकी पूजा आपका पाठ हमारी जिम्मेदारी';

  @override
  String get vedalayTitle => 'वेदालय';

  @override
  String get vedalaySubtitle => 'आपकी पूजा आपका पाठ हमारी जिम्मेदारी';

  @override
  String get panchangTitle => 'पंचांग';

  @override
  String get panchangSubtitle => 'शांति के लिए दैनिक नाम जप';

  @override
  String get samagriTitle => 'सामग्री';

  @override
  String get samagriSubtitle => 'शांति के लिए दैनिक नाम जप';

  @override
  String get startYourDayWith => 'अपना दिन शुरू करें';

  @override
  String get naamJapa => 'नाम जप';

  @override
  String get bannerSubtitle => 'आपकी पूजा आपका पाठ हमारी जिम्मेदारी';

  @override
  String get searchPlaceholder => 'खोजें...';

  @override
  String get radheRadhe => 'राधे राधे';

  @override
  String get about => 'के बारे में';

  @override
  String get benefits => 'लाभ';

  @override
  String get process => 'प्रक्रिया';

  @override
  String get temple => 'मंदिर';

  @override
  String get packages => 'पैकेज';

  @override
  String get reviews => 'समीक्षाएं';

  @override
  String get aboutPuja => 'पूजा के बारे में';

  @override
  String get availablePackages => 'उपलब्ध पैकेज';

  @override
  String get website => 'वेबसाइट';

  @override
  String get selectedPackage => 'चयनित पैकेज';

  @override
  String get bookNow => 'अभी बुक करें';

  @override
  String get devotees => 'भक्त';

  @override
  String tillNowDevoteesParticipated(String count) {
    return 'अब तक $count भक्तों ने KARMASU के माध्यम से अपना संकल्प लिया है।';
  }

  @override
  String bookingCloses(String time) {
    return 'बुकिंग बंद: $time';
  }

  @override
  String get startingFrom => 'शुरुआत';

  @override
  String get dakshina => 'दक्षिणा';

  @override
  String get amount => 'राशि';

  @override
  String get sankalpNow => 'संकल्प अभी';

  @override
  String get mySankalp => 'मेरा संकल्प';

  @override
  String get name => 'नाम';

  @override
  String get bio => 'जीवन परिचय';

  @override
  String get location => 'स्थान';

  @override
  String get enterName => 'अपना नाम दर्ज करें';

  @override
  String get enterEmail => 'अपना ईमेल दर्ज करें';

  @override
  String get enterPhone => 'अपना फोन नंबर दर्ज करें';

  @override
  String get enterBio => 'अपने बारे में बताएं...';

  @override
  String get enterLocation => 'आपका स्थान...';

  @override
  String get notProvided => 'प्रदान नहीं किया गया';

  @override
  String get profileInformation => 'प्रोफाइल जानकारी';

  @override
  String get learningActivities => 'सीखना और गतिविधियां';

  @override
  String get spiritualJourney => 'आध्यात्मिक यात्रा';

  @override
  String get selectAstrologer => 'ज्योतिषी चुनें';

  @override
  String get ourKundliReports => 'हमारी कुंडली रिपोर्ट्स';

  @override
  String get loadingAstrologers => 'ज्योतिषी लोड हो रहे हैं...';

  @override
  String get viewAllAstrologers => 'सभी ज्योतिषी देखें';

  @override
  String get yourAstrologers => 'आपके ज्योतिषी';

  @override
  String get viewYourAstrologers => 'अपने ज्योतिषी देखें';

  @override
  String get viewYourBookedAstrologers =>
      'अपने बुक किए गए ज्योतिषी देखें और उनसे सीधे संपर्क करें';

  @override
  String get noAstrologersAvailable => 'कोई ज्योतिषी उपलब्ध नहीं';

  @override
  String get book => 'बुक करें';

  @override
  String aboutAstrologer(String astrologerName) {
    return 'ज्योतिषी के बारे में';
  }

  @override
  String get bookASession => 'सेशन बुक करें';

  @override
  String get chooseBookingType => 'बुकिंग प्रकार चुनें';

  @override
  String get perMinute => 'प्रति मिनट';

  @override
  String get perMonth => 'प्रति महीना';

  @override
  String get bookPerMinute => 'प्रति मिनट बुक करें';

  @override
  String get bookPerMonth => 'प्रति महीना बुक करें';

  @override
  String get bookingOptionsNotAvailable =>
      'बुकिंग विकल्प इस समय उपलब्ध नहीं हैं';

  @override
  String get bookPerMinuteSession => 'प्रति मिनट सेशन बुक करें';

  @override
  String get enterNumberOfMinutes =>
      'अपनी सलाह के लिए मिनटों की संख्या दर्ज करें:';

  @override
  String get numberOfMinutes => 'मिनटों की संख्या';

  @override
  String get minutesExample => 'जैसे, 15, 30, 60';

  @override
  String get communicationMode => 'संचार मोड:';

  @override
  String get chat => 'चैट';

  @override
  String get call => 'कॉल';

  @override
  String get totalAmount => 'कुल राशि:';

  @override
  String get payNow => 'अभी भुगतान करें';

  @override
  String get noAstrologersOrKundliReportsAvailable =>
      'कोई ज्योतिषी या कुंडली रिपोर्ट उपलब्ध नहीं';

  @override
  String get retry => 'पुनः प्रयास करें';

  @override
  String get allAstrologers => 'सभी ज्योतिषी';

  @override
  String get searchAstrologers => 'ज्योतिषी खोजें...';

  @override
  String get noAstrologersFound => 'कोई ज्योतिषी नहीं मिला';

  @override
  String noAstrologersFoundFor(String searchTerm) {
    return 'के लिए कोई ज्योतिषी नहीं मिला';
  }

  @override
  String get clearSearch => 'खोज साफ़ करें';

  @override
  String downloading(String title) {
    return '$title डाउनलोड हो रहा है...';
  }

  @override
  String get pleaseEnterNumberOfMinutes => 'कृपया मिनटों की संख्या दर्ज करें';

  @override
  String get minutesMustBePositive => 'मिनट एक सकारात्मक संख्या होनी चाहिए';

  @override
  String get calculatedAmountIsZero =>
      'गणना की गई राशि शून्य है। आगे नहीं बढ़ सकते।';

  @override
  String get pleaseLoginToContinue => 'कृपया जारी रखने के लिए लॉगिन करें';

  @override
  String get monthlyChargeNotAvailable =>
      'मासिक शुल्क उपलब्ध नहीं है। आगे नहीं बढ़ सकते।';

  @override
  String errorProcessingPayment(String error) {
    return 'भुगतान प्रसंस्करण में त्रुटि';
  }

  @override
  String get paymentSuccessful =>
      'भुगतान सफल! आपकी बुकिंग पुष्टि हो गई और सहेज दी गई।';

  @override
  String get paymentSuccessfulButFailedToSave =>
      'भुगतान सफल लेकिन बुकिंग सहेजने में विफल। कृपया सहायता से संपर्क करें।';

  @override
  String get paymentSuccessfulButMissingData =>
      'भुगतान सफल लेकिन आवश्यक डेटा गुम है। कृपया सहायता से संपर्क करें।';

  @override
  String get paymentSuccessfulButErrorOccurred =>
      'भुगतान सफल लेकिन त्रुटि हुई। कृपया सहायता से संपर्क करें।';

  @override
  String paymentFailed(String error) {
    return 'भुगतान विफल';
  }

  @override
  String redirectingToExternalWallet(String walletName) {
    return 'बाहरी वॉलेट पर रीडायरेक्ट हो रहा है';
  }

  @override
  String get minutes => 'मिनट';

  @override
  String get month => 'महीना';

  @override
  String get perMin => 'प्रति मिन';

  @override
  String get pandit => 'पंडित';

  @override
  String get spiritualServices => 'आध्यात्मिक सेवाएं';

  @override
  String get bookPanditJi => 'पंडित जी बुक करें';

  @override
  String get connectWithSpiritualGuide => 'अपने आध्यात्मिक गुरु से जुड़ें';

  @override
  String get spiritualDiary => 'आध्यात्मिक डायरी';

  @override
  String get trackSpiritualJourney => 'अपनी आध्यात्मिक यात्रा को ट्रैक करें';

  @override
  String get todaysPujaSuggestion => 'आज की पूजा सुझाव';

  @override
  String get discoverTodaysAuspiciousPujas => 'आज के शुभ पूजा की खोज करें';

  @override
  String get myFamilyPandit => 'मेरे परिवार के पंडित';

  @override
  String get viewAssignedPanditDetails => 'अपने निर्धारित पंडित का विवरण देखें';

  @override
  String get forgotPassword => 'पासवर्ड भूल गए?';

  @override
  String get resetPassword => 'पासवर्ड रीसेट करें';

  @override
  String get enterEmailToReset =>
      'पासवर्ड रीसेट करने के लिए अपना ईमेल दर्ज करें';

  @override
  String get sendResetLink => 'रीसेट लिंक भेजें';

  @override
  String get passwordResetEmailSent =>
      'पासवर्ड रीसेट कोड भेजा गया! अपना ईमेल चेक करें।';

  @override
  String get enterOtpCode => 'OTP कोड दर्ज करें';

  @override
  String get otpCodeHint => 'ईमेल से 6 अंकोंका कोड';

  @override
  String get otpRequired => 'OTP कोड आवश्यक है';

  @override
  String get otpInvalid => 'OTP 6 अंकों का होना चाहिए';

  @override
  String get resendCode => 'कोड फिर से भेजें';

  @override
  String get codeResentSuccess => 'सत्यापन कोड सफलतापूर्वक फिर से भेजा गया';

  @override
  String get invalidOtpCode => 'अमान्य या समाप्त OTP कोड';

  @override
  String get passwordResetSuccess =>
      'पासवर्ड रीसेट सफल! अब आप अपने नए पासवर्ड से लॉगिन कर सकते हैं।';

  @override
  String get acharya => 'गुरुकुल';

  @override
  String get gururkul => 'गुरुकुल';

  @override
  String get store => 'स्टोर';

  @override
  String get pujaPath => 'पूजा/पाठ';

  @override
  String get ourCourses => 'हमारे कोर्स';

  @override
  String get upcomingWebinars => 'आगामी वेबिनार';

  @override
  String get quizzes => 'क्विज़';

  @override
  String get viewMore => 'और देखें';

  @override
  String get noQuizzesAvailable => 'कोई क्विज़ उपलब्ध नहीं';

  @override
  String get mantrasTitle => 'मंत्र';

  @override
  String get mantrasLoading => 'मंत्र लोड हो रहे हैं...';

  @override
  String get noInternetConnection => 'इंटरनेट कनेक्शन नहीं';

  @override
  String get sadhakProfile => 'साधक प्रोफाइल';

  @override
  String get divineMantras => 'दिव्य मंत्र';

  @override
  String get discoverFavoriteMantras =>
      'अपने पसंदीदा मंत्रों को खोजें और सीखें';

  @override
  String get searchMantrasHint => 'मंत्र खोजें...';

  @override
  String get mantrasLoadFailed =>
      'मंत्र लोड करने में विफल। कृपया अपना इंटरनेट कनेक्शन जाँचें।';

  @override
  String get noMantrasFound => 'कोई मंत्र नहीं मिला';

  @override
  String get favoriteMantras => 'पसंदीदा मंत्र';
}

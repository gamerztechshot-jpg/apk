// core/services/share_message_service.dart
/// Types of share messages supported in the app.
enum ShareMessageType {
  /// Generic full app share (used from invite banner etc.)
  fullApp,

  /// Sharing that the user completed a pooja using the app.
  pujaShare,

  /// Sharing daily Panchang usage.
  panchangShare,

  /// Sharing mantra / japa practice.
  mantraJaapShare,

  /// Short eBook share line.
  ebookShort,

  /// Detailed eBook + Sakha AI experience share.
  ebookExperience,
}

/// Central place to build share text based on selected app language.
///
/// Usage:
///   final text = ShareMessages.forType(
///     ShareMessageType.fullApp,
///     isHindi: languageService.isHindi,
///   );
class ShareMessages {
  ShareMessages._();

  /// Single source of truth for app link used in shares.
  static const String appLink =
      'https://play.google.com/store/apps/details?id=com.digital.hindugurukul';

  /// Returns localized share text for the given [type] and [isHindi] flag.
  static String forType(ShareMessageType type, {required bool isHindi}) {
    switch (type) {
      case ShareMessageType.fullApp:
        return isHindi
            ? 'मैंने अभी-अभी KARMASU App का उपयोग शुरू किया है और यह सच में मेरा आध्यात्मिक साथी बन गया है। 🌺📿\n\n👉 अभी डाउनलोड करें: $appLink'
            : 'I’ve just started using the KARMASU App, and it has truly become my spiritual companion. 🌺📿\n\n👉 Download now: $appLink';

      case ShareMessageType.pujaShare:
        return isHindi
            ? 'मैंने आज KARMASU App के माध्यम से शास्त्रों के अनुसार पूजा संपन्न की। 🙏🌺\n\n👉 अभी डाउनलोड करें: $appLink'
            : 'Today, I completed my pooja using the KARMASU App. 🙏🌺\n\n👉 Download now: $appLink';

      case ShareMessageType.panchangShare:
        return isHindi
            ? 'मैं रोज़ KARMASU App पर पंचांग देखकर अपने दिन की शुरुआत करता हूँ। 🙏📅\n\n👉 अभी डाउनलोड करें: $appLink'
            : 'I start my day by checking the Panchang on the KARMASU App. 🙏📅\n\n👉 Download now: $appLink';

      case ShareMessageType.mantraJaapShare:
        return isHindi
            ? 'मैंने आज KARMASU App के साथ मंत्र जाप किया। 🕉️📿\n\n👉 अभी डाउनलोड करें: $appLink'
            : 'Today, I practiced mantra chanting using the KARMASU App. 🕉️📿\n\n👉 Download now: $appLink';

      case ShareMessageType.ebookShort:
        return isHindi
            ? 'मैंने अभी KARMASU App पर एक आध्यात्मिक eBook पढ़ी। 📘🌺\n\n👉 अभी डाउनलोड करें: $appLink'
            : 'I just read a spiritual eBook on the KARMASU App. 📘🌺\n\n👉 Download now: $appLink';

      case ShareMessageType.ebookExperience:
        return isHindi
            ? '''शास्त्रों का गूढ़ ज्ञान डिजिटल गुरुकुल के माध्यम से सरल और सहज भाषा में समझने को मिला।
और जहाँ भी अर्थ या भाव को लेकर शंका हुई, सखा AI ने तुरंत स्पष्ट और शांत मार्गदर्शन दिया। 🤖🌼

यह पढ़ना सिर्फ जानकारी नहीं था,
बल्कि धर्म को समझने और जीने का अनुभव था।

अगर आप भी सनातन ज्ञान को सही संदर्भ और सरल रूप में पढ़ना चाहते हैं —
तो यह App ज़रूर उपयोग करें। 🙏
👉 अभी डाउनलोड करें: $appLink

भक्ति को तकनीक से जोड़िए। 🔱📲
अगर आप भी अपनी जड़ों से फिर से जुड़ना चाहते हैं
और धर्म को केवल जानना नहीं, जीना चाहते हैं —
तो यह App आपके लिए है। 🌸

👉 अभी डाउनलोड करें: $appLink'''
            : '''Ancient wisdom was beautifully explained
through the Digital Gurukul in a simple and meaningful way.
And whenever I needed clarity,
Sakha AI instantly helped with clear explanations and context. 🤖🌼

This wasn’t just reading —
it felt like truly understanding and living the wisdom.

If you want to explore Sanatan knowledge
with authenticity and ease,
this app is worth using. 🙏
👉 Download now: $appLink

Where devotion meets technology. 📲✨
If you also want to reconnect with your roots
and not just know Dharma, but live it —
this app is for you. 🌸

👉 Download now: $appLink''';
    }
  }
}


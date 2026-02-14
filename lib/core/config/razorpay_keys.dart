// core/config/razorpay_keys.dart
// Reads Razorpay keys from assets/.env (loaded at app startup in main.dart)
import 'package:flutter_dotenv/flutter_dotenv.dart';

/// Razorpay API key (from .env: razorpay_api_key)
String get razorpayApiKey =>
    dotenv.env['razorpay_api_key'] ?? '';

/// Razorpay API secret (from .env: razorpay_api_secret)
String get razorpayApiSecret =>
    dotenv.env['razorpay_api_secret'] ?? '';

/// Legacy names for backward compatibility with existing imports
@Deprecated('Use razorpayApiKey instead')
String get api_key => razorpayApiKey;

@Deprecated('Use razorpayApiSecret instead')
String get api_secret => razorpayApiSecret;

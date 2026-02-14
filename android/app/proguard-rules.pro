# Razorpay SDK - Keep rules
-keep class com.razorpay.** { *; }
-keep class proguard.annotation.** { *; }
-dontwarn proguard.annotation.**

# Ignore missing Google Pay classes (Razorpay optional dependency)
-dontwarn com.google.android.apps.nbu.paisa.inapp.client.api.**

// features/onboarding/models/onboarding_item.dart

enum OnboardingMediaType { image, video }

class OnboardingItem {
  final int order;
  final String url;
  final OnboardingMediaType type;

  const OnboardingItem({
    required this.order,
    required this.url,
    required this.type,
  });
}

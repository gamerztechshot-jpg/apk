// features/mantra_generator/models/access_status_model.dart

enum AccessReason {
  granted,
  noPackage,
  packageInactive,
  notInPackage,
  insufficientCredits,
  problemNotFound,
}

class AccessStatus {
  final bool hasAccess;
  final AccessReason reason;
  final String message;
  final int? requiredCredits;
  final int? availableCredits;

  AccessStatus({
    required this.hasAccess,
    required this.reason,
    required this.message,
    this.requiredCredits,
    this.availableCredits,
  });

  factory AccessStatus.granted() {
    return AccessStatus(
      hasAccess: true,
      reason: AccessReason.granted,
      message: 'Access granted',
    );
  }

  factory AccessStatus.noPackage() {
    return AccessStatus(
      hasAccess: false,
      reason: AccessReason.noPackage,
      message: 'Please purchase a package to access this content',
    );
  }

  factory AccessStatus.packageInactive() {
    return AccessStatus(
      hasAccess: false,
      reason: AccessReason.packageInactive,
      message: 'Your package is not active',
    );
  }

  factory AccessStatus.notInPackage() {
    return AccessStatus(
      hasAccess: false,
      reason: AccessReason.notInPackage,
      message: 'This problem is not included in your package',
    );
  }

  factory AccessStatus.insufficientCredits({
    required int requiredCredits,
    required int availableCredits,
  }) {
    return AccessStatus(
      hasAccess: false,
      reason: AccessReason.insufficientCredits,
      message:
          'This requires $requiredCredits credit${requiredCredits > 1 ? 's' : ''}. '
          'You have $availableCredits credit${availableCredits != 1 ? 's' : ''} available.',
      requiredCredits: requiredCredits,
      availableCredits: availableCredits,
    );
  }

  factory AccessStatus.problemNotFound() {
    return AccessStatus(
      hasAccess: false,
      reason: AccessReason.problemNotFound,
      message: 'Problem not found',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'hasAccess': hasAccess,
      'reason': reason.toString(),
      'message': message,
      'requiredCredits': requiredCredits,
      'availableCredits': availableCredits,
    };
  }
}

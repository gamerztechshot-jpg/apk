class TeacherModel {
  final String id;
  final String name;
  final String? profileImage;
  final String specialty;
  final String bio;

  TeacherModel({
    required this.id,
    required this.name,
    this.profileImage,
    required this.specialty,
    required this.bio,
  });

  factory TeacherModel.fromJson(Map<String, dynamic> json) {
    final basicInfo = json['basic_info'] as Map<String, dynamic>?;

    return TeacherModel(
      id: json['id'] ?? '',
      name: basicInfo?['name'] ?? json['full_name'] ?? json['name'] ?? '',
      profileImage:
          basicInfo?['photo_url'] ??
          json['avatar_url'] ??
          json['profile_image'],
      specialty: basicInfo?['qualification'] ?? json['specialty'] ?? '',
      bio: basicInfo?['about_you'] ?? json['bio'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'profile_image': profileImage,
      'specialty': specialty,
      'bio': bio,
    };
  }
}

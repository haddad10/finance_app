class UserModel {
  final String id;
  final String username;
  final String email;
  final String? photoUrl;
  final String createdAt;

  const UserModel({
    required this.id,
    required this.username,
    required this.email,
    this.photoUrl,
    required this.createdAt,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'] as String? ?? '',
      username: json['username'] as String? ?? '',
      email: json['email'] as String? ?? '',
      photoUrl: json['photo_url'] as String?,
      createdAt: json['created_at'] as String? ?? '',
    );
  }
}

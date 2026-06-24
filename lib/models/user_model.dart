class UserModel {
  final String id;       // ID numerik berurutan (1, 2, 3, ...) sebagai String
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
    // ID bisa berupa int (akun baru) atau String (akun lama)
    final rawId = json['id'];
    final String id = rawId != null ? rawId.toString() : '';

    return UserModel(
      id: id,
      username: json['username'] as String? ?? '',
      email: json['email'] as String? ?? '',
      photoUrl: json['photo_url'] as String?,
      createdAt: json['created_at'] as String? ?? '',
    );
  }

  /// Untuk tampilan ID yang rapih: #1, #2, #3
  String get displayId => '#$id';
}

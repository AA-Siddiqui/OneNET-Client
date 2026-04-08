class UserModel {
  final String id;
  final String email;
  final String username;
  final String displayName;
  final String? avatarUrl;
  final String region;
  final String language;
  final String timezone;
  final bool isAdmin;

  const UserModel({
    required this.id,
    required this.email,
    required this.username,
    required this.displayName,
    this.avatarUrl,
    this.region = 'HK',
    this.language = 'zh-HK',
    this.timezone = 'Asia/Hong_Kong',
    this.isAdmin = false,
  });

  /// Parse from the `user` object in the login response.
  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'] as String,
      email: json['email'] as String,
      username: json['username'] as String? ?? '',
      displayName: json['display_name'] as String? ?? json['username'] as String? ?? '',
      avatarUrl: json['avatar_url'] as String?,
      region: json['region'] as String? ?? 'HK',
      language: json['language'] as String? ?? 'zh-HK',
      timezone: json['timezone'] as String? ?? 'Asia/Hong_Kong',
      isAdmin: json['is_admin'] as bool? ?? false,
    );
  }
}

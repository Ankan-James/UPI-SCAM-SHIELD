class User {
  const User({
    required this.id,
    required this.username,
    required this.email,
  });

  final int id;
  final String username;
  final String email;

  factory User.fromJson(Map<String, dynamic> json) => User(
        id: (json['user_id'] as num).toInt(),
        username: json['username'] as String,
        email: json['email'] as String,
      );
}

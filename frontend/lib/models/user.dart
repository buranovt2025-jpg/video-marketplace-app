enum UserRole { admin, seller, buyer, courier }

enum Language { en, ru, uz }

class User {
  final String id;
  final String phone;
  final String? email;
  final String firstName;
  final String lastName;
  final UserRole role;
  final String? avatar;
  final bool isVerified;
  final Language language;
  final DateTime? createdAt;

  User({
    required this.id,
    required this.phone,
    this.email,
    required this.firstName,
    required this.lastName,
    required this.role,
    this.avatar,
    this.isVerified = false,
    this.language = Language.ru,
    this.createdAt,
  });

  String get fullName => '$firstName $lastName';

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'] as String,
      phone: json['phone'] as String,
      email: json['email'] as String?,
      firstName: json['firstName'] as String,
      lastName: json['lastName'] as String,
      role: UserRole.values.firstWhere(
        (e) => e.name == json['role'],
        orElse: () => UserRole.buyer,
      ),
      avatar: json['avatar'] as String?,
      isVerified: json['isVerified'] as bool? ?? false,
      language: Language.values.firstWhere(
        (e) => e.name == json['language'],
        orElse: () => Language.ru,
      ),
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'] as String)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'phone': phone,
      'email': email,
      'firstName': firstName,
      'lastName': lastName,
      'role': role.name,
      'avatar': avatar,
      'isVerified': isVerified,
      'language': language.name,
      'createdAt': createdAt?.toIso8601String(),
    };
  }

  User copyWith({
    String? id,
    String? phone,
    String? email,
    String? firstName,
    String? lastName,
    UserRole? role,
    String? avatar,
    bool? isVerified,
    Language? language,
    DateTime? createdAt,
  }) {
    return User(
      id: id ?? this.id,
      phone: phone ?? this.phone,
      email: email ?? this.email,
      firstName: firstName ?? this.firstName,
      lastName: lastName ?? this.lastName,
      role: role ?? this.role,
      avatar: avatar ?? this.avatar,
      isVerified: isVerified ?? this.isVerified,
      language: language ?? this.language,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}

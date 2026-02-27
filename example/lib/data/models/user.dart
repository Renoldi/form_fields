import 'package:dio/dio.dart';
import 'package:json_annotation/json_annotation.dart';
import 'package:form_fields_example/data/services/http_service.dart';

part 'user.g.dart';

@JsonSerializable()
class User {
  final int? id;
  final String? username;
  final String? email;
  final String? firstName;
  final String? lastName;
  final String? image;
  final String? accessToken;
  final String? refreshToken;

  const User({
    this.id,
    this.username,
    this.email,
    this.firstName,
    this.lastName,
    this.image,
    this.accessToken,
    this.refreshToken,
  });

  factory User.fromJson(Map<String, dynamic> json) => _$UserFromJson(json);

  Map<String, dynamic> toJson() => _$UserToJson(this);

  String? get displayName {
    final fullName = '$firstName $lastName'.trim();
    return fullName.isEmpty ? username : fullName;
  }

  // Authentication methods using global HttpService

  static Future<User> login({
    required String username,
    required String password,
  }) async {
    final response = await HttpService.instance.post<Map<String, dynamic>>(
      '/auth/login',
      data: {
        'username': username,
        'password': password,
      },
    );

    return User.fromJson(response);
  }

  static Future<User> getMe({
    required String accessToken,
  }) async {
    final response = await HttpService.instance.get<Map<String, dynamic>>(
      '/auth/me',
      options: Options(
        headers: {
          'Authorization': 'Bearer $accessToken',
        },
      ),
    );

    return User.fromJson(response);
  }

  static Future<User> updateMe({
    required String accessToken,
    required User user,
  }) async {
    if (user.id == null) {
      throw Exception('User ID is required for update');
    }

    final data = user.toJson();
    // Remove tokens from update data
    data.remove('accessToken');
    data.remove('refreshToken');
    data.remove('id');

    final response = await HttpService.instance.put<Map<String, dynamic>>(
      '/users/${user.id}',
      data: data,
      options: Options(
        headers: {
          'Authorization': 'Bearer $accessToken',
        },
      ),
    );

    return User.fromJson(response);
  }
}

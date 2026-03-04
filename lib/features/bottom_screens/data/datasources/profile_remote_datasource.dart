import 'dart:io';
import 'package:dio/dio.dart';
import 'package:matchpoint/core/api/api_endpoints.dart';
import 'package:matchpoint/core/services/storage/user_session_service.dart';

class ProfileRemoteDataSource {
  final Dio _dio;
  final UserSessionService _session;

  ProfileRemoteDataSource(this._dio, this._session);

  Future<String?> fetchProfilePictureUrl() async {
    return _session.getProfileImageUrl();
  }

  Future<String> uploadProfilePicture(File file) async {
    final token = await _session.getToken();

    if (token == null || token.isEmpty) {
      throw Exception("Token missing. Please login again.");
    }

    final formData = FormData.fromMap({
      'image': await MultipartFile.fromFile(file.path),
    });

    final response = await _dio.put(
      '${ApiEndpoints.baseUrl}${ApiEndpoints.authProfile}',
      data: formData,
      options: Options(
        headers: {
          'Authorization': 'Bearer $token',
        },
      ),
    );

    final imagePath =
        ((response.data['data'] as Map<String, dynamic>?)?['image'] ?? '')
            .toString();

    if (imagePath.isEmpty) {
      throw Exception('Profile image not returned by server');
    }

    final imageUrl = imagePath.startsWith('http')
        ? imagePath
        : '${ApiEndpoints.serverUrl}$imagePath';

    await _session.saveProfileImageUrl(imageUrl);
    return imageUrl;
  }

  Future<Map<String, String>> updateProfile({
    required String name,
    required String email,
  }) async {
    final token = await _session.getToken();

    if (token == null || token.isEmpty) {
      throw Exception('Token missing. Please login again.');
    }

    final response = await _dio.put(
      '${ApiEndpoints.baseUrl}${ApiEndpoints.authProfile}',
      data: {
        'name': name,
        'email': email,
      },
      options: Options(
        headers: {
          'Authorization': 'Bearer $token',
        },
      ),
    );

    final data = (response.data['data'] as Map<String, dynamic>?) ?? {};
    final userId = (data['_id'] ?? _session.getCurrentUserId() ?? '').toString();
    final updatedName = (data['name'] ?? name).toString();
    final updatedEmail = (data['email'] ?? email).toString();
    final imagePath = (data['image'] ?? '').toString();

    String imageUrl = _session.getProfileImageUrl() ?? '';
    if (imagePath.isNotEmpty) {
      imageUrl = imagePath.startsWith('http')
          ? imagePath
          : imagePath.startsWith('/uploads/')
              ? '${ApiEndpoints.serverUrl}$imagePath'
              : '${ApiEndpoints.serverUrl}/uploads/users/$imagePath';
      await _session.saveProfileImageUrl(imageUrl);
    }

    return {
      'userId': userId,
      'name': updatedName,
      'email': updatedEmail,
      'imageUrl': imageUrl,
    };
  }

  Future<void> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    final token = await _session.getToken();
    final email = _session.getCurrentUserEmail();

    if (token == null || token.isEmpty) {
      throw Exception('Token missing. Please login again.');
    }
    if (email == null || email.isEmpty) {
      throw Exception('Email missing in session. Please login again.');
    }

    try {
      await _dio.post(
        '${ApiEndpoints.baseUrl}${ApiEndpoints.authLogin}',
        data: {
          'email': email,
          'password': currentPassword,
        },
      );
    } on DioException {
      throw Exception('Current password is incorrect');
    }

    await _dio.put(
      '${ApiEndpoints.baseUrl}${ApiEndpoints.authProfile}',
      data: {
        'password': newPassword,
      },
      options: Options(
        headers: {
          'Authorization': 'Bearer $token',
        },
      ),
    );
  }
}

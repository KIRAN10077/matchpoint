
import 'package:matchpoint/core/api/api_client.dart';
import 'package:matchpoint/core/api/api_endpoints.dart';
import 'package:matchpoint/core/services/storage/user_session_service.dart';
import 'package:matchpoint/features/auth/data/datasources/auth_datasource.dart';
import 'package:matchpoint/features/auth/data/models/auth_api_model.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:jwt_decoder/jwt_decoder.dart';

final authRemoteDatasourceProvider = Provider<IAuthRemoteDataSource>((ref) {
  return AuthRemoteDatasource(
    apiClient: ref.read(apiClientProvider),
    userSessionService: ref.read(userSessionServiceProvider),
  );
});

class AuthRemoteDatasource implements IAuthRemoteDataSource{

  final ApiClient _apiClient;
  final UserSessionService _userSessionService;

  AuthRemoteDatasource({
    required ApiClient apiClient,
    required UserSessionService userSessionService,
  })  : _apiClient = apiClient,
        _userSessionService = userSessionService;

  @override
  Future<AuthApiModel?> getUserById(String authId) {
    // TODO: implement getUserById
    throw UnimplementedError();
  }

  @override
  Future<AuthApiModel?> login(String email, String password) async {
    final response = await _apiClient.post(
      ApiEndpoints.authLogin,
      data: {
        'email': email,
        'password': password,
      },
    );

    if (response.data['success'] == true) {
      final token = response.data['token'] as String?;
      if (token != null) {
        final decodedToken = JwtDecoder.decode(token);
        final userData = (response.data['data'] as Map<String, dynamic>?) ?? {};
        final userId = (userData['_id'] ?? decodedToken['id']).toString();
        final fullName =
            (userData['name'] ?? decodedToken['name'] ?? '').toString();
        final userEmail =
            (userData['email'] ?? decodedToken['email'] ?? email).toString();
        final rawImagePath = (userData['image'] ?? '').toString();
        final imageUrl = rawImagePath.isEmpty
          ? ''
          : rawImagePath.startsWith('http')
            ? rawImagePath
            : rawImagePath.startsWith('/uploads/')
              ? '${ApiEndpoints.serverUrl}$rawImagePath'
              : '${ApiEndpoints.serverUrl}/uploads/users/$rawImagePath';

        await _userSessionService.saveToken(token);
        await _userSessionService.saveUserSession(
          userId: userId,
          email: userEmail,
          fullName: fullName,
        );
        await _userSessionService.saveProfileImageUrl(imageUrl);

        return AuthApiModel(
          id: userId,
          fullName: fullName,
          email: userEmail,
          password: null,
          username: (userData['username'] ?? fullName).toString(),
        );
      }
    }

    return null;
  }

  @override
  Future<AuthApiModel> register(AuthApiModel user) async {
    final normalizedName = user.fullName.trim().isNotEmpty
        ? user.fullName.trim()
        : user.username.trim();
    final nameParts = normalizedName.split(RegExp(r'\s+'));
    final firstName = nameParts.isNotEmpty ? nameParts.first : normalizedName;
    final lastName =
        nameParts.length > 1 ? nameParts.sublist(1).join(' ') : firstName;

    final response = await _apiClient.post(
      ApiEndpoints.authRegister,
      data: {
        'firstName': firstName,
        'lastName': lastName,
        'name': normalizedName,
        'email': user.email,
        'password': user.password,
        'confirmPassword': user.password,
      },
    );

    if (response.data['success'] == true) {
      final data = response.data['data'] as Map<String, dynamic>;
      final registeredUser = AuthApiModel.fromJson(data);
      final registeredUserId =
          (data['_id'] ?? data['id'] ?? registeredUser.id ?? '').toString();

      if (registeredUserId.isEmpty) {
        throw Exception('User id missing in registration response');
      }

      await _userSessionService.saveUserSession(
        userId: registeredUserId,
        email: registeredUser.email,
        fullName: registeredUser.fullName,
      );

      return registeredUser;
    } else {
      throw Exception(response.data['message'] ?? 'Registration failed');
    }
  }
  
  
}
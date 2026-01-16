import 'package:hive/hive.dart';
import 'package:matchpoint/core/constants/hive_table_constants.dart';
import 'package:matchpoint/features/auth/domain/entities/auth_entity.dart';
import 'package:uuid/uuid.dart';

part 'auth_hive_model.g.dart';

@HiveType(typeId: HiveTableConstants.authTypeId)
class AuthHiveModel extends HiveObject {
  @HiveField(0)
  final String? authId;

  @HiveField(1)
  final String fullName;

  @HiveField(2)
  final String username;

  @HiveField(3)
  final String email;

  @HiveField(4)
  final String? password;



  AuthHiveModel({
    String? authId,
    required this.fullName,
    required this.username,
    required this.email,
    this.password,
  }) : authId = authId ?? const Uuid().v4();

  // ✅ change: take AuthEntity, not AuthHiveModel
  factory AuthHiveModel.fromEntity(AuthEntity entity) {
    return AuthHiveModel(
      authId: entity.authId, // ✅ map userId -> authId
      fullName: entity.fullName,
      username: entity.username,
      email: entity.email,
      password: entity.password,
    );
  }

  // ✅ change: AuthEntity expects userId (not authId)
  AuthEntity toEntity() {
    return AuthEntity(
      authId: authId, // ✅ map authId -> userId
      fullName: fullName,
      username: username,
      email: email,
      password: password,
    );
  }
}
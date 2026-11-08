import 'package:equatable/equatable.dart';

class UserModel extends Equatable {
  final String id;
  final String email;
  final String displayName;

  const UserModel({
    required this.id,
    required this.email,
    required this.displayName,
  });

  static const empty = UserModel(id: '', email: '', displayName: '');

  bool get isEmpty => this == empty;
  bool get isNotEmpty => this != empty;

  @override
  List<Object?> get props => [id, email, displayName];
}


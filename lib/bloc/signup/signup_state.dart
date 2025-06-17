import 'package:equatable/equatable.dart';

class SignupState extends Equatable {
  final String username;
  final String email;
  final String password;
  final String reenterPassword;
  final bool obscureTextPassword;
  final bool obscureTextReenterPassword;
  final bool isLoading;
  final String? errorMessage;
  final bool isSuccess;

  const SignupState({
    this.username = '',
    this.email = '',
    this.password = '',
    this.reenterPassword = '',
    this.obscureTextPassword = true,
    this.obscureTextReenterPassword = true,
    this.isLoading = false,
    this.errorMessage,
    this.isSuccess = false,
  });

  SignupState copyWith({
    String? username,
    String? email,
    String? password,
    String? reenterPassword,
    bool? obscureTextPassword,
    bool? obscureTextReenterPassword,
    bool? isLoading,
    String? errorMessage,
    bool? isSuccess,
  }) {
    return SignupState(
      username: username ?? this.username,
      email: email ?? this.email,
      password: password ?? this.password,
      reenterPassword: reenterPassword ?? this.reenterPassword,
      obscureTextPassword: obscureTextPassword ?? this.obscureTextPassword,
      obscureTextReenterPassword: obscureTextReenterPassword ?? this.obscureTextReenterPassword,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage,
      isSuccess: isSuccess ?? false,
    );
  }

  @override
  List<Object?> get props => [
    username,
    email,
    password,
    reenterPassword,
    obscureTextPassword,
    obscureTextReenterPassword,
    isLoading,
    errorMessage,
    isSuccess,
  ];
}

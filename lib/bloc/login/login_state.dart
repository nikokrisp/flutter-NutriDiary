import 'package:equatable/equatable.dart';

class LoginState extends Equatable {
  final String email;
  final String password;
  final bool obscureText;
  final bool isLoading;
  final String? errorMessage;
  final bool isSuccess;

  const LoginState({
    this.email = '',
    this.password = '',
    this.obscureText = true,
    this.isLoading = false,
    this.errorMessage,
    this.isSuccess = false,
  });

  LoginState copyWith({
    String? email,
    String? password,
    bool? obscureText,
    bool? isLoading,
    String? errorMessage,
    bool? isSuccess,
  }) {
    return LoginState(
      email: email ?? this.email,
      password: password ?? this.password,
      obscureText: obscureText ?? this.obscureText,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage,
      isSuccess: isSuccess ?? false,
    );
  }

  @override
  List<Object?> get props => [email, password, obscureText, isLoading, errorMessage, isSuccess];
}

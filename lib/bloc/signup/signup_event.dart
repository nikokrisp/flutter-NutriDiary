import 'package:equatable/equatable.dart';

abstract class SignupEvent extends Equatable {
  @override
  List<Object?> get props => [];
}

class SignupUsernameChanged extends SignupEvent {
  final String username;
  SignupUsernameChanged(this.username);

  @override
  List<Object?> get props => [username];
}

class SignupEmailChanged extends SignupEvent {
  final String email;
  SignupEmailChanged(this.email);

  @override
  List<Object?> get props => [email];
}

class SignupPasswordChanged extends SignupEvent {
  final String password;
  SignupPasswordChanged(this.password);

  @override
  List<Object?> get props => [password];
}

class SignupReenterPasswordChanged extends SignupEvent {
  final String reenterPassword;
  SignupReenterPasswordChanged(this.reenterPassword);

  @override
  List<Object?> get props => [reenterPassword];
}

class SignupPasswordVisibilityToggled extends SignupEvent {}

class SignupReenterPasswordVisibilityToggled extends SignupEvent {}

class SignupSubmitted extends SignupEvent {}

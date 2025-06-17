import 'package:flutter_bloc/flutter_bloc.dart';
import 'signup_event.dart';
import 'signup_state.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';

class SignupBloc extends Bloc<SignupEvent, SignupState> {
  SignupBloc() : super(const SignupState()) {
    on<SignupUsernameChanged>((event, emit) {
      emit(state.copyWith(username: event.username, errorMessage: null));
    });
    on<SignupEmailChanged>((event, emit) {
      emit(state.copyWith(email: event.email, errorMessage: null));
    });
    on<SignupPasswordChanged>((event, emit) {
      emit(state.copyWith(password: event.password, errorMessage: null));
    });
    on<SignupReenterPasswordChanged>((event, emit) {
      emit(state.copyWith(reenterPassword: event.reenterPassword, errorMessage: null));
    });
    on<SignupPasswordVisibilityToggled>((event, emit) {
      emit(state.copyWith(obscureTextPassword: !state.obscureTextPassword));
    });
    on<SignupReenterPasswordVisibilityToggled>((event, emit) {
      emit(state.copyWith(obscureTextReenterPassword: !state.obscureTextReenterPassword));
    });
    on<SignupSubmitted>(_onSignupSubmitted);
  }

  Future<void> _onSignupSubmitted(SignupSubmitted event, Emitter<SignupState> emit) async {
    final username = state.username.trim();
    final email = state.email.trim();
    final password = state.password;
    final reenterPassword = state.reenterPassword;

    // Validation
    String? error;
    if (username.isEmpty) {
      error = 'Username is required.';
    } else if (username.length < 3) {
      error = 'Username must be at least 3 characters long.';
    } else if (username.length > 24) {
      error = 'Username must be less than 24 characters long.';
    } else if (!RegExp(r'^[a-zA-Z0-9_]+$').hasMatch(username)) {
      error = 'Username can only contain letters, numbers, and underscores.';
    } else if (email.isEmpty) {
      error = 'Email is required';
    } else if (!RegExp(r'^([a-zA-Z0-9_\-\.]+)@([a-zA-Z0-9_\-\.]+)\.([a-zA-Z]{2,5})$').hasMatch(email)) {
      error = 'Enter a valid email address.\nFormat: example@email.com';
    } else if (password.isEmpty) {
      error = 'Password is required.';
    } else if (password.length < 6) {
      error = 'Password must be at least 6 characters long.';
    } else if (reenterPassword.isEmpty) {
      error = 'Re-enter password is required.';
    } else if (reenterPassword != password) {
      error = 'Passwords do not match.';
    }

    if (error != null) {
      emit(state.copyWith(errorMessage: error));
      return;
    }

    emit(state.copyWith(isLoading: true, errorMessage: null, isSuccess: false));

    try {
      UserCredential userCredential = await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      User? user = userCredential.user;

      if (user != null) {
        await user.updateDisplayName(username);
        String uid = user.uid;
        await FirebaseDatabase.instance.ref('users/$uid').set({
          'username': username,
          'email': email,
          'profilePictureUrl': null,
        });
        emit(state.copyWith(isLoading: false, isSuccess: true, errorMessage: null));
      } else {
        emit(state.copyWith(isLoading: false, errorMessage: 'Signup failed. Please try again.', isSuccess: false));
      }
    } on FirebaseAuthException catch (e) {
      String errorMessage = 'An error occurred during signup.';
      if (e.code == 'weak-password') {
        errorMessage = 'The password provided is too weak.';
      } else if (e.code == 'email-already-in-use') {
        errorMessage = 'An account already exists for that email.';
      } else if (e.code == 'invalid-email') {
        errorMessage = 'The email address is not valid.';
      }
      emit(state.copyWith(isLoading: false, errorMessage: errorMessage, isSuccess: false));
    } catch (e) {
      emit(state.copyWith(isLoading: false, errorMessage: 'An unexpected error occurred: ${e.toString()}', isSuccess: false));
    }
  }
}

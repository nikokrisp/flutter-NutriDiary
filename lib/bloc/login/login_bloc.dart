import 'package:flutter_bloc/flutter_bloc.dart';
import 'login_event.dart';
import 'login_state.dart';
import 'package:flutter_nutridiary/providers/app_state_provider.dart';
import 'package:flutter_nutridiary/providers/item_provider.dart';
import 'package:flutter_nutridiary/providers/page_index_provider.dart';

class LoginBloc extends Bloc<LoginEvent, LoginState> {
  final AppStateProvider appStateProvider;
  final ItemProvider itemProvider;
  final PageIndexProvider pageIndexProvider;

  LoginBloc({
    required this.appStateProvider,
    required this.itemProvider,
    required this.pageIndexProvider,
  }) : super(const LoginState()) {
    on<LoginEmailChanged>((event, emit) {
      emit(state.copyWith(email: event.email, errorMessage: null));
    });

    on<LoginPasswordChanged>((event, emit) {
      emit(state.copyWith(password: event.password, errorMessage: null));
    });

    on<TogglePasswordVisibility>((event, emit) {
      emit(state.copyWith(obscureText: !state.obscureText));
    });

    on<LoginSubmitted>(_onLoginSubmitted);
  }

  Future<void> _onLoginSubmitted(LoginSubmitted event, Emitter<LoginState> emit) async {
    final email = state.email.trim();
    final password = state.password;
    final RegExp emailRegex = RegExp(
      r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$',
      caseSensitive: false,
    );

    if (email.isEmpty || password.isEmpty) {
      emit(state.copyWith(errorMessage: 'Please enter email and password'));
      return;
    }

    if (!emailRegex.hasMatch(email)) {
      emit(state.copyWith(errorMessage: 'Please enter a valid email address format.'));
      return;
    }

    emit(state.copyWith(isLoading: true, errorMessage: null, isSuccess: false));

    try {
      String? errorMessage = await appStateProvider.performFirebaseLogin(email, password);

      if (errorMessage == null) {
        pageIndexProvider.setIndex(1);
        final String? userId = appStateProvider.currentUserId;
        if (userId != null) {
          itemProvider.clearFavoriteItems();
          await itemProvider.getFavoriteItems();
        }
        emit(state.copyWith(isLoading: false, isSuccess: true, errorMessage: null, email: '', password: ''));
      } else {
        emit(state.copyWith(isLoading: false, errorMessage: errorMessage, isSuccess: false));
      }
    } catch (e) {
      emit(state.copyWith(isLoading: false, errorMessage: 'An unexpected error occurred. Please try again.', isSuccess: false));
    }
  }
}

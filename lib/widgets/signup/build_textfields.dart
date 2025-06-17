import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_nutridiary/bloc/signup/signup_bloc.dart';
import 'package:flutter_nutridiary/bloc/signup/signup_state.dart';
import 'package:flutter_nutridiary/bloc/signup/signup_event.dart';

// Place these at the top of the file, outside any class
final GlobalKey<UsernameFieldState> usernameKey = GlobalKey<UsernameFieldState>();
final GlobalKey<EmailFieldState> emailKey = GlobalKey<EmailFieldState>();
final GlobalKey<PasswordFieldState> passwordKey = GlobalKey<PasswordFieldState>();
final GlobalKey<ReenterPasswordFieldState> reenterPasswordKey = GlobalKey<ReenterPasswordFieldState>();

// UsernameField
class UsernameField extends StatefulWidget {
  final double horizontalPadding;
  const UsernameField({super.key, required this.horizontalPadding});
  @override
  State<UsernameField> createState() => UsernameFieldState();
}

class UsernameFieldState extends State<UsernameField> {
  final FocusNode _focusNode = FocusNode();
  final TextEditingController _controller = TextEditingController();

  @override
  void dispose() {
    _focusNode.dispose();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<SignupBloc, SignupState>(
      buildWhen: (prev, curr) => prev.username != curr.username,
      builder: (context, state) {
        if (_controller.text != state.username) {
          _controller.value = TextEditingValue(
            text: state.username,
            selection: TextSelection.collapsed(offset: state.username.length),
          );
        }
        return Container(
          margin: EdgeInsets.symmetric(horizontal: widget.horizontalPadding),
          child: TextFormField(
            controller: _controller,
            focusNode: _focusNode,
            decoration: InputDecoration(
              fillColor: const Color(0xFF2196F3).withAlpha(50), // blue
              filled: true,
              labelStyle: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w500),
              disabledBorder: OutlineInputBorder(
                borderSide: BorderSide(color: Colors.white70),
              ),
              enabledBorder: OutlineInputBorder(
                borderSide: BorderSide(color: Colors.white70),
              ),
              focusedBorder: OutlineInputBorder(
                borderSide: BorderSide(color: Colors.white70),
              ),
              labelText: 'Username',
              border: OutlineInputBorder(),
              prefixIcon: Icon(Icons.person, color: Colors.white70),
            ),
            onChanged: (value) => context.read<SignupBloc>().add(SignupUsernameChanged(value)),
            textInputAction: TextInputAction.next,
            onFieldSubmitted: (_) {
              final nextState = emailKey.currentState;
              if (nextState != null && nextState.mounted) {
                FocusScope.of(context).requestFocus(nextState._focusNode);
              } else {
                FocusScope.of(context).unfocus();
              }
            },
          ),
        );
      },
    );
  }
}

// EmailField
class EmailField extends StatefulWidget {
  final double horizontalPadding;
  const EmailField({super.key, required this.horizontalPadding});
  @override
  State<EmailField> createState() => EmailFieldState();
}

class EmailFieldState extends State<EmailField> {
  final FocusNode _focusNode = FocusNode();
  final TextEditingController _controller = TextEditingController();

  @override
  void dispose() {
    _focusNode.dispose();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<SignupBloc, SignupState>(
      buildWhen: (prev, curr) => prev.email != curr.email,
      builder: (context, state) {
        if (_controller.text != state.email) {
          _controller.value = TextEditingValue(
            text: state.email,
            selection: TextSelection.collapsed(offset: state.email.length),
          );
        }
        return Container(
          margin: EdgeInsets.symmetric(horizontal: widget.horizontalPadding),
          child: TextFormField(
            controller: _controller,
            focusNode: _focusNode,
            decoration: InputDecoration(
              fillColor: const Color(0xFF2196F3).withAlpha(50), // blue
              filled: true,
              labelStyle: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w500),
              disabledBorder: OutlineInputBorder(
                borderSide: BorderSide(color: Colors.white70),
              ),
              enabledBorder: OutlineInputBorder(
                borderSide: BorderSide(color: Colors.white70),
              ),
              focusedBorder: OutlineInputBorder(
                borderSide: BorderSide(color: Colors.white70),
              ),
              labelText: 'Email Address',
              border: OutlineInputBorder(),
              prefixIcon: Icon(Icons.email, color: Colors.white70),
            ),
            keyboardType: TextInputType.emailAddress,
            onChanged: (value) => context.read<SignupBloc>().add(SignupEmailChanged(value)),
            textInputAction: TextInputAction.next,
            onFieldSubmitted: (_) {
              final nextState = passwordKey.currentState;
              if (nextState != null && nextState.mounted) {
                FocusScope.of(context).requestFocus(nextState._focusNode);
              } else {
                FocusScope.of(context).unfocus();
              }
            },
          ),
        );
      },
    );
  }
}

// PasswordField
class PasswordField extends StatefulWidget {
  final double horizontalPadding;
  const PasswordField({super.key, required this.horizontalPadding});
  @override
  State<PasswordField> createState() => PasswordFieldState();
}

class PasswordFieldState extends State<PasswordField> {
  final FocusNode _focusNode = FocusNode();
  final TextEditingController _controller = TextEditingController();

  @override
  void dispose() {
    _focusNode.dispose();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<SignupBloc, SignupState>(
      buildWhen: (prev, curr) =>
          prev.password != curr.password ||
          prev.obscureTextPassword != curr.obscureTextPassword,
      builder: (context, state) {
        if (_controller.text != state.password) {
          _controller.value = TextEditingValue(
            text: state.password,
            selection: TextSelection.collapsed(offset: state.password.length),
          );
        }
        return Container(
          margin: EdgeInsets.symmetric(horizontal: widget.horizontalPadding),
          child: TextFormField(
            controller: _controller,
            focusNode: _focusNode,
            decoration: InputDecoration(
              fillColor: const Color(0xFF2196F3).withAlpha(50), // blue
              filled: true,
              labelStyle: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w500),
              disabledBorder: OutlineInputBorder(
                borderSide: BorderSide(color: Colors.white70),
              ),
              enabledBorder: OutlineInputBorder(
                borderSide: BorderSide(color: Colors.white70),
              ),
              focusedBorder: OutlineInputBorder(
                borderSide: BorderSide(color: Colors.white70),
              ),
              labelText: 'Password',
              border: OutlineInputBorder(),
              prefixIcon: Icon(Icons.lock, color: Colors.white70),
              suffixIcon: IconButton(
                onPressed: () {
                  context.read<SignupBloc>().add(SignupPasswordVisibilityToggled());
                },
                icon: Icon(
                  state.obscureTextPassword ? Icons.visibility : Icons.visibility_off,
                  color: Colors.white70,
                ),
              ),
            ),
            obscureText: state.obscureTextPassword,
            onChanged: (value) => context.read<SignupBloc>().add(SignupPasswordChanged(value)),
            textInputAction: TextInputAction.next,
            onFieldSubmitted: (_) {
              final nextState = reenterPasswordKey.currentState;
              if (nextState != null && nextState.mounted) {
                FocusScope.of(context).requestFocus(nextState._focusNode);
              } else {
                FocusScope.of(context).unfocus();
              }
            },
          ),
        );
      },
    );
  }
}

// ReenterPasswordField
class ReenterPasswordField extends StatefulWidget {
  final double horizontalPadding;
  const ReenterPasswordField({super.key, required this.horizontalPadding});
  @override
  State<ReenterPasswordField> createState() => ReenterPasswordFieldState();
}

class ReenterPasswordFieldState extends State<ReenterPasswordField> {
  final FocusNode _focusNode = FocusNode();
  final TextEditingController _controller = TextEditingController();

  @override
  void dispose() {
    _focusNode.dispose();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<SignupBloc, SignupState>(
      buildWhen: (prev, curr) =>
          prev.reenterPassword != curr.reenterPassword ||
          prev.obscureTextReenterPassword != curr.obscureTextReenterPassword,
      builder: (context, state) {
        if (_controller.text != state.reenterPassword) {
          _controller.value = TextEditingValue(
            text: state.reenterPassword,
            selection: TextSelection.collapsed(offset: state.reenterPassword.length),
          );
        }
        return Container(
          margin: EdgeInsets.symmetric(horizontal: widget.horizontalPadding),
          child: TextFormField(
            controller: _controller,
            focusNode: _focusNode,
            decoration: InputDecoration(
              fillColor: const Color(0xFF2196F3).withAlpha(50), // blue
              filled: true,
              labelStyle: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w500),
              disabledBorder: OutlineInputBorder(
                borderSide: BorderSide(color: Colors.white70),
              ),
              enabledBorder: OutlineInputBorder(
                borderSide: BorderSide(color: Colors.white70),
              ),
              focusedBorder: OutlineInputBorder(
                borderSide: BorderSide(color: Colors.white70),
              ),
              labelText: 'Re-enter Password',
              border: OutlineInputBorder(),
              prefixIcon: Icon(Icons.lock, color: Colors.white70),
              suffixIcon: IconButton(
                onPressed: () {
                  context.read<SignupBloc>().add(SignupReenterPasswordVisibilityToggled());
                },
                icon: Icon(
                  state.obscureTextReenterPassword ? Icons.visibility : Icons.visibility_off,
                  color: Colors.white70,
                ),
              ),
            ),
            obscureText: state.obscureTextReenterPassword,
            onChanged: (value) => context.read<SignupBloc>().add(SignupReenterPasswordChanged(value)),
            textInputAction: TextInputAction.done,
            onFieldSubmitted: (_) {
              FocusScope.of(context).unfocus();
              context.read<SignupBloc>().add(SignupSubmitted());
            },
          ),
        );
      },
    );
  }
}
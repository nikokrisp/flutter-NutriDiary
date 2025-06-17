import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_nutridiary/bloc/login/login_bloc.dart';
import 'package:flutter_nutridiary/bloc/login/login_event.dart';
import 'package:flutter_nutridiary/bloc/login/login_state.dart';

class LoginTextFields extends StatefulWidget {
  final double horizontalPadding;
  const LoginTextFields({super.key, required this.horizontalPadding, required this.state, required this.bloc});
  final LoginState state;
  final LoginBloc bloc;

  @override
  State<LoginTextFields> createState() => _LoginTextFieldsState();
}

class _LoginTextFieldsState extends State<LoginTextFields> {
  late final TextEditingController _emailController;
  late final TextEditingController _passwordController;
  final FocusNode _emailFocus = FocusNode();
  final FocusNode _passwordFocus = FocusNode();

  @override
  void initState() {
    super.initState();
    _emailController = TextEditingController(text: widget.state.email);
    _passwordController = TextEditingController(text: widget.state.password);
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _emailFocus.dispose();
    _passwordFocus.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        BlocBuilder<LoginBloc, LoginState>(
          buildWhen: (prev, curr) => prev.email != curr.email,
          builder: (context, state) {
            if (_emailController.text != state.email) {
              _emailController.value = TextEditingValue(
                text: state.email,
                selection: TextSelection.collapsed(offset: state.email.length),
              );
            }
            return Container(
              margin: EdgeInsets.symmetric(horizontal: widget.horizontalPadding),
              child: TextFormField(
                style: TextStyle(color: Colors.white),
                cursorColor: Colors.white70,
                controller: _emailController,
                focusNode: _emailFocus,
                decoration: InputDecoration(
                  fillColor: Colors.lightBlue.shade400.withAlpha(180), // blue
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
                  labelText: 'Email',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.person, color: Colors.white70),
                ),
                onChanged: (value) => context.read<LoginBloc>().add(LoginEmailChanged(value)),
                textInputAction: TextInputAction.next,
                onFieldSubmitted: (_) {
                  FocusScope.of(context).requestFocus(_passwordFocus);
                },
              ),
            );
          },
        ),
        SizedBox(height: (MediaQuery.of(context).size.height - MediaQuery.of(context).padding.top) * 0.01),
        BlocBuilder<LoginBloc, LoginState>(
          buildWhen: (prev, curr) => prev.password != curr.password || prev.obscureText != curr.obscureText,
          builder: (context, state) {
            if (_passwordController.text != state.password) {
              _passwordController.value = TextEditingValue(
                text: state.password,
                selection: TextSelection.collapsed(offset: state.password.length),
              );
            }
            return Container(
              margin: EdgeInsets.symmetric(horizontal: widget.horizontalPadding),
              child: TextFormField(
                style: TextStyle(color: Colors.white),
                cursorColor: Colors.white70,
                controller: _passwordController,
                focusNode: _passwordFocus,
                decoration: InputDecoration(
                  fillColor: Colors.lightBlue.shade400.withAlpha(180), // blue
                  filled: true,
                  labelStyle: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w500), 
                  disabledBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: Colors.white70),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: Colors.white70),
                  ),
                  focusColor: Colors.white70,
                  focusedBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: Colors.white70),
                  ),
                  labelText: 'Password',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.lock, color: Colors.white70),
                  suffixIcon: IconButton(
                    onPressed: () {
                      context.read<LoginBloc>().add(TogglePasswordVisibility());
                    },
                    icon: Icon(
                      state.obscureText ? Icons.visibility : Icons.visibility_off,
                      color: Colors.white70,
                    ),
                  ),
                ),
                obscureText: state.obscureText,
                onChanged: (value) => context.read<LoginBloc>().add(LoginPasswordChanged(value)),
                textInputAction: TextInputAction.done,
                onFieldSubmitted: (_) {
                  FocusScope.of(context).unfocus();
                  context.read<LoginBloc>().add(LoginSubmitted());
                },
              ),
            );
          }
        ),
      ],
    );
  }
}

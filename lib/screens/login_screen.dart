import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_nutridiary/providers/page_index_provider.dart';
import 'package:flutter_nutridiary/screens/signup_screen.dart';
import 'package:provider/provider.dart';
import 'package:flutter_nutridiary/providers/app_state_provider.dart';
import 'package:flutter_nutridiary/providers/item_provider.dart';
// import 'package:flutter_nutridiary/providers/session_provider.dart';
// Add BLoC imports
import 'package:flutter_nutridiary/bloc/login/login_bloc.dart';
import 'package:flutter_nutridiary/bloc/login/login_event.dart';
import 'package:flutter_nutridiary/bloc/login/login_state.dart';
import 'package:flutter_nutridiary/widgets/login/build_textfields.dart';
import 'package:flutter_nutridiary/widgets/login_gradient.dart';

class LoginScreen extends StatelessWidget {
  const LoginScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height - MediaQuery.of(context).padding.top;
    final screenWidth = MediaQuery.of(context).size.width;
    final horizontalPadding = screenWidth * 0.05;

    return BlocProvider(
      create: (context) => LoginBloc(
        appStateProvider: Provider.of<AppStateProvider>(context, listen: false),
        itemProvider: Provider.of<ItemProvider>(context, listen: false),
        pageIndexProvider: Provider.of<PageIndexProvider>(context, listen: false),
      ),
      child: BlocConsumer<LoginBloc, LoginState>(
        listener: (context, state) {
          if (state.isSuccess) {
            // ScaffoldMessenger.of(context).showSnackBar(
            //   const SnackBar(content: Text('Login successful!')),
            // );
            // Session removed
          } else if (state.errorMessage != null && state.errorMessage!.isNotEmpty) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(state.errorMessage!)),
            );
          }
        },
        builder: (context, state) {
          final bloc = context.read<LoginBloc>();

          return Scaffold(
            body: Stack(
              children: [
                // Animated mesh gradient background
                const AnimatedMeshBackground(),
                // Foreground content
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Center(
                    child: Container(
                      height: screenHeight * 0.5,
                      width: screenWidth * 0.8,
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            Color.fromARGB(150, 201, 232, 2),
                            Color.fromARGB(150, 87, 149, 0), 
                          ],
                        ),
                        borderRadius: BorderRadius.circular(12.0),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black12,
                            offset: Offset(0, 2),
                            blurRadius: 8.0,
                          ),
                        ],
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          SizedBox(
                            width: screenWidth * 0.5,
                            height: screenHeight * 0.1,
                            child: Center(
                              child: RichText(
                                text: TextSpan(
                                  children: <TextSpan>[
                                    TextSpan(
                                      text: 'Nutri',
                                      style: TextStyle(
                                        fontFamily: 'Pacifico',
                                        fontWeight: FontWeight.normal,
                                        fontSize: 40,
                                        color: Color(0xFFF94144),
                                      ),
                                    ),
                                    TextSpan(
                                      text: 'Diary',
                                      style: TextStyle(
                                        fontFamily: 'Lato',
                                        fontWeight: FontWeight.bold,
                                        fontSize: 40,
                                        color: Color(0xFF577590),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                          LoginTextFields(
                            horizontalPadding: horizontalPadding,
                            state: state,
                            bloc: bloc,
                          ),
                          SizedBox(height: screenHeight * 0.02),
                          ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.lightBlue, // blue
                              foregroundColor: Colors.white, // label pure white
                              textStyle: TextStyle(fontWeight: FontWeight.bold),
                              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 14),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                            onPressed: state.isLoading
                                ? null
                                : () {
                                    bloc.add(LoginSubmitted());
                                  },
                            child: state.isLoading
                                ? SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                                  )
                                : Text('Login'),
                          ),
                          SizedBox(height: 20),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text("Don't have an account yet? ",
                                style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
                            GestureDetector(
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(builder: (context) => SignupScreen()),
                                  );
                                },
                              child: Text(
                                "Make an account.",
                                style: TextStyle(
                                  color: Colors.blue,
                                  decoration: TextDecoration.underline,
                                  fontWeight: FontWeight.bold,
                                  decorationColor: Colors.blue
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

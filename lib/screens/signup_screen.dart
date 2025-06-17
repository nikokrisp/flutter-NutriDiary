import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_nutridiary/screens/profilepic_screen.dart';
// Add BLoC imports
import 'package:flutter_nutridiary/bloc/signup/signup_bloc.dart';
import 'package:flutter_nutridiary/bloc/signup/signup_event.dart';
import 'package:flutter_nutridiary/bloc/signup/signup_state.dart';
import 'package:flutter_nutridiary/widgets/signup/build_textfields.dart';
import 'package:flutter_nutridiary/widgets/login_gradient.dart';

class SignupScreen extends StatelessWidget {
  const SignupScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final horizontalPadding = screenWidth * 0.18;

    return BlocProvider(
      create: (_) => SignupBloc(),
      child: BlocConsumer<SignupBloc, SignupState>(
        listener: (context, state) async {
          if (state.isSuccess) {
            final user = FirebaseAuth.instance.currentUser;
            if (user != null) {
              // Go to profile picture screen after signup
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => SelectProfilePictureScreen(uid: user.uid, onProfilePicComplete: () async {
                    // After profile picture, sign out and pop to login
                    await FirebaseAuth.instance.signOut();
                    if (context.mounted) {
                      Navigator.of(context).popUntil((route) => route.isFirst);
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Account created! Please log in.')),
                      );
                    }
                  }),
                ),
              );
            }
          } else if (state.errorMessage != null && state.errorMessage!.isNotEmpty) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(state.errorMessage!)),
            );
          }
        },
        builder: (context, state) {
          return Scaffold(
            appBar: AppBar(title: Text('Sign Up')),
            body: Stack(
              children: [
                // Animated mesh gradient background
                const AnimatedMeshBackground(),
                Center(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(24.0),
                    child: state.isLoading
                        ? Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              CircularProgressIndicator(),
                              SizedBox(height: 20),
                              Text('Signing up...'),
                            ],
                          )
                        : Form(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                SizedBox(
                                  width: screenWidth * 0.75,
                                  height: 80,
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
                                UsernameField(key: usernameKey, horizontalPadding: horizontalPadding),
                                SizedBox(height: 20),
                                EmailField(key: emailKey, horizontalPadding: horizontalPadding),
                                SizedBox(height: 20),
                                PasswordField(key: passwordKey, horizontalPadding: horizontalPadding),
                                SizedBox(height: 20),
                                ReenterPasswordField(key: reenterPasswordKey, horizontalPadding: horizontalPadding),
                                SizedBox(height: 30),
                                Container(
                                  margin: EdgeInsets.symmetric(horizontal: screenWidth * 0.25),
                                  child: ElevatedButton(
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Color(0xFF2196F3), // blue
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
                                            context.read<SignupBloc>().add(SignupSubmitted());
                                          },
                                    child: state.isLoading
                                        ? SizedBox(
                                            width: 20,
                                            height: 20,
                                            child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                                          )
                                        : Text('Sign Up'),
                                  ),
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

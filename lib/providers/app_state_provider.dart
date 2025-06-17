import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart'; // <-- Needed to fetch username

class AppStateProvider extends ChangeNotifier {
  // Theme state can remain as is
  bool _isDarkMode = true;
  bool get isDarkMode => _isDarkMode;
  void toggleTheme(bool isDarkMode) {
    _isDarkMode = isDarkMode;
    notifyListeners();
  }

  // --- Firebase Auth State ---
  User? _currentUser; // Holds the Firebase Auth User object
  String? _profileUsername; // Holds the username fetched from RTDB profile data
  String? _profilePictureUrl; // Holds the profile picture URL (if needed)

  User? get currentUser => _currentUser;
  String? get currentUserId => _currentUser?.uid; // Easy access to UID

  // Derive login state directly from _currentUser
  bool get isLoggedIn => _currentUser != null;

  // Getter for the profile username
  String? get profileUsername => _profileUsername;
  String? get profilePictureUrl => _profilePictureUrl; // Getter for profile picture URL

  // --- Loading State ---
  // Loading state for async operations like login, fetching profile/claims
  bool _isLoading = false;
  bool get isLoading => _isLoading;

  // --- Add state properties for admin roles based on Custom Claims ---
  bool _isAdmin = false;
  bool get isAdmin => _isAdmin; // Getter for isAdmin status

  bool _isSuperAdmin = false;
  bool get isSuperAdmin => _isSuperAdmin; // Getter for isSuperAdmin status
  // --- End new properties ---


  // Constructor or init method to start listening to auth state changes
  AppStateProvider() {
    // Start listening to auth state changes as soon as the provider is created.
    // The listener will handle fetching profile/claims and updating state.
    setupAuthStateListener();
  }

  // Method to perform Firebase login
  Future<String?> performFirebaseLogin(String email, String password) async {
    String? resultErrorMessage;

    // --- Start Loading State Update ---
    _isLoading = true;
    notifyListeners(); // Notify to show loading indicator immediately

    try {
      final UserCredential userCredential = await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      // Authentication successful! Set the current user.
      _currentUser = userCredential.user;
      debugPrint('[_performFirebaseLogin] User logged in: ${_currentUser?.uid}');

      // --- Fetch profile data AND claims immediately on successful login ---
      if (_currentUser != null) {
         // Await both fetching operations
         await _fetchUserProfile(_currentUser!.uid); // Your existing profile fetch
         await _fetchAndSetClaims(_currentUser!); // <-- NEW: Fetch and set claims
         // --- Remove session reset hack ---
      }

      // resultErrorMessage remains null on success

    } on FirebaseAuthException catch (e) {
      // Authentication failed with a Firebase Auth specific error
      _currentUser = null; // Ensure user is null on failure
      _profileUsername = null; // Clear profile data on failure
      _profilePictureUrl = null;
      // Clear admin status on failure
      _isAdmin = false;
      _isSuperAdmin = false;


      // Determine the specific error message to return based on code
      if (e.code == 'user-not-found') {
        resultErrorMessage = 'No account found with this email.';
      } else if (e.code == 'wrong-password' || e.code == 'invalid-credential') {
        // Use 'invalid-credential' for newer Firebase Auth versions
        resultErrorMessage = 'Incorrect email or password. Please try again.';
      } else if (e.code == 'invalid-email') {
        resultErrorMessage = 'The email address format is invalid.';
      } else if (e.code == 'user-disabled') {
        resultErrorMessage = 'This account has been disabled.';
      } else {
        debugPrint('Unhandled FirebaseAuthException code in login: ${e.code}');
        resultErrorMessage = 'Login failed: ${e.message}';
      }

    } catch (e) {
      // Catch any other unexpected errors
      _currentUser = null;
      _profileUsername = null;
      _profilePictureUrl = null;
      _isAdmin = false; // Clear admin status on error
      _isSuperAdmin = false;
      debugPrint('An unexpected error occurred in performFirebaseLogin: $e');
      resultErrorMessage = 'An unexpected error occurred. Please try again.';
    } finally {
        // --- Stop Loading State and Notify Listeners ONCE ---
        // This happens after try/catch and all state is set.
        _isLoading = false;
        notifyListeners(); // <-- Notify listeners after ALL state updates
    }

    return resultErrorMessage; // Return the error message or null
  }

  // Logout method
  Future<void> logout() async {
    _isLoading = true; // Indicate loading while signing out
    notifyListeners(); // Notify to potentially show a loading state

    try {
        await FirebaseAuth.instance.signOut();
        // The authStateChanges listener will handle setting _currentUser to null
        // and clearing other states like profile data and claims.
    } catch (e) {
        debugPrint('Error during logout: $e');
        // Handle logout error if necessary
    } finally {
        // The authStateChanges listener's null user case will set isLoading=false and notify.
        // We don't strictly need notifyListeners() here again, but no harm in adding it.
        // _isLoading = false; // Done by listener
        // notifyListeners(); // Done by listener
    }
  }

  // Method to listen to auth state changes on app startup and whenever auth state changes
  // This is the main handler for updating state based on authentication.
  void setupAuthStateListener() {
    FirebaseAuth.instance.authStateChanges().listen((User? user) async {
      debugPrint('Auth state changed. User: ${user?.uid ?? "null"}');

      _currentUser = user; // Update the Firebase User object

      // --- Start Loading State if user becomes non-null (logging in/reloading app) ---
      // Only set loading if user is NOT null. If user is null, we are signing out,
      // and the process is usually quick, or the logout method already handled loading.
      bool wasLoading = _isLoading; // Keep track of whether we were already loading
      if (user != null && !wasLoading) {
         _isLoading = true;
         // notifyListeners(); // Optional: Notify immediately to show loading *before* fetching
      }

      if (user != null) {
        debugPrint('Auth state change: User is signed in with UID: ${user.uid}');
        // --- User just logged in or app started with logged-in user ---
        // Fetch profile data AND claims when user is set
        await _fetchUserProfile(user.uid); // Your existing profile fetch
        await _fetchAndSetClaims(user); // <-- NEW: Fetch and set claims

      } else {
        debugPrint('Auth state change: User is signed out.');
        // --- User just logged out or app started signed out ---
        // Clear all user-specific state
        _profileUsername = null;
        _profilePictureUrl = null;
        _isAdmin = false; // Clear admin status when signed out
        _isSuperAdmin = false;
        // Clear any other user-specific data like favorited items etc.
        // Consider using a pattern like a callback passed to AppStateProvider or a Stream
      }

      // --- Stop Loading State and Notify Listeners ONCE ---
      // This happens after all async operations within the listener complete
      // and all dependent state variables have been updated.
      _isLoading = false; // Ensure loading is off
      notifyListeners(); // Notify listeners whenever state changes based on auth
    }, onError: (e) {
       // Handle errors in the auth state listener itself
       debugPrint('Error in authStateChanges listener: $e');
       // Clear state on error as a fallback
       _isLoading = false;
       _currentUser = null;
       _profileUsername = null;
       _profilePictureUrl = null;
       _isAdmin = false;
       _isSuperAdmin = false;
       notifyListeners();
    });
  }

  // --- NEW: Method to fetch and set user claims ---
  Future<void> _fetchAndSetClaims(User user) async {
    debugPrint('[_fetchAndSetClaims] Attempting to fetch claims for UID: ${user.uid}');
    try {
      // Force refresh the token to ensure we get the latest claims
      IdTokenResult idTokenResult = await user.getIdTokenResult(true);
      Map<String, dynamic>? claims = idTokenResult.claims;

      // Safely set the admin and superadmin flags based on claims
      _isAdmin = claims?['admin'] == true;
      _isSuperAdmin = claims?['superadmin'] == true;

      debugPrint('[_fetchAndSetClaims] Fetched claims: $claims');
      debugPrint('[_fetchAndSetClaims] Is Admin: $_isAdmin, Is Super Admin: $_isSuperAdmin');

    } catch (e) {
      debugPrint('[_fetchAndSetClaims] Error fetching claims for UID ${user.uid}: $e');
      // On error, default to non-admin
      _isAdmin = false;
      _isSuperAdmin = false;
    }
    // Note: notifyListeners is NOT called here. The caller (the listener or login method)
    // will call notifyListeners AFTER this Future completes and other state is updated.
  }


  // --- Your existing method to fetch user profile data from RTDB (looks good!) ---
  Future<void> _fetchUserProfile(String uid) async {
    debugPrint('[_fetchUserProfile] Attempting to fetch profile for UID: $uid');
    try {
      DatabaseReference userRef = FirebaseDatabase.instance.ref('users/$uid');
      DataSnapshot snapshot = await userRef.get();

      if (snapshot.exists) {
        Map<dynamic, dynamic>? userData = snapshot.value as Map<dynamic, dynamic>?;
        debugPrint('[_fetchUserProfile] Raw snapshot value: ${snapshot.value.toString()}');

        if (userData != null) {
          _profileUsername = userData['username']?.toString() ?? 'No Username Set';
          debugPrint('[_fetchUserProfile] Fetched profile username: $_profileUsername');

          _profilePictureUrl = userData['profilePictureUrl']?.toString();
          if (_profilePictureUrl != null && _profilePictureUrl!.isNotEmpty) {
              debugPrint('[_fetchUserProfile] Fetched profile picture URL: $_profilePictureUrl');
          } else {
              debugPrint('[_fetchUserProfile] Profile picture URL field missing or empty.');
              _profilePictureUrl = null;
          }
        } else {
          _profileUsername = 'Profile Data Null';
          _profilePictureUrl = null;
          debugPrint('[_fetchUserProfile] User data map is null for UID: $uid');
        }
      } else {
        _profileUsername = 'Profile Not Found';
        _profilePictureUrl = null;
        debugPrint('[_fetchUserProfile] User profile node not found in RTDB for UID: $uid');
      }
    } catch (e) {
       debugPrint('[_fetchUserProfile] Error fetching user profile for UID $uid: $e');
       _profileUsername = 'Error Loading Username';
       _profilePictureUrl = null;
    }
    // Note: notifyListeners is NOT called here. The caller will call it.
  }

  // Add a method to manually refresh claims if needed from outside the provider
  // This is useful if you set claims via the function and want the UI to update immediately.
  Future<void> refreshClaims() async {
     User? user = FirebaseAuth.instance.currentUser;
     if (user != null) {
        _isLoading = true;
        notifyListeners(); // Indicate loading while refreshing

        try {
           await _fetchAndSetClaims(user); // Use the internal method
        } catch (e) {
            // Error handled within _fetchAndSetClaims
        } finally {
            _isLoading = false;
            notifyListeners(); // Notify after refresh
        }
     }
  }

}

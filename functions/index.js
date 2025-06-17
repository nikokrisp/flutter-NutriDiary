const functions = require("firebase-functions");
// const admin = require("firebase-admin"); // <-- Comment this line out or remove it

let admin = null; // Declare a variable to hold the initialized admin app

// This is our Callable Cloud Function to set a custom claim
exports.setAdminClaim = functions.https.onCall(async (data, context) => {

  // --- Lazy Initialization of Firebase Admin SDK ---
  // Check if the admin SDK has already been initialized for this function instance
  if (!admin) {
    // The Admin SDK is not initialized yet, initialize it now.
    // require it here
    admin = require('firebase-admin');
    // Initialize the app - uses application default credentials provided by the environment
    // If deploying functions via `firebase init`, this will often use projectId etc from the environment
    admin.initializeApp();
    // Optional: Log to see when initialization happens (helpful for debugging)
    console.log('Firebase Admin SDK initialized for setAdminClaim function.');
  }
  // --- End Lazy Initialization ---

  // Now 'admin' is guaranteed to be initialized and ready to use
  const auth = admin.auth(); // Get the auth service from the initialized admin app

  // 1. Check if the user making the request is authenticated
  //    Callable functions automatically provide auth context.
  if (!context.auth) {
    // Throwing an HttpsError is the standard way to
    // report errors from Callable Functions
    throw new functions.https.HttpsError(
        "unauthenticated",
        "The function must be called while authenticated.",
    );
  }

  // *** IMPORTANT SECURITY CHECK ***
  // 2. Validate that the authenticated user (the caller) is authorized
  //    to set admin claims. You MUST implement a check here!
  //    Let's assume for this example that only users with a
  //    'superadmin' claim can proceed.

  const callerUid = context.auth.uid;

  // Get the user record for the caller to check their custom claims
  // Use the initialized 'auth' object here
  const callerUserRecord = await auth.getUser(callerUid);
  const callerClaims = callerUserRecord.customClaims;

  // Check if the caller has the 'superadmin' claim set to true
  if (!(callerClaims && callerClaims.superadmin === true)) {
    throw new functions.https.HttpsError(
        "permission-denied",
        "Only authorized users can set admin claims.",
    );
  }
  //    *** END IMPORTANT SECURITY CHECK ***

  // Let's proceed assuming the caller is authorized!

  // 3. Get the UID of the target user from the data passed to the function
  const targetUid = data.targetUid;

  // 4. Basic validation of the input
  if (!targetUid || typeof targetUid !== "string") {
    throw new functions.https.HttpsError(
        "invalid-argument",
        "The function must be called with a targetUid" +
        " parameter containing the user ID to make admin.",
    );
  }

  try {
    // 5. Set the custom claim on the target user's account
    // Use the initialized 'auth' object here
    await auth.setCustomUserClaims(targetUid, {admin: true});

    // 6. Optionally, inform the user that their claims have been updated.
    //    Setting claims doesn't immediately update the client-side token.
    //    The client will need to re-authenticate or refresh their token
    //    to get the new claims. Sending a message or trigger via FCM
    //    could be useful here, but for now, we'll just return success.

    console.log(`Successfully set admin claim for user ${targetUid}`);

    // 7. Return a success response
    return {
      message: `Success! User ${targetUid} is now an admin.`,
    };
  } catch (error) {
    // If there's an error setting the claims (e.g., UID not found)
    console.error("Error setting custom claims:", error);
    throw new functions.https.HttpsError(
        "internal", // Or 'not-found' if you checked for user existence first
        "An error occurred while setting the admin claim.",
        error.message, // Include the original error message for debugging
    );
  }
});

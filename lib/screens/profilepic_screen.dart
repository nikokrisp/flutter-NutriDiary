// ignore_for_file: use_build_context_synchronously

import 'package:flutter/material.dart';
import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:provider/provider.dart';
import 'package:flutter_nutridiary/providers/app_state_provider.dart';
// Import the image manipulation library
import 'package:image/image.dart' as img;
import 'dart:typed_data'; // Needed for Uint8List
import 'package:image_cropper/image_cropper.dart';

class SelectProfilePictureScreen extends StatefulWidget {
  // We receive the user's unique ID (UID) when navigating to this screen.
  final String uid;
  final VoidCallback? onProfilePicComplete; // Note: this callback isn't used in the current navigation flow.

  const SelectProfilePictureScreen({super.key, required this.uid, this.onProfilePicComplete});

  @override
  SelectProfilePictureScreenState createState() => SelectProfilePictureScreenState();
}

class SelectProfilePictureScreenState extends State<SelectProfilePictureScreen> {
  // State variable to hold the selected image file from the user's device.
  File? _selectedImageFile;
  // State variable to indicate if an upload (including resizing) is in progress.
  bool _isUploading = false;
  // Instance of ImagePicker to handle picking images.
  final ImagePicker _picker = ImagePicker();

  // --- UI Widgets ---

  // Widget to display the circular profile picture area.
  Widget _buildProfilePictureArea() {
    // If an image is selected, show it. Otherwise, show a placeholder icon.
    // While uploading/resizing, we can still show the selected image but indicate busyness
    return CircleAvatar(
      radius: 80, // Set the size of the circle
      backgroundColor: Colors.grey[300], // Placeholder background color
      backgroundImage: _selectedImageFile != null
          ? FileImage(_selectedImageFile!) // Use the selected image file
          : null, // No background image if no file is selected
      child: _selectedImageFile == null
          ? Icon(
              Icons.person, // Placeholder icon
              size: 80,
              color: Colors.grey[600],
            )
          : null, // No icon if an image is displayed
    );
  }

  // --- Image Picking and Upload Logic ---

  // Function to open the gallery and let the user pick an image.
  Future<void> _pickImage() async {
    // Prevent picking a new image if an operation is already in progress
    if (_isUploading) return;

    // Use the ImagePicker to get an image from the gallery.
    final pickedFile = await _picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 85, // Let's use slightly higher quality after resizing
      maxWidth: 1024, // Pick a larger source for potential resizing
      maxHeight: 1024, // Pick a larger source for potential resizing
    );

    if (pickedFile != null) {
      // Prompt user to crop/zoom
      final croppedFile = await ImageCropper().cropImage(
        sourcePath: pickedFile.path,
        aspectRatio: CropAspectRatio(ratioX: 1, ratioY: 1), // Square crop for profile
        uiSettings: [
          AndroidUiSettings(
            toolbarTitle: 'Crop your profile picture',
            lockAspectRatio: true,
          ),
          IOSUiSettings(
            title: 'Crop your profile picture',
            aspectRatioLockEnabled: true,
          ),
        ],
      );

      if (croppedFile != null) {
        setState(() {
          _selectedImageFile = File(croppedFile.path);
          _isUploading = false;
        });
      }
    } else {
      // Handle the case where the user cancels the picker.
      debugPrint('No image selected.');
      if (context.mounted) {
         ScaffoldMessenger.of(context).showSnackBar(
           const SnackBar(content: Text('No image selected.')),
         );
      }
    }
  }

  // Function to resize the selected image and upload it to Firebase Storage
  // and save the download URL to Realtime Database.
  Future<void> _processAndUploadPicture() async {
    // Check if an image file has been selected.
    if (_selectedImageFile == null) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please select a picture first.')),
        );
      }
      return; // Stop the function here
    }

    // Prevent multiple taps while processing/uploading
    if (_isUploading) return;


    setState(() {
      _isUploading = true; // Show loading indicator
    });

    Uint8List? resizedImageBytes; // Will hold the bytes of the resized image

    try {
      // --- Step 1: Resize the image locally ---
      // Read the file bytes
      List<int> imageBytes = await _selectedImageFile!.readAsBytes();

      // Convert List<int> to Uint8List for image package compatibility
      Uint8List imageBytesUint8 = Uint8List.fromList(imageBytes);

      // Decode the image
      img.Image? originalImage = img.decodeImage(imageBytesUint8);

      if (originalImage == null) {
         throw Exception("Could not decode image file.");
      }

      // Resize the image.
      // We'll resize to a square (e.g., 200x200). You might want different logic
      // here like cropping or fitting while maintaining aspect ratio depending on needs.
      // This example uses copyResize which will stretch/squash if dimensions don't match ratio.
      // For a profile pic, a common approach is to resize the smaller dimension and then crop center.
      // Let's aim for a size suitable for a profile icon, e.g., 200x200 pixels.
      // We can also ensure it's smaller overall if it was huge. Let's cap max dimension too.

      // A better approach for profile pics: resize to fit within a square boundary
       img.Image resizedImage = img.copyResize(originalImage, width: 200, height: 200); // Example size


      // Encode the resized image back to JPEG format with a specific quality
      resizedImageBytes = img.encodeJpg(resizedImage, quality: 85); // 85% quality

      // --- Step 2: Upload the resized image bytes to Cloud Storage ---
      // Define the storage path. Use a unique filename to avoid overwriting,
      // and maybe include size info.
      String uniqueFileName = '${widget.uid}_${DateTime.now().millisecondsSinceEpoch}_200x200.jpg';
      // Store resized images separately
      String storagePath = 'profile_pictures_resized/${widget.uid}/$uniqueFileName';

      // Create a reference to the location in Cloud Storage.
      Reference storageRef = FirebaseStorage.instance.ref().child(storagePath);

      // Upload the resized image bytes (Uint8List)
      UploadTask uploadTask = storageRef.putData(resizedImageBytes);

      // Optional: Listen for upload progress (this is upload of the resized image)
      uploadTask.snapshotEvents.listen((TaskSnapshot snapshot) {
        debugPrint('Upload progress (resized): ${snapshot.bytesTransferred}/${snapshot.totalBytes}');
        // You could use this to update a progress bar in the UI
      });

      // Wait for the upload to complete
      TaskSnapshot snapshot = await uploadTask;

      // --- Step 3: Get the download URL for the uploaded resized image ---
      String downloadUrl = await snapshot.ref.getDownloadURL();
      debugPrint('Uploaded resized image URL: $downloadUrl');

      // --- Step 4: Update the user's data in Realtime Database ---
      await FirebaseDatabase.instance.ref('users/${widget.uid}').update({
        'profilePictureUrl': downloadUrl,
      });
       debugPrint('Database updated with URL');


      // --- Step 5: Success! ---
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Profile picture saved successfully!')),
        );
        await _signOutAndGoToLogin(); // Navigate away
      }

    } on Exception catch (e) { // Catching base Exception to include image processing errors
       debugPrint('Error during picture process/upload: ${e.toString()}');
       String errorMessage = 'An error occurred while processing or uploading your picture.';
       if (e is FirebaseException) {
           errorMessage = 'Firebase Error: ${e.message}';
            if (e.code == 'storage/unauthorized') {
               errorMessage = 'You do not have permission to upload.'; // Check your Storage rules!
            }
       } else if (e.toString().contains("Could not decode image")) {
           errorMessage = "Could not process the selected image format.";
       }
       // Add more specific error handling for the image library if needed

       if (context.mounted) {
         ScaffoldMessenger.of(context).showSnackBar(
           SnackBar(content: Text(errorMessage)),
         );
       }
    } finally {
      // This block runs regardless of success or failure.
      // Stop the loading indicator.
      setState(() {
        _isUploading = false;
      });
      // Clear selected image after attempt (optional, depends on desired flow)
      // setState(() {
      //    _selectedImageFile = null;
      // });
    }
  }

  // Function to handle skipping the picture selection.
  void _skipPicture() {
    // Prevent skipping while an operation is in progress
    if (_isUploading) return;
    _signOutAndGoToLogin();
  }

  // Helper function to sign out and navigate back to the login screen.
  Future<void> _signOutAndGoToLogin() async {
    // Ensure you don't trigger navigation if widget is disposed during async op
     if (!mounted) return;

    try {
        // Assuming logout handles Firebase Auth signOut and potentially other app state cleanup
        final appState = Provider.of<AppStateProvider>(context, listen: false);
        await appState.logout();
    } catch (e) {
        debugPrint('Error during logout: $e');
        // Optionally inform user logout failed but proceed with navigation?
        if (context.mounted) {
             ScaffoldMessenger.of(context).showSnackBar(
               SnackBar(content: Text("Logout failed: ${e.toString()}")),
             );
        }
    }

    // Check context validity again before navigating and showing SnackBar
    if (context.mounted) {
      Navigator.of(context).popUntil((route) => route.isFirst);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("You've successfully added a new account! Please log in.")),
      );
    }
  }


  // Note: removed redundant context.mounted checks like context.mounted ? context : context
  // Just using context is fine after the initial if(context.mounted) check.


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Add Profile Picture'),
        // If you want to prevent the user from going back without making a choice,
        // you can remove or customize the back button:
        automaticallyImplyLeading: false,
        actions: [
          IconButton(
            icon: const Icon(Icons.skip_next),
            tooltip: 'Skip',
            onPressed: _isUploading ? null : _skipPicture, // Disable skip while uploading
          ),
        ],
      ),
      body: Center( // Center the content vertically and horizontally
        child: SingleChildScrollView( // Allows scrolling if content overflows
          padding: const EdgeInsets.all(24.0),
          child: _isUploading
              ? Column( // Show spinner and message if uploading/resizing
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: const [
                    CircularProgressIndicator(),
                    SizedBox(height: 20),
                    // More descriptive text since it includes processing now
                    Text('Processing and uploading picture...'),
                  ],
                )
              : Column( // Show the main content when not uploading
                  mainAxisAlignment: MainAxisAlignment.center, // Center column content
                  crossAxisAlignment: CrossAxisAlignment.stretch, // Stretch buttons horizontally
                  children: <Widget>[
                    const Text(
                      'Add a Profile Picture',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 40),

                    // Display the profile picture area
                    Align( // Use Align to center the CircleAvatar
                      alignment: Alignment.center,
                      child: _buildProfilePictureArea(),
                    ),
                    const SizedBox(height: 30),

                    // Button to pick image from gallery
                    // Disabled if an operation is in progress
                    Align(
                      alignment: Alignment.center,
                      child: SizedBox(
                        width: MediaQuery.of(context).size.width * 0.6,
                        child: ElevatedButton.icon(
                          onPressed: _isUploading ? null : _pickImage,
                          icon: Icon(Icons.photo_library, color: _isUploading ? Colors.grey[300] : Color(0xFF388E3C)),
                          label: Text(
                            'Select Picture from Gallery',
                            style: TextStyle(
                              color: _isUploading ? Colors.white : Color(0xFF388E3C),
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: _isUploading
                                ? Colors.grey[200] // Grey when disabled
                                : const Color(0xFFA5E1A6), // Pastel green when enabled
                            padding: const EdgeInsets.symmetric(vertical: 12),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 15),

                    // Button to process, upload, and save the picture
                    // Disabled if no image is selected or if an operation is in progress
                    Align(
                      alignment: Alignment.center,
                      child: SizedBox(
                        width: MediaQuery.of(context).size.width * 0.6,
                        child: ElevatedButton.icon(
                          onPressed: _selectedImageFile != null && !_isUploading
                              ? _processAndUploadPicture // Call the new function name
                              : null, // Disable button
                          icon: Icon(Icons.cloud_upload, color: _selectedImageFile != null && !_isUploading ? Color(0xFF388E3C) : Colors.grey[300]),
                          label: Text(
                            'Upload and Save',
                            style: TextStyle(
                              color: _selectedImageFile != null && !_isUploading ? Color(0xFF388E3C) : Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: _selectedImageFile != null && !_isUploading
                                ? const Color(0xFFA5E1A6)
                                : Colors.grey[200], // Pastel green when enabled, grey when disabled
                            padding: const EdgeInsets.symmetric(vertical: 12),
                          ),
                        ),
                      ),
                    ),
                     const SizedBox(height: 15), // <-- This is where the previous snippet ended

                    // Button to skip adding a picture
                    TextButton(
                      onPressed: _isUploading ? null : _skipPicture, // Disable skip while uploading
                      child: Text('Skip for now', 
                        style: TextStyle(
                          color: !_isUploading ? Color.fromARGB(255, 40, 40, 255) : Color(0xFF800080), // Use the same color as the upload button
                          fontWeight: FontWeight.bold,
                          decoration: TextDecoration.underline,
                          decorationColor: !_isUploading ? Color.fromARGB(255, 40, 40, 255) : Color(0xFF800080), // Underline color
                        ),
                      ),
                    ),
                  ],
                ),
        ),
      ),
    );
  }
}

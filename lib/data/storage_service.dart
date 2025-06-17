import 'dart:io'; // Required for File

import 'package:firebase_storage/firebase_storage.dart'; // Required for Cloud Storage interaction
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart'; // Required to get local file paths

/// Downloads a file from Firebase Cloud Storage to the application's documents directory.
/// If the file already exists locally, it returns the existing path without re-downloading.
/// Returns the local file path on success, or null on failure.
Future<String?> downloadFileAndGetLocalPath(String storagePath) async {
  if (storagePath.isEmpty) {
    debugPrint("[downloadFileAndGetLocalPath] Error: storagePath is empty.");
    return null;
  }

  try {
    // Get a reference to the file in Cloud Storage
    final storageRef = FirebaseStorage.instance.ref().child(storagePath);

    // Determine the local directory to save the file
    final appDocDir = await getApplicationDocumentsDirectory();

    // Use the file name from the storage path for the local file name
    final String fileName = storageRef.name;

    // Create a specific subdirectory for downloaded images for organization
    final downloadDir = Directory('${appDocDir.path}/downloaded_images');

    // Ensure the subdirectory exists
    if (!await downloadDir.exists()) {
        await downloadDir.create(recursive: true);
        debugPrint("[downloadFileAndGetLocalPath] Created local directory: ${downloadDir.path}");
    }

    // Construct the full local file path
    final String filePath = "${downloadDir.path}/$fileName";
    final File localFile = File(filePath);

    // Check if the file already exists locally to avoid re-downloading
    if (await localFile.exists()) {
      debugPrint("[downloadFileAndGetLocalPath] File '$fileName' already exists locally at: $filePath. Skipping download.");
      return filePath; // Return the path to the existing local file
    }

    debugPrint("[downloadFileAndGetLocalPath] Starting download for '$fileName' from Cloud Storage path: $storagePath");

    // Initiate the download task
    final downloadTask = storageRef.writeToFile(localFile);

    // You can add snapshot listeners here if you want to track progress,
    // but awaiting the task is sufficient for waiting for completion.
    // downloadTask.snapshotEvents.listen((TaskSnapshot taskSnapshot) { ... });

    // Wait for the download task to complete
    await downloadTask;

    debugPrint("[downloadFileAndGetLocalPath] Download of '$fileName' successful to: $filePath");
    return filePath; // Return the path to the newly downloaded local file

  } on FirebaseException catch (e) {
    // Handle specific Firebase Storage errors
    debugPrint("[downloadFileAndGetLocalPath] Firebase download error for '$storagePath': ${e.code} - ${e.message}");
    // You might want to handle specific error codes like 'object-not-found' differently
    return null; // Indicate failure
  } catch (e) {
    // Handle any other unexpected errors
    debugPrint("[downloadFileAndGetLocalPath] General download error for '$storagePath': $e");
    return null; // Indicate failure
  }
}

// You can add other Cloud Storage related utility functions here if needed later,
// e.g., uploadFile, deleteFile, etc.

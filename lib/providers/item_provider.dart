import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_nutridiary/data/model.dart';
// import 'package:http/http.dart' as http;
// import 'dart:convert';
// Import Firebase SDKs
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';

class FoodItem {
  final int foodId;
  final String imageUrl;
  final String name;
  final String description;
  final double calories;
  final double sugar;
  final double fat;
  final double carbo;
  final double protein;
  final double sodium;

  FoodItem({
    required this.foodId,
    required this.imageUrl,
    required this.name,
    required this.description,
    required this.calories,
    required this.sugar,
    required this.fat,
    required this.carbo,
    required this.protein,
    required this.sodium,
  });
}

class ItemProvider extends ChangeNotifier {
  // Food Items
  final List<FoodItem> _allFoodItems = [
    FoodItem(
      foodId: 1,
      imageUrl: "images/apple pic.webp",
      name: "Apple",
      description: "An apple a day keeps the doctor away. \nApples are extremely rich in important antioxidants, flavanoids, and dietary fiber.",
      calories: 52.0,
      sugar: 10.0,
      fat: 0.2,
      carbo: 14.0,
      protein: 0.3,
      sodium: 1,
    ),
    FoodItem(
      foodId: 2,
      imageUrl: "images/orange pic.jpeg",
      name: "Orange",
      description: "Oranges are a good source of vitamin C and potassium. \nThey also contain fiber, antioxidants, and other vitamins.",
      calories: 49.0,
      sugar: 8.5,
      fat: 0.2,
      carbo: 13.0,
      protein: 0.9,
      sodium: 1.0,
    ),
    FoodItem(
      foodId: 3,
      imageUrl: "images/banana pic.jpg",
      name: "Banana",
      description: "Bananas are rich in potassium and vitamin C. \nThey are also a good source of dietary fiber.",
      calories: 89.0,
      sugar: 12.0,
      fat: 0.3,
      carbo: 22.8,
      protein: 1.1,
      sodium: 1.0,
    ),
    FoodItem(
      foodId: 4,
      imageUrl: "images/melon pic.png",
      name: "Melon",
      description: "Melons like cantaloupe and honeydew are low in calories and rich in vitamins, minerals, and antioxidants, making them a healthy and hydrating snack. They are particularly good sources of Vitamin C and potassium.",
      calories: 34.0,
      sugar: 7.9,
      fat: 0.2,
      carbo: 8.2,
      protein: 0.8,
      sodium: 16.0,
    ),
    FoodItem(
      foodId: 5,
      imageUrl: "images/watermelon pic.jpg",
      name: "Watermelon",
      description: "Watermelons are hydrating fruits that are low in calories. \nThey are a good source of vitamins A and C.",
      calories: 30.0,
      sugar: 6.2,
      fat: 0.2,
      carbo: 7.6,
      protein: 0.6,
      sodium: 1,
    ),
    FoodItem(
      foodId: 6,
      imageUrl: "images/carrot pic.webp",
      name: "Carrot",
      description: "Carrots are root vegetables that are highly nutritious. \nThey are an excellent source of beta carotene, fiber, and antioxidants.",
      calories: 35.0,
      sugar: 3.5,
      fat: 0.2,
      carbo: 8.2,
      protein: 0.8,
      sodium: 2.8,
    )
  ];

  final List<FoodItem>  _favoriteFoodItems = [];

  List<FoodItem> get allFoodItems => List.unmodifiable(_allFoodItems);
  List<FoodItem> get favoriteFoodItems => List.unmodifiable(_favoriteFoodItems);

  // Variable to hold the auth state listener subscription
  late StreamSubscription<User?> _authStateChangesSubscription;

  // Constructor or Init method
  ItemProvider() {
    _initialize();
  }

  void _initialize() {
    // Set up the auth state listener
    _authStateChangesSubscription = FirebaseAuth.instance.authStateChanges().listen((User? user) {
      if (user != null) {
        // User is signed in. Fetch their favorite items.
        debugPrint('Auth state changed: User ${user.uid} is signed in. Fetching favorites...');
        getFavoriteItems(); // Call the SDK-based getFavoriteItems
      } else {
        // User is signed out. Clear the favorite items list.
        debugPrint('Auth state changed: User is signed out. Clearing favorites...');
        clearFavoriteItems(); // Call the clear function
      }
    });

    // You might want to immediately check the current user state when the provider is created
    // in case the authStateChanges stream hasn't emitted the initial value yet.
    // However, the listen callback *does* typically get called with the initial state.
    // Leaving this out for simplicity, but keep in mind if you see delays.
    // final user = FirebaseAuth.instance.currentUser;
    // if (user != null) {
    //   getFavoriteItems();
    // } else {
    //   clearFavoriteItems();
    // }
  }


  void toggleFavoriteFood(FoodItem item) async {
    // The methods below will get the UID from FirebaseAuth.instance.currentUser

    debugPrint('Toggling favorite for: ${item.name}');
    if (isFavoriteFood(item)) {
      debugPrint('Item is already a favorite. Removing...');
      await deleteFavoriteItem(item); // Call the modified delete method
    } else {
      debugPrint('Item is not a favorite. Adding...');
      await postFavoriteItem(item); // Call the modified post method
    }
    debugPrint('Fetching updated favorite items...');
    await getFavoriteItems(); // Call the modified get method
    debugPrint('Updated favorite items: $_favoriteFoodItems');
    notifyListeners();
  }

  bool isFavoriteFood(FoodItem item) {
    return _favoriteFoodItems.any((favorite) => favorite.foodId == item.foodId);
  }

  Future<void> postFavoriteItem(FoodItem item) async {
    // 1. Get the current authenticated user's UID using FirebaseAuth
    User? user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      // Handle the case where the user is not logged in
      debugPrint('Error posting favorite item: User not logged in');
      // Consider showing a message to the user or navigating to login
      return; // Exit the function if no user is logged in
    }

    // 2. Create a DatabaseReference to the specific location
    // This path maps to /FavoriteItems/{user.uid}/{item.foodId} in your RTDB
    final DatabaseReference favoriteItemRef = FirebaseDatabase.instance.ref()
      .child('FavoriteItems') // Go to the 'FavoriteItems' node
      .child(user.uid)       // Go under the logged-in user's UID
      .child(item.foodId.toString()); // Use the foodId as the key (needs to be a string in RTDB paths)

    // 3. Prepare the data. Use ServerValue.timestamp for creation time.
    final favoriteItemData = {
      'foodId': item.foodId,
      'imageUrl': item.imageUrl,
      'name': item.name,
      'description': item.description,
      'calories': item.calories,
      'sugar': item.sugar,
      'fat': item.fat,
      'carbo': item.carbo,
      'protein': item.protein,
      'sodium': item.sodium,
      'CreatedAt': DateTime.now().toIso8601String(), // Use server timestamp
    };

    try {
      // 4. Use the SDK's set() method to write (or overwrite) the data
      await favoriteItemRef.set(favoriteItemData);
      debugPrint('Successfully added favorite item: ${item.name} for user ${user.uid}');
    } on FirebaseException catch (e) {
       debugPrint('Firebase Error posting favorite item: ${e.message}');
       // Handle specific Firebase errors (e.g., permission denied will be caught here if rules fail)
       throw Exception('Failed to post favorite item: ${e.message}');
    } catch (error) {
      debugPrint('Generic Error posting favorite item: $error');
       // Catch any other errors during the process
      throw Exception('Failed to post favorite item: $error');
    }
  }

  Future<void> deleteFavoriteItem(FoodItem item) async {
    // 1. Get the current authenticated user's UID
    User? user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      debugPrint('Error deleting favorite item: User not logged in');
       // Consider showing a message to the user or navigating to login
      return; // Exit if user is not logged in
    }

    // 2. Create a DatabaseReference to the specific item's location to delete
     // This path maps to /FavoriteItems/{user.uid}/{item.foodId}
    final DatabaseReference itemToDeleteRef = FirebaseDatabase.instance.ref()
      .child('FavoriteItems') // Go to the 'FavoriteItems' node
      .child(user.uid)       // Go under the logged-in user's UID
      .child(item.foodId.toString()); // Target the specific food item key

    try {
      // 3. Use the SDK's remove() method to delete the data
      await itemToDeleteRef.remove();
      debugPrint('Favorite item deleted successfully: ${item.name} for user ${user.uid}');
    } on FirebaseException catch (e) {
       debugPrint('Firebase Error deleting favorite item: ${e.message}');
        // Handle specific Firebase errors (e.g., permission denied)
       throw Exception('Failed to delete favorite item: ${e.message}');
    } catch (error) {
      debugPrint('Generic Error deleting favorite item: $error');
        // Catch any other errors
      throw Exception('Failed to delete favorite item: $error');
    }
  }

    Future<void> getFavoriteItems() async {
    User? user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      debugPrint('Error fetching favorite items: User not logged in');
      _favoriteFoodItems.clear();
      notifyListeners();
      return;
    }

    final DatabaseReference userFavoritesRef = FirebaseDatabase.instance.ref()
      .child('FavoriteItems')
      .child(user.uid); // Reference to the user's favorites node

    try {
      // Fetch the data once
      final DatabaseEvent event = await userFavoritesRef.once();
      // ignore: unnecessary_nullable_for_final_variable_declarations
      final DataSnapshot? snapshot = event.snapshot;

      _favoriteFoodItems.clear(); // Clear the current list

      if (snapshot != null && snapshot.value != null) {
         debugPrint('Raw snapshot value from database: ${snapshot.value}');

        // --- Parsing Logic Updated to Handle List OR Map ---

        final dynamic data = snapshot.value; // Get the raw value

        if (data is Map<dynamic, dynamic>) {
           // Case 1: Data is returned as a Map (preferred)
           debugPrint('Parsing data as Map...');
           data.forEach((key, value) {
             // 'key' is the foodId string (e.g., "1", "2")
             // 'value' is the map of data for that food item
              if (value != null && value is Map && value.containsKey('foodId')) {
                 try {
                   _favoriteFoodItems.add(FoodItem(
                     foodId: value['foodId'] is int ? value['foodId'] : int.parse(value['foodId'].toString()),
                     imageUrl: value['imageUrl'] ?? '',
                     name: value['name'] ?? 'Unknown',
                     description: value['description'] ?? '',
                     calories: (value['calories'] ?? 0).toDouble(),
                     sugar: (value['sugar'] ?? 0).toDouble(),
                     fat: (value['fat'] ?? 0).toDouble(),
                     carbo: (value['carbo'] ?? 0).toDouble(),
                     protein: (value['protein'] ?? 0).toDouble(),
                     sodium: (value['sodium'] ?? 0).toDouble(),
                   ));
                 } catch (e) {
                   debugPrint('Error parsing item from Map for key $key: $e');
                 }
             } else {
                debugPrint('Skipping unexpected item format in Map for key $key: $value');
             }
           });

        } else if (data is List<dynamic>) {
          // Case 2: Data is returned as a List (due to consecutive integer keys)
          debugPrint('Parsing data as List...');
          // Iterate through the list items
          for (var value in data) {
            // 'value' is the item data, potentially null for gaps
            if (value != null && value is Map && value.containsKey('foodId')) {
               try {
                 _favoriteFoodItems.add(FoodItem(
                   foodId: value['foodId'] is int ? value['foodId'] : int.parse(value['foodId'].toString()),
                   imageUrl: value['imageUrl'] ?? '',
                   name: value['name'] ?? 'Unknown',
                   description: value['description'] ?? '',
                   calories: (value['calories'] ?? 0).toDouble(),
                   sugar: (value['sugar'] ?? 0).toDouble(),
                   fat: (value['fat'] ?? 0).toDouble(),
                   carbo: (value['carbo'] ?? 0).toDouble(),
                   protein: (value['protein'] ?? 0).toDouble(),
                   sodium: (value['sodium'] ?? 0).toDouble(),
                 ));
               } catch (e) {
                 debugPrint('Error parsing item from List: $e');
               }
            } else {
               // This handles null values in the list (like the leading 'null')
               // and items that aren't Maps with a foodId
               debugPrint('Skipping null or unexpected item format in List: $value');
            }
          }
        } else {
           // Case 3: Data is not a Map or a List (unexpected)
           debugPrint('Unexpected snapshot value format: ${data.runtimeType}. Expected Map or List.');
           // Decide how to handle this - maybe clear the list and show an error
        }

        // --- End Parsing Logic ---

      } else {
        debugPrint('No favorite items found for user ${user.uid}. Snapshot value is null.');
      }

      debugPrint('Fetched favorite items count: ${_favoriteFoodItems.length}');
      notifyListeners(); // Notify listeners after the list is updated

    } on FirebaseException catch (e) {
       debugPrint('Firebase Error fetching favorite items: ${e.message}');
       // Handle specific Firebase errors (e.g., permission denied)
       throw Exception('Failed to fetch favorite items: ${e.message}');
    } catch (error) {
      debugPrint('Generic Error fetching favorite items: $error');
       // Catch any other errors
      throw Exception('Failed to fetch favorite items: $error');
    }
  }


  void clearFavoriteItems() {
    _favoriteFoodItems.clear();
    debugPrint('Favorite items list cleared.');
    notifyListeners();
  }

  // --- IMPORTANT: Dispose the listener when the provider is no longer needed ---
@override
void dispose() {
  debugPrint('ItemProvider disposing. Cancelling auth state listener.');
  _authStateChangesSubscription.cancel(); // Cancel the subscription
  super.dispose(); // Call the super class dispose
}


  // Insight Items
  final List<InsightItem> _allInsightItems = [
    InsightItem(
      foodId: 2,
      insightId: 1,
      imageUrl: "images/orange pic.jpeg",
      name: "Orange has its own special benefits other than being a source of Vitamin C!",
      description: "In addition to vitamin C, oranges have other nutrients that keep your body healthy.\n The fiber in oranges can keep blood sugar levels in check and reduce high cholesterol to prevent cardiovascular disease.\n Oranges contain approximately 55 milligrams of calcium, or 6% of your daily requirement.",
      source: "https://www.webmd.com/diet/health-benefits-oranges",
    ),
    InsightItem(
      foodId: 1,
      insightId: 2,
      imageUrl: "images/apple pic.webp",
      name: "Apples are great for your brain!",
      description: "Eating apples has been linked to improved brain health. They contain antioxidants that may help reduce the risk of neurodegenerative diseases like Alzheimer's.",
      source: "https://www.healthline.com/nutrition/foods/apples",
    ),
    InsightItem(
      foodId: 2,
      insightId: 3,
      imageUrl: "images/orange pic.jpeg",
      name: "Oranges can boost your immune system!",
      description: "Oranges are packed with vitamin C, which is essential for a healthy immune system. Regular consumption can help your body fight off colds and infections.",
      source: "https://www.medicalnewstoday.com/articles/272782",
    ),
    InsightItem(
      foodId: 2,
      insightId: 4,
      imageUrl: "images/orange pic.jpeg",
      name: "Oranges are good for your skin!",
      description: "The antioxidants in oranges, including vitamin C, can help protect your skin from damage caused by the sun and pollution. They also promote collagen production for healthy, glowing skin.",
      source: "https://www.stylecraze.com/articles/benefits-of-oranges/",
    ),
    InsightItem(
      foodId: 1,
      insightId: 5,
      imageUrl: "images/apple pic.webp",
      name: "Apples can help with weight management!",
      description: "Apples are low in calories and high in fiber, making them a great snack for weight management. Eating apples can help you feel full longer, reducing overall calorie intake.",
      source: "https://www.medicalnewstoday.com/articles/267290",
    ),
    InsightItem(
      foodId: 1,
      insightId: 6,
      imageUrl: "images/apple pic.webp",
      name: "Apples may lower the risk of diabetes!",
      description: "Studies have shown that eating apples is linked to a lower risk of type 2 diabetes. The polyphenols in apples may help prevent tissue damage to beta cells in your pancreas, which produce insulin.",
      source: "https://www.healthline.com/nutrition/foods/apples",
    ),
  ];

  List<InsightItem> get allInsightItems => List.unmodifiable(_allInsightItems);
}

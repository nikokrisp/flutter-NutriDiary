import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';

class DailyItem {
  final int foodId;
  final double amount;

  DailyItem({required this.foodId, required this.amount});

  factory DailyItem.fromMap(Map<dynamic, dynamic> map) {
    return DailyItem(
      foodId: map['foodId'] is int ? map['foodId'] : int.parse(map['foodId'].toString()),
      amount: (map['amount'] ?? 0).toDouble(),
    );
  }

  Map<String, dynamic> toMap() => {
    'foodId': foodId,
    'amount': amount,
  };
}

class DailyMealProvider extends ChangeNotifier {
  final List<DailyItem> _dailyItems = [];
  List<DailyItem> get dailyItems => List.unmodifiable(_dailyItems);

  Future<void> getDailyItems() async {
    User? user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      _dailyItems.clear();
      notifyListeners();
      return;
    }
    final DatabaseReference userDailyRef = FirebaseDatabase.instance.ref()
      .child('DailyItems')
      .child(user.uid);
    try {
      final DatabaseEvent event = await userDailyRef.once();
      final DataSnapshot snapshot = event.snapshot;
      _dailyItems.clear();
      if (snapshot.value != null) {
        final dynamic data = snapshot.value;
        if (data is Map<dynamic, dynamic>) {
          data.forEach((key, value) {
            if (value != null && value is Map && value.containsKey('foodId')) {
              _dailyItems.add(DailyItem.fromMap(value));
            }
          });
        } else if (data is List<dynamic>) {
          for (var value in data) {
            if (value != null && value is Map && value.containsKey('foodId')) {
              _dailyItems.add(DailyItem.fromMap(value));
            }
          }
        }
      }
      notifyListeners();
    } catch (e) {
      // Handle error
      rethrow;
    }
  }

  Future<void> postDailyItem(DailyItem item) async {
    User? user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    final DatabaseReference itemRef = FirebaseDatabase.instance.ref()
      .child('DailyItems')
      .child(user.uid)
      .child(item.foodId.toString());
    try {
      await itemRef.set(item.toMap());
      await getDailyItems();
    } catch (e) {
      rethrow;
    }
  }

  Future<void> deleteDailyItem(int foodId) async {
    User? user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    final DatabaseReference itemRef = FirebaseDatabase.instance.ref()
      .child('DailyItems')
      .child(user.uid)
      .child(foodId.toString());
    try {
      await itemRef.remove();
      await getDailyItems();
    } catch (e) {
      rethrow;
    }
  }

  Future<void> clearDailyItems() async {
    User? user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    final DatabaseReference userDailyRef = FirebaseDatabase.instance.ref()
      .child('DailyItems')
      .child(user.uid);
    try {
      await userDailyRef.remove();
      _dailyItems.clear();
      notifyListeners();
    } catch (e) {
      rethrow;
    }
  }
}
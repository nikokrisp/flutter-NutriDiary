import 'package:flutter/material.dart';
import 'daily_planner.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../providers/daily_meal_provider.dart';
import '../providers/item_provider.dart';
import 'dart:convert';

class DailyScreen extends StatefulWidget {
  const DailyScreen({super.key});

  @override
  DailyScreenState createState() => DailyScreenState();
}

class DailyScreenState extends State<DailyScreen> {
  String? expandedMeal; // Tracks which dropdown is open
  List<Map<String, dynamic>> tempDailyItems = [];
  bool allDone = false;
  bool loaded = false;
  DateTime? lastFetchedDate;
  bool noPlan = false;

  @override
  void initState() {
    super.initState();
    _loadOrFetchDailyItems();
  }

  Future<void> _loadOrFetchDailyItems() async {
    final prefs = await SharedPreferences.getInstance();
    final today = DateTime.now();
    final todayKey = "tempDailyItems_${today.year}_${today.month}_${today.day}";
    final lastFetchedString = prefs.getString('tempDailyItems_lastFetched');
    if (lastFetchedString != null) {
      lastFetchedDate = DateTime.tryParse(lastFetchedString);
    }
    if (lastFetchedDate != null &&
        lastFetchedDate!.year == today.year &&
        lastFetchedDate!.month == today.month &&
        lastFetchedDate!.day == today.day &&
        prefs.containsKey(todayKey)) {
      // Load from cache
      final cached = prefs.getString(todayKey);
      if (cached != null) {
        setState(() {
          tempDailyItems = List<Map<String, dynamic>>.from(json.decode(cached));
          allDone = tempDailyItems.isEmpty;
          loaded = true;
          noPlan = false;
        });
        return;
      }
    }
    // Fetch from provider
    // ignore: use_build_context_synchronously
    final dailyMealProvider = Provider.of<DailyMealProvider>(context, listen: false);
    final items = dailyMealProvider.dailyItems;
    if (items.isEmpty) {
      setState(() {
        tempDailyItems = [];
        allDone = false;
        loaded = true;
        noPlan = true;
      });
      await prefs.remove(todayKey);
      await prefs.remove('tempDailyItems_lastFetched');
      return;
    }
    tempDailyItems = items.map((e) => {
      'foodId': e.foodId,
      'amount': e.amount,
    }).toList();
    await prefs.setString(todayKey, json.encode(tempDailyItems));
    await prefs.setString('tempDailyItems_lastFetched', today.toIso8601String());
    setState(() {
      allDone = tempDailyItems.isEmpty;
      loaded = true;
      noPlan = false;
    });
  }

  void _decrementAmount(int foodId) async {
    final prefs = await SharedPreferences.getInstance();
    final today = DateTime.now();
    final todayKey = "tempDailyItems_${today.year}_${today.month}_${today.day}";
    setState(() {
      final idx = tempDailyItems.indexWhere((e) => e['foodId'] == foodId);
      if (idx != -1) {
        tempDailyItems[idx]['amount'] = (tempDailyItems[idx]['amount'] as num) - 1;
        if (tempDailyItems[idx]['amount'] <= 0) {
          tempDailyItems.removeAt(idx);
        }
      }
      allDone = tempDailyItems.isEmpty;
    });
    await prefs.setString(todayKey, json.encode(tempDailyItems));
    if (tempDailyItems.isEmpty) {
      if (mounted) {
        Future.delayed(Duration(milliseconds: 300), () {
          // ignore: use_build_context_synchronously
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text("You've done your daily meals! congrats!!"),
              backgroundColor: Colors.green,
              behavior: SnackBarBehavior.floating,
              margin: EdgeInsets.only(top: 40, left: 20, right: 20),
              duration: Duration(seconds: 2),
            ),
          );
        });
      }
    }
  }

  Map<String, bool> mealStatus = {
    "Morning": false,
    "Afternoon": false,
    "Night": false,
  };

  Map<String, String> mealTimes = {
    "Morning": "06:00 - 12:00",
    "Afternoon": "12:00 - 18:00",
    "Night": "18:00 - 00:00",
  };

  String getCurrentMeal() {
    final hour = DateTime.now().hour;
    if (hour >= 6 && hour < 12) return "Morning";
    if (hour >= 12 && hour < 18) return "Afternoon";
    if (hour >= 18 && hour < 23) return "Night";
    return "Midnight";
  }

  Color getRowColor(String meal) {
    final now = DateTime.now();
    final mealTimeString = mealTimes[meal];
    final status = mealStatus[meal];

    if (mealTimeString == null || status == null) {
      return Colors.grey; // fallback color for unknown meals
    }

    final mealTime = mealTimeString.split(' - ');
    final startHour = int.parse(mealTime[0].split(':')[0]);
    final endHour = int.parse(mealTime[1].split(':')[0]);

    if (now.hour >= startHour && now.hour < endHour) {
      return status ? Colors.green : Colors.red;
    }
    return Colors.grey;
  }

  String getMealBanner(String meal) {
    switch (meal) {
      case "Morning":
        return "images/morning banner.png";
      case "Afternoon":
        return "images/afternoon banner.png";
      case "Night":
        return "images/evening banner.png";
      default:
        return "images/morning banner.png"; // Fallback
    }
  }

  List<Color> getMealColors(String meal) {
    switch (meal) {
      case "Morning":
        return [Colors.amber.shade200, Colors.amber.shade100, Colors.amber.shade50];
      case "Afternoon":
        return [Colors.yellow.shade300, Colors.lightBlue.shade200, Colors.lightBlue.shade100, Colors.lightBlue.shade50];
      case "Night":
        return [Colors.indigo.shade900, Colors.indigo.shade700, Colors.deepPurple.shade400, Colors.deepPurple.shade200];
      default:
        return [Colors.grey.shade200, Colors.grey.shade100, Colors.grey.shade50]; // Fallback
    }
  }

  void confirmMeal(String meal) {
    setState(() {
      mealStatus[meal] = true;
    });
  }

  // --- DAILY MEAL UI ---
  @override
  Widget build(BuildContext context) {
    final appbarHeight = (MediaQuery.of(context).size.height - MediaQuery.of(context).padding.top) * 0.065;
    final screenHeight = MediaQuery.of(context).size.height - MediaQuery.of(context).padding.top - appbarHeight;
    final screenWidth = MediaQuery.of(context).size.width;
    final itemProvider = Provider.of<ItemProvider>(context, listen: false);

    return SingleChildScrollView(
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Container(
              height: screenHeight * 0.6,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: getMealColors(getCurrentMeal()),
                  begin: Alignment.topLeft,
                  end: Alignment.bottomCenter,
                ),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Column(
                children: [
                  Container(
                    height: screenHeight * 0.067,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      image: DecorationImage(
                        image: AssetImage(getMealBanner(getCurrentMeal())),
                        fit: BoxFit.cover,
                      ),
                      borderRadius: BorderRadius.only(topLeft: Radius.circular(5), topRight: Radius.circular(5)),
                    ),
                    child: Text(
                      "Daily Diet: ${getCurrentMeal() == "Midnight" ? "Midnight" : getCurrentMeal()}",
                      style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.lightGreen),
                    ),
                  ),
                  SizedBox(height: screenHeight * 0.02),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 8.0),
                      child: Builder(
                        builder: (context) {
                          if (!loaded) {
                            return Center(child: CircularProgressIndicator());
                          }
                          if (noPlan) {
                            return Align(
                              alignment: Alignment.topCenter,
                              child: Padding(
                                padding: const EdgeInsets.only(top: 16.0),
                                child: ShaderMask(
                                  shaderCallback: (Rect bounds) {
                                    return LinearGradient(
                                      colors: [Colors.green, Colors.white],
                                      begin: Alignment.topCenter,
                                      end: Alignment.bottomCenter,
                                    ).createShader(bounds);
                                  },
                                  child: Text(
                                    "Haven't made a plan yet",
                                    style: TextStyle(
                                      fontSize: 32,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                ),
                              ),
                            );
                          }
                          if (allDone) {
                            return Align(
                              alignment: Alignment.topCenter,
                              child: Padding(
                                padding: const EdgeInsets.only(top: 16.0),
                                child: ShaderMask(
                                  shaderCallback: (Rect bounds) {
                                    return LinearGradient(
                                      colors: [Colors.green, Colors.white],
                                      begin: Alignment.topCenter,
                                      end: Alignment.bottomCenter,
                                    ).createShader(bounds);
                                  },
                                  child: Text(
                                    "all done!",
                                    style: TextStyle(
                                      fontSize: 32,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                ),
                              ),
                            );
                          }
                          // Only ListTile and Text should have color, everything else is transparent
                          return ListView.separated(
                            itemCount: tempDailyItems.length,
                            physics: tempDailyItems.length > 3 ? ScrollPhysics() : NeverScrollableScrollPhysics(),
                            separatorBuilder: (context, idx) => SizedBox(height: 16),
                            itemBuilder: (context, idx) {
                              final foodId = tempDailyItems[idx]['foodId'];
                              final amount = tempDailyItems[idx]['amount'] is int
                                  ? tempDailyItems[idx]['amount']
                                  : (tempDailyItems[idx]['amount'] as num).toInt();
                              final foodItem = itemProvider.allFoodItems.firstWhere(
                                (e) => e.foodId == foodId,
                                orElse: () => itemProvider.allFoodItems.isNotEmpty ? itemProvider.allFoodItems.first : throw Exception('No food items'),
                              );
                              if (foodItem.foodId != foodId) return SizedBox.shrink();
                              final isDark = Theme.of(context).brightness == Brightness.dark;
                              final tileBg = isDark
                                  ? Color.fromARGB(150, 255, 255, 255) // Opaque white with alpha 150 for dark mode
                                  : Color.fromARGB(150, 0, 0, 0);      // Opaque black with alpha 150 for light mode
                              return Dismissible(
                                key: ValueKey(foodId),
                                direction: DismissDirection.endToStart,
                                onDismissed: (_) => _decrementAmount(foodId),
                                child: GestureDetector(
                                  onTap: () => _decrementAmount(foodId),
                                  child: AnimatedOpacity(
                                    opacity: amount > 0 ? 1.0 : 0.0,
                                    duration: Duration(milliseconds: 300),
                                    child: Container(
                                      decoration: BoxDecoration(
                                        color: tileBg,
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
                                      child: ListTile(
                                        contentPadding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                                        minVerticalPadding: 16,
                                        tileColor: Colors.transparent,
                                        leading: CircleAvatar(
                                          backgroundImage: AssetImage(foodItem.imageUrl),
                                          radius: 30,
                                          backgroundColor: Colors.transparent,
                                        ),
                                        title: Text(
                                          foodItem.name,
                                          style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 20,
                                            color: isDark ? Colors.black : Colors.white, // Ensure text is visible on tileBg
                                            shadows: [
                                              Shadow(
                                                blurRadius: 2,
                                                color: isDark ? Colors.white.withAlpha(51) : Colors.black.withAlpha(51),
                                                offset: Offset(0, 1),
                                              ),
                                            ],
                                          ),
                                        ),
                                        trailing: Container(
                                          padding: EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                                          decoration: BoxDecoration(
                                            color: Colors.green.shade100.withAlpha(179),
                                            borderRadius: BorderRadius.circular(12),
                                          ),
                                          child: Text(
                                            amount.toString(),
                                            style: TextStyle(
                                              fontWeight: FontWeight.bold,
                                              fontSize: 20,
                                              color: Colors.green.shade900,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              );
                            },
                          );
                        },
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: SizedBox(
              height: screenHeight * 0.3, // Adjust height as needed
              child: GridView.count(
                crossAxisCount: 2,
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
                childAspectRatio: 0.8, // Adjust for button shape
                shrinkWrap: true,
                physics: NeverScrollableScrollPhysics(),
                children: [
                  GestureDetector(
                    onTap: () async {
                      await Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => CreatePlanPage()),
                      );
                      // Refresh after returning from planner
                      await _loadOrFetchDailyItems();
                    },
                    child: Container(
                      height: screenHeight * 0.4,
                      padding: EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomLeft,
                          colors: [
                          Colors.amber.shade600,
                          Colors.amber.shade400,
                          Colors.amber.shade200
                          ]
                        ),
                        borderRadius: BorderRadius.circular(5),
                      ),
                      child: GridTile(
                        header: Text(
                          tempDailyItems.isNotEmpty ? "Change your Daily Plan" : "Create a daily plan",
                          style: TextStyle(
                            color: Theme.of(context).brightness == Brightness.dark ? Colors.white : Colors.black,
                            fontWeight: FontWeight.bold,
                            fontSize: 20,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        child: Icon(Icons.create_outlined, size: screenWidth * 0.25,),
                      ),
                    ),
                  ),
                  GestureDetector(
                    onTap: () {
                      showDialog(
                        context: context,
                        builder: (context) => QuickRecommendationDialog(),
                      );
                    },
                    child: Container(
                      height:  screenHeight * 0.4,
                      padding: EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomRight,
                          colors: [
                            Colors.green.shade500,
                            Colors.lightGreen.shade400,
                            Colors.lightGreen.shade300
                            ],
                        ),
                        borderRadius: BorderRadius.circular(5),
                      ),
                      child: GridTile(
                        header: Text("Quick Recommendation diet", style: TextStyle(color: Theme.of(context).brightness == Brightness.dark ? Colors.white : Colors.black, fontWeight: FontWeight.bold, fontSize: 20), textAlign: TextAlign.center,),
                        child: Icon(Icons.auto_awesome, size: screenWidth * 0.25,)),
                    ),
                  ),
                ],
              ),
            ),
          ),
          // 3. Add Delete Plan button below the two grid buttons
          if (true) // Always show the box, but greyed out if no plan
            Center(
              child: GestureDetector(
                onTap: tempDailyItems.isEmpty
                    ? null
                    : () async {
                        final prefs = await SharedPreferences.getInstance();
                        final today = DateTime.now();
                        final todayKey = "tempDailyItems_delete${today.year}_${today.month}_${today.day}";
                        await prefs.remove(todayKey);
                        await prefs.remove('tempDailyItems_lastFetched');
                        setState(() {
                          tempDailyItems.clear();
                          allDone = false;
                          loaded = true;
                          noPlan = true;
                        });
                      },
                child: Opacity(
                  opacity: tempDailyItems.isEmpty ? 0.5 : 1.0,
                  child: Container(
                    width: screenWidth * 0.95,
                    height: 70,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [Colors.red, Colors.red, Colors.red, Colors.red.shade300],
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                      ),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.delete, color: Theme.of(context).brightness == Brightness.dark ? Colors.white : Colors.black, size: 32),
                        SizedBox(width: 16),
                        Text(
                          "Delete your Daily Plan",
                          style: TextStyle(
                            color: Theme.of(context).brightness == Brightness.dark ? Colors.white : Colors.black,
                            fontWeight: FontWeight.bold,
                            fontSize: 22,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class QuickRecommendationDialog extends StatefulWidget {
  const QuickRecommendationDialog({super.key});

  @override
  QuickRecommendationDialogState createState() => QuickRecommendationDialogState();
}

class QuickRecommendationDialogState extends State<QuickRecommendationDialog> {
  List<String> availableGoals = ["Refreshing", "High Vitamin C"];
  late String selectedGoal; // Will be initialized in initState
  Map<String, List<Map<String, dynamic>>> mealRecommendations = {
    // Add default amounts for each food
    "Refreshing": [
      {"name": "Watermelon", "amount": 1},
      {"name": "Melon", "amount": 1},
    ],
    "High Vitamin C": [
      {"name": "Orange", "amount": 2},
      {"name": "Banana", "amount": 1},
    ],
  };
  Map<String, int> customAmounts = {};

  @override
  void initState() {
    super.initState();
    selectedGoal = availableGoals[0]; // Default
    for (var rec in mealRecommendations[selectedGoal]!) {
      customAmounts[rec["name"]] = rec["amount"];
    }
  }

  void updateAmountsForGoal() {
    customAmounts.clear();
    for (var rec in mealRecommendations[selectedGoal]!) {
      customAmounts[rec["name"]] = rec["amount"];
    }
  }

  @override
  Widget build(BuildContext context) {
    final itemProvider = Provider.of<ItemProvider>(context, listen: false);
    return AlertDialog(
      title: Text("Quick Recommendation Diet"),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text("Select your health goal:"),
          DropdownButton<String>(
            value: selectedGoal,
            items: availableGoals.map((goal) => DropdownMenuItem(
              value: goal,
              child: Text(goal),
            )).toList(),
            onChanged: (goal) {
              setState(() {
                selectedGoal = goal!;
                updateAmountsForGoal();
              });
            },
          ),
          SizedBox(height: 10),
          ...mealRecommendations[selectedGoal]!.map((rec) {
            final name = rec["name"] as String;
            final controller = TextEditingController(text: customAmounts[name]?.toString() ?? "1");
            controller.selection = TextSelection.fromPosition(TextPosition(offset: controller.text.length));
            return FocusScope(
              child: Focus(
                onFocusChange: (hasFocus) {
                  if (!hasFocus) {
                    int n = int.tryParse(controller.text) ?? 1;
                    if (n < 1) n = 1;
                    setState(() {
                      customAmounts[name] = n;
                      controller.text = n.toString();
                      controller.selection = TextSelection.fromPosition(TextPosition(offset: controller.text.length));
                    });
                  }
                },
                child: Row(
                  children: [
                    Expanded(child: Text("• $name")),
                    SizedBox(width: 8),
                    SizedBox(
                      width: 48,
                      child: TextFormField(
                        controller: controller,
                        keyboardType: TextInputType.number,
                        maxLength: 2,
                        decoration: InputDecoration(
                          isDense: true,
                          contentPadding: EdgeInsets.symmetric(vertical: 4, horizontal: 8),
                          counterText: "",
                        ),
                        onChanged: (val) {
                          int n = int.tryParse(val) ?? 0;
                          if (n > 99) n = 99;
                          setState(() {
                            customAmounts[name] = n;
                          });
                        },
                        onFieldSubmitted: (_) {
                          FocusScope.of(context).unfocus();
                        },
                      ),
                    ),
                  ],
                ),
              ),
            );
          }),
        ],
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: Text("Cancel")),
        ElevatedButton(
          onPressed: () async {
            // Check if a plan already exists
            final prefs = await SharedPreferences.getInstance();
            final today = DateTime.now();
            final todayKey = "tempDailyItems_${today.year}_${today.month}_${today.day}";
            final hasPlan = prefs.containsKey(todayKey);
            if (hasPlan) {
              // Show confirmation dialog
              final confirmed = await showDialog<bool>(
                // ignore: use_build_context_synchronously
                context: context,
                builder: (ctx) => AlertDialog(
                  title: Text("Replace existing plan?"),
                  content: Text("You already have a daily plan. Do you want to replace it with this recommendation?"),
                  actions: [
                    TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text("No")),
                    ElevatedButton(onPressed: () => Navigator.pop(ctx, true), child: Text("Yes")),
                  ],
                ),
              );
              if (confirmed != true) return;
            }
            // Build the plan
            final foodList = <Map<String, dynamic>>[];
            for (var rec in mealRecommendations[selectedGoal]!) {
              final name = rec["name"] as String;
              final amount = customAmounts[name] ?? 1;
              final food = itemProvider.allFoodItems.firstWhere((f) => f.name == name, orElse: () => itemProvider.allFoodItems.first);
              foodList.add({"foodId": food.foodId, "amount": amount});
            }
            await prefs.setString(todayKey, json.encode(foodList));
            await prefs.setString('tempDailyItems_lastFetched', today.toIso8601String());
            // ignore: use_build_context_synchronously
            if (mounted) Navigator.pop(context);
          },
          child: Text("Apply Plan"),
        ),
      ],
    );
  }
}

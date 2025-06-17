import 'package:flutter/material.dart';

class DailyScreen extends StatefulWidget {
  const DailyScreen({super.key});

  @override
  DailyScreenState createState() => DailyScreenState();
}

class DailyScreenState extends State<DailyScreen> {
  String? expandedMeal; // Tracks which dropdown is open

  void toggleDropdown(String meal) {
    setState(() {
      expandedMeal = expandedMeal == meal ? null : meal; // Toggle dropdown visibility
    });
  }

  Widget buildMealContainer(String meal, List<String> mealItems) {
    return Column(
      children: [
        GestureDetector(
          onTap: () => toggleDropdown(meal),
          child: Container(
            height: (MediaQuery.of(context).size.height - MediaQuery.of(context).padding.top) * 0.065,
            width: MediaQuery.of(context).size.width * 0.85,
            decoration: BoxDecoration(
              image: DecorationImage(
                image: AssetImage(getMealBanner(meal)),
                fit: BoxFit.cover,
              ),
              borderRadius: expandedMeal == meal ? BorderRadius.only(topLeft: Radius.circular(5), topRight: Radius.circular(5)) : BorderRadius.circular(5),
            ),
            padding: EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  meal,
                  style: TextStyle(
                    shadows: [Shadow(color: Colors.blue.shade600, offset: Offset(1, -1), blurRadius: 2)],
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.amber,
                  ),
                ),
                Icon(expandedMeal == meal ? Icons.keyboard_arrow_down : Icons.keyboard_arrow_right, color: Colors.amber, size: 32),
              ],
            ),
          ),
        ),
        if (expandedMeal == meal) // Show dropdown when meal is expanded
          Container(
            width: MediaQuery.of(context).size.width * 0.85,
            padding: EdgeInsets.symmetric(vertical: 10),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Colors.blueAccent.withAlpha(50),
                  Colors.lightBlueAccent.withAlpha(50),
                  Colors.blueAccent.withAlpha(50)
                  ],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter
                )
            ),
            child: Column(
              children: mealItems.map((item) => ListTile(
                title: Text(item),
                trailing: Icon(Icons.restaurant_menu),
              )).toList(),
            ),
          ),
        SizedBox(height: 10),
      ],
    );
  }

  Map<String, bool> mealStatus = {
    "Breakfast": false,
    "Lunch": false,
    "Dinner": false,
  };

  Map<String, String> mealTimes = {
    "Breakfast": "06:00 - 10:00",
    "Lunch": "12:00 - 15:00",
    "Dinner": "18:00 - 22:00",
  };

  String getCurrentMeal() {
    final hour = DateTime.now().hour;
    if (hour >= 6 && hour < 10) return "Breakfast";
    if (hour >= 12 && hour < 15) return "Lunch";
    if (hour >= 18 && hour < 22) return "Dinner";
    return "Waiting";
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
      case "Breakfast":
        return "images/morning banner.png";
      case "Lunch":
        return "images/afternoon banner.png";
      case "Dinner":
        return "images/evening banner.png";
      default:
        return "images/morning banner.png"; // Fallback
    }
  }

  void confirmMeal(String meal) {
    setState(() {
      mealStatus[meal] = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    final appbarHeight = (MediaQuery.of(context).size.height - MediaQuery.of(context).padding.top) * 0.065;
    final screenHeight = MediaQuery.of(context).size.height - MediaQuery.of(context).padding.top - appbarHeight;
    final screenWidth = MediaQuery.of(context).size.width;

    return SingleChildScrollView(
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Container(
              height: screenHeight * 0.6,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Colors.blue.shade200.withAlpha(225),
                    Colors.blue.shade100.withAlpha(225),
                    Colors.blue.shade50.withAlpha(225)
                    ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomCenter,
                ),
                borderRadius: BorderRadius.circular(10),
              ),
              padding: EdgeInsets.all(16),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    children: [
                      Container(
                        height: screenHeight * 0.05,
                        alignment: Alignment.center,
                        child: Text(
                          "Weekly Diet: ${getCurrentMeal() == "Waiting" ? "Waiting for meal time" : getCurrentMeal()}",
                          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Theme.of(context).brightness == Brightness.light ? Colors.black : Colors.white),
                        ),
                      ),
                      SizedBox(height: screenHeight * 0.01,),
                      ...mealStatus.keys.map((meal) => buildMealContainer(meal, const [])),
                    ],
                  ),
                  SizedBox(
                    width: screenWidth * 0.75,
                    child: ElevatedButton(
                      onPressed: () => getCurrentMeal() == "Waiting" ? null : confirmMeal(getCurrentMeal()),
                      style: ButtonStyle(
                        backgroundColor: WidgetStateProperty.all(getRowColor(getCurrentMeal())),
                      ),
                      child: Text(getCurrentMeal() == "Waiting" ? "Not Yet!" : "Done!", style: TextStyle(color: Colors.black87, fontWeight: FontWeight.bold),),
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
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => CreatePlanPage()),
                      );
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
                        header: Text("Create a weekly plan", style: TextStyle(color: Theme.of(context).brightness == Brightness.dark ? Colors.white : Colors.black, fontWeight: FontWeight.bold), textAlign: TextAlign.center,),
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
                        header: Text("Quick Recommendation diet", style: TextStyle(color: Theme.of(context).brightness == Brightness.dark ? Colors.white : Colors.black, fontWeight: FontWeight.bold), textAlign: TextAlign.center,),
                        child: Icon(Icons.auto_awesome, size: screenWidth * 0.25,)),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class CreatePlanPage extends StatelessWidget {
  const CreatePlanPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Create a Daily Plan")),
      body: Center(child: Text("Implement daily diet plan creation here.")),
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
  Map<String, List<String>> mealRecommendations = {
    "Refreshing": ["Watermelon", "Melon"],
    "High Vitamin C": ["Orange", "Banana"],
  };

  @override
  void initState() {
    super.initState();
    selectedGoal = availableGoals[0]; // Default
  }

  @override
  Widget build(BuildContext context) {
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
              });
            },
          ),
          SizedBox(height: 10),
          ...mealRecommendations[selectedGoal]!.map((meal) => Text("• $meal")),
        ],
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: Text("Cancel")),
        ElevatedButton(
          onPressed: () {
            // Apply AI recommendation logic here
            Navigator.pop(context);
          },
          child: Text("Apply Plan"),
        ),
      ],
    );
  }
}

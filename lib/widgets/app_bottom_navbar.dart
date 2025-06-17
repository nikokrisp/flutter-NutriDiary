import 'package:flutter/material.dart';

class AppBottomNavBar extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;
  const AppBottomNavBar({super.key, required this.currentIndex, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;

    return BottomNavigationBar(
      currentIndex: currentIndex,
      onTap: onTap,
      items: const [
        BottomNavigationBarItem(icon: Icon(Icons.search), label: "NutriCheck"),
        BottomNavigationBarItem(icon: Icon(Icons.calendar_month), label: "NutriDaily"),
        BottomNavigationBarItem(icon: Icon(Icons.favorite), label: "Your Food"),
        BottomNavigationBarItem(icon: Icon(Icons.person), label: "Your Insight"),
      ],
      selectedItemColor: Theme.brightnessOf(context) == Brightness.dark ? Colors.white : Colors.black,
      unselectedItemColor: Theme.brightnessOf(context) == Brightness.dark ? Colors.white70 : Colors.black54,
      backgroundColor: Theme.brightnessOf(context) == Brightness.dark ? Colors.black : Colors.white,
      selectedIconTheme: IconThemeData(size: screenWidth * .12),
      unselectedIconTheme: IconThemeData(size: screenWidth * .08),
      selectedFontSize: screenWidth * .048,
      unselectedFontSize: screenWidth * .036,
      showSelectedLabels: true,
      showUnselectedLabels: true,
      type: BottomNavigationBarType.fixed,
      elevation: 10,
      selectedLabelStyle: const TextStyle(fontWeight: FontWeight.bold),
    );
  }
}

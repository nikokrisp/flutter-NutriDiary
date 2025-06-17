import 'package:flutter/material.dart';

class PageIndexProvider extends ChangeNotifier {
  int _currentIndex = 2;
  bool _openSearchBar = false;

  int get currentIndex => _currentIndex;
  bool get openSearchBar => _openSearchBar;

  void setIndex(int index) {
    _currentIndex = index;
    notifyListeners();
  }

  void triggerSearchBar() {
    _openSearchBar = true;
    notifyListeners();
  }

  void resetSearchBarTrigger() {
    _openSearchBar = false;
    notifyListeners();
  }
}

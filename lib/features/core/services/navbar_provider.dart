import 'package:flutter/material.dart';

class NavBarProvider extends ChangeNotifier {
  bool _isHidden = false;

  bool get isHidden => _isHidden;

  setHiddenStatus(bool isHidden) {
    _isHidden = isHidden;
    notifyListeners();
  }

  bool _isPlay = true;

  bool get isPlay => _isPlay;

  videoPlay(bool isHidden) {
    _isPlay = isHidden;
    notifyListeners();
  }

  int _currentIndex = 0;

  int get currentIndex => _currentIndex;

  setCurrentIndex(int index) {
    _currentIndex = index;
    notifyListeners();
  }
}

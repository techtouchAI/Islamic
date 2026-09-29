import 'package:flutter/foundation.dart';

/// Bottom tabs are roots, not entries in the detail back stack.
class AppNavigationController extends ChangeNotifier {
  static const roots = ['home', 'quran', 'adhkar', 'favorites'];
  String _root = 'home';
  final List<String> _details = [];

  String get currentSection => _details.isEmpty ? _root : _details.last;
  int get selectedIndex => roots.indexOf(_root);
  bool get isDetail => _details.isNotEmpty;
  bool get canGoBack => isDetail || _root != 'home';

  void selectTab(int index) => navigateTo(roots[index]);

  void navigateTo(String section) {
    if (section == currentSection) return;
    if (roots.contains(section)) {
      _root = section;
      _details.clear();
    } else {
      _details.add(section);
    }
    notifyListeners();
  }

  void goBack() {
    if (!canGoBack) return;
    if (_details.isNotEmpty) {
      _details.removeLast();
    } else {
      _root = 'home';
    }
    notifyListeners();
  }
}

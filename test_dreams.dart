import 'dart:convert';
import 'dart:io';

void main() async {
  final file = File('assets/data/content.json');
  final String jsonStr = await file.readAsString();
  final Map<String, dynamic> db = json.decode(jsonStr);

  print('Sections: ${db['sections']['dreams']}');
  print('Dreams Categories: ${db['dreams_categories'].length}');

  // Simulate DataManager.getItems('dreams')
  final cats = db['dreams_categories'] ?? [];
  print('DataManager.getItems("dreams") count: ${cats.length}');

  // Simulate DataManager.getItems('dreams_cat_1')
  final id = 1;
  final cat = (cats as List).firstWhere((c) => c['id'] == id, orElse: () => null);
  if (cat != null) {
    final items = db['content']['dreams_cat_$id'] ?? [];
    print('DataManager.getItems("dreams_cat_1") count: ${items.length}');
    print('First item title: ${items.isNotEmpty ? items[0]['title'] : "none"}');
  } else {
    print('Category not found!');
  }
}

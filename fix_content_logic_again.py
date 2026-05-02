import re

with open('lib/data/data_manager.dart', 'r') as f:
    content = f.read()

search_fatawa_cat = """    if (section.startsWith('fatawa_cat_')) {
      final idString = section.replaceAll('fatawa_cat_', '');
      final id = int.tryParse(idString);
      final cats = _db!['fatawa_categories'] as List<dynamic>? ?? [];
      final cat = cats.firstWhere((c) => c['id'] == id, orElse: () => null);
      if (cat != null) {
        return cat['items'] as List<dynamic>? ?? [];
      }
      return [];
    }"""

replace_fatawa_cat = """    if (section.startsWith('fatawa_cat_')) {
      final idString = section.replaceAll('fatawa_cat_', '');
      final id = int.tryParse(idString);
      final cats = _db!['fatawa_categories'] as List<dynamic>? ?? [];
      final cat = cats.firstWhere((c) => c['id'] == id, orElse: () => null);
      if (cat != null) {
        return cat['items'] as List<dynamic>? ?? [];
      }
      return [];
    }
    
    if (section.startsWith('dreams_cat_')) {
      final idString = section.replaceAll('dreams_cat_', '');
      final id = int.tryParse(idString);
      final cats = _db!['dreams_categories'] as List<dynamic>? ?? [];
      final cat = cats.firstWhere((c) => c['id'] == id, orElse: () => null);
      if (cat != null) {
        return cat['items'] as List<dynamic>? ?? [];
      }
      return [];
    }"""

if search_fatawa_cat in content:
    content = content.replace(search_fatawa_cat, replace_fatawa_cat)
    print("Injected dreams_cat_ logic.")

with open('lib/data/data_manager.dart', 'w') as f:
    f.write(content)

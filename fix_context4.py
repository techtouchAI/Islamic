import re

with open("lib/presentation/screens/istikhara_screen.dart", "r") as f:
    content = f.read()

content = content.replace("import 'package:path/path.dart' hide Context;", "import 'package:path/path.dart' as p;")
content = content.replace('final path = join(dbPath, "quran_db.db");', 'final path = p.join(dbPath, "quran_db.db");')
content = content.replace("import 'package:flutter/foundation.dart';\n", "")

with open("lib/presentation/screens/istikhara_screen.dart", "w") as f:
    f.write(content)

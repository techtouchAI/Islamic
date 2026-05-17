import re

with open("lib/presentation/screens/istikhara_screen.dart", "r") as f:
    content = f.read()

content = content.replace("import 'package:path/path.dart';", "import 'package:path/path.dart' hide Context;")
content = content.replace("import 'package:sqflite/sqflite.dart' hide Context;", "import 'package:sqflite/sqflite.dart';")

with open("lib/presentation/screens/istikhara_screen.dart", "w") as f:
    f.write(content)

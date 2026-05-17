import re

with open("lib/presentation/screens/istikhara_screen.dart", "r") as f:
    content = f.read()

content = content.replace("import 'package:sqflite/sqflite.dart';", "import 'package:sqflite/sqflite.dart' hide Context;")

with open("lib/presentation/screens/istikhara_screen.dart", "w") as f:
    f.write(content)

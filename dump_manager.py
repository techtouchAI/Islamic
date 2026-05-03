with open('lib/data/data_manager.dart', 'r') as f:
    content = f.read()

import re
match = re.search(r'static List<dynamic> getItems\(String section\) \{.*?\n  \}', content, re.DOTALL)
if match:
    print(match.group(0))

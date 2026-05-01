import re

with open('assets/data/content.json', 'r', encoding='utf-8') as f:
    content = f.read()

# Resolve Git Merge Conflict
content = re.sub(r'<<<<<<< Updated upstream\n(.*?)\n=======\n(.*?)\n>>>>>>> Stashed changes\n', r'\2\n', content, flags=re.DOTALL)

with open('assets/data/content.json', 'w', encoding='utf-8') as f:
    f.write(content)

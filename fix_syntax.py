import sys

with open('lib/main.dart', 'r') as f:
    content = f.read()

start = content.find("class _ReaderPageState extends State<ReaderPage>")
end = content.find("  Widget _buildBottomToolbar", start)

snippet = content[start:end]

lines = snippet.split('\n')
for i, line in enumerate(lines):
    if "child: Column(" in line:
        print(f"Column at {i}: {line}")

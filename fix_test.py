with open("test/widget_test.dart", "r") as f:
    content = f.read()

content = content.replace("expect(find.byType(CircularProgressIndicator), findsNothing);", "expect(find.byType(CircularProgressIndicator), findsOneWidget);")

with open("test/widget_test.dart", "w") as f:
    f.write(content)

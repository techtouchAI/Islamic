import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:aldhakereen/main.dart';
import 'dart:io';

// Since _buildImage is private, we'll create a helper widget to test it.
// We need to use a trick to access private functions or move it to a public place.
// In this case, since I cannot easily change the visibility without affecting more files,
// I will check if I can test it indirectly or if I should make it public.
// Given the task, I will temporarily make it public to test it if needed, or better,
// I'll test it via the widgets that use it if possible.

// Actually, I can't easily test private functions from other files in Dart.
// I'll check if I can use the existing widgets.
// AppDrawer uses _buildImage for the logo.
// HomeSection uses _buildImage for the background.

void main() {
  testWidgets('Image loading security test - HTTPS allowed', (WidgetTester tester) async {
    const httpsPath = 'https://example.com/image.png';

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (context) {
              // We'll use a hacky way to call the private function if we can't make it public.
              // But for a clean test, let's see if we can find it in the code.
              // It's at the top level of main.dart, but it's not exported if it starts with _.
              // Wait, it is NOT private! It is `Widget _buildImage`.
              // Oh, in Dart, top-level identifiers starting with _ ARE library-private.
              return _TestImageWrapper(path: httpsPath);
            },
          ),
        ),
      ),
    );

    expect(find.byType(Image), findsOneWidget);
    final imageWidget = tester.widget<Image>(find.byType(Image));
    expect(imageWidget.image, isA<NetworkImage>());
    expect((imageWidget.image as NetworkImage).url, httpsPath);
  });

  testWidgets('Image loading security test - HTTP blocked', (WidgetTester tester) async {
    const httpPath = 'http://example.com/image.png';

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: _TestImageWrapper(path: httpPath),
        ),
      ),
    );

    expect(find.byIcon(Icons.security), findsOneWidget);
    final iconWidget = tester.widget<Icon>(find.byIcon(Icons.security));
    expect(iconWidget.color, Colors.red);
  });

  testWidgets('Image loading security test - Data URI allowed', (WidgetTester tester) async {
    const dataPath = 'data:image/png;base64,iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mP8z8BQDwAEhQGAhKmMIQAAAABJRU5ErkJggg==';

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: _TestImageWrapper(path: dataPath),
        ),
      ),
    );

    expect(find.byType(Image), findsOneWidget);
    final imageWidget = tester.widget<Image>(find.byType(Image));
    expect(imageWidget.image, isA<MemoryImage>());
  });
}

// Helper widget to call _buildImage from within the same library if it was private,
// but since we are in a different file (test file), we need to make it public
// or use a helper in main.dart.
// I will modify lib/main.dart to make it public by removing the leading underscore.

class _TestImageWrapper extends StatelessWidget {
  final String path;
  const _TestImageWrapper({required this.path});

  @override
  Widget build(BuildContext context) {
    // This will only work if we rename _buildImage to buildImage in lib/main.dart
    return buildImage(path);
  }
}

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';

class HtmlContentRenderer extends StatefulWidget {
  final String content;
  final TextStyle baseStyle;
  final TextAlign textAlign;
  final int? bookmarkedIndex;
  final ValueChanged<int>? onParagraphTapped;
  final Widget? blinkingStar;

  const HtmlContentRenderer({
    super.key,
    required this.content,
    required this.baseStyle,
    this.textAlign = TextAlign.center,
    this.bookmarkedIndex,
    this.onParagraphTapped,
    this.blinkingStar,
  });

  @override
  State<HtmlContentRenderer> createState() => _HtmlContentRendererState();
}

class _HtmlContentRendererState extends State<HtmlContentRenderer> {
  Color? _parseColor(String colorString) {
    try {
      if (colorString.startsWith('#')) {
        return Color(
            int.parse(colorString.substring(1), radix: 16) + 0xFF000000);
      }
    } catch (_) {}
    return null;
  }

  List<Widget> _parseContentRobust(
      String content, TextStyle baseStyle, TextAlign textAlign) {
    String processed = content.replaceAll('<html>', '').replaceAll('//', '');
    processed = processed
        .replaceAll(RegExp(r'<\/?p>', caseSensitive: false), '\n\n')
        .replaceAll(RegExp(r'<br>', caseSensitive: false), '\n');
    processed = processed.replaceAll(RegExp(r'\n{3,}'), '\n\n').trim();

    // Insert a newline after Ayah markers so they can be parsed as independent paragraphs
    processed = processed.replaceAllMapped(
      RegExp(r'(﴿[0-9٠-٩]+﴾|۝)'),
      (match) => '${match.group(1)}\n',
    );

    // Pad common Arabic punctuation and structural HTML tags with spaces
    // so they are not glued to words, ensuring accurate word-level splitting.
    processed = processed
        .replaceAll('،', ' ، ')
        .replaceAll('.', ' . ')
        .replaceAll('؟', ' ؟ ')
        .replaceAll('!', ' ! ')
        .replaceAll(':', ' : ');

    // Pad tags as well to avoid merging
    processed = processed.replaceAllMapped(
      RegExp(r'(<[^>]+>)'),
      (match) => ' ${match.group(1)} ',
    );

    // Split by words to ensure word-by-word bookmark granularity.
    // We split by space or newline, preserving the separators to reconstruct formatting.
    final wordsAndSpaces = processed.split(RegExp(r'(?<=\s)|(?=\s)'));

    final List<Widget> paragraphWidgets = [];
    List<InlineSpan> currentSpans = [];

    final RegExp tagRegex =
        RegExp(r'(<b>|</b>|<c=(#[a-zA-Z0-9]{6})>|</c>)', caseSensitive: false);

    bool isBold = false;
    Color? currentColor;
    int wordIndex = 0;

    for (int i = 0; i < wordsAndSpaces.length; i++) {
      final token = wordsAndSpaces[i];
      if (token.isEmpty) continue;

      if (token == '\n') {
        // End of paragraph, wrap it in a RichText and reset spans
        if (currentSpans.isNotEmpty) {
          paragraphWidgets.add(
            Container(
              width: double.infinity,
              padding: const EdgeInsets.only(bottom: 8.0),
              child: GestureDetector(
                behavior: HitTestBehavior.translucent,
                child: RichText(
                  key: ValueKey(
                      '${widget.bookmarkedIndex}_${paragraphWidgets.length}'),
                  textAlign: textAlign,
                  textDirection: TextDirection.rtl,
                  text: TextSpan(
                    style: baseStyle,
                    children: List.from(currentSpans),
                  ),
                ),
              ),
            ),
          );
          currentSpans.clear();
        } else {
          // Empty newline paragraph
          paragraphWidgets.add(const SizedBox(height: 8.0));
        }
        continue;
      }

      final isWhitespace = token.trim().isEmpty;

      if (isWhitespace) {
        currentSpans.add(TextSpan(
            text: token,
            style: TextStyle(
              fontWeight: isBold ? FontWeight.bold : baseStyle.fontWeight,
              color: currentColor ?? baseStyle.color,
              fontFamily: baseStyle.fontFamily,
              fontSize: baseStyle.fontSize,
              height: baseStyle.height,
            )));
        continue;
      }

      final currentWordIndex = wordIndex++;
      final List<InlineSpan> tokenSpans = [];

      if (!token.contains('<')) {
        tokenSpans.add(TextSpan(
            text: token,
            style: TextStyle(
              fontWeight: isBold ? FontWeight.bold : baseStyle.fontWeight,
              color: currentColor ?? baseStyle.color,
              fontFamily: baseStyle.fontFamily,
              fontSize: baseStyle.fontSize,
              height: baseStyle.height,
            )));
      } else {
        int lastMatchEnd = 0;

        for (final match in tagRegex.allMatches(token)) {
          if (match.start > lastMatchEnd) {
            tokenSpans.add(TextSpan(
              text: token.substring(lastMatchEnd, match.start),
              style: TextStyle(
                fontWeight: isBold ? FontWeight.bold : baseStyle.fontWeight,
                color: currentColor ?? baseStyle.color,
                fontFamily: baseStyle.fontFamily,
                fontSize: baseStyle.fontSize,
                height: baseStyle.height,
              ),
            ));
          }

          final String tag = match.group(1)!.toLowerCase();
          if (tag == '<b>') {
            isBold = true;
          } else if (tag == '</b>') {
            isBold = false;
          } else if (tag.startsWith('<c=')) {
            currentColor = _parseColor(match.group(2)!);
          } else if (tag == '</c>') {
            currentColor = null;
          }

          lastMatchEnd = match.end;
        }

        if (lastMatchEnd < token.length) {
          tokenSpans.add(TextSpan(
            text: token.substring(lastMatchEnd),
            style: TextStyle(
              fontWeight: isBold ? FontWeight.bold : baseStyle.fontWeight,
              color: currentColor ?? baseStyle.color,
              fontFamily: baseStyle.fontFamily,
              fontSize: baseStyle.fontSize,
              height: baseStyle.height,
            ),
          ));
        }
      }

      // Add zero-width floating star if this word is bookmarked
      if (widget.bookmarkedIndex?.toString() == currentWordIndex.toString()) {
        tokenSpans.add(const WidgetSpan(
          alignment: PlaceholderAlignment.middle,
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: 2),
            child: Icon(Icons.star, color: Colors.green, size: 16),
          ),
        ));
      }

      currentSpans.add(TextSpan(
        children: tokenSpans,
        recognizer: TapGestureRecognizer()
          ..onTap = () {
            widget.onParagraphTapped?.call(currentWordIndex);
          },
      ));
    }

    // Add any remaining spans as the last paragraph
    if (currentSpans.isNotEmpty) {
      paragraphWidgets.add(
        Container(
          width: double.infinity,
          padding: const EdgeInsets.only(bottom: 8.0),
          child: GestureDetector(
            behavior: HitTestBehavior.translucent,
            child: RichText(
              key: ValueKey(
                  '${widget.bookmarkedIndex}_${paragraphWidgets.length}'),
              textAlign: textAlign,
              textDirection: TextDirection.rtl,
              text: TextSpan(
                style: baseStyle,
                children: currentSpans,
              ),
            ),
          ),
        ),
      );
    }

    return paragraphWidgets;
  }

  @override
  Widget build(BuildContext context) {
    return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: _parseContentRobust(
            widget.content, widget.baseStyle, widget.textAlign));
  }
}

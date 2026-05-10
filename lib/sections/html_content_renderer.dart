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
  late List<Widget> _parsedWidgets;

  @override
  void initState() {
    super.initState();
    _parsedWidgets =
        _parseContentRobust(widget.content, widget.baseStyle, widget.textAlign);
  }

  @override
  void didUpdateWidget(HtmlContentRenderer oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.content != widget.content ||
        oldWidget.baseStyle != widget.baseStyle ||
        oldWidget.textAlign != widget.textAlign ||
        oldWidget.bookmarkedIndex != widget.bookmarkedIndex) {
      _parsedWidgets = _parseContentRobust(
          widget.content, widget.baseStyle, widget.textAlign);
    }
  }

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

    final paragraphs = processed.split('\n\n');
    final List<Widget> paragraphWidgets = [];

    final RegExp tagRegex =
        RegExp(r'(<b>|</b>|<c=(#[a-zA-Z0-9]{6})>|</c>)', caseSensitive: false);

    for (int i = 0; i < paragraphs.length; i++) {
      final p = paragraphs[i];
      final List<InlineSpan> spans = [];

      if (!p.contains('<')) {
        spans.add(TextSpan(text: p, style: baseStyle));
      } else {
        int lastMatchEnd = 0;
        bool isBold = false;
        Color? currentColor;

        for (final match in tagRegex.allMatches(p)) {
          if (match.start > lastMatchEnd) {
            spans.add(TextSpan(
              text: p.substring(lastMatchEnd, match.start),
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

        if (lastMatchEnd < p.length) {
          spans.add(TextSpan(
            text: p.substring(lastMatchEnd),
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

      if (widget.bookmarkedIndex == i && widget.blinkingStar != null) {
        spans.add(WidgetSpan(
          alignment: PlaceholderAlignment.middle,
          child: widget.blinkingStar!,
        ));
      }

      paragraphWidgets.add(
        GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: () {
            debugPrint('Child: Paragraph $i tapped');
            widget.onParagraphTapped?.call(i);
          },
          onLongPress: () {
            debugPrint('Child: Paragraph $i tapped');
            widget.onParagraphTapped?.call(i);
          },
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.only(bottom: 8.0),
            child: RichText(
              textAlign: textAlign,
              textDirection: TextDirection.rtl,
              text: TextSpan(
                style: baseStyle,
                children: spans,
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
        children: _parsedWidgets);
  }
}

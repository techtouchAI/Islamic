import 'package:flutter/material.dart';

class HtmlContentRenderer extends StatefulWidget {
  final String content;
  final TextStyle baseStyle;
  final TextAlign textAlign;

  const HtmlContentRenderer({
    super.key,
    required this.content,
    required this.baseStyle,
    this.textAlign = TextAlign.center,
  });

  @override
  State<HtmlContentRenderer> createState() => _HtmlContentRendererState();
}

class _HtmlContentRendererState extends State<HtmlContentRenderer> {
  late List<Widget> _parsedWidgets;

  @override
  void initState() {
    super.initState();
    _parsedWidgets = _parseContent(widget.content, widget.baseStyle, widget.textAlign);
  }

  @override
  void didUpdateWidget(HtmlContentRenderer oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.content != widget.content || oldWidget.baseStyle != widget.baseStyle || oldWidget.textAlign != widget.textAlign) {
      _parsedWidgets = _parseContent(widget.content, widget.baseStyle, widget.textAlign);
    }
  }

  Color? _parseColor(String colorString) {
    try {
      if (colorString.startsWith('#')) {
        return Color(int.parse(colorString.substring(1), radix: 16) + 0xFF000000);
      }
    } catch (_) {}
    return null;
  }

  List<Widget> _parseContent(String content, TextStyle baseStyle, TextAlign textAlign) {
    if (!content.contains('<')) {
      return [
        Text(
          content,
          textAlign: textAlign,
          style: baseStyle,
        )
      ];
    }

    String processed = content.replaceAll('<p>', '\n').replaceAll('</p>', '\n').replaceAll('<br>', '\n');
    List<String> paragraphs = processed.split('\n');

    List<Widget> paragraphWidgets = [];
    for (int i = 0; i < paragraphs.length; i++) {
      String p = paragraphs[i].trim();
      if (p.isEmpty) {
        // preserve consecutive empty spaces if intended as separation
        if (i < paragraphs.length - 1 && paragraphs[i + 1].trim().isNotEmpty) {
           paragraphWidgets.add(const SizedBox(height: 12));
        }
        continue;
      }

      List<TextSpan> spans = _parseInline(p);
      paragraphWidgets.add(
        RichText(
          textAlign: textAlign,
          textDirection: TextDirection.rtl,
          text: TextSpan(
            style: baseStyle,
            children: spans,
          ),
        )
      );
      if (i < paragraphs.length - 1) {
        paragraphWidgets.add(const SizedBox(height: 12));
      }
    }

    return paragraphWidgets;
  }

  List<TextSpan> _parseInline(String text) {
    final List<TextSpan> spans = [];
    final RegExp tagRegex = RegExp(r'<c=(#[a-zA-Z0-9]{6})><b>(.*?)</b></c>|<c=(#[a-zA-Z0-9]{6})>(.*?)</c>|<b>(.*?)</b>');
    int lastMatchEnd = 0;

    for (final match in tagRegex.allMatches(text)) {
      if (match.start > lastMatchEnd) {
         spans.add(TextSpan(text: text.substring(lastMatchEnd, match.start)));
      }

      if (match.group(1) != null && match.group(2) != null) {
        spans.add(TextSpan(
          text: match.group(2),
          style: TextStyle(
            color: _parseColor(match.group(1)!),
            fontWeight: FontWeight.bold,
          )
        ));
      } else if (match.group(3) != null && match.group(4) != null) {
        spans.add(TextSpan(
          text: match.group(4),
          style: TextStyle(
            color: _parseColor(match.group(3)!),
          )
        ));
      } else if (match.group(5) != null) {
        spans.add(TextSpan(
          text: match.group(5),
          style: const TextStyle(fontWeight: FontWeight.bold),
        ));
      }

      lastMatchEnd = match.end;
    }

    if (lastMatchEnd < text.length) {
      spans.add(TextSpan(text: text.substring(lastMatchEnd)));
    }

    return spans;
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: _parsedWidgets,
    );
  }
}

/// One place that turns the raw HTML dialect of `content.json` into text.
///
/// The CMS stores most collections as a very small HTML subset: a leading
/// `html` marker, `<p>` paragraphs, `<br>` line breaks, `<b>` bold and
/// `<c=#rrggbb>` colour spans. Three consumers need three different views of
/// the very same string:
///
///  * [ContentSanitizer.displayMarkup] — what the reader renders: paragraphs
///    become line breaks and the inline tags the renderer understands stay.
///  * [ContentSanitizer.plainText] — what the clipboard and the share sheet
///    receive: every tag is gone, paragraphs stay separated by a blank line.
///  * [ContentSanitizer.snippet] — one line, for card subtitles and previews.
///
/// The reader, the renderer and the list subtitle used to clean the payload
/// each in their own way, which is how markup reached the share sheet and how
/// stray `//` and `!` replacements damaged real text. Every view now comes
/// from here, so what a user reads, copies and shares cannot drift apart.
class ContentSanitizer {
  /// The `html` marker the CMS writes in front of a markup payload.
  static final RegExp _payloadMarker = RegExp(
    r'^\s*html\b',
    caseSensitive: false,
  );

  /// `<!-- … -->` blocks left behind by Word and the export scripts.
  static final RegExp _comment = RegExp(r'<!--.*?-->', dotAll: true);

  /// `### ` heading markers used by a few legacy entries.
  static final RegExp _headingMarker = RegExp(
    r'^[ \t]*#{1,6}[ \t]*',
    multiLine: true,
  );

  /// Document-level wrappers that carry no text of their own.
  static final RegExp _documentTag = RegExp(
    r'</?\s*(?:html|head|body|meta|title|link|script|style)\b[^<>]*>',
    caseSensitive: false,
  );

  /// A single forced line break.
  static final RegExp _lineBreak = RegExp(
    r'<\s*br\s*/?\s*>',
    caseSensitive: false,
  );

  /// Block boundaries that become a paragraph break.
  static final RegExp _blockBoundary = RegExp(
    r'<\s*/?\s*(?:p|div|hr|tr|li|ul|ol|table|blockquote|h[1-6])\b[^<>]*>',
    caseSensitive: false,
  );

  /// Anything shaped like a tag — `<` then an optional `/`, a letter and the
  /// closing `>` — so a stray `<` inside prose (`5 < 6`) survives.
  static final RegExp _tagLike = RegExp(r'</?[A-Za-z][^<>]{0,300}>');

  static final RegExp _linePadding = RegExp(r'[ \t\u00a0]+\n');
  static final RegExp _wideGap = RegExp(r'[ \t\u00a0]{2,}');
  static final RegExp _blankLines = RegExp(r'\n{3,}');
  static final RegExp _anyNewline = RegExp(r'\s*\n\s*');

  /// Markup the reader renders: paragraphs as blank lines, inline tags kept.
  static String displayMarkup(String raw) {
    var text = _stripPayload(raw);
    text = _toParagraphs(text);
    return _tidy(text);
  }

  /// Tag-free text for the clipboard and the share sheet.
  static String plainText(String raw) {
    var text = _stripPayload(raw);
    text = _toParagraphs(text);
    text = text.replaceAll(_tagLike, '');
    text = _decodeEntities(text);
    return _tidy(text);
  }

  /// A single line of [plainText], optionally clipped to [maxLength].
  static String snippet(String raw, {int? maxLength}) {
    final text = plainText(raw).replaceAll(_anyNewline, ' ');
    if (maxLength == null || text.length <= maxLength) return text;
    return '${text.substring(0, maxLength).trimRight()}…';
  }

  /// Drops the payload marker, comments, heading markers and document
  /// wrappers, and spells out the Quranic ligatures the CMS stores.
  static String _stripPayload(String raw) {
    var text = raw.replaceFirst(_payloadMarker, '');
    text = text.replaceAll(_comment, '');
    text = text.replaceAll(_headingMarker, '');
    text = text.replaceAll(_documentTag, '');
    return text
        .replaceAll('\uFDFA', '(صلى الله عليه وآله)')
        .replaceAll('\uFDFB', '(جل جلاله)');
  }

  static String _toParagraphs(String text) => text
      .replaceAll(_lineBreak, '\n')
      .replaceAll(_blockBoundary, '\n\n');

  /// `&amp;` is decoded last so an escaped `&lt;` is not decoded twice.
  static String _decodeEntities(String text) => text
      .replaceAll('&nbsp;', ' ')
      .replaceAll('&ensp;', ' ')
      .replaceAll('&emsp;', ' ')
      .replaceAll('&lt;', '<')
      .replaceAll('&gt;', '>')
      .replaceAll('&quot;', '"')
      .replaceAll('&#39;', "'")
      .replaceAll('&apos;', "'")
      .replaceAll('&amp;', '&');

  static String _tidy(String text) => text
      .replaceAll(_linePadding, '\n')
      .replaceAll(_wideGap, ' ')
      .replaceAll(_blankLines, '\n\n')
      .trim();
}

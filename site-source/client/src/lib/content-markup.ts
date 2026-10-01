/** Design: نفس منطق `ContentSanitizer` في التطبيق — المكتبة تعرض النص لا وسومه. */
export type ContentRun = { text: string; bold: boolean; color?: string };
export type ContentParagraph = { runs: ContentRun[] };

const PAYLOAD_MARKER = /^\s*html\b/i;
const COMMENT = /<!--[\s\S]*?-->/g;
const HEADING_MARKER = /^[ \t]*#{1,6}[ \t]*/gm;
const DOCUMENT_TAG = /<\/?\s*(?:html|head|body|meta|title|link|script|style)\b[^<>]*>/gi;
const LINE_BREAK = /<\s*br\s*\/?\s*>/gi;
const BLOCK_BOUNDARY = /<\/?\s*(?:p|div|hr|tr|li|ul|ol|table|blockquote|h[1-6])\b[^<>]*>/gi;
const INLINE_TAG = /<\s*(\/?)\s*(b|c(?:=#[0-9a-fA-F]{3,8})?)\s*>/g;
const TAG_LIKE = /<\/?[A-Za-z][^<>]{0,300}>/g;
const LINE_PADDING = /[ \t\u00a0]+\n/g;
const WIDE_GAP = /[ \t\u00a0]{2,}/g;
const BLANK_LINES = /\n{3,}/g;
const ANY_NEWLINE = /\s*\n\s*/g;

const LIGATURES: Array<[RegExp, string]> = [
  [/\uFDFA/g, "(صلى الله عليه وآله)"],
  [/\uFDFB/g, "(جل جلاله)"],
];

function decodeEntities(text: string): string {
  return text
    .replace(/&nbsp;/g, " ")
    .replace(/&ensp;/g, " ")
    .replace(/&emsp;/g, " ")
    .replace(/&lt;/g, "<")
    .replace(/&gt;/g, ">")
    .replace(/&quot;/g, "\"")
    .replace(/&#39;/g, "'")
    .replace(/&apos;/g, "'")
    .replace(/&amp;/g, "&");
}

function stripPayload(raw: string): string {
  let text = raw.replace(PAYLOAD_MARKER, "");
  text = text.replace(COMMENT, "");
  text = text.replace(HEADING_MARKER, "");
  text = text.replace(DOCUMENT_TAG, "");
  for (const [ligature, spelling] of LIGATURES) text = text.replace(ligature, spelling);
  return text;
}

function toParagraphs(text: string): string {
  return text.replace(LINE_BREAK, "\n").replace(BLOCK_BOUNDARY, "\n\n");
}

function tidy(text: string): string {
  return text.replace(LINE_PADDING, "\n").replace(WIDE_GAP, " ").replace(BLANK_LINES, "\n\n").trim();
}

function inlineRuns(block: string): ContentRun[] {
  const runs: ContentRun[] = [];
  let bold = false;
  let color: string | undefined;
  let cursor = 0;
  const push = (text: string) => {
    if (!text) return;
    const previous = runs[runs.length - 1];
    if (previous && previous.bold === bold && previous.color === color) previous.text += text;
    else runs.push({ text, bold, color });
  };
  INLINE_TAG.lastIndex = 0;
  let match = INLINE_TAG.exec(block);
  while (match) {
    push(block.slice(cursor, match.index));
    cursor = match.index + match[0].length;
    const closing = match[1] === "/";
    const name = match[2];
    if (name.toLowerCase() === "b") bold = !closing;
    else if (closing) color = undefined;
    else color = name.slice(name.indexOf("#") + 1).toLowerCase();
    match = INLINE_TAG.exec(block);
  }
  push(block.slice(cursor));
  return runs.map((run) => ({ ...run, text: decodeEntities(run.text) }));
}

/** الفقرات كما يرسمها التطبيق: نص منسّق مع اللون والعريض. */
export function contentParagraphs(value: unknown): ContentParagraph[] {
  if (typeof value !== "string" || !value.trim()) return [];
  return toParagraphs(stripPayload(value))
    .split(/\n{2,}/)
    .map((block) => block.trim())
    .filter((block) => block.length > 0)
    .map((block) => ({ runs: inlineRuns(block) }));
}

/** النص الخالص: ما ينسخ ويُشارك، بلا أي وسم. */
export function contentPlainText(value: unknown): string {
  if (typeof value !== "string") return "";
  const text = toParagraphs(stripPayload(value)).replace(TAG_LIKE, "");
  return tidy(decodeEntities(text));
}

/** سطر واحد للمعاينات والبطاقات. */
export function contentSnippet(value: unknown, maxLength?: number): string {
  const text = contentPlainText(value).replace(ANY_NEWLINE, " ");
  if (maxLength === undefined || text.length <= maxLength) return text;
  return `${text.slice(0, maxLength).trimEnd()}…`;
}

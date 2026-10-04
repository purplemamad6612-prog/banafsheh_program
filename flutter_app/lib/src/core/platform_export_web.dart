import 'dart:convert';
import 'dart:html' as html;

bool downloadText(String filename, String mimeType, String text) {
  final blob = html.Blob([utf8.encode('\uFEFF$text')], mimeType);
  final url = html.Url.createObjectUrlFromBlob(blob);
  final anchor = html.AnchorElement(href: url)..download = filename..style.display = 'none';
  html.document.body?.children.add(anchor);
  anchor.click();
  anchor.remove();
  html.Url.revokeObjectUrl(url);
  return true;
}

bool printCurrentPage() {
  html.window.print();
  return true;
}

// lib/utils/web_utils_web.dart
// ignore: avoid_web_libraries_in_flutter
import 'dart:html' as html;
import 'dart:convert';

void exportarCSVWeb(String contenido, String nombreArchivo) {
  final bytes = utf8.encode(contenido);
  final blob = html.Blob([bytes]);
  final url = html.Url.createObjectUrlFromBlob(blob);
  final anchor =
      html.AnchorElement(href: url)
        ..setAttribute('download', nombreArchivo)
        ..click();
  html.Url.revokeObjectUrl(url);
}

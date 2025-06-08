// exportar_web.dart
import 'dart:convert';
import 'dart:html' as html;

/// Exporta el contenido CSV en la web con un archivo descargable
void exportarCSVWeb(String csv, String nombreArchivo) {
  final bytes = utf8.encode(csv);
  final blob = html.Blob([bytes]);
  final url = html.Url.createObjectUrlFromBlob(blob);
  final anchor =
      html.AnchorElement(href: url)
        ..setAttribute('download', nombreArchivo)
        ..click();
  html.Url.revokeObjectUrl(url);
}

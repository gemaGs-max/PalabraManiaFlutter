import 'package:flutter/material.dart';

/// Widget que muestra un personaje (mono) con un mensaje encima.
/// Útil para dar retroalimentación animada en los minijuegos.
class PersonajeHabla extends StatelessWidget {
  /// Texto que dirá el personaje.
  final String texto;

  /// Constructor que requiere el texto a mostrar.
  const PersonajeHabla({super.key, required this.texto});

  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: Alignment.bottomRight,
      children: [
        // Burbujita del mensaje
        Padding(
          padding: const EdgeInsets.only(bottom: 70, right: 12),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.orange.shade100, // Fondo suave para la burbuja
              borderRadius: BorderRadius.circular(12),
              boxShadow: const [
                BoxShadow(
                  color: Colors.black26,
                  blurRadius: 4,
                  offset: Offset(2, 2),
                ),
              ],
            ),
            child: Text(
              texto,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Colors.black87,
              ),
            ),
          ),
        ),
        // Imagen del mono
        Padding(
          padding: const EdgeInsets.only(right: 10, bottom: 10),
          child: Image.asset(
            'assets/images/mono.png',
            height: 60,
            fit: BoxFit.contain,
          ),
        ),
      ],
    );
  }
}

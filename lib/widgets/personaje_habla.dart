import 'package:flutter/material.dart';

class PersonajeHabla extends StatelessWidget {
  final String mensaje;

  const PersonajeHabla({super.key, required this.mensaje});

  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: Alignment.bottomRight,
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: 70, right: 12),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.yellow.shade100,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.black12,
                  blurRadius: 4,
                  offset: Offset(2, 2),
                ),
              ],
            ),
            child: Text(
              mensaje,
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
            ),
          ),
        ),
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

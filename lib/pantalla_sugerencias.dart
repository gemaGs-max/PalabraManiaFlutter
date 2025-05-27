import 'package:flutter/material.dart';

class PantallaSugerencias extends StatelessWidget {
  const PantallaSugerencias({super.key});

  final String urlWeb = 'https://gemags-max.github.io/PalabraMania/';
  final String email = 'soporte@palabramania.com';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('💌 Sugerencias'),
        backgroundColor: Colors.teal,
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '¿Tienes ideas para mejorar PalabraManía?',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),
            const Text('🌐 Puedes visitar nuestra web:'),
            SelectableText(
              urlWeb,
              style: const TextStyle(
                color: Colors.blueAccent,
                fontSize: 16,
                decoration: TextDecoration.underline,
              ),
            ),
            const SizedBox(height: 20),
            const Text('✉️ También puedes escribirnos a:'),
            SelectableText(
              email,
              style: const TextStyle(
                color: Colors.deepPurple,
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 30),
            const Text(
              '¡Gracias por ayudarnos a mejorar! 😊',
              style: TextStyle(fontStyle: FontStyle.italic),
            ),
          ],
        ),
      ),
    );
  }
}

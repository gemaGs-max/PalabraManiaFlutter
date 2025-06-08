import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'pantalla_juegos.dart';

class PantallaIdioma extends StatelessWidget {
  const PantallaIdioma({super.key});

  void _guardarIdioma(BuildContext context, String idioma) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('idioma', idioma);
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => PantallaJuegos()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Selecciona un idioma')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ElevatedButton.icon(
              onPressed: () => _guardarIdioma(context, 'ingles'),
              icon: const Icon(Icons.language),
              label: const Text('Aprender Inglés'),
            ),
            ElevatedButton.icon(
              onPressed: () => _guardarIdioma(context, 'frances'),
              icon: const Icon(Icons.language),
              label: const Text('Aprender Francés'),
            ),
          ],
        ),
      ),
    );
  }
}

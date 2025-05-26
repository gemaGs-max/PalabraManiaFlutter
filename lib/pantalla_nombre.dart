// Importamos librerías necesarias de Flutter, SharedPreferences y Firebase.
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart'; // Para guardar el nombre localmente.
import 'package:firebase_auth/firebase_auth.dart'; // Para autenticación anónima.
import 'pantalla_juegos.dart'; // Navegamos aquí al terminar.

/// Pantalla que solicita el nombre del usuario antes de acceder a los juegos.
class PantallaNombre extends StatefulWidget {
  @override
  _PantallaNombreState createState() => _PantallaNombreState();
}

class _PantallaNombreState extends State<PantallaNombre> {
  final TextEditingController _controller = TextEditingController(); // Controlador del campo de texto.

  /// Guarda el nombre en SharedPreferences, inicia sesión anónima y navega a los juegos.
  Future<void> _guardarNombreYContinuar() async {
    final nombre = _controller.text.trim(); // Eliminamos espacios al inicio y final.

    if (nombre.isEmpty) {
      // Mostramos mensaje si no se ha escrito nada.
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Por favor, escribe tu nombre.')),
      );
      return;
    }

    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('nombre_usuario', nombre); // Guardamos el nombre localmente.

      // Si no hay usuario autenticado, iniciamos sesión anónima con Firebase.
      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser == null) {
        await FirebaseAuth.instance.signInAnonymously();
      }

      // Navegamos a la pantalla de juegos.
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => PantallaJuegos()),
      );
    } catch (e) {
      // En caso de error, mostramos un mensaje.
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFF8E1), // Color crema de fondo.
      appBar: AppBar(
        title: const Text('¿Cómo te llamas?'),
        backgroundColor: Colors.deepOrangeAccent,
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(30.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Título de la pantalla.
            const Text(
              'Escribe tu nombre para comenzar:',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),

            // Campo de texto para introducir el nombre.
            TextField(
              controller: _controller,
              decoration: const InputDecoration(
                hintText: 'Tu nombre',
                border: OutlineInputBorder(),
                filled: true,
                fillColor: Colors.white,
              ),
            ),
            const SizedBox(height: 30),

            // Botón para guardar el nombre y empezar a jugar.
            ElevatedButton(
              onPressed: _guardarNombreYContinuar,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.deepOrangeAccent,
                padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 15),
              ),
              child: const Text(
                'Empezar a jugar',
                style: TextStyle(fontSize: 18, color: Colors.white),
              ),
            )
          ],
        ),
      ),
    );
  }
}

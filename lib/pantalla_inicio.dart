import 'package:flutter/material.dart';
import 'auth_screen.dart';

/// Pantalla de bienvenida de la app PalabraManía.
/// Desde aquí, el usuario puede iniciar sesión o registrarse.
class PantallaInicio extends StatelessWidget {
  const PantallaInicio({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFF8E1), // Fondo crema claro.
      appBar: AppBar(
        title: const Text('PalabraManía'),
        backgroundColor: Colors.deepOrangeAccent,
        centerTitle: true,
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Logo con protección en caso de error al cargar
            Image.asset(
              'assets/logo.png',
              width: 180,
              errorBuilder: (context, error, stackTrace) {
                // Si falla al cargar la imagen, se muestra un ícono alternativo
                return const Icon(
                  Icons.broken_image,
                  size: 100,
                  color: Colors.red,
                );
              },
            ),

            const SizedBox(height: 25),

            // Mensaje de bienvenida
            const Text(
              '¡Bienvenida a PalabraManía!',
              style: TextStyle(
                fontSize: 26,
                fontWeight: FontWeight.bold,
                color: Colors.deepOrange,
              ),
            ),

            const SizedBox(height: 10),

            const Text(
              'Aprende idiomas jugando y diviértete al máximo.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 16),
            ),

            const SizedBox(height: 40),

            // Botón para ir a la pantalla de login/registro
            ElevatedButton(
              onPressed: () {
                try {
                  // Intentamos navegar a la pantalla de autenticación
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const AuthScreen()),
                  );
                } catch (e) {
                  // Si hay un error, se imprime en consola
                  print("Error al navegar a AuthScreen: $e");
                  // Aquí podrías mostrar un mensaje al usuario si lo deseas
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.deepOrangeAccent,
                padding: const EdgeInsets.symmetric(
                  horizontal: 40,
                  vertical: 15,
                ),
              ),
              child: const Text(
                '¡Empezar ya!',
                style: TextStyle(fontSize: 18, color: Colors.white),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

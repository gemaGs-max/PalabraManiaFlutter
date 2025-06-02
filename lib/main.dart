import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'pantalla_inicio.dart'; // Pantalla de inicio de sesión/registro
import 'pantalla_juegos.dart'; // Pantalla principal de juegos para usuarios logueados

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Inicializamos Firebase con las opciones de configuración del proyecto
  await Firebase.initializeApp(
    options: const FirebaseOptions(
      apiKey: "AIzaSyBSzzvMzXlHBSPlaiv4Rgg6ZTCE-qc660A",
      authDomain: "gemags31.firebaseapp.com",
      projectId: "gemags31",
      storageBucket: "gemags31.firebasestorage.app",
      messagingSenderId: "292249107038",
      appId: "1:292249107038:web:432f4ba1b897cfdb2892cf",
      measurementId: "G-TR3XTC6ZX5",
    ),
  );

  runApp(const PalabraManiaApp());
}

/// Widget raíz de la aplicación PalabraManía
class PalabraManiaApp extends StatelessWidget {
  const PalabraManiaApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'PalabraManía',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.lightBlue, // Color principal de la aplicación
        scaffoldBackgroundColor: const Color(
          0xFFE1F5FE,
        ), // Color de fondo de las pantallas
      ),
      // Usamos StreamBuilder para escuchar cambios en el estado de autenticación
      home: StreamBuilder<User?>(
        stream: FirebaseAuth.instance.authStateChanges(),
        builder: (context, snapshot) {
          // Mientras Firebase determina si hay usuario logueado, mostramos un indicador de carga
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Scaffold(
              body: Center(child: CircularProgressIndicator()),
            );
          }
          // Si hay un usuario autenticado, navegamos a la pantalla de juegos
          else if (snapshot.hasData && snapshot.data != null) {
            return PantallaJuegos();
          }
          // Si no hay usuario, mostramos la pantalla de inicio (login/registro)
          else {
            return const PantallaInicio();
          }
        },
      ),
    );
  }
}

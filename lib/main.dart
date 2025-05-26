import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'pantalla_inicio.dart';
import 'pantalla_juegos.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

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

class PalabraManiaApp extends StatelessWidget {
  const PalabraManiaApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'PalabraManía',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.lightBlue,
        scaffoldBackgroundColor: const Color(0xFFE1F5FE),
      ),
      home: StreamBuilder<User?>(
        stream: FirebaseAuth.instance.authStateChanges(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Scaffold(
              body: Center(child: CircularProgressIndicator()),
            );
          } else if (snapshot.hasData && snapshot.data != null) {
            return PantallaJuegos(); // Usuario logueado
          } else {
            return const PantallaInicio(); // Usuario no logueado
          }
        },
      ),
    );
  }
}

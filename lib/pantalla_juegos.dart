import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'auth_screen.dart';
import 'flashcards.dart';
import 'completa_frase.dart';
import 'memoria.dart';
import 'pronunciacion_simulada.dart';
import 'pantalla_perfil.dart';
import 'pantalla_ranking.dart';
import 'pantalla_admin.dart';
import 'ahorcado_page.dart';
import 'ordena_frase_page.dart';
import 'tienda_page.dart';
import 'palabra_dia_page.dart';
import 'pantalla_sugerencias.dart';
import 'reto_del_mono_page.dart';
import 'reto_pro_page.dart'; // NUEVO JUEGO BLOQUEADO

class PantallaJuegos extends StatefulWidget {
  @override
  _PantallaJuegosState createState() => _PantallaJuegosState();
}

class _PantallaJuegosState extends State<PantallaJuegos> {
  String nombreUsuario = '';
  int puntosTotales = 0;
  bool esAdmin = false;
  String? avatarUrl;

  @override
  void initState() {
    super.initState();
    _cargarDatosUsuario();
  }

  Future<void> _cargarDatosUsuario() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid != null) {
      final doc =
          await FirebaseFirestore.instance
              .collection('usuarios')
              .doc(uid)
              .get();
      if (doc.exists && mounted) {
        setState(() {
          nombreUsuario = doc.data()?['nombre'] ?? 'Invitada/o';
          puntosTotales = doc.data()?['puntos'] ?? 0;
          esAdmin = doc.data()?['rol'] == 'administrador';
          avatarUrl = doc.data()?['fotoPerfil'];
        });
      }
    }
  }

  int nivelUsuario() => (puntosTotales / 100).floor() + 1;
  double progresoNivel() => (puntosTotales % 100) / 100;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color.fromARGB(255, 213, 130, 184),
      appBar: AppBar(
        backgroundColor: const Color.fromARGB(255, 30, 214, 134),
        elevation: 0,
        title: Text('¡Hola, $nombreUsuario!'),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.person),
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => PantallaPerfil()),
            );
          },
        ),
        actions: [
          if (avatarUrl != null)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10),
              child: CircleAvatar(
                backgroundImage: AssetImage('assets/avatars/$avatarUrl'),
              ),
            ),
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              await FirebaseAuth.instance.signOut();
              final prefs = await SharedPreferences.getInstance();
              await prefs.clear();
              Navigator.of(context).pushReplacement(
                MaterialPageRoute(builder: (_) => const AuthScreen()),
              );
            },
          ),
        ],
      ),
      body: Column(
        children: [
          Container(
            color: const Color.fromARGB(255, 71, 157, 188),
            padding: const EdgeInsets.symmetric(vertical: 12),
            child: Column(
              children: [
                Text(
                  'Nivel ${nivelUsuario()}',
                  style: const TextStyle(fontSize: 16, color: Colors.white),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 4,
                  ),
                  child: LinearProgressIndicator(
                    value: progresoNivel(),
                    backgroundColor: const Color.fromARGB(255, 196, 236, 243),
                    valueColor: const AlwaysStoppedAnimation<Color>(
                      Colors.white,
                    ),
                    minHeight: 6,
                  ),
                ),
                Text(
                  '$puntosTotales puntos totales',
                  style: const TextStyle(color: Colors.white70, fontSize: 12),
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),
          const Text(
            'Elige un juego para comenzar 🎮',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 10),
          Expanded(
            child: GridView.count(
              crossAxisCount: 3,
              childAspectRatio: 0.9,
              padding: const EdgeInsets.all(10),
              crossAxisSpacing: 10,
              mainAxisSpacing: 10,
              children: [
                _gameCard('🧠', 'Flashcards', FlashcardsPage()),
                _gameCard('✍️', 'Completa la frase', CompletaFrasePage()),
                _gameCard('🧩', 'Memoria', MemoriaPage()),
                _gameCard('🎤', 'Escucha Inglés', PronunciacionSimulada()),
                _gameCard('🕹️', 'Ahorcado', AhorcadoPage()),
                _gameCard('🔡', 'Ordena la frase', OrdenaFrasePage()),
                _gameCard('📖', 'Palabra del día', const PalabraDelDiaPage()),
                _gameCard('🛒', 'Tienda', const TiendaPage()),
                _gameCard('🐒', 'Reto del Mono', RetoDelMonoPage()),
                puntosTotales >= 40
                    ? _gameCard('🔥', 'Reto Pro', const RetoProPage())
                    : _gameCardBloqueado('🔥', 'Reto Pro (Bloqueado)'),
                _gameCard('💌', 'Sugerencias', const PantallaSugerencias()),
                _gameCard('🏆', 'Ranking', PantallaRanking()),
                if (esAdmin) _gameCard('🔧', 'Admin', PantallaAdmin()),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _gameCard(String emoji, String title, Widget destino) {
    return InkWell(
      onTap: () {
        Navigator.push(context, MaterialPageRoute(builder: (_) => destino));
      },
      borderRadius: BorderRadius.circular(14),
      hoverColor: const Color(0xFFE1F5FE),
      child: Container(
        decoration: BoxDecoration(
          color: const Color.fromARGB(255, 32, 236, 138),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: const Color(0xFFDDDDDD)),
          boxShadow: const [
            BoxShadow(
              color: Colors.black12,
              blurRadius: 4,
              offset: Offset(2, 2),
            ),
          ],
        ),
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 10),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(emoji, style: const TextStyle(fontSize: 22)),
            const SizedBox(height: 6),
            Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
            ),
          ],
        ),
      ),
    );
  }

  Widget _gameCardBloqueado(String emoji, String title) {
    return InkWell(
      onTap: () {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              '🔒 Necesitas 40 puntos para desbloquear este minijuego.',
            ),
            duration: Duration(seconds: 2),
          ),
        );
      },
      borderRadius: BorderRadius.circular(14),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.grey[400],
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: Colors.grey[300]!),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 10),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(emoji, style: const TextStyle(fontSize: 22)),
            const SizedBox(height: 6),
            Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
            ),
          ],
        ),
      ),
    );
  }
}

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
import 'reto_pro_page.dart';

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
    final nivel = nivelUsuario();
    return Scaffold(
      backgroundColor: const Color.fromARGB(255, 232, 162, 57),
      appBar: AppBar(
        backgroundColor: const Color.fromARGB(255, 219, 67, 209),
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
                  'Nivel $nivel',
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
                _restrictedGameCard(
                  '💪',
                  'Reto Pro',
                  const RetoProPage(),
                  puntosTotales,
                  40,
                ),
                _gameCard('🐒', 'Reto del Mono', RetoDelMonoPage()),
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
      onTap:
          () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => destino),
          ),
      borderRadius: BorderRadius.circular(14),
      hoverColor: const Color(0xFFE1F5FE),
      child: Container(
        decoration: BoxDecoration(
          color: const Color.fromARGB(255, 71, 224, 148),
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

  Widget _restrictedGameCard(
    String emoji,
    String title,
    Widget destino,
    int puntosActuales,
    int puntosRequeridos,
  ) {
    final enabled = puntosActuales >= puntosRequeridos;
    return InkWell(
      onTap:
          enabled
              ? () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => destino),
              )
              : () {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      'Necesitas al menos $puntosRequeridos puntos para acceder a "$title".',
                    ),
                  ),
                );
              },
      borderRadius: BorderRadius.circular(14),
      hoverColor: const Color(0xFFE1F5FE),
      child: Container(
        decoration: BoxDecoration(
          color:
              enabled
                  ? const Color.fromARGB(255, 71, 224, 148)
                  : Colors.grey.shade400,
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
            Text(
              emoji,
              style: TextStyle(
                fontSize: 22,
                color: enabled ? null : Colors.grey,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              title,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: enabled ? Colors.black : Colors.grey.shade700,
              ),
            ),
            if (!enabled)
              Padding(
                padding: const EdgeInsets.only(top: 6),
                child: Text(
                  'Requiere $puntosRequeridos puntos',
                  style: const TextStyle(fontSize: 10, color: Colors.white70),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

// Pantalla principal de juegos de PalabraManía con hover animado y separación divertida
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:confetti/confetti.dart';
import 'dart:math';

import 'widgets/personaje_habla.dart';
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
import 'traduccion_tecnica_page.dart';
import 'emoji_crack_page.dart';

class PantallaJuegos extends StatefulWidget {
  @override
  _PantallaJuegosState createState() => _PantallaJuegosState();
}

class _PantallaJuegosState extends State<PantallaJuegos> {
  String nombreUsuario = '';
  int puntosTotales = 0;
  bool esAdmin = false;
  String? avatarUrl;
  int _nivelAnterior = 1;
  late ConfettiController _confettiController;
  String _fraseMono = '';

  @override
  void initState() {
    super.initState();
    _confettiController = ConfettiController(
      duration: const Duration(seconds: 2),
    );
    _fraseMono = frasesMono[Random().nextInt(frasesMono.length)];
    _cargarDatosUsuario();
  }

  @override
  void dispose() {
    _confettiController.dispose();
    super.dispose();
  }

  final List<String> frasesMono = [
    '🐵 ¿Listo para aprender y jugar?',
    '🙈 ¡A ver si puedes con todos los retos!',
    '💡 Hoy es un gran día para practicar idiomas',
    '🎯 ¡A mejorar ese inglés a tope!',
    '🔥 Tu cerebro está en modo power!',
  ];

  Future<void> _cargarDatosUsuario() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid != null) {
      final doc =
          await FirebaseFirestore.instance
              .collection('usuarios')
              .doc(uid)
              .get();
      if (doc.exists && mounted) {
        final nuevosPuntos = doc.data()?['puntos'] ?? 0;
        final nuevoNivel = (nuevosPuntos / 50).floor() + 1;

        if (nuevoNivel > _nivelAnterior) {
          _mostrarSubidaNivel(nuevoNivel);
        }

        setState(() {
          nombreUsuario = doc.data()?['nombre'] ?? 'Invitada/o';
          puntosTotales = nuevosPuntos;
          esAdmin = doc.data()?['rol'] == 'administrador';
          avatarUrl = doc.data()?['fotoPerfil'];
          _nivelAnterior = nuevoNivel;
        });
      }
    }
  }

  void _mostrarSubidaNivel(int nuevoNivel) {
    _confettiController.play();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('🎉 ¡Subiste al nivel $nuevoNivel! ¡Sigue así! 🚀'),
        duration: const Duration(seconds: 3),
      ),
    );
  }

  int nivelUsuario() => (puntosTotales / 50).floor() + 1;
  double progresoNivel() => (puntosTotales % 50) / 50;

  @override
  Widget build(BuildContext context) {
    final juegos = _listaDeJuegos();
    final otros = _listaDeUtilidades();

    return Scaffold(
      backgroundColor: const Color.fromARGB(255, 213, 130, 184),
      appBar: AppBar(
        backgroundColor: const Color.fromARGB(255, 30, 214, 134),
        elevation: 0,
        title: Text('¡Hola, $nombreUsuario!'),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.person),
          onPressed:
              () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => PantallaPerfil()),
              ),
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
      body: Stack(
        children: [
          Column(
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
                        backgroundColor: const Color.fromARGB(255, 7, 200, 110),
                        valueColor: const AlwaysStoppedAnimation<Color>(
                          Colors.white,
                        ),
                        minHeight: 6,
                      ),
                    ),
                    Text(
                      '$puntosTotales puntos totales',
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 10),
              PersonajeHabla(mensaje: _fraseMono),
              const SizedBox(height: 10),
              const Text(
                'Elige un juego para comenzar 🎮',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 10),
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    children: [
                      Wrap(
                        spacing: 10,
                        runSpacing: 10,
                        alignment: WrapAlignment.center,
                        children: juegos,
                      ),
                      const SizedBox(height: 20),
                      const Text(
                        '🕹️ Minijuegos arriba 👆 Utilidades 🛠️ abajo 👇 ',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 10),
                      Wrap(
                        spacing: 10,
                        runSpacing: 10,
                        alignment: WrapAlignment.center,
                        children: otros,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          Align(
            alignment: Alignment.topCenter,
            child: ConfettiWidget(
              confettiController: _confettiController,
              blastDirection: pi / 2,
              maxBlastForce: 10,
              minBlastForce: 5,
              emissionFrequency: 0.05,
              numberOfParticles: 30,
              gravity: 0.3,
              colors: const [
                Colors.purple,
                Colors.pink,
                Colors.orange,
                Colors.green,
              ],
            ),
          ),
        ],
      ),
    );
  }

  List<Widget> _listaDeJuegos() => [
    _hoverCard('🧠', 'Flashcards', FlashcardsPage()),
    _hoverCard('✍️', 'Completa la frase', CompletaFrasePage()),
    _hoverCard('🧩', 'Memoria', MemoriaPage()),
    _hoverCard('🎤', 'Escucha Inglés', PronunciacionSimulada()),
    _hoverCard('🕹️', 'Ahorcado', AhorcadoPage()),
    _hoverCard('🔡', 'Ordena la frase', OrdenaFrasePage()),
    _hoverCard('📖', 'Palabra del día', const PalabraDelDiaPage()),
    _hoverCard('🐒', 'Reto del Mono', RetoDelMonoPage()),
    puntosTotales >= 40
        ? _hoverCard('🔥', 'Reto Pro', const RetoProPage())
        : _gameCardBloqueado('🔥', 'Reto Pro (Bloqueado)'),
    _hoverCard('💻', 'Traducción Técnica', const TraduccionTecnicaPage()),
    _hoverCard('😜', 'EmojiCrack', const EmojiCrackPage()),
  ];

  List<Widget> _listaDeUtilidades() => [
    _hoverCardExtra('🛒', 'Tienda', const TiendaPage()),
    _hoverCardExtra('💌', 'Sugerencias', const PantallaSugerencias()),
    _hoverCardExtra('🏆', 'Ranking', PantallaRanking()),
    if (esAdmin) _hoverCardExtra('🔧', 'Admin', PantallaAdmin()),
  ];

  Widget _hoverCard(String emoji, String title, Widget destino) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap:
            () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => destino),
            ),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeInOut,
          width: 140,
          height: 140,
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
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(emoji, style: const TextStyle(fontSize: 24)),
              const SizedBox(height: 6),
              Text(
                title,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _hoverCardExtra(String emoji, String title, Widget destino) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap:
            () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => destino),
            ),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeInOut,
          width: 140,
          height: 140,
          decoration: BoxDecoration(
            color: const Color.fromARGB(255, 255, 238, 88),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: Colors.black12),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(emoji, style: const TextStyle(fontSize: 24)),
              const SizedBox(height: 6),
              Text(
                title,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _gameCardBloqueado(String emoji, String title) {
    return GestureDetector(
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
      child: Container(
        width: 140,
        height: 140,
        decoration: BoxDecoration(
          color: Colors.grey[400],
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: Colors.grey[300]!),
        ),
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

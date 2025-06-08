import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:confetti/confetti.dart';
import 'package:audioplayers/audioplayers.dart'; // 🎵 Reproductor de sonido
import 'dart:math';
import 'widgets/personaje_habla.dart';

class TraduccionTecnicaPage extends StatefulWidget {
  const TraduccionTecnicaPage({super.key});

  @override
  State<TraduccionTecnicaPage> createState() => _TraduccionTecnicaPageState();
}

class _TraduccionTecnicaPageState extends State<TraduccionTecnicaPage> {
  // Lista de preguntas del minijuego: traducción de términos técnicos
  final List<Map<String, dynamic>> _preguntas = [
    {
      'es': 'bucle',
      'correcta': 'loop',
      'opciones': ['loop', 'branch', 'case'],
    },
    {
      'es': 'cadena de texto',
      'correcta': 'string',
      'opciones': ['string', 'variable', 'statement'],
    },
    {
      'es': 'depurar',
      'correcta': 'debug',
      'opciones': ['debug', 'compile', 'build'],
    },
    {
      'es': 'condicional',
      'correcta': 'if statement',
      'opciones': ['for loop', 'if statement', 'function'],
    },
    {
      'es': 'compilador',
      'correcta': 'compiler',
      'opciones': ['compiler', 'engine', 'emulator'],
    },
  ];

  int _indice = 0; // Índice de la pregunta actual
  int _puntos = 0; // Puntuación acumulada en esta partida
  String _mensajeMono = '¡A por ello! 🙈'; // Mensaje motivador del mono
  late ConfettiController _confettiController;
  final AudioPlayer _audioPlayer = AudioPlayer(); // 🎵 Controlador de audio

  @override
  void initState() {
    super.initState();
    _confettiController = ConfettiController(
      duration: const Duration(seconds: 2),
    );
    _preguntas.shuffle(); // Mezcla las preguntas aleatoriamente
  }

  @override
  void dispose() {
    _confettiController.dispose(); // Libera el confetti
    _audioPlayer.dispose(); // Libera el audio
    super.dispose();
  }

  // Verifica si la respuesta seleccionada es correcta o no
  void _verificarRespuesta(String seleccion) async {
    final actual = _preguntas[_indice];
    final esCorrecta = seleccion == actual['correcta'];

    if (esCorrecta) {
      setState(() {
        _mensajeMono = '¡Correcto! 🎯';
        _puntos++;
      });
      _confettiController.play();
      await _audioPlayer.play(
        AssetSource('audios/correcto.mp3'),
      ); // 🎵 Sonido correcto
    } else {
      setState(() {
        _mensajeMono = 'Ups... esa no era 😅';
      });
      await _audioPlayer.play(
        AssetSource('audios/error.mp3'),
      ); // 🎵 Sonido error
    }

    // Espera 2 segundos y pasa a la siguiente pregunta o muestra el diálogo final
    Future.delayed(const Duration(seconds: 2), () {
      if (_indice < _preguntas.length - 1) {
        setState(() {
          _indice++;
        });
      } else {
        _mostrarDialogoFinal(); // Juego finalizado
      }
    });
  }

  // Guarda la mejor puntuación y suma puntos al usuario en Firestore
  Future<void> _guardarPuntuacion() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid != null) {
      final ref = FirebaseFirestore.instance
          .collection('puntuaciones')
          .doc(uid);
      final doc = await ref.get();
      int mejor = 0;

      if (doc.exists && doc.data()!.containsKey('traduccion_tecnica')) {
        mejor = doc['traduccion_tecnica'];
      }

      if (_puntos > mejor) {
        await ref.set({'traduccion_tecnica': _puntos}, SetOptions(merge: true));
      }

      await FirebaseFirestore.instance.collection('usuarios').doc(uid).update({
        'puntos': FieldValue.increment(_puntos),
      });
    }
  }

  // Muestra el diálogo final con la puntuación y opciones
  void _mostrarDialogoFinal() async {
    await _guardarPuntuacion();

    showDialog(
      context: context,
      barrierDismissible: false,
      builder:
          (_) => AlertDialog(
            title: const Text('✅ Juego finalizado'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                PersonajeHabla(
                  mensaje:
                      _puntos >= 4
                          ? '¡Lo has petado! 🧠🚀'
                          : '¡Buen intento! 💪',
                ),
                const SizedBox(height: 20),
                Text('Puntuación final: $_puntos / ${_preguntas.length}'),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.pop(context); // Cierra el diálogo
                  setState(() {
                    _indice = 0;
                    _puntos = 0;
                    _mensajeMono = '¡A por ello! 🙈';
                    _preguntas.shuffle(); // Reinicia las preguntas
                  });
                },
                child: const Text('🔁 Reintentar'),
              ),
              TextButton(
                onPressed: () {
                  Navigator.pop(context); // Cierra el diálogo
                  Navigator.pop(context); // Vuelve al menú de juegos
                },
                child: const Text('🏠 Menú'),
              ),
            ],
          ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final actual = _preguntas[_indice];

    return Scaffold(
      backgroundColor: Colors.blue[50],
      appBar: AppBar(
        backgroundColor: const Color.fromARGB(255, 211, 65, 141),
        title: const Text('🖥️ Traducción Técnica'),
        centerTitle: true,
      ),
      body: Stack(
        children: [
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Mono animado con mensaje
                PersonajeHabla(mensaje: _mensajeMono),
                const SizedBox(height: 30),

                // Pregunta actual
                Text(
                  '¿Cómo se dice en inglés: "${actual['es']}"?',
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 30),

                // Botones con opciones
                ...actual['opciones'].map<Widget>((opcion) {
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 6),
                    child: ElevatedButton(
                      onPressed: () => _verificarRespuesta(opcion),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: Colors.black,
                        minimumSize: const Size(double.infinity, 50),
                      ),
                      child: Text(opcion, style: const TextStyle(fontSize: 18)),
                    ),
                  );
                }).toList(),
              ],
            ),
          ),

          // 🎉 Confetti al acertar
          Align(
            alignment: Alignment.topCenter,
            child: ConfettiWidget(
              confettiController: _confettiController,
              blastDirection: pi / 2,
              numberOfParticles: 30,
              gravity: 0.2,
            ),
          ),
        ],
      ),
    );
  }
}

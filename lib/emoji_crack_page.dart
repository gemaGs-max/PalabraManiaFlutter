import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:confetti/confetti.dart';
import 'package:audioplayers/audioplayers.dart';
import 'dart:math';
import 'widgets/personaje_habla.dart';

// Página principal del minijuego EmojiCrack
class EmojiCrackPage extends StatefulWidget {
  const EmojiCrackPage({super.key});

  @override
  State<EmojiCrackPage> createState() => _EmojiCrackPageState();
}

class _EmojiCrackPageState extends State<EmojiCrackPage> {
  // Lista de preguntas: cada una con un conjunto de emojis, opciones de respuesta y la respuesta correcta
  final List<Map<String, dynamic>> _preguntas = [
    {
      'emoji': '📖❤️🇬🇧',
      'opciones': ['I love English books', 'Read love UK', 'Heart book flag'],
      'respuesta': 'I love English books',
    },
    {
      'emoji': '🍽️⏰',
      'opciones': ['Dinner time', 'Eat fast', 'Time to sleep'],
      'respuesta': 'Dinner time',
    },
    {
      'emoji': '🏃💨💦',
      'opciones': ['I am sweating', 'Run fast', 'Jump water'],
      'respuesta': 'Run fast',
    },
    {
      'emoji': '😴🛏️🌙',
      'opciones': ['Sleep tight', 'Good night bed', 'I love sleep'],
      'respuesta': 'Sleep tight',
    },
    {
      'emoji': '☕💻👩‍💻',
      'opciones': ['Coding coffee', 'Work time', 'Laptop break'],
      'respuesta': 'Coding coffee',
    },
  ];

  int _indiceActual = 0; // Índice de la pregunta actual
  int _puntuacion = 0; // Puntos obtenidos por el usuario
  late ConfettiController _confettiController; // Controlador de confetti 🎊
  final AudioPlayer _audioPlayer = AudioPlayer(); // Controlador de audio 🎵
  String _mensajeMono = '¡A jugar! 🙈'; // Mensaje que dice el personaje

  @override
  void initState() {
    super.initState();
    _preguntas.shuffle(); // Mezclamos las preguntas al iniciar el juego
    _confettiController = ConfettiController(
      duration: const Duration(seconds: 2),
    );
  }

  @override
  void dispose() {
    _confettiController.dispose(); // Libera el recurso de confetti
    _audioPlayer.dispose(); // Libera el reproductor de audio
    super.dispose();
  }

  // Función que verifica si la opción seleccionada es correcta
  void _verificarRespuesta(String seleccion) async {
    final correcta = _preguntas[_indiceActual]['respuesta'];

    if (seleccion == correcta) {
      setState(() {
        _mensajeMono = '¡Genial! 🎯';
        _puntuacion++;
      });
      _confettiController.play(); // 🎊 Efecto visual de confetti
      await _audioPlayer.play(
        AssetSource('audios/correcto.mp3'),
      ); // ✅ Sonido de acierto
    } else {
      setState(() {
        _mensajeMono = '¡Ups! Era "$correcta" 😅';
      });
      await _audioPlayer.play(
        AssetSource('audios/error.mp3'),
      ); // ❌ Sonido de error
    }

    // Esperamos 2 segundos y pasamos a la siguiente pregunta o mostramos el final
    Future.delayed(const Duration(seconds: 2), () {
      if (_indiceActual < _preguntas.length - 1) {
        setState(() {
          _indiceActual++;
          _mensajeMono = '¡Sigue así! 💪';
        });
      } else {
        _mostrarFinal(); // Si ya es la última, mostramos mensaje final
      }
    });
  }

  // Guarda la puntuación en Firebase Firestore
  Future<void> _guardarPuntuacion() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;

    final puntuacionRef = FirebaseFirestore.instance
        .collection('puntuaciones')
        .doc(uid);
    final usuarioRef = FirebaseFirestore.instance
        .collection('usuarios')
        .doc(uid);

    final doc = await puntuacionRef.get();
    int mejorAnterior = 0;

    // Si ya existe una puntuación anterior, la leemos
    if (doc.exists && doc.data()!.containsKey('emoji_crack')) {
      mejorAnterior = doc['emoji_crack'];
    }

    // Solo guardamos si es mejor que la anterior
    if (_puntuacion > mejorAnterior) {
      await puntuacionRef.set({
        'emoji_crack': _puntuacion,
      }, SetOptions(merge: true));
    }

    // Sumamos los puntos a la puntuación general del usuario
    await usuarioRef.update({'puntos': FieldValue.increment(_puntuacion)});
  }

  // Muestra un diálogo final con la puntuación obtenida
  void _mostrarFinal() async {
    await _guardarPuntuacion(); // Guardamos la puntuación
    await _audioPlayer.play(
      AssetSource('audios/great_day.mp3'),
    ); // 🎵 Sonido final

    if (!mounted) return;

    showDialog(
      context: context,
      builder:
          (_) => AlertDialog(
            title: const Text('🎉 ¡Juego completado!'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                PersonajeHabla(
                  mensaje: 'Has conseguido $_puntuacion puntos 👏',
                ),
                const SizedBox(height: 16),
                const Text('¿Qué quieres hacer ahora?'),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.pop(context); // Cierra el diálogo
                  setState(() {
                    _indiceActual = 0;
                    _puntuacion = 0;
                    _mensajeMono = '¡Otra ronda! 🐵';
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
                child: const Text('🏠 Volver al menú'),
              ),
            ],
          ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final pregunta = _preguntas[_indiceActual];

    return Scaffold(
      backgroundColor: const Color.fromARGB(255, 227, 172, 20),
      appBar: AppBar(
        title: const Text('🧠 EmojiCrack'),
        backgroundColor: const Color.fromARGB(255, 58, 162, 183),
        centerTitle: true,
      ),
      body: Stack(
        children: [
          Center(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Componente que muestra el mensaje del mono animado
                  PersonajeHabla(mensaje: _mensajeMono),
                  const SizedBox(height: 20),

                  // Título de la pregunta
                  const Text(
                    '¿Qué frase representan estos emojis?',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 10),

                  // Muestra el emoji actual
                  Text(pregunta['emoji'], style: const TextStyle(fontSize: 48)),
                  const SizedBox(height: 20),

                  // Botones con las opciones de respuesta
                  ...List.generate(
                    pregunta['opciones'].length,
                    (index) => Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      child: ElevatedButton(
                        onPressed:
                            () => _verificarRespuesta(
                              pregunta['opciones'][index],
                            ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.white,
                          foregroundColor: Colors.black,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        child: Text(
                          pregunta['opciones'][index],
                          textAlign: TextAlign.center,
                          style: const TextStyle(fontSize: 16),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Efecto confetti en la parte superior
          Align(
            alignment: Alignment.topCenter,
            child: ConfettiWidget(
              confettiController: _confettiController,
              blastDirection: pi * 1.5,
              colors: const [Colors.purple, Colors.orange, Colors.pink],
              numberOfParticles: 25,
              gravity: 0.4,
            ),
          ),
        ],
      ),
    );
  }
}

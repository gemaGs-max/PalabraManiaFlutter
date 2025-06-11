import 'package:flutter/material.dart';
import 'dart:math';
import 'package:confetti/confetti.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:palabramania/widgets/personaje_habla.dart';
import 'package:palabramania/pantalla_juegos.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class EmojiCrackPage extends StatefulWidget {
  const EmojiCrackPage({super.key});
  // Pantalla del juego EmojiCrack, un juego de adivinanza de emojis
  @override
  State<EmojiCrackPage> createState() => _EmojiCrackPageState();
}

class _EmojiCrackPageState extends State<EmojiCrackPage>
    with SingleTickerProviderStateMixin {
  final List<Map<String, dynamic>> _todasLasPreguntas = [
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
      'opciones': ['I’m crying', 'I’m tired', 'Running and sweating'],
      'respuesta': 'Running and sweating',
    },
    {
      'emoji': '🛏️💤',
      'opciones': ['Good morning', 'Time to sleep', 'Let’s party'],
      'respuesta': 'Time to sleep',
    },
  ];
  // Lista de preguntas con emojis y opciones de respuesta
  List<Map<String, dynamic>> _preguntas = [];
  int _indicePregunta = 0;
  int _puntos = 0;
  String _mensajeMono = '¡Vamos a jugar!';
  bool _juegoTerminado = false;

  late ConfettiController _confettiController;
  final AudioPlayer _audioPlayer = AudioPlayer();
  // Controlador de confeti para animaciones festivas
  @override
  void initState() {
    super.initState();
    _preguntas = List.from(_todasLasPreguntas)..shuffle();
    _confettiController = ConfettiController(
      duration: const Duration(seconds: 2),
    );
  }

  // Inicializa el juego y mezcla las preguntas
  @override
  void dispose() {
    _confettiController.dispose();
    _audioPlayer.dispose();
    super.dispose();
  }

  // Libera recursos al cerrar la pantalla
  /// Guarda la puntuación del usuario en Firestore si es mejor que la anterior
  Future<void> _guardarPuntuacion() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;
    final docRef = FirebaseFirestore.instance
        .collection('puntuaciones')
        .doc('$uid-emoji_crack');
    final doc = await docRef.get();
    final mejorAnterior = doc.exists ? doc['puntos'] ?? 0 : 0;

    if (_puntos > mejorAnterior) {
      await docRef.set({
        'usuarioId': uid,
        'minijuego': 'emoji_crack',
        'puntos': _puntos,
        'fecha': DateTime.now().toUtc().toIso8601String(),
      });
    }
  }

  // Guarda la puntuación en Firestore si es mejor que la anterior
  /// Devuelve una frase final según la puntuación del usuario
  String _fraseFinal() {
    if (_puntos == _preguntas.length) return '¡Increíble, lo sabes todo!';
    if (_puntos >= 2) return '¡Genial! Pero aún puedes mejorar.';
    return '¡No pasa nada! ¡Sigue practicando!';
  }

  // Devuelve una frase final según la puntuación del usuario
  void _responder(String seleccion) async {
    if (_juegoTerminado || !mounted) return;
    final correcta = _preguntas[_indicePregunta]['respuesta'];

    if (seleccion == correcta) {
      setState(() {
        _puntos++;
        _mensajeMono = '¡Bien hecho!';
      });
      _confettiController.play();
      await _audioPlayer.play(AssetSource('audios/correcto.mp3'));
    } else {
      setState(() {
        _mensajeMono = '¡Oh no! 😓';
      });
      await _audioPlayer.play(AssetSource('audios/error.mp3'));
    }

    await Future.delayed(const Duration(seconds: 1));

    if (!mounted) return;

    if (_indicePregunta < _preguntas.length - 1) {
      setState(() {
        _indicePregunta++;
        _mensajeMono = '¡Tú puedes!';
      });
    } else {
      setState(() {
        _juegoTerminado = true;
      });
      await Future.wait([
        _audioPlayer.play(AssetSource('audios/final.mp3')),
        _guardarPuntuacion(),
      ]);
      if (mounted) {
        setState(() {
          _mensajeMono = _fraseFinal();
        });
      }
    }
  }

  // Valida la respuesta seleccionada y actualiza el estado del juego
  void _reiniciarJuego() {
    setState(() {
      _preguntas = List.from(_todasLasPreguntas)..shuffle();
      _indicePregunta = 0;
      _puntos = 0;
      _mensajeMono = '¡Vamos a jugar!';
      _juegoTerminado = false;
    });
  }

  // Reinicia el juego y mezcla las preguntas nuevamente
  @override
  Widget build(BuildContext context) {
    final pregunta = _preguntas[_indicePregunta];

    return Scaffold(
      backgroundColor: const Color(0xFFE0F7FA),
      appBar: AppBar(
        backgroundColor: Colors.teal,
        title: const Text('EmojiCrack'),
        centerTitle: true,
      ),
      body: SafeArea(
        child: Stack(
          children: [
            Column(
              children: [
                PersonajeHabla(texto: _mensajeMono),
                const SizedBox(height: 20),
                if (_juegoTerminado)
                  Expanded(
                    child: Center(
                      child: Card(
                        color: Colors.white.withOpacity(0.95),
                        margin: const EdgeInsets.symmetric(horizontal: 30),
                        elevation: 10,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(25),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(24.0),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Text(
                                '🎉 ¡Juego terminado!',
                                style: TextStyle(
                                  fontSize: 26,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 20),
                              Text(
                                'Has conseguido $_puntos punto${_puntos == 1 ? '' : 's'}.',
                                style: const TextStyle(fontSize: 20),
                              ),
                              const SizedBox(height: 10),
                              Text(
                                _fraseFinal(),
                                textAlign: TextAlign.center,
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontStyle: FontStyle.italic,
                                ),
                              ),
                              const SizedBox(height: 24),
                              ElevatedButton.icon(
                                onPressed: _reiniciarJuego,
                                icon: const Icon(Icons.replay),
                                label: const Text('Reintentar'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.deepPurple,
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 30,
                                    vertical: 15,
                                  ),
                                  textStyle: const TextStyle(fontSize: 18),
                                ),
                              ),
                              const SizedBox(height: 12),
                              ElevatedButton.icon(
                                onPressed: () {
                                  Navigator.pushReplacement(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) => const PantallaJuegos(),
                                    ),
                                  );
                                },
                                icon: const Icon(Icons.home),
                                label: const Text('Volver al menú'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.grey.shade300,
                                  foregroundColor: Colors.black87,
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 25,
                                    vertical: 15,
                                  ),
                                  textStyle: const TextStyle(fontSize: 18),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  )
                else ...[
                  Text(
                    pregunta['emoji'],
                    style: const TextStyle(fontSize: 72),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 24),
                  ...pregunta['opciones'].map<Widget>((opcion) {
                    return Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 8,
                      ),
                      child: ElevatedButton(
                        onPressed: () => _responder(opcion),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.pinkAccent.shade100,
                          minimumSize: const Size.fromHeight(50),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20),
                          ),
                        ),
                        child: Text(
                          opcion,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                  const Spacer(),
                  Text(
                    'Puntos: $_puntos',
                    style: const TextStyle(fontSize: 18),
                  ),
                  const SizedBox(height: 16),
                ],
              ],
            ),
            Align(
              alignment: Alignment.topCenter,
              child: ConfettiWidget(
                confettiController: _confettiController,
                blastDirection: pi / 2,
                maxBlastForce: 20,
                minBlastForce: 8,
                emissionFrequency: 0.05,
                numberOfParticles: 20,
                gravity: 0.1,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'dart:math';
import 'package:confetti/confetti.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:palabramania/widgets/personaje_habla.dart'; // Mono que habla
import 'package:palabramania/pantalla_juegos.dart'; // Menú de juegos

class EmojiCrackPage extends StatefulWidget {
  const EmojiCrackPage({super.key});

  @override
  State<EmojiCrackPage> createState() => _EmojiCrackPageState();
}

class _EmojiCrackPageState extends State<EmojiCrackPage> {
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
      'opciones': ['I’m crying', 'I’m tired', 'Running and sweating'],
      'respuesta': 'Running and sweating',
    },
    {
      'emoji': '🛏️💤',
      'opciones': ['Good morning', 'Time to sleep', 'Let’s party'],
      'respuesta': 'Time to sleep',
    },
  ];

  int _indicePregunta = 0;
  int _puntos = 0;
  String _mensajeMono = '¡Vamos a jugar!';

  late ConfettiController _confettiController;
  final AudioPlayer _audioPlayer = AudioPlayer();

  @override
  void initState() {
    super.initState();
    _confettiController = ConfettiController(
      duration: const Duration(seconds: 2),
    );
  }

  @override
  void dispose() {
    _confettiController.dispose();
    _audioPlayer.dispose();
    super.dispose();
  }

  // Método que se llama al seleccionar una opción
  void _responder(String seleccion) async {
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

    if (_indicePregunta < _preguntas.length - 1) {
      setState(() {
        _indicePregunta++;
        _mensajeMono = '¡Tú puedes!';
      });
    } else {
      await _audioPlayer.play(
        AssetSource('audios/final.mp3'),
      ); // Si tienes final.mp3
      _mostrarDialogoFinal();
    }
  }

  // Mostrar diálogo de fin del juego
  void _mostrarDialogoFinal() {
    showDialog(
      context: context,
      builder:
          (_) => AlertDialog(
            title: const Text('¡Juego terminado!'),
            content: Text(
              'Has conseguido $_puntos punto${_puntos == 1 ? '' : 's'}.',
            ),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.pop(context);
                  _reiniciarJuego();
                },
                child: const Text('Reintentar'),
              ),
              TextButton(
                onPressed: () {
                  Navigator.pop(context);
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(builder: (_) => const PantallaJuegos()),
                  );
                },
                child: const Text('Volver al menú'),
              ),
            ],
          ),
    );
  }

  // Reinicia el juego
  void _reiniciarJuego() {
    setState(() {
      _indicePregunta = 0;
      _puntos = 0;
      _mensajeMono = '¡Vamos a jugar!';
    });
  }

  @override
  Widget build(BuildContext context) {
    final pregunta = _preguntas[_indicePregunta];

    return Scaffold(
      appBar: AppBar(
        title: const Text('EmojiCrack'),
        backgroundColor: Colors.pinkAccent,
      ),
      body: Stack(
        children: [
          Column(
            children: [
              // Mono con mensaje animado
              PersonajeHabla(texto: _mensajeMono),
              const SizedBox(height: 20),
              // Emoji gigante
              Text(pregunta['emoji'], style: const TextStyle(fontSize: 64)),
              const SizedBox(height: 20),
              // Botones con opciones
              ...pregunta['opciones'].map<Widget>((opcion) {
                return Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  child: ElevatedButton(
                    onPressed: () => _responder(opcion),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color.fromARGB(255, 183, 120, 173),
                      minimumSize: const Size.fromHeight(50),
                    ),
                    child: Text(opcion, style: const TextStyle(fontSize: 18)),
                  ),
                );
              }).toList(),
              const Spacer(),
              // Puntuación actual
              Text('Puntos: $_puntos', style: const TextStyle(fontSize: 18)),
              const SizedBox(height: 16),
            ],
          ),
          // Confetti de celebración
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
    );
  }
}

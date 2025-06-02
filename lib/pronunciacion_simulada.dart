// Minijuego "Escucha en inglés" - El usuario escucha frases y puede pasar a la siguiente
import 'package:flutter/material.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:confetti/confetti.dart';

/// Minijuego de escucha: el usuario escucha frases en inglés
class PronunciacionSimulada extends StatefulWidget {
  const PronunciacionSimulada({super.key});

  @override
  State<PronunciacionSimulada> createState() => _PronunciacionSimuladaState();
}

class _PronunciacionSimuladaState extends State<PronunciacionSimulada> {
  // Lista de frases y sus audios correspondientes
  final List<Map<String, String>> frases = [
    {'texto': 'How are you?', 'audio': 'how_are_you.mp3'},
    {'texto': 'Let’s practice.', 'audio': 'practice.mp3'},
    {'texto': 'Good morning!', 'audio': 'good_morning.mp3'},
    {'texto': 'Nice to meet you.', 'audio': 'nice_to_meet_you.mp3'},
    {'texto': 'Have a great day!', 'audio': 'great_day.mp3'},
  ];

  final AudioPlayer _player = AudioPlayer(); // Reproductor de audio
  late ConfettiController _confettiController; // Controlador de confeti
  int fraseActual = 0; // Índice de la frase actual

  @override
  void initState() {
    super.initState();
    _confettiController = ConfettiController(duration: Duration(seconds: 2));
  }

  @override
  void dispose() {
    _player.dispose();
    _confettiController.dispose();
    super.dispose();
  }

  // Reproduce el audio de la frase actual y lanza confeti
  Future<void> reproducirAudio(String archivo) async {
    try {
      await _player.play(AssetSource('audios/$archivo'));
      _confettiController.play();
    } catch (e) {
      print("Error al reproducir audio: $e");
    }
  }

  // Avanza a la siguiente frase en la lista
  void siguienteFrase() {
    setState(() {
      fraseActual = (fraseActual + 1) % frases.length;
    });
  }

  @override
  Widget build(BuildContext context) {
    final frase = frases[fraseActual];

    return Stack(
      children: [
        Scaffold(
          backgroundColor: const Color(0xFFE1F5FE),
          appBar: AppBar(
            title: const Text('🎧 Escucha en inglés'),
            backgroundColor: Colors.lightBlue,
            centerTitle: true,
          ),
          body: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text(
                  'Escucha esta frase:',
                  style: TextStyle(fontSize: 22),
                ),
                const SizedBox(height: 20),

                // Tarjeta con la frase en pantalla
                Card(
                  elevation: 4,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  color: Colors.white,
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Text(
                      '"${frase['texto']}"',
                      style: const TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: Colors.teal,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),

                const SizedBox(height: 40),

                // Botón para reproducir el audio
                ElevatedButton.icon(
                  icon: const Icon(Icons.volume_up),
                  label: const Text('Escuchar audio'),
                  onPressed: () => reproducirAudio(frase['audio']!),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.teal,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 12,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),

                const SizedBox(height: 20),

                // Botón para cambiar de frase
                ElevatedButton(
                  onPressed: siguienteFrase,
                  child: const Text('➡️ Otra frase'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.grey.shade200,
                    foregroundColor: Colors.black,
                  ),
                ),
              ],
            ),
          ),
        ),

        // Confeti animado al reproducir el audio
        Align(
          alignment: Alignment.center,
          child: ConfettiWidget(
            confettiController: _confettiController,
            blastDirectionality: BlastDirectionality.explosive,
            colors: const [Colors.blue, Colors.green, Colors.orange],
            numberOfParticles: 20,
            gravity: 0.3,
            shouldLoop: false,
          ),
        ),
      ],
    );
  }
}

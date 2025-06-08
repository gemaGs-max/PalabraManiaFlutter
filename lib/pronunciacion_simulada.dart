import 'package:flutter/material.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:confetti/confetti.dart';

/// Minijuego de escucha: el usuario ve frases y las escucha con audio
class PronunciacionSimulada extends StatefulWidget {
  const PronunciacionSimulada({super.key});

  @override
  State<PronunciacionSimulada> createState() => _PronunciacionSimuladaState();
}

class _PronunciacionSimuladaState extends State<PronunciacionSimulada> {
  // Lista de frases con el texto en inglés y el archivo de audio correspondiente
  final List<Map<String, String>> frases = [
    {'texto': 'How are you?', 'audio': 'how_are_you.mp3'},
    {'texto': 'Let’s practice.', 'audio': 'practice.mp3'},
    {'texto': 'Good morning!', 'audio': 'good_morning.mp3'},
    {'texto': 'Nice to meet you.', 'audio': 'nice_to_meet_you.mp3'},
    {'texto': 'Have a great day!', 'audio': 'great_day.mp3'},
  ];

  final AudioPlayer _player = AudioPlayer(); // Reproductor de audio
  late ConfettiController _confettiController; // Controlador de confeti animado
  int fraseActual = 0; // Índice de la frase actual

  @override
  void initState() {
    super.initState();
    // Inicializa el confeti con duración de 2 segundos
    _confettiController = ConfettiController(duration: Duration(seconds: 2));
  }

  @override
  void dispose() {
    // Libera recursos del audio y confeti
    _player.dispose();
    _confettiController.dispose();
    super.dispose();
  }

  /// Reproduce el audio de la frase actual y lanza confeti como retroalimentación visual
  Future<void> reproducirAudio(String archivo) async {
    try {
      await _player.play(AssetSource('audios/$archivo'));
      _confettiController.play(); // Activa la animación del confeti
    } catch (e) {
      print("Error al reproducir audio: $e");
    }
  }

  /// Pasa a la siguiente frase o muestra un mensaje cuando se han completado todas
  void siguienteFrase() {
    if (fraseActual == frases.length - 1) {
      // Si es la última frase, muestra diálogo final con el mono y opciones
      showDialog(
        context: context,
        builder:
            (context) => AlertDialog(
              title: const Text('¡Juego completado!'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Imagen del mono
                  Image.asset('assets/images/mono.png', height: 80),

                  const SizedBox(height: 12),

                  // Mensaje motivador dentro de una burbuja
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.yellow.shade100,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Text(
                      '¡Buen trabajo! 🎉',
                      style: TextStyle(fontWeight: FontWeight.bold),
                      textAlign: TextAlign.center,
                    ),
                  ),

                  const SizedBox(height: 20),

                  // Texto con opciones
                  const Text(
                    'Has escuchado todas las frases.\n¿Qué quieres hacer ahora?',
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
              actions: [
                // Botón para repetir desde el principio
                TextButton(
                  onPressed: () {
                    Navigator.of(context).pop(); // Cierra el diálogo
                    setState(() {
                      fraseActual = 0; // Reinicia el índice
                    });
                  },
                  child: const Text('🔁 Volver a escuchar'),
                ),
                // Botón para volver al menú principal
                TextButton(
                  onPressed: () {
                    Navigator.of(context).pop(); // Cierra el diálogo
                    Navigator.of(context).pop(); // Sale del minijuego
                  },
                  child: const Text('🏠 Volver al menú'),
                ),
              ],
            ),
      );
    } else {
      // Si aún hay frases, avanza a la siguiente
      setState(() {
        fraseActual++;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final frase = frases[fraseActual]; // Frase actual a mostrar

    return Stack(
      children: [
        Scaffold(
          backgroundColor: const Color(0xFFE1F5FE), // Fondo azul claro
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

                // Tarjeta que muestra la frase
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

                // Botón para escuchar el audio
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

                // Botón para pasar a la siguiente frase
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

        // Animación de confeti al reproducir audio
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

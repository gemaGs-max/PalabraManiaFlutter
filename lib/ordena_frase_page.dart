import 'package:flutter/material.dart';
import 'dart:math';
import 'package:confetti/confetti.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:palabramania/services/firestore_service.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'widgets/personaje_habla.dart'; // Mono que habla

class OrdenaFrasePage extends StatefulWidget {
  const OrdenaFrasePage({super.key});

  @override
  State<OrdenaFrasePage> createState() => _OrdenaFrasePageState();
}

class _OrdenaFrasePageState extends State<OrdenaFrasePage> {
  final List<Map<String, String>> _frases = [
    {'es': '¿Cómo estás?', 'en': 'How are you'},
    {'es': 'Yo soy estudiante', 'en': 'I am a student'},
    {'es': 'Nosotros jugamos fútbol', 'en': 'We play football'},
    {'es': 'Ella tiene un gato', 'en': 'She has a cat'},
    {'es': 'Nos gusta leer libros', 'en': 'We like to read books'},
    {'es': 'Ellos están en la escuela', 'en': 'They are at school'},
    {'es': 'Tú hablas inglés muy bien', 'en': 'You speak English very well'},
    {'es': 'Mi hermano vive en Madrid', 'en': 'My brother lives in Madrid'},
    {'es': 'Hoy es un buen día', 'en': 'Today is a good day'},
    {'es': 'Vamos al parque mañana', 'en': 'We go to the park tomorrow'},
  ];

  late Map<String, String> _fraseActual;
  List<Map<String, String>> _frasesRestantes = [];
  List<String> _palabrasDesordenadas = [];
  List<String> _respuestaUsuario = [];

  late ConfettiController _confettiController;
  final AudioPlayer _audioPlayer = AudioPlayer();

  bool _mostrarResultado = false;
  bool _esCorrecto = false;

  int _puntos = 0;
  int _mejorPuntuacion = 0;

  String _mensajeMono = ''; // Frase aleatoria del mono

  @override
  void initState() {
    super.initState();
    _confettiController = ConfettiController(
      duration: const Duration(seconds: 2),
    );
    _cargarMejorPuntuacion();
    _frasesRestantes = List.from(_frases)..shuffle();
    _nuevaFrase();
  }

  // Cargar la mejor puntuación del usuario desde Firestore
  Future<void> _cargarMejorPuntuacion() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid != null) {
      final doc = await getPuntuacion(uid, 'ordena_frase');
      if (doc != null) {
        setState(() {
          _mejorPuntuacion = doc['puntos'] ?? 0;
        });
      }
    }
  }

  // Cargar una nueva frase y mezclarla
  void _nuevaFrase() {
    setState(() {
      _mostrarResultado = false;
      _esCorrecto = false;
      _respuestaUsuario.clear();
      _mensajeMono = '';

      if (_frasesRestantes.isEmpty) {
        _mostrarDialogoFinal();
        return;
      }

      _fraseActual = _frasesRestantes.removeAt(0);
      _palabrasDesordenadas = _fraseActual['en']!.split(' ')..shuffle();
    });
  }

  // Diálogo al completar todas las frases
  void _mostrarDialogoFinal() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder:
          (_) => AlertDialog(
            title: const Text('🎉 ¡Juego terminado!'),
            content: Text(
              'Has completado todas las frases.\n\nPuntuación final: $_puntos ⭐',
            ),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.pop(context);
                  Navigator.pop(context);
                },
                child: const Text('Salir'),
              ),
              ElevatedButton(
                onPressed: () {
                  Navigator.pop(context);
                  setState(() {
                    _puntos = 0;
                    _frasesRestantes = List.from(_frases)..shuffle();
                    _nuevaFrase();
                  });
                },
                child: const Text('Reintentar'),
              ),
            ],
          ),
    );
  }

  // Añadir palabra a la respuesta del usuario
  void _seleccionarPalabra(String palabra) {
    if (_mostrarResultado) return;

    setState(() {
      _respuestaUsuario.add(palabra);
      _palabrasDesordenadas.remove(palabra);
    });
  }

  // Quitar la última palabra seleccionada
  void _quitarUltimaPalabra() {
    if (_respuestaUsuario.isNotEmpty && !_mostrarResultado) {
      setState(() {
        String ultima = _respuestaUsuario.removeLast();
        _palabrasDesordenadas.add(ultima);
      });
    }
  }

  // Verificar si la frase es correcta
  void _verificar() async {
    // Frases aleatorias del mono al acertar
    final frasesCorrecto = [
      '¡Bien hecho! 👏',
      '¡Eres un crack! 💥',
      '¡Lo clavaste! 🎯',
      '¡Perfecto! 🧠',
      '¡Sigue así! 🔝',
      '🥉 ¡Buen comienzo!',
      '🥈 ¡Muy bien! Sigue así 💪',
      '🥇 ¡Increíble! Nivel experto 🔥',
    ];

    // Frases aleatorias del mono al fallar
    final frasesError = [
      'Uy... casi 😅',
      '¡Vamos, tú puedes! 💪',
      'No pasa nada, intenta otra vez 🙌',
      '¡Ánimo! 💥',
      'Respira hondo y vuelve a intentarlo 😌',
    ];

    if (_respuestaUsuario.join(' ') == _fraseActual['en']) {
      _esCorrecto = true;
      _puntos++;

      if (_puntos > _mejorPuntuacion) {
        _mejorPuntuacion = _puntos;
        await guardarPuntuacion('ordena_frase', _puntos);
      }

      _confettiController.play();
      await _audioPlayer.play(AssetSource('audios/correcto.mp3'));
      _mensajeMono = (frasesCorrecto..shuffle()).first;
    } else {
      _esCorrecto = false;
      await _audioPlayer.play(AssetSource('audios/error.mp3'));
      _mensajeMono = (frasesError..shuffle()).first;
    }

    setState(() {
      _mostrarResultado = true;
    });
  }

  // Construir botones de palabras
  Widget _buildPalabras(List<String> palabras, void Function(String) onTap) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      alignment: WrapAlignment.center,
      children:
          palabras
              .map(
                (p) => ElevatedButton(
                  onPressed: () => onTap(p),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: Colors.black,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Text(p, style: const TextStyle(fontSize: 18)),
                ),
              )
              .toList(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Scaffold(
          backgroundColor: Colors.amber.shade100,
          appBar: AppBar(
            backgroundColor: Colors.amber.shade700,
            centerTitle: true,
            title: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text('🔤 Ordena la frase'),
                const SizedBox(width: 16),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.orange.shade100,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    '⭐ $_puntos',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
          ),
          body: SingleChildScrollView(
            child: Center(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Texto de traducción
                    Text(
                      'Traduce: "${_fraseActual['es']}"',
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 20),

                    // Palabras seleccionadas por el usuario
                    _buildPalabras(_respuestaUsuario, (_) {}),

                    const SizedBox(height: 8),

                    // Botón para quitar la última palabra
                    if (_respuestaUsuario.isNotEmpty && !_mostrarResultado)
                      TextButton(
                        onPressed: _quitarUltimaPalabra,
                        child: const Text('⏪ Quitar última palabra'),
                      ),

                    const SizedBox(height: 12),

                    // Palabras disponibles para seleccionar
                    _buildPalabras(_palabrasDesordenadas, _seleccionarPalabra),

                    const SizedBox(height: 30),

                    // Botones de acción
                    if (!_mostrarResultado)
                      ElevatedButton(
                        onPressed: _verificar,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 30,
                            vertical: 12,
                          ),
                        ),
                        child: const Text('Verificar'),
                      ),

                    if (_mostrarResultado)
                      Column(
                        children: [
                          Text(
                            _esCorrecto ? '✅ ¡Correcto!' : '❌ Intenta de nuevo',
                            style: TextStyle(
                              fontSize: 22,
                              color: _esCorrecto ? Colors.green : Colors.red,
                            ),
                          ),
                          const SizedBox(height: 10),
                          Text(
                            'Mejor puntuación: $_mejorPuntuacion ⭐',
                            style: const TextStyle(
                              fontSize: 16,
                              fontStyle: FontStyle.italic,
                            ),
                          ),
                          const SizedBox(height: 10),
                          ElevatedButton(
                            onPressed: _nuevaFrase,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.deepOrange,
                            ),
                            child: const Text('Otra frase'),
                          ),
                        ],
                      ),

                    const SizedBox(height: 20),

                    // Mono motivador con frase
                    if (_mensajeMono.isNotEmpty)
                      PersonajeHabla(mensaje: _mensajeMono),
                  ],
                ),
              ),
            ),
          ),
        ),

        // Confeti animado en el centro superior
        Align(
          alignment: Alignment.topCenter,
          child: ConfettiWidget(
            confettiController: _confettiController,
            blastDirection: pi / 2,
            numberOfParticles: 30,
            maxBlastForce: 15,
            minBlastForce: 5,
            gravity: 0.2,
          ),
        ),
      ],
    );
  }
}

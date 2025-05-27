// completa_frase_page.dart actualizado con medallas visibles
import 'package:flutter/material.dart';
import 'package:palabramania/services/firestore_service.dart';
import 'package:confetti/confetti.dart';
import 'package:audioplayers/audioplayers.dart';
import 'dart:math' as Math;

class CompletaFrasePage extends StatefulWidget {
  @override
  _CompletaFrasePageState createState() => _CompletaFrasePageState();
}

class _CompletaFrasePageState extends State<CompletaFrasePage> {
  final List<Map<String, dynamic>> _frases = [
    {
      'texto': 'She ___ a teacher.',
      'opciones': ['is', 'are', 'be'],
      'correcta': 'is',
    },
    {
      'texto': 'I ___ from Spain.',
      'opciones': ['am', 'is', 'are'],
      'correcta': 'am',
    },
    {
      'texto': 'They ___ football on Sundays.',
      'opciones': ['plays', 'play', 'played'],
      'correcta': 'play',
    },
  ];

  int _indice = 0;
  String _respuestaSeleccionada = '';
  bool _mostrandoResultado = false;
  int _puntos = 0;
  String _medalla = '';
  late ConfettiController _confettiController;
  late ConfettiController _estrellaController;
  final AudioPlayer _player = AudioPlayer();

  @override
  void initState() {
    super.initState();
    _confettiController = ConfettiController(
      duration: const Duration(seconds: 2),
    );
    _estrellaController = ConfettiController(
      duration: const Duration(seconds: 1),
    );
  }

  @override
  void dispose() {
    _confettiController.dispose();
    _estrellaController.dispose();
    _player.dispose();
    super.dispose();
  }

  void _verificarRespuesta(String opcion) async {
    if (_mostrandoResultado) return;

    final correcta = _frases[_indice]['correcta'];
    final esCorrecta = opcion == correcta;

    setState(() {
      _respuestaSeleccionada = opcion;
      _mostrandoResultado = true;
      if (esCorrecta) {
        _puntos++;
        _estrellaController.play();
      }
    });

    final sonido = esCorrecta ? 'correcto.mp3' : 'error.mp3';
    await _player.play(AssetSource('audios/$sonido'));

    Future.delayed(const Duration(seconds: 2), () {
      if (_indice + 1 < _frases.length) {
        setState(() {
          _indice++;
          _respuestaSeleccionada = '';
          _mostrandoResultado = false;
        });
      } else {
        guardarPuntuacion('completa_frase', _puntos);
        _confettiController.play();
        _evaluarLogro();
        _mostrarDialogoFinal();
      }
    });
  }

  void _evaluarLogro() {
    if (_puntos == 1) {
      _medalla = '🥉';
    } else if (_puntos == 2) {
      _medalla = '🥈';
    } else if (_puntos == 3) {
      _medalla = '🥇';
    }
  }

  void _mostrarDialogoFinal() {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('🎉 ¡Juego completado!'),
            content: Text('Tu puntuación final es: $_puntos $_medalla'),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop();
                  setState(() {
                    _indice = 0;
                    _respuestaSeleccionada = '';
                    _mostrandoResultado = false;
                    _puntos = 0;
                    _medalla = '';
                  });
                },
                child: const Text('🔁 Reintentar'),
              ),
              TextButton(
                onPressed:
                    () => Navigator.of(
                      context,
                    ).popUntil((route) => route.isFirst),
                child: const Text('🏠 Salir'),
              ),
            ],
          ),
    );
  }

  Path _drawStar(Size size) {
    const numberOfPoints = 5;
    final double radius = 6;
    final Path path = Path();
    final angle = (2 * Math.pi) / numberOfPoints;

    for (int i = 0; i < numberOfPoints; i++) {
      final x = radius * Math.cos(i * angle);
      final y = radius * Math.sin(i * angle);
      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }
    path.close();
    return path;
  }

  @override
  Widget build(BuildContext context) {
    final fraseActual = _frases[_indice];
    final esCorrecta = _respuestaSeleccionada == fraseActual['correcta'];

    return Stack(
      children: [
        Scaffold(
          backgroundColor: const Color(0xFFFFF8E1),
          appBar: AppBar(
            title: const Text('✍️ Completa la frase'),
            backgroundColor: Colors.orange.shade400,
            centerTitle: true,
            actions: [
              Padding(
                padding: const EdgeInsets.all(12.0),
                child: Center(
                  child: Text(
                    '⭐ Puntos: $_puntos',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ],
          ),
          body: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                LinearProgressIndicator(
                  value: (_indice + 1) / _frases.length,
                  backgroundColor: Colors.orange.shade100,
                  color: Colors.deepOrange,
                  minHeight: 12,
                ),
                const SizedBox(height: 20),
                Card(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  elevation: 4,
                  color: Colors.white,
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Text(
                      fraseActual['texto'],
                      style: const TextStyle(
                        fontSize: 26,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
                const SizedBox(height: 30),
                ...fraseActual['opciones'].map<Widget>((opcion) {
                  Color color = Colors.blueAccent;
                  if (_mostrandoResultado) {
                    if (opcion == fraseActual['correcta']) {
                      color = Colors.green;
                    } else if (opcion == _respuestaSeleccionada) {
                      color = Colors.red;
                    } else {
                      color = Colors.grey.shade400;
                    }
                  }

                  return AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    curve: Curves.easeInOut,
                    width: double.infinity,
                    margin: const EdgeInsets.symmetric(vertical: 8),
                    child: ElevatedButton(
                      onPressed: () => _verificarRespuesta(opcion),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: color,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        elevation: 5,
                      ),
                      child: Text(
                        opcion,
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  );
                }).toList(),
                if (_mostrandoResultado)
                  Padding(
                    padding: const EdgeInsets.only(top: 24),
                    child: Text(
                      esCorrecta ? '🎯 ¡Correcto!' : '❌ ¡Incorrecto!',
                      style: TextStyle(
                        fontSize: 26,
                        fontWeight: FontWeight.bold,
                        color: esCorrecta ? Colors.green : Colors.red,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
        Align(
          alignment: Alignment.topCenter,
          child: ConfettiWidget(
            confettiController: _confettiController,
            blastDirection: 3.14 / 2,
            maxBlastForce: 20,
            minBlastForce: 5,
            emissionFrequency: 0.05,
            numberOfParticles: 30,
            gravity: 0.1,
            shouldLoop: false,
          ),
        ),
        Align(
          alignment: Alignment.center,
          child: ConfettiWidget(
            confettiController: _estrellaController,
            blastDirectionality: BlastDirectionality.explosive,
            colors: const [Colors.yellow, Colors.orange, Colors.purple],
            createParticlePath: _drawStar,
            emissionFrequency: 0.2,
            numberOfParticles: 10,
            gravity: 0.3,
            shouldLoop: false,
          ),
        ),
      ],
    );
  }
}

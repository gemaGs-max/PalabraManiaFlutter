import 'package:flutter/material.dart';
import 'package:palabramania/services/firestore_service.dart'; // Servicio para guardar puntuaciones en Firestore
import 'package:confetti/confetti.dart'; // Para mostrar confeti al completar el juego
import 'package:audioplayers/audioplayers.dart'; // Para reproducir sonidos de acierto/error
import 'dart:math' as Math; // Para cálculos matemáticos (dibujar estrellas)

/// Página de juego “Completa la frase”
/// Muestra varias frases con una palabra faltante y opciones para completarlas.
/// Al final, muestra puntuación y medalla según número de respuestas correctas.
class CompletaFrasePage extends StatefulWidget {
  @override
  _CompletaFrasePageState createState() => _CompletaFrasePageState();
}

class _CompletaFrasePageState extends State<CompletaFrasePage> {
  // Lista de frases a completar. Cada elemento es un mapa con:
  // - 'texto': la frase con un espacio en blanco (___)
  // - 'opciones': lista de posibles palabras para rellenar
  // - 'correcta': la opción correcta
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

  int _indice = 0; // Índice de la frase actual en la lista
  String _respuestaSeleccionada = ''; // Opción que eligió el usuario
  bool _mostrandoResultado =
      false; // Indica si se está mostrando feedback de correcto/incorrecto
  int _puntos = 0; // Puntos obtenidos (una unidad por acierto)
  String _medalla = ''; // Emoji de medalla final (🥉, 🥈, 🥇)

  late ConfettiController
  _confettiController; // Controlador para confeti al terminar el juego
  late ConfettiController
  _estrellaController; // Controlador para confeti de estrellas al acertar
  final AudioPlayer _player = AudioPlayer(); // Reproductor de sonido

  @override
  void initState() {
    super.initState();
    // Creamos los controladores de confeti con duraciones diferentes
    _confettiController = ConfettiController(
      duration: const Duration(seconds: 2),
    );
    _estrellaController = ConfettiController(
      duration: const Duration(seconds: 1),
    );
  }

  @override
  void dispose() {
    // Liberamos los controladores y el reproductor al cerrar la pantalla
    _confettiController.dispose();
    _estrellaController.dispose();
    _player.dispose();
    super.dispose();
  }

  /// Verifica si la [opcion] elegida es correcta para la frase actual.
  /// Muestra feedback, reproduce sonido, suma puntos y avanza en la lista de frases.
  void _verificarRespuesta(String opcion) async {
    if (_mostrandoResultado)
      return; // Evita doble clic cuando ya se muestra el resultado

    final correcta = _frases[_indice]['correcta'];
    final esCorrecta = opcion == correcta;

    setState(() {
      _respuestaSeleccionada = opcion;
      _mostrandoResultado = true;
      if (esCorrecta) {
        _puntos++; // Aumenta 1 punto si la respuesta es correcta
        _estrellaController.play(); // Dispara confeti de estrellas
      }
    });

    // Reproducir sonido según acierto o error
    final sonido = esCorrecta ? 'correcto.mp3' : 'error.mp3';
    await _player.play(AssetSource('audios/$sonido'));

    // Después de 2 segundos, pasamos a la siguiente frase o terminamos el juego
    Future.delayed(const Duration(seconds: 2), () {
      if (_indice + 1 < _frases.length) {
        // Si quedan frases por mostrar, avanzamos índice y reseteamos estado
        setState(() {
          _indice++;
          _respuestaSeleccionada = '';
          _mostrandoResultado = false;
        });
      } else {
        // Si ya era la última frase, guardamos la puntuación en Firestore
        guardarPuntuacion('completa_frase', _puntos);
        // Disparamos confeti principal
        _confettiController.play();
        // Calculamos medalla final según puntos obtenidos
        _evaluarLogro();
        // Mostramos diálogo final con puntuación y medalla
        _mostrarDialogoFinal();
      }
    });
  }

  /// Asigna la [medalla] según los puntos obtenidos:
  /// - 1 punto: bronce (🥉)
  /// - 2 puntos: plata (🥈)
  /// - 3 puntos: oro (🥇)
  void _evaluarLogro() {
    if (_puntos == 1) {
      _medalla = '🥉';
    } else if (_puntos == 2) {
      _medalla = '🥈';
    } else if (_puntos == 3) {
      _medalla = '🥇';
    }
  }

  /// Muestra un [AlertDialog] al finalizar el juego, con la puntuación y medalla.
  /// Ofrece dos opciones: “Reintentar” (reiniciar variables) o “Salir” (volver al inicio).
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
                  Navigator.of(context).pop(); // Cierra el diálogo
                  // Reiniciamos el juego desde el principio
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
                onPressed: () {
                  // Cierra el diálogo y navega hasta la primera ruta en el stack
                  Navigator.of(context).popUntil((route) => route.isFirst);
                },
                child: const Text('🏠 Salir'),
              ),
            ],
          ),
    );
  }

  /// Genera un [Path] con forma de estrella para usar en el efecto de confeti.
  /// - [size] no se usa aquí, solo devolvemos un polígono de 5 puntas.
  Path _drawStar(Size size) {
    const numberOfPoints = 5;
    final double radius = 6; // Radio de la estrella
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
    // Obtenemos la frase actual según el índice
    final fraseActual = _frases[_indice];
    // Verificamos si la respuesta seleccionada coincide con la correcta
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
              // Mostrar en el AppBar los puntos actuales
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
                // Indicador de progreso lineal que avanza según cuántas frases ya se mostraron
                LinearProgressIndicator(
                  value: (_indice + 1) / _frases.length,
                  backgroundColor: Colors.orange.shade100,
                  color: Colors.deepOrange,
                  minHeight: 12,
                ),
                const SizedBox(height: 20),

                // Tarjeta que muestra el texto de la frase con el espacio en blanco
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

                // Botones de opciones para completar la frase
                ...fraseActual['opciones'].map<Widget>((opcion) {
                  // El color del botón varía si ya se mostró resultado:
                  // - Verde para la opción correcta
                  // - Rojo si fue la seleccionada y es incorrecta
                  // - Gris claro para las demás cuando se muestra el resultado
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

                // Mostramos texto de “¡Correcto!” o “¡Incorrecto!” si ya verificamos la respuesta
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

        // Confeti principal que se activa cuando se completa el juego
        Align(
          alignment: Alignment.topCenter,
          child: ConfettiWidget(
            confettiController: _confettiController,
            blastDirection: Math.pi / 2, // Hacia abajo
            maxBlastForce: 20,
            minBlastForce: 5,
            emissionFrequency: 0.05,
            numberOfParticles: 30,
            gravity: 0.1,
            shouldLoop: false,
          ),
        ),

        // Efecto de confeti de estrellas al acertar una respuesta
        Align(
          alignment: Alignment.center,
          child: ConfettiWidget(
            confettiController: _estrellaController,
            blastDirectionality: BlastDirectionality.explosive,
            colors: const [Colors.yellow, Colors.orange, Colors.purple],
            createParticlePath:
                _drawStar, // Dibuja cada partícula en forma de estrella
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

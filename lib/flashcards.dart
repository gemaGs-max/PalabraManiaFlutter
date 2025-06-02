import 'dart:async';
import 'package:flutter/material.dart';
import 'package:palabramania/services/firestore_service.dart';
import 'package:confetti/confetti.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:audioplayers/audioplayers.dart';
import 'widgets/personaje_habla.dart';

class FlashcardsPage extends StatefulWidget {
  @override
  _FlashcardsPageState createState() => _FlashcardsPageState();
}

class _FlashcardsPageState extends State<FlashcardsPage> {
  final List<Map<String, String>> _flashcardsOriginales = [
    {'front': 'Manzana', 'back': 'Apple'},
    {'front': 'Perro', 'back': 'Dog'},
    {'front': 'Casa', 'back': 'House'},
    {'front': 'Libro', 'back': 'Book'},
    {'front': 'Escuela', 'back': 'School'},
  ];

  late List<Map<String, String>> _flashcards;
  int _currentIndex = 0;
  int _puntos = 0;
  int _mejorPuntuacion = 0;
  int _tiempoRestante = 10; // Tiempo por tarjeta
  bool _mostrarFeedback = false;
  bool _bloquear = false;
  String _feedback = '';
  String _mensajeMono = "¡Vamos a empezar!";
  Timer? _timer;
  late ConfettiController _confettiController;
  final TextEditingController _respuestaController = TextEditingController();
  final AudioPlayer _player = AudioPlayer();

  @override
  void initState() {
    super.initState();
    _confettiController = ConfettiController(
      duration: const Duration(seconds: 2),
    );
    _cargarMejorPuntuacion();
    _reiniciarJuego();
  }

  // Cargar la mejor puntuación desde Firestore
  void _cargarMejorPuntuacion() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid != null) {
      final doc = await getPuntuacion(uid, 'flashcards');
      if (doc != null) {
        setState(() {
          _mejorPuntuacion = doc['puntos'] ?? 0;
        });
      }
    }
  }

  // Reinicia todo para comenzar una nueva partida
  void _reiniciarJuego() {
    _flashcards = List.from(_flashcardsOriginales)..shuffle();
    _currentIndex = 0;
    _puntos = 0;
    _mostrarFeedback = false;
    _bloquear = false;
    _mensajeMono = "¡Vamos a empezar!";
    _respuestaController.clear();
    _iniciarTemporizador();
  }

  // Inicia el temporizador para cada tarjeta
  void _iniciarTemporizador() {
    _timer?.cancel();
    _tiempoRestante = 10;
    _timer = Timer.periodic(Duration(seconds: 1), (timer) {
      setState(() {
        _tiempoRestante--;
      });
      if (_tiempoRestante == 0) {
        timer.cancel();
        _mostrarRespuestaAutomatica();
      }
    });
  }

  // Muestra la respuesta cuando se agota el tiempo
  void _mostrarRespuestaAutomatica() {
    final correcta = _flashcards[_currentIndex]['back']!;
    setState(() {
      _feedback = '⏰ Tiempo agotado. Era: $correcta';
      _mostrarFeedback = true;
      _bloquear = true;
      _mensajeMono = "¡Oh no! Se acabó el tiempo.";
    });
    Future.delayed(Duration(seconds: 2), _pasarSiguiente);
  }

  // Verifica si la respuesta es correcta
  void _comprobarRespuesta() {
    if (_bloquear) return;
    final correcta = _flashcards[_currentIndex]['back']!.toLowerCase().trim();
    final respuesta = _respuestaController.text.toLowerCase().trim();
    _timer?.cancel();
    setState(() {
      if (respuesta == correcta) {
        _puntos++;
        _feedback = '🎉 ¡Correcto!';
        _mensajeMono = "¡Genial! ¡Sigue así!";
      } else {
        _feedback = '❌ Era: ${_flashcards[_currentIndex]['back']}';
        _mensajeMono = "¡Ups! Intenta con la siguiente.";
      }
      _mostrarFeedback = true;
      _bloquear = true;
    });
    Future.delayed(Duration(seconds: 2), _pasarSiguiente);
  }

  // Pasa a la siguiente tarjeta
  void _pasarSiguiente() {
    if (_currentIndex + 1 >= _flashcards.length) {
      guardarPuntuacion('flashcards', _puntos);
      _confettiController.play();
      _mensajeMono = "¡Has terminado! ¿Repetimos?";
      _mostrarDialogoFinal();
      return;
    }
    setState(() {
      _currentIndex++;
      _respuestaController.clear();
      _mostrarFeedback = false;
      _bloquear = false;
    });
    _iniciarTemporizador();
  }

  // Muestra un diálogo al terminar todas las tarjetas
  void _mostrarDialogoFinal() {
    _timer?.cancel();
    showDialog(
      context: context,
      barrierDismissible: false,
      builder:
          (context) => AlertDialog(
            title: const Text('✅ Juego completado'),
            content: Text(
              'Has conseguido $_puntos puntos.\n'
              'Tu mejor puntuación: $_mejorPuntuacion\n'
              '¿Quieres reintentar?',
            ),
            actions: [
              TextButton(
                child: const Text('Salir'),
                onPressed:
                    () => Navigator.of(
                      context,
                    ).popUntil((route) => route.isFirst),
              ),
              ElevatedButton(
                child: const Text('Reintentar'),
                onPressed: () {
                  Navigator.of(context).pop();
                  setState(() {
                    _reiniciarJuego();
                  });
                },
              ),
            ],
          ),
    );
  }

  @override
  void dispose() {
    _respuestaController.dispose();
    _timer?.cancel();
    _confettiController.dispose();
    _player.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final currentCard = _flashcards[_currentIndex];
    return Stack(
      children: [
        Scaffold(
          backgroundColor: const Color(0xFFE0F7FA),
          appBar: AppBar(
            backgroundColor: Colors.teal,
            title: const Text('Flashcards'),
            centerTitle: true,
          ),
          body: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            child: Column(
              children: [
                Text(
                  '🏆 Mejor puntuación: $_mejorPuntuacion',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.teal.shade800,
                  ),
                ),
                const SizedBox(height: 8),
                // Barra de progreso del número de tarjetas
                LinearProgressIndicator(
                  value: (_currentIndex + 1) / _flashcards.length,
                  backgroundColor: Colors.teal.shade100,
                  color: Colors.teal.shade700,
                  minHeight: 8,
                ),
                const SizedBox(height: 16),
                // Barra de tiempo restante
                LinearProgressIndicator(
                  value: _tiempoRestante / 10,
                  backgroundColor: Colors.grey.shade300,
                  color: Colors.redAccent,
                  minHeight: 8,
                ),
                const SizedBox(height: 8),
                // Texto con el tiempo restante
                Text(
                  '⏳ Tiempo restante: $_tiempoRestante s',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.redAccent,
                  ),
                ),
                const SizedBox(height: 24),
                // Tarjeta con la palabra en español
                Card(
                  elevation: 6,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  color: Colors.purple.shade50,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      vertical: 40,
                      horizontal: 24,
                    ),
                    width: double.infinity,
                    alignment: Alignment.center,
                    child: Text(
                      currentCard['front']!,
                      style: const TextStyle(
                        fontSize: 36,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 32),
                // Campo de texto para escribir la traducción
                TextField(
                  controller: _respuestaController,
                  enabled: !_bloquear,
                  decoration: InputDecoration(
                    hintText: 'Escribe la palabra en inglés',
                    filled: true,
                    fillColor: Colors.white,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                // Botón para comprobar la respuesta
                ElevatedButton(
                  onPressed: _bloquear ? null : _comprobarRespuesta,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.teal.shade600,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 32,
                      vertical: 14,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  child: const Text(
                    'Comprobar',
                    style: TextStyle(fontSize: 18),
                  ),
                ),
                const SizedBox(height: 24),
                // Mensaje de feedback
                if (_mostrarFeedback)
                  AnimatedOpacity(
                    opacity: 1.0,
                    duration: Duration(milliseconds: 300),
                    child: Text(
                      _feedback,
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color:
                            _feedback.contains('Correcto')
                                ? Colors.green
                                : Colors.red,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
        // Confetti al final del juego
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
        // Mono que habla en la esquina inferior derecha
        Positioned(
          bottom: 12,
          right: 12,
          child: PersonajeHabla(mensaje: _mensajeMono),
        ),
      ],
    );
  }
}

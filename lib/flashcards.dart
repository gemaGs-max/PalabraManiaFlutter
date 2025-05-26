import 'dart:async';
import 'package:flutter/material.dart';
import 'package:palabramania/services/firestore_service.dart';
import 'package:confetti/confetti.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:audioplayers/audioplayers.dart';

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
  int _tiempoRestante = 10;
  bool _mostrarFeedback = false;
  bool _bloquear = false;
  String _feedback = '';
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

  void _reiniciarJuego() {
    _flashcards = List.from(_flashcardsOriginales);
    _flashcards.shuffle();
    _currentIndex = 0;
    _puntos = 0;
    _mostrarFeedback = false;
    _bloquear = false;
    _respuestaController.clear();
    _iniciarTemporizador();
  }

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

  void _mostrarRespuestaAutomatica() {
    final correcta = _flashcards[_currentIndex]['back']!;
    setState(() {
      _feedback = '⏰ Tiempo agotado. Era: $correcta';
      _mostrarFeedback = true;
      _bloquear = true;
    });
    Future.delayed(Duration(seconds: 2), _pasarSiguiente);
  }

  void _comprobarRespuesta() {
    if (_bloquear) return;
    final correcta = _flashcards[_currentIndex]['back']!.toLowerCase().trim();
    final respuesta = _respuestaController.text.toLowerCase().trim();
    _timer?.cancel();
    setState(() {
      if (respuesta == correcta) {
        _puntos++;
        _feedback = '🎉 ¡Correcto!';
      } else {
        _feedback = '❌ Era: ${_flashcards[_currentIndex]['back']}';
      }
      _mostrarFeedback = true;
      _bloquear = true;
    });
    Future.delayed(Duration(seconds: 2), _pasarSiguiente);
  }

  void _pasarSiguiente() {
    if (_currentIndex + 1 >= _flashcards.length) {
      guardarPuntuacion('flashcards', _puntos);
      _confettiController.play();

      if (_puntos == 3) {
        _mostrarMensajeLogro('🥉 ¡Buen comienzo!');
      } else if (_puntos == 5) {
        _mostrarMensajeLogro('🥈 ¡Sigue así!');
      } else if (_puntos == 10) {
        _mostrarMensajeLogro('🥇 ¡Eres una máquina!');
      }

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

  void _mostrarMensajeLogro(String texto) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(texto),
        backgroundColor: Colors.teal,
        duration: Duration(seconds: 2),
      ),
    );
  }

  void _mostrarDialogoFinal() {
    _timer?.cancel();
    showDialog(
      context: context,
      barrierDismissible: false,
      builder:
          (context) => AlertDialog(
            title: Text('✅ Juego completado'),
            content: Text(
              'Has conseguido $_puntos puntos.\n¿Quieres reintentar?',
            ),
            actions: [
              TextButton(
                child: Text('Salir'),
                onPressed:
                    () => Navigator.of(
                      context,
                    ).popUntil((route) => route.isFirst),
              ),
              ElevatedButton(
                child: Text('Reintentar'),
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
          backgroundColor: Color(0xFFE0F7FA),
          appBar: PreferredSize(
            preferredSize: Size.fromHeight(kToolbarHeight),
            child: Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xFF26C6DA), Color(0xFF00ACC1)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              child: AppBar(
                title: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.flash_on, color: Colors.white),
                    SizedBox(width: 8),
                    Text(
                      'Flashcards',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
                backgroundColor: Colors.transparent,
                elevation: 0,
                centerTitle: true,
                actions: [
                  Padding(
                    padding: const EdgeInsets.all(12.0),
                    child: Center(
                      child: Text(
                        '⭐ $_puntos | 🏆 $_mejorPuntuacion\n⏱️ $_tiempoRestante s',
                        style: TextStyle(fontSize: 14),
                        textAlign: TextAlign.right,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          body: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            child: Column(
              children: [
                LinearProgressIndicator(
                  value: (_currentIndex + 1) / _flashcards.length,
                  backgroundColor: Colors.teal.shade100,
                  color: Colors.teal.shade700,
                  minHeight: 8,
                ),
                const SizedBox(height: 24),
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
                    elevation: 5,
                  ),
                  child: const Text(
                    'Comprobar',
                    style: TextStyle(fontSize: 18),
                  ),
                ),
                const SizedBox(height: 24),
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
      ],
    );
  }
}

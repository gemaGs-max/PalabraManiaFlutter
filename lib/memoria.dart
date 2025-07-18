// ignore_for_file: use_build_context_synchronously
import 'package:flutter/material.dart';
import 'dart:math';
import 'package:palabramania/services/firestore_service.dart';
import 'package:confetti/confetti.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:firebase_auth/firebase_auth.dart';

class MemoriaPage extends StatefulWidget {
  @override
  _MemoriaPageState createState() => _MemoriaPageState();
}

// Página del juego de memoria con cartas que se giran y descubren
class _MemoriaPageState extends State<MemoriaPage> {
  List<_CartaMemoria> _cartas = [];
  List<int> _seleccionadas = [];
  bool _bloqueado = false;
  int _puntos = 0;
  int _mejorPuntuacion = 0;
  bool _modoNoche = false; // 🌙 Activar/desactivar modo oscuro

  final ConfettiController _confettiController = ConfettiController(
    duration: Duration(seconds: 2),
  );
  final AudioPlayer _player = AudioPlayer();
  // Controlador de confeti y reproductor de audio para efectos de sonido
  @override
  void initState() {
    super.initState();
    _generarCartas();
    _cargarMejorPuntuacion();
  }

  // Inicializa las cartas y carga la mejor puntuación del usuario
  void _cargarMejorPuntuacion() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid != null) {
      final doc = await getPuntuacion(uid, 'memoria');
      if (doc != null) {
        setState(() {
          _mejorPuntuacion = doc['puntos'] ?? 0;
        });
      }
    }
  }

  // Carga la mejor puntuación del usuario desde Firestore
  @override
  void dispose() {
    _confettiController.dispose();
    _player.dispose();
    super.dispose();
  }

  // Carga las cartas de memoria y la mejor puntuación del usuario
  void _generarCartas() {
    final pares = [
      {'es': '🏠', 'en': 'House'},
      {'es': '🐶', 'en': 'Dog'},
      {'es': '🍎', 'en': 'Apple'},
      {'es': '📖', 'en': 'Book'},
      {'es': '🏫', 'en': 'School'},
      {'es': '💻', 'en': 'Computer'},
    ];
    List<_CartaMemoria> todas = [];
    for (var par in pares) {
      todas.add(_CartaMemoria(texto: par['es']!, id: par['es']!));
      todas.add(_CartaMemoria(texto: par['en']!, id: par['es']!));
    }
    todas.shuffle(Random());
    setState(() {
      _cartas = todas;
      _puntos = 0;
    });
  }

  // Genera las cartas de memoria y las mezcla aleatoriamente
  void _seleccionarCarta(int index) async {
    if (_bloqueado || _cartas[index].descubierta || _cartas[index].girada)
      return;

    setState(() {
      _cartas[index].girada = true;
      _seleccionadas.add(index);
    });

    if (_seleccionadas.length == 2) {
      _bloqueado = true;
      int i1 = _seleccionadas[0];
      int i2 = _seleccionadas[1];
      bool esPar = _cartas[i1].id == _cartas[i2].id;

      setState(() {
        _cartas[i1].colorTemporal = esPar ? Colors.green : Colors.redAccent;
        _cartas[i2].colorTemporal = esPar ? Colors.green : Colors.redAccent;
      });

      final sonido = esPar ? 'correcto.mp3' : 'error.mp3';
      await _player.play(AssetSource('audios/$sonido'));

      Future.delayed(Duration(milliseconds: 700), () {
        setState(() {
          if (esPar) {
            _cartas[i1].descubierta = true;
            _cartas[i2].descubierta = true;
            _puntos++;
          } else {
            _cartas[i1].girada = false;
            _cartas[i2].girada = false;
          }
          _cartas[i1].colorTemporal = null;
          _cartas[i2].colorTemporal = null;
          _seleccionadas.clear();
          _bloqueado = false;
        });

        if (_cartas.every((c) => c.descubierta)) {
          guardarPuntuacion('memoria', _puntos);
          _confettiController.play();

          String? logro;
          if (_puntos == 4)
            logro = '🥉 ¡Primera memoria completa!';
          else if (_puntos == 5)
            logro = '🥈 ¡Buena memoria!';
          else if (_puntos == 6)
            logro = '🥇 ¡Memoria prodigiosa!';

          if (logro != null) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(logro),
                backgroundColor: const Color.fromARGB(255, 58, 177, 183),
              ),
            );
          }

          _mostrarDialogoFinal();
        }
      });
    }
  }

  // Selecciona una carta y maneja la lógica de emparejamiento
  void _mostrarDialogoFinal() {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            backgroundColor: _modoNoche ? Colors.grey[900] : null,
            title: Text(
              '🎉 ¡Has encontrado todas las parejas!',
              style: TextStyle(color: _modoNoche ? Colors.white : null),
            ),
            content: Text(
              'Tu puntuación: $_puntos',
              style: TextStyle(color: _modoNoche ? Colors.white70 : null),
            ),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop();
                  _generarCartas();
                },
                child: Text('🔁 Reintentar'),
              ),
              TextButton(
                onPressed:
                    () => Navigator.of(
                      context,
                    ).popUntil((route) => route.isFirst),
                child: Text('🏠 Volver al menú'),
              ),
            ],
          ),
    );
  }

  // Muestra un diálogo al finalizar el juego con la puntuación obtenida
  Widget _buildCarta(_CartaMemoria carta, int index) {
    return GestureDetector(
      onTap: () => _seleccionarCarta(index),
      child: AnimatedSwitcher(
        duration: Duration(milliseconds: 300),
        transitionBuilder:
            (child, anim) => RotationYTransition(turns: anim, child: child),
        child: Container(
          key: ValueKey(carta.girada || carta.descubierta),
          decoration: BoxDecoration(
            color:
                carta.colorTemporal ??
                (carta.girada || carta.descubierta
                    ? (_modoNoche ? Colors.grey[300] : Colors.white)
                    : (_modoNoche
                        ? Colors.deepPurple.shade900
                        : Colors.deepPurple)),
            borderRadius: BorderRadius.circular(10),
            boxShadow: [
              BoxShadow(
                color: Colors.black26,
                blurRadius: 4,
                offset: Offset(2, 2),
              ),
            ],
            border: Border.all(
              color: carta.descubierta ? Colors.green : Colors.transparent,
              width: 2,
            ),
          ),
          alignment: Alignment.center,
          child: AnimatedOpacity(
            duration: Duration(milliseconds: 200),
            opacity: carta.girada || carta.descubierta ? 1 : 0,
            child: Text(
              carta.texto,
              style: TextStyle(
                fontSize: MediaQuery.of(context).size.width > 600 ? 24 : 20,
                fontWeight: FontWeight.bold,
                color:
                    carta.descubierta
                        ? Colors.green.shade800
                        : (_modoNoche ? Colors.white : Colors.black),
              ),
            ),
          ),
        ),
      ),
    );
  }

  // Construye una carta de memoria con animación y efectos visuales
  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Scaffold(
          backgroundColor: _modoNoche ? Colors.black : Color(0xFFF3E5F5),
          appBar: AppBar(
            title: const Text(
              '🧩 Juego de Memoria',
              style: TextStyle(color: Colors.deepPurple),
            ),
            backgroundColor:
                _modoNoche ? Colors.black87 : const Color(0xFFE6E6FA),
            centerTitle: true,
            iconTheme: IconThemeData(
              color: _modoNoche ? Colors.white : Colors.deepPurple,
            ),
            actions: [
              IconButton(
                icon: Icon(
                  _modoNoche ? Icons.light_mode : Icons.dark_mode,
                  color: _modoNoche ? Colors.white : Colors.deepPurple,
                ),
                tooltip: 'Modo noche',
                onPressed: () {
                  setState(() {
                    _modoNoche = !_modoNoche;
                  });
                },
              ),
              Padding(
                padding: const EdgeInsets.all(12.0),
                child: Center(
                  child: Text(
                    '⭐ $_puntos | 🏆 $_mejorPuntuacion',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: _modoNoche ? Colors.white : Colors.deepPurple,
                    ),
                  ),
                ),
              ),
            ],
          ),

          body: Column(
            children: [
              SizedBox(height: 20),
              Expanded(
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    final width = constraints.maxWidth;
                    final crossAxisCount =
                        width > 1000
                            ? 6
                            : width > 600
                            ? 4
                            : 2;
                    return GridView.builder(
                      padding: EdgeInsets.all(16),
                      itemCount: _cartas.length,
                      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: crossAxisCount,
                        crossAxisSpacing: 10,
                        mainAxisSpacing: 10,
                        childAspectRatio: 1,
                      ),
                      itemBuilder:
                          (context, index) =>
                              _buildCarta(_cartas[index], index),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
        Align(
          alignment: Alignment.center,
          child: ConfettiWidget(
            confettiController: _confettiController,
            blastDirectionality: BlastDirectionality.explosive,
            colors: [Colors.purple, Colors.pink, Colors.amber],
            numberOfParticles: 20,
            gravity: 0.3,
          ),
        ),
      ],
    );
  }
}

class _CartaMemoria {
  final String texto;
  final String id;
  bool girada = false;
  bool descubierta = false;
  Color? colorTemporal;

  _CartaMemoria({required this.texto, required this.id});
}

class RotationYTransition extends StatelessWidget {
  final Animation<double> turns;
  final Widget child;

  const RotationYTransition({required this.turns, required this.child});

  @override
  Widget build(BuildContext context) {
    final double angle = turns.value * pi;
    final transform =
        Matrix4.identity()
          ..setEntry(3, 2, 0.001)
          ..rotateY(angle);
    return Transform(
      transform: transform,
      alignment: Alignment.center,
      child: child,
    );
  }
}

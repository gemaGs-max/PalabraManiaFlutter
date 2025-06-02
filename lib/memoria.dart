// Importación de paquetes necesarios
import 'package:flutter/material.dart';
import 'dart:math';
import 'package:palabramania/services/firestore_service.dart';
import 'package:confetti/confetti.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:firebase_auth/firebase_auth.dart';

// Pantalla principal del minijuego de memoria
class MemoriaPage extends StatefulWidget {
  @override
  _MemoriaPageState createState() => _MemoriaPageState();
}

class _MemoriaPageState extends State<MemoriaPage> {
  // Lista de cartas en el juego
  List<_CartaMemoria> _cartas = [];

  // Índices de las cartas seleccionadas temporalmente
  List<int> _seleccionadas = [];

  // Evita interacciones mientras se procesan dos cartas
  bool _bloqueado = false;

  // Puntos actuales y mejor puntuación registrada
  int _puntos = 0;
  int _mejorPuntuacion = 0;

  // Controlador para la animación de confeti
  final ConfettiController _confettiController = ConfettiController(
    duration: Duration(seconds: 2),
  );

  // Reproductor de audio para efectos de sonido
  final AudioPlayer _player = AudioPlayer();

  // Se ejecuta al iniciar la pantalla
  @override
  void initState() {
    super.initState();
    _generarCartas();
    _cargarMejorPuntuacion();
  }

  // Carga la mejor puntuación del usuario desde Firestore
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

  // Libera recursos al cerrar la pantalla
  @override
  void dispose() {
    _confettiController.dispose();
    _player.dispose();
    super.dispose();
  }

  // Genera las cartas del juego con pares de emojis y palabras
  void _generarCartas() {
    final pares = [
      {'es': '🏠', 'en': 'House'},
      {'es': '🐶', 'en': 'Dog'},
      {'es': '🍎', 'en': 'Apple'},
      {'es': '📖', 'en': 'Book'},
    ];

    List<_CartaMemoria> todas = [];

    for (var par in pares) {
      todas.add(_CartaMemoria(texto: par['es']!, id: par['es']!));
      todas.add(_CartaMemoria(texto: par['en']!, id: par['es']!));
    }

    // Mezcla aleatoria
    todas.shuffle(Random());

    setState(() {
      _cartas = todas;
      _puntos = 0;
    });
  }

  // Lógica de selección de carta
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

      // Sonido de acierto o fallo
      final sonido = esPar ? 'correcto.mp3' : 'error.mp3';
      await _player.play(AssetSource('audios/$sonido'));

      // Espera antes de mostrar resultado
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

        // Si se han descubierto todas, mostrar confeti y guardar puntuación
        if (_cartas.every((c) => c.descubierta)) {
          guardarPuntuacion('memoria', _puntos);
          _confettiController.play();

          // Mostrar logro según puntos
          String? logro;
          if (_puntos == 4) {
            logro = '🥉 ¡Primera memoria completa!';
          } else if (_puntos == 5) {
            logro = '🥈 ¡Buena memoria!';
          } else if (_puntos == 6) {
            logro = '🥇 ¡Memoria prodigiosa!';
          }

          if (logro != null) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(logro),
                backgroundColor: Colors.deepPurple,
              ),
            );
          }

          _mostrarDialogoFinal();
        }
      });
    }
  }

  // Muestra un diálogo al finalizar el juego
  void _mostrarDialogoFinal() {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: Text('🎉 ¡Has encontrado todas las parejas!'),
            content: Text('Tu puntuación: $_puntos'),
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
                child: Text('🏠 Salir'),
              ),
            ],
          ),
    );
  }

  // Construye visualmente una carta
  Widget _buildCarta(_CartaMemoria carta, int index) {
    return GestureDetector(
      onTap: () => _seleccionarCarta(index),
      child: AnimatedSwitcher(
        duration: Duration(milliseconds: 400),
        transitionBuilder:
            (child, animation) =>
                RotationYTransition(turns: animation, child: child),
        child: Container(
          key: ValueKey(carta.girada || carta.descubierta),
          decoration: BoxDecoration(
            color:
                carta.colorTemporal ??
                (carta.descubierta || carta.girada
                    ? Colors.white
                    : Colors.deepPurple.shade400),
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.black26,
                blurRadius: 6,
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
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color:
                    carta.descubierta ? Colors.green.shade800 : Colors.black87,
              ),
            ),
          ),
        ),
      ),
    );
  }

  // Construcción general de la pantalla del juego
  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Scaffold(
          backgroundColor: Color(0xFFF3E5F5),
          appBar: AppBar(
            title: Text('🧩 Juego de Memoria'),
            backgroundColor: Colors.purple.shade700,
            centerTitle: true,
            actions: [
              Padding(
                padding: const EdgeInsets.all(12.0),
                child: Center(
                  child: Text(
                    '⭐ $_puntos | 🏆 $_mejorPuntuacion',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                ),
              ),
            ],
          ),
          body: Column(
            children: [
              const SizedBox(height: 20),
              Expanded(
                child: GridView.builder(
                  padding: EdgeInsets.all(16),
                  itemCount: _cartas.length,
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 4,
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                  ),
                  itemBuilder:
                      (context, index) => _buildCarta(_cartas[index], index),
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
            colors: const [Colors.purple, Colors.pink, Colors.amber],
            numberOfParticles: 20,
            gravity: 0.3,
            shouldLoop: false,
          ),
        ),
      ],
    );
  }
}

// Clase para representar cada carta del juego de memoria
class _CartaMemoria {
  final String texto;
  final String id;
  bool girada = false;
  bool descubierta = false;
  Color? colorTemporal;

  _CartaMemoria({required this.texto, required this.id});
}

// Transición personalizada para girar las cartas en Y
class RotationYTransition extends StatelessWidget {
  final Animation<double> turns;
  final Widget child;

  const RotationYTransition({required this.turns, required this.child});

  @override
  Widget build(BuildContext context) {
    final double angle = turns.value * pi;
    return Transform(
      transform: Matrix4.rotationY(angle),
      alignment: Alignment.center,
      child: child,
    );
  }
}

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:palabramania/services/firestore_service.dart';
import 'dart:math';

class RetoDelMonoPage extends StatefulWidget {
  const RetoDelMonoPage({super.key});

  @override
  State<RetoDelMonoPage> createState() => _RetoDelMonoPageState();
}

class _RetoDelMonoPageState extends State<RetoDelMonoPage> {
  // Lista completa de preguntas
  final List<Map<String, dynamic>> _preguntas = [
    {
      'pregunta': 'What is the capital of France?',
      'opciones': ['London', 'Madrid', 'Paris'],
      'respuesta': 'Paris',
    },
    {
      'pregunta': 'Which animal says "meow"?',
      'opciones': ['Dog', 'Cat', 'Bird'],
      'respuesta': 'Cat',
    },
    {
      'pregunta': 'How many colors are there in a rainbow?',
      'opciones': ['5', '7', '9'],
      'respuesta': '7',
    },
    {
      'pregunta': 'Which planet is known as the Red Planet?',
      'opciones': ['Mars', 'Venus', 'Saturn'],
      'respuesta': 'Mars',
    },
    {
      'pregunta': 'What is the most spoken language in the world?',
      'opciones': ['Spanish', 'English', 'Chinese'],
      'respuesta': 'Chinese',
    },
  ];

  late List<Map<String, dynamic>> _preguntasSeleccionadas;
  int _preguntaActual = 0;
  int _puntuacion = 0;
  int _mejorPuntuacion = 0;
  String _fraseMono = 'Hello! Ready for the challenge?';
  bool _mostrarBoton = false;

  final List<String> _frasesExito = [
    'You are amazing!',
    'Great job!',
    'Correct! Awesome!',
    'Well done!',
  ];

  final List<String> _frasesFallo = [
    'Oops! Not that one...',
    'Almost there!',
    'No worries, try the next one!',
    'Try again :)',
  ];

  @override
  void initState() {
    super.initState();
    _preguntasSeleccionadas = _obtenerPreguntasAleatorias(3);
    _cargarMejorPuntuacion();
  }

  // Obtener mejor puntuación del usuario en este minijuego
  Future<void> _cargarMejorPuntuacion() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final datos = await getPuntuacion(user.uid, 'retoMono');
    setState(() {
      _mejorPuntuacion = datos?['puntos'] ?? 0;
    });
  }

  // Elegir preguntas aleatorias
  List<Map<String, dynamic>> _obtenerPreguntasAleatorias(int cantidad) {
    final copia = List<Map<String, dynamic>>.from(_preguntas);
    copia.shuffle();
    return copia.take(cantidad).toList();
  }

  // Verificar respuesta seleccionada
  void _responder(String seleccionada) {
    final pregunta = _preguntasSeleccionadas[_preguntaActual];
    final esCorrecta = seleccionada == pregunta['respuesta'];

    setState(() {
      if (esCorrecta) {
        _puntuacion++;
        _fraseMono = _frasesExito[Random().nextInt(_frasesExito.length)];
      } else {
        _fraseMono = _frasesFallo[Random().nextInt(_frasesFallo.length)];
      }

      // Pasar a siguiente pregunta o terminar
      if (_preguntaActual < _preguntasSeleccionadas.length - 1) {
        _preguntaActual++;
      } else {
        _mostrarBoton = true;
        guardarPuntuacion(
          'retoMono',
          _puntuacion,
        ); // ✅ guardar en Firestore con lógica adaptada
      }
    });
  }

  // Reiniciar minijuego
  void _reiniciarJuego() {
    setState(() {
      _preguntasSeleccionadas = _obtenerPreguntasAleatorias(3);
      _preguntaActual = 0;
      _puntuacion = 0;
      _fraseMono = 'Hello! Ready for the challenge?';
      _mostrarBoton = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final pregunta = _preguntasSeleccionadas[_preguntaActual];

    return Scaffold(
      appBar: AppBar(
        title: const Text('🐒 Monkey Challenge'),
        backgroundColor: Colors.orange,
      ),
      backgroundColor: Colors.yellow[50],
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Image.asset('assets/images/mono.png', height: 120),
            const SizedBox(height: 12),

            // Frase animada del personaje
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 500),
              child: Text(
                _fraseMono,
                key: ValueKey(_fraseMono),
                style: const TextStyle(
                  fontSize: 16,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ),

            const SizedBox(height: 20),
            Text(
              'Best score: $_mejorPuntuacion',
              style: const TextStyle(fontSize: 14),
            ),

            const SizedBox(height: 10),
            Text(
              pregunta['pregunta'],
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),

            const SizedBox(height: 20),

            // Opciones
            ...List.generate(pregunta['opciones'].length, (index) {
              final opcion = pregunta['opciones'][index];
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 6),
                child: ElevatedButton(
                  onPressed: _mostrarBoton ? null : () => _responder(opcion),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.lightBlueAccent,
                    minimumSize: const Size(double.infinity, 48),
                  ),
                  child: Text(opcion, style: const TextStyle(fontSize: 16)),
                ),
              );
            }),

            if (_mostrarBoton) ...[
              const SizedBox(height: 20),
              Text('Score: $_puntuacion / ${_preguntasSeleccionadas.length}'),
              const SizedBox(height: 10),
              ElevatedButton(
                onPressed: _reiniciarJuego,
                child: const Text('Try again?'),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

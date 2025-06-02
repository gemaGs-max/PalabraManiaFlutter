import 'package:flutter/material.dart';
import 'package:palabramania/services/firestore_service.dart';
import 'dart:math';

class RetoDelMonoPage extends StatefulWidget {
  const RetoDelMonoPage({super.key});

  @override
  State<RetoDelMonoPage> createState() => _RetoDelMonoPageState();
}

class _RetoDelMonoPageState extends State<RetoDelMonoPage> {
  // Lista de preguntas en inglés con sus opciones y la respuesta correcta
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

  // Lista que se llenará con preguntas aleatorias
  late List<Map<String, dynamic>> _preguntasSeleccionadas;

  int _preguntaActual = 0; // Índice de la pregunta actual
  int _puntuacion = 0; // Puntos del jugador
  String _fraseMono = 'Hi! Ready for the challenge?'; // Frase inicial del mono
  bool _mostrarBoton = false; // Si se debe mostrar el botón de reinicio

  // Frases que el mono dice cuando el usuario acierta
  final List<String> _frasesExito = [
    'Great job!',
    'Awesome!',
    'Correct! You rock!',
    'Well done!',
  ];

  // Frases que el mono dice cuando el usuario falla
  final List<String> _frasesFallo = [
    'Oops! That was not correct.',
    'Almost!',
    'Don’t worry, try the next one!',
    'Keep going :)',
  ];

  @override
  void initState() {
    super.initState();
    // Al iniciar, seleccionamos 3 preguntas aleatorias
    _preguntasSeleccionadas = _obtenerPreguntasAleatorias(3);
  }

  // Función para mezclar y obtener una lista limitada de preguntas
  List<Map<String, dynamic>> _obtenerPreguntasAleatorias(int cantidad) {
    final random = Random();
    final preguntasCopia = List<Map<String, dynamic>>.from(_preguntas);
    preguntasCopia.shuffle(random); // Mezclar el orden
    return preguntasCopia
        .take(cantidad)
        .toList(); // Tomar las primeras 'cantidad'
  }

  // Lógica para cuando el usuario responde
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

      if (_preguntaActual < _preguntasSeleccionadas.length - 1) {
        _preguntaActual++; // Pasar a la siguiente pregunta
      } else {
        _mostrarBoton = true; // Juego finalizado
        guardarPuntuacion(
          'retoMono',
          _puntuacion,
        ); // Guardar puntuación en Firestore
      }
    });
  }

  // Reinicia el juego desde cero
  void _reiniciarJuego() {
    setState(() {
      _preguntasSeleccionadas = _obtenerPreguntasAleatorias(3);
      _preguntaActual = 0;
      _puntuacion = 0;
      _fraseMono = 'Hi! Ready for the challenge?';
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
            // Imagen del mono
            Image.asset('assets/images/mono.png', height: 120),

            const SizedBox(height: 12),

            // Frase que dice el mono
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

            // Pregunta actual
            Text(
              pregunta['pregunta'],
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),

            const SizedBox(height: 20),

            // Opciones de respuesta
            ...List.generate(pregunta['opciones'].length, (index) {
              final opcion = pregunta['opciones'][index];
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 6),
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.lightBlueAccent,
                    minimumSize: const Size(double.infinity, 48),
                  ),
                  onPressed: _mostrarBoton ? null : () => _responder(opcion),
                  child: Text(opcion, style: const TextStyle(fontSize: 16)),
                ),
              );
            }),

            // Si ya ha terminado el juego, mostramos la puntuación final
            if (_mostrarBoton) ...[
              const SizedBox(height: 20),
              Text('Score: $_puntuacion / ${_preguntasSeleccionadas.length}'),
              const SizedBox(height: 10),
              ElevatedButton(
                onPressed: _reiniciarJuego,
                child: const Text('Play again?'),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

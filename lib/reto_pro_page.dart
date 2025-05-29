import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'dart:math';
import 'package:palabramania/services/firestore_service.dart'; // Asegúrate de tener esta función

class RetoProPage extends StatefulWidget {
  const RetoProPage({super.key});

  @override
  State<RetoProPage> createState() => _RetoProPageState();
}

class _RetoProPageState extends State<RetoProPage> {
  // Lista de preguntas tipo test
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
  String _fraseMono = '¡Hola! ¿Preparado para el reto?';
  bool _mostrarBoton = false;

  final List<String> _frasesExito = [
    '¡Eres genial!',
    '¡Muy bien hecho!',
    '¡Correcto!',
    '¡Sigue así!',
  ];

  final List<String> _frasesFallo = [
    '¡Ups! Esa no era...',
    '¡Casi!',
    '¡Inténtalo de nuevo!',
    '¡No pasa nada!',
  ];

  @override
  void initState() {
    super.initState();
    _preguntasSeleccionadas = _obtenerPreguntasAleatorias(3);
    _cargarMejorPuntuacion();
  }

  // Cargar la mejor puntuación desde Firestore
  Future<void> _cargarMejorPuntuacion() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final datos = await getPuntuacion(user.uid, 'retoPro');
    setState(() {
      _mejorPuntuacion = datos?['puntos'] ?? 0;
    });
  }

  // Seleccionar preguntas aleatorias del total
  List<Map<String, dynamic>> _obtenerPreguntasAleatorias(int cantidad) {
    final copia = List<Map<String, dynamic>>.from(_preguntas);
    copia.shuffle();
    return copia.take(cantidad).toList();
  }

  // Procesar la respuesta elegida
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
        _preguntaActual++;
      } else {
        _mostrarBoton = true;
        guardarPuntuacion('retoPro', _puntuacion);
      }
    });
  }

  // Reiniciar el juego
  void _reiniciarJuego() {
    setState(() {
      _preguntasSeleccionadas = _obtenerPreguntasAleatorias(3);
      _preguntaActual = 0;
      _puntuacion = 0;
      _fraseMono = '¡Hola! ¿Preparado para el reto?';
      _mostrarBoton = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final pregunta = _preguntasSeleccionadas[_preguntaActual];

    return Scaffold(
      appBar: AppBar(
        title: const Text('🐒 Reto Pro'),
        backgroundColor: const Color.fromARGB(255, 14, 239, 93),
      ),
      backgroundColor: Colors.deepPurple[50],
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Image.asset('assets/images/mono.png', height: 100),
            const SizedBox(height: 10),

            // Frase que dice el personaje animado
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 400),
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
              '🧠 Mejor puntuación: $_mejorPuntuacion',
              style: const TextStyle(fontSize: 14),
            ),

            const SizedBox(height: 10),
            Text(
              pregunta['pregunta'],
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),

            const SizedBox(height: 20),

            // Botones de opciones
            ...List.generate(pregunta['opciones'].length, (index) {
              final opcion = pregunta['opciones'][index];
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 6),
                child: ElevatedButton(
                  onPressed: _mostrarBoton ? null : () => _responder(opcion),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.indigoAccent,
                    minimumSize: const Size(double.infinity, 48),
                  ),
                  child: Text(opcion, style: const TextStyle(fontSize: 16)),
                ),
              );
            }),

            if (_mostrarBoton) ...[
              const SizedBox(height: 20),
              Text(
                '🏅 Puntuación: $_puntuacion / ${_preguntasSeleccionadas.length}',
              ),
              const SizedBox(height: 10),
              ElevatedButton(
                onPressed: _reiniciarJuego,
                child: const Text('¿Intentar de nuevo?'),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

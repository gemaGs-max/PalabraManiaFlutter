import 'package:flutter/material.dart';
import 'package:palabramania/services/firestore_service.dart';
import 'dart:math';

class RetoDelMonoPage extends StatefulWidget {
  const RetoDelMonoPage({super.key});

  @override
  State<RetoDelMonoPage> createState() => _RetoDelMonoPageState();
}

class _RetoDelMonoPageState extends State<RetoDelMonoPage> {
  final List<Map<String, dynamic>> _preguntas = [
    {
      'pregunta': '¿Cuál es la capital de Francia?',
      'opciones': ['Londres', 'Madrid', 'París'],
      'respuesta': 'París',
    },
    {
      'pregunta': '¿Qué animal hace "miau"?',
      'opciones': ['Perro', 'Gato', 'Pájaro'],
      'respuesta': 'Gato',
    },
    {
      'pregunta': '¿Cuántos colores tiene el arcoíris?',
      'opciones': ['5', '7', '9'],
      'respuesta': '7',
    },
    {
      'pregunta': '¿Qué planeta es conocido como el planeta rojo?',
      'opciones': ['Marte', 'Venus', 'Saturno'],
      'respuesta': 'Marte',
    },
    {
      'pregunta': '¿Cuál es el idioma más hablado del mundo?',
      'opciones': ['Español', 'Inglés', 'Chino'],
      'respuesta': 'Chino',
    },
  ];

  late List<Map<String, dynamic>> _preguntasSeleccionadas;
  int _preguntaActual = 0;
  int _puntuacion = 0;
  String _fraseMono = '¡Hola! ¿Preparada para el reto?';
  bool _mostrarBoton = false;

  final List<String> _frasesExito = [
    '¡Eres increíble!',
    '¡Muy bien hecho!',
    '¡Acertaste, crack!',
    '¡Así se hace!',
  ];

  final List<String> _frasesFallo = [
    '¡Uy! No era esa...',
    '¡Casi, casi!',
    'No pasa nada, ¡vamos a por la siguiente!',
    'Inténtalo otra vez :)',
  ];

  @override
  void initState() {
    super.initState();
    _preguntasSeleccionadas = _obtenerPreguntasAleatorias(3);
  }

  List<Map<String, dynamic>> _obtenerPreguntasAleatorias(int cantidad) {
    final random = Random();
    final preguntasCopia = List<Map<String, dynamic>>.from(_preguntas);
    preguntasCopia.shuffle(random);
    return preguntasCopia.take(cantidad).toList();
  }

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
        guardarPuntuacion('retoMono', _puntuacion);
      }
    });
  }

  void _reiniciarJuego() {
    setState(() {
      _preguntasSeleccionadas = _obtenerPreguntasAleatorias(3);
      _preguntaActual = 0;
      _puntuacion = 0;
      _fraseMono = '¡Hola! ¿Preparada para el reto?';
      _mostrarBoton = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final pregunta = _preguntasSeleccionadas[_preguntaActual];

    return Scaffold(
      appBar: AppBar(
        title: const Text('🐒 Reto del Mono'),
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
              pregunta['pregunta'],
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
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
            if (_mostrarBoton) ...[
              const SizedBox(height: 20),
              Text(
                'Puntuación: $_puntuacion / ${_preguntasSeleccionadas.length}',
              ),
              const SizedBox(height: 10),
              ElevatedButton(
                onPressed: _reiniciarJuego,
                child: const Text('¿Quieres intentarlo de nuevo?'),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

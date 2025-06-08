import 'package:flutter/material.dart';
import 'package:palabramania/services/firestore_service.dart';
import 'dart:math';

class RetoDelMonoPage extends StatefulWidget {
  const RetoDelMonoPage({super.key});

  @override
  State<RetoDelMonoPage> createState() => _RetoDelMonoPageState();
}

class _RetoDelMonoPageState extends State<RetoDelMonoPage> {
  // Preguntas sobre inglés básico: vocabulario y comprensión
  final List<Map<String, dynamic>> _preguntas = [
    {
      'pregunta': 'What is the meaning of "apple"?',
      'opciones': ['Manzana', 'Pera', 'Banana'],
      'respuesta': 'Manzana',
    },
    {
      'pregunta': 'Choose the correct translation: "I am a student."',
      'opciones': [
        'Yo soy un estudiante',
        'Tú eres un profesor',
        'Ella es una doctora',
      ],
      'respuesta': 'Yo soy un estudiante',
    },
    {
      'pregunta': 'What is the opposite of "hot"?',
      'opciones': ['Warm', 'Cold', 'Dark'],
      'respuesta': 'Cold',
    },
    {
      'pregunta': 'What does "Good night" mean?',
      'opciones': ['Buenos días', 'Buenas noches', 'Buenas tardes'],
      'respuesta': 'Buenas noches',
    },
    {
      'pregunta': 'Translate: "Blue, green, red"',
      'opciones': [
        'Rojo, amarillo, rosa',
        'Azul, verde, rojo',
        'Marrón, gris, negro',
      ],
      'respuesta': 'Azul, verde, rojo',
    },
  ];

  late List<Map<String, dynamic>> _preguntasSeleccionadas;
  int _preguntaActual = 0;
  int _puntuacion = 0;
  String _fraseMono = '🐵 ¡Hola! ¿Preparada para el reto en inglés?';
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
    _preguntasSeleccionadas = _obtenerPreguntasAleatorias(
      3,
    ); // Selecciona 3 aleatorias
  }

  // Baraja las preguntas y escoge una cantidad
  List<Map<String, dynamic>> _obtenerPreguntasAleatorias(int cantidad) {
    final random = Random();
    final preguntasCopia = List<Map<String, dynamic>>.from(_preguntas);
    preguntasCopia.shuffle(random);
    return preguntasCopia.take(cantidad).toList();
  }

  // Valida la respuesta seleccionada
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
        guardarPuntuacion('retoMono', _puntuacion); // Guarda en Firestore
      }
    });
  }

  // Reinicia todo el juego
  void _reiniciarJuego() {
    setState(() {
      _preguntasSeleccionadas = _obtenerPreguntasAleatorias(3);
      _preguntaActual = 0;
      _puntuacion = 0;
      _fraseMono = '🐵 ¡Hola! ¿Preparada para el reto en inglés?';
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
            Image.asset(
              'assets/images/mono.png',
              height: 120,
            ), // Imagen del mono
            const SizedBox(height: 12),
            // Frase del mono animada
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
            // Opciones
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

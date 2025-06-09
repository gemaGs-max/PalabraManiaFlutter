import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:confetti/confetti.dart';
import 'dart:math';

class TraduccionTecnicaPage extends StatefulWidget {
  const TraduccionTecnicaPage({super.key});
  // Esta página es un juego de traducción técnica de términos informáticos
  @override
  State<TraduccionTecnicaPage> createState() => _TraduccionTecnicaPageState();
}

class _TraduccionTecnicaPageState extends State<TraduccionTecnicaPage> {
  final List<Map<String, dynamic>> _preguntas = [
    {
      'es': '¿Cómo se traduce "bucle" al inglés?',
      'opciones': ['loop', 'bug', 'array'],
      'respuesta': 'loop',
    },
    {
      'es': '¿Qué significa "debug"?',
      'opciones': ['Depurar', 'Compilar', 'Ejecutar'],
      'respuesta': 'Depurar',
    },
    {
      'es': 'Traducción de "variable"',
      'opciones': ['function', 'loop', 'variable'],
      'respuesta': 'variable',
    },
    {
      'es': '¿Qué es un "array"?',
      'opciones': ['Arreglo', 'Archivo', 'Error'],
      'respuesta': 'Arreglo',
    },
    {
      'es': '¿Cómo se dice "interfaz" en inglés?',
      'opciones': ['interface', 'internship', 'internet'],
      'respuesta': 'interface',
    },
  ];
  // Variables del juego
  int _indice = 0;
  int _puntos = 0;
  String _mensajeMono = '';
  final AudioPlayer _player = AudioPlayer();
  final ConfettiController _confettiController = ConfettiController(
    duration: const Duration(seconds: 2),
  );

  // Función para verificar la respuesta
  void _verificarRespuesta(String seleccion) {
    final correcta = _preguntas[_indice]['respuesta'];
    final esCorrecta = seleccion == correcta;

    if (esCorrecta) {
      _player.play(AssetSource('audios/correcto.mp3'));
      _mensajeMono = '¡Bien hecho! 😃';
      _puntos++;
    } else {
      _player.play(AssetSource('audios/error.mp3'));
      _mensajeMono = '¡Oh no! Era "$correcta" 😅';
    }

    setState(() {});

    Future.delayed(const Duration(seconds: 2), () {
      if (_indice < _preguntas.length - 1) {
        setState(() {
          _indice++;
          _mensajeMono = '';
        });
      } else {
        _confettiController.play();
        _guardarPuntuacion();
        _mostrarDialogoFinal();
      }
    });
  }

  // Guardar la mejor puntuación del usuario en Firestore
  Future<void> _guardarPuntuacion() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;

    final docRef = FirebaseFirestore.instance
        .collection('puntuaciones')
        .doc(uid)
        .collection('traduccion_tecnica')
        .doc('mejor');

    final doc = await docRef.get();

    if (!doc.exists || (_puntos > (doc['mejorPuntuacion'] ?? 0))) {
      await docRef.set({'mejorPuntuacion': _puntos, 'fecha': DateTime.now()});
    }

    // Guardar total acumulado
    final userRef = FirebaseFirestore.instance.collection('usuarios').doc(uid);

    await FirebaseFirestore.instance.runTransaction((transaction) async {
      final snapshot = await transaction.get(userRef);
      final actual = snapshot.data()?['puntosTotales'] ?? 0;
      transaction.update(userRef, {'puntosTotales': actual + _puntos});
    });
  }

  // Mostrar mensaje al terminar todas las preguntas
  void _mostrarDialogoFinal() {
    showDialog(
      context: context,
      builder:
          (_) => AlertDialog(
            title: const Text('¡Juego completado!'),
            content: Text(
              'Has conseguido $_puntos puntos. ¿Qué quieres hacer?',
            ),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.pop(context);
                  Navigator.pop(context);
                },
                child: const Text('Volver al menú'),
              ),
              TextButton(
                onPressed: () {
                  Navigator.pop(context);
                  setState(() {
                    _indice = 0;
                    _puntos = 0;
                    _mensajeMono = '';
                  });
                },
                child: const Text('Reintentar'),
              ),
            ],
          ),
    );
  }

  @override
  void dispose() {
    _player.dispose();
    _confettiController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final pregunta = _preguntas[_indice];

    return Scaffold(
      appBar: AppBar(title: const Text('Traducción Técnica 🧠')),
      body: Stack(
        children: [
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  'Puntuación: $_puntos',
                  style: const TextStyle(fontSize: 20),
                ),
                const SizedBox(height: 20),
                Text(
                  pregunta['es'],
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 20),
                ...pregunta['opciones'].map<Widget>((opcion) {
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4.0),
                    child: ElevatedButton(
                      onPressed: () => _verificarRespuesta(opcion),
                      child: Text(opcion),
                    ),
                  );
                }).toList(),
                const SizedBox(height: 20),
                Text(
                  _mensajeMono,
                  style: const TextStyle(fontSize: 18, color: Colors.purple),
                ),
              ],
            ),
          ),
          Align(
            alignment: Alignment.topCenter,
            child: ConfettiWidget(
              confettiController: _confettiController,
              blastDirection: pi / 2,
              maxBlastForce: 20,
              minBlastForce: 10,
              numberOfParticles: 20,
              gravity: 0.2,
            ),
          ),
        ],
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class RetoProPage extends StatefulWidget {
  const RetoProPage({super.key});

  @override
  State<RetoProPage> createState() => _RetoProPageState();
}

class _RetoProPageState extends State<RetoProPage> {
  final List<Map<String, dynamic>> _retos = [
    {
      'tipo': 'trivia',
      'pregunta': 'What does "break a leg" mean?',
      'opciones': ['Good luck', 'Break your leg', 'Run'],
      'respuesta': 'Good luck',
    },
    {
      'tipo': 'ordenar',
      'palabras': ['How', 'are', 'you'],
      'correcta': 'How are you',
    },
    {
      'tipo': 'completar',
      'frase': 'I ___ to the store yesterday.',
      'opciones': ['go', 'went', 'gone'],
      'respuesta': 'went',
    },
  ];

  int _indice = 0;
  int _puntuacion = 0;
  bool _respondido = false;
  List<String> _ordenSeleccionada = [];

  void _verificarTrivia(String seleccion) {
    if (_respondido) return;
    setState(() {
      _respondido = true;
      if (seleccion == _retos[_indice]['respuesta']) _puntuacion++;
    });
    Future.delayed(const Duration(seconds: 1), _siguiente);
  }

  void _verificarCompletar(String seleccion) {
    if (_respondido) return;
    setState(() {
      _respondido = true;
      if (seleccion == _retos[_indice]['respuesta']) _puntuacion++;
    });
    Future.delayed(const Duration(seconds: 1), _siguiente);
  }

  void _verificarOrdenar() {
    if (_respondido) return;
    setState(() {
      _respondido = true;
      if (_ordenSeleccionada.join(' ') == _retos[_indice]['correcta'])
        _puntuacion++;
    });
    Future.delayed(const Duration(seconds: 1), _siguiente);
  }

  void _siguiente() {
    if (_indice < _retos.length - 1) {
      setState(() {
        _indice++;
        _respondido = false;
        _ordenSeleccionada = [];
      });
    } else {
      _guardarPuntuacion();
      _mostrarResultado();
    }
  }

  Future<void> _guardarPuntuacion() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final docRef = FirebaseFirestore.instance
        .collection('puntuaciones')
        .doc(user.uid);

    final doc = await docRef.get();
    final mejorAnterior =
        doc.exists && doc.data()!.containsKey('retoPro')
            ? doc['retoPro'] as int
            : 0;

    if (_puntuacion > mejorAnterior) {
      await docRef.set({'retoPro': _puntuacion}, SetOptions(merge: true));
    }
  }

  void _mostrarResultado() {
    showDialog(
      context: context,
      builder:
          (_) => AlertDialog(
            title: const Text('🎉 Game Completed!'),
            content: Text('Your score: $_puntuacion / ${_retos.length}'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Exit'),
              ),
              TextButton(
                onPressed: () {
                  setState(() {
                    _indice = 0;
                    _puntuacion = 0;
                    _respondido = false;
                    _ordenSeleccionada = [];
                  });
                  Navigator.pop(context);
                },
                child: const Text('Try Again'),
              ),
            ],
          ),
    );
  }

  Widget _construirTrivia(Map<String, dynamic> reto) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(reto['pregunta'], style: const TextStyle(fontSize: 20)),
        const SizedBox(height: 20),
        ...reto['opciones'].map<Widget>((texto) {
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 4.0),
            child: MouseRegion(
              cursor: SystemMouseCursors.click,
              child: ElevatedButton(
                onPressed: () => _verificarTrivia(texto),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blueAccent,
                  foregroundColor: Colors.white,
                  elevation: 3,
                ),
                child: Text(texto),
              ),
            ),
          );
        }).toList(),
      ],
    );
  }

  Widget _construirCompletar(Map<String, dynamic> reto) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(reto['frase'], style: const TextStyle(fontSize: 20)),
        const SizedBox(height: 20),
        ...reto['opciones'].map<Widget>((texto) {
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 4.0),
            child: MouseRegion(
              cursor: SystemMouseCursors.click,
              child: ElevatedButton(
                onPressed: () => _verificarCompletar(texto),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.teal,
                  foregroundColor: Colors.white,
                  elevation: 3,
                ),
                child: Text(texto),
              ),
            ),
          );
        }).toList(),
      ],
    );
  }

  Widget _construirOrdenar(Map<String, dynamic> reto) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Put the words in the correct order:',
          style: TextStyle(fontSize: 18),
        ),
        const SizedBox(height: 10),
        Wrap(
          spacing: 10,
          children:
              reto['palabras'].map<Widget>((palabra) {
                final yaUsada = _ordenSeleccionada.contains(palabra);
                return MouseRegion(
                  cursor:
                      yaUsada
                          ? SystemMouseCursors.forbidden
                          : SystemMouseCursors.click,
                  child: ElevatedButton(
                    onPressed:
                        yaUsada
                            ? null
                            : () {
                              setState(() {
                                _ordenSeleccionada.add(palabra);
                              });
                            },
                    style: ElevatedButton.styleFrom(
                      backgroundColor:
                          yaUsada ? Colors.grey : Colors.deepPurple,
                      foregroundColor: Colors.white,
                      elevation: 3,
                    ),
                    child: Text(palabra),
                  ),
                );
              }).toList(),
        ),
        const SizedBox(height: 20),
        Text('Your sentence: ${_ordenSeleccionada.join(' ')}'),
        const SizedBox(height: 10),
        ElevatedButton(
          onPressed: _verificarOrdenar,
          child: const Text('Check'),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final reto = _retos[_indice];

    return Scaffold(
      appBar: AppBar(title: const Text('🧠 Pro Challenge')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Challenge ${_indice + 1} of ${_retos.length}',
                style: const TextStyle(fontSize: 16),
              ),
              const SizedBox(height: 20),
              if (reto['tipo'] == 'trivia') _construirTrivia(reto),
              if (reto['tipo'] == 'completar') _construirCompletar(reto),
              if (reto['tipo'] == 'ordenar') _construirOrdenar(reto),
            ],
          ),
        ),
      ),
    );
  }
}

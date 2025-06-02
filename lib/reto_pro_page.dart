// Importa los widgets de Flutter para construir la interfaz visual
import 'package:flutter/material.dart';

// Importa Firebase Firestore para guardar puntuaciones
import 'package:cloud_firestore/cloud_firestore.dart';

// Importa Firebase Auth para acceder al usuario autenticado
import 'package:firebase_auth/firebase_auth.dart';

// Pantalla principal del minijuego "Reto Pro"
class RetoProPage extends StatefulWidget {
  const RetoProPage({super.key});

  @override
  State<RetoProPage> createState() => _RetoProPageState();
}

class _RetoProPageState extends State<RetoProPage> {
  // Lista de escenarios con distintos tipos de retos
  final List<Map<String, dynamic>> _escenarios = [
    {
      'tipo': 'completar',
      'narrativa': '🔍 Encuentras una nota en la mesa que dice:',
      'frase': 'I ___ in London last summer.',
      'opciones': ['go', 'gone', 'was', 'was living'],
      'respuesta': 'was living',
    },
    {
      'tipo': 'ordenar',
      'narrativa': '🔐 El candado tiene un mensaje desordenado:',
      'palabras': ['you', 'can', 'open', 'the', 'door'],
      'correcta': 'you can open the door',
    },
    {
      'tipo': 'trivia',
      'narrativa': '📱 El móvil se enciende y muestra una pregunta:',
      'pregunta': 'What does "Break a leg" mean?',
      'opciones': ['Break your leg', 'Run fast', 'Good luck'],
      'respuesta': 'Good luck',
    },
    {
      'tipo': 'trivia',
      'narrativa':
          '✈️ Encuentras una pegatina con un avión. ¿Qué palabra la representa mejor?',
      'pregunta': 'Choose the best word:',
      'opciones': ['eat', 'fly', 'run'],
      'respuesta': 'fly',
    },
  ];

  int _indice = 0; // índice del escenario actual
  int _puntos = 0; // puntuación del jugador
  bool _respondido = false; // indica si el usuario ya respondió
  List<String> _ordenSeleccionada =
      []; // palabras seleccionadas en el reto de ordenar

  // Verifica si la respuesta seleccionada es correcta
  void _verificarRespuesta(String seleccion) {
    if (_respondido) return;
    final escenario = _escenarios[_indice];
    final acierto = seleccion == escenario['respuesta'];

    setState(() {
      _respondido = true;
      if (acierto) _puntos++;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(acierto ? '✅ ¡Correcto!' : '❌ Incorrecto'),
        duration: const Duration(milliseconds: 800),
        backgroundColor: acierto ? Colors.green : Colors.red,
      ),
    );

    Future.delayed(const Duration(seconds: 1), _siguiente);
  }

  // Verifica si el orden de palabras es correcto
  void _verificarOrdenar() {
    if (_respondido) return;
    final escenario = _escenarios[_indice];
    final acierto = _ordenSeleccionada.join(' ') == escenario['correcta'];

    setState(() {
      _respondido = true;
      if (acierto) _puntos++;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(acierto ? '✅ ¡Correcto!' : '❌ Incorrecto'),
        duration: const Duration(milliseconds: 800),
        backgroundColor: acierto ? Colors.green : Colors.red,
      ),
    );

    Future.delayed(const Duration(seconds: 1), _siguiente);
  }

  // Avanza al siguiente escenario o muestra resultado si ha terminado
  void _siguiente() {
    if (_indice < _escenarios.length - 1) {
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

  // Guarda la puntuación en Firestore si es la mejor
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
    if (_puntos > mejorAnterior) {
      await docRef.set({'retoPro': _puntos}, SetOptions(merge: true));
    }
  }

  // Muestra un cuadro de diálogo con el resultado final
  void _mostrarResultado() {
    final haEscapado = _puntos >= 3;
    showDialog(
      context: context,
      builder:
          (_) => AlertDialog(
            title: Text(haEscapado ? '🎉 ¡Escapaste!' : '🔒 Encerrado...'),
            content: Text(
              haEscapado
                  ? '¡Has resuelto el Escape Room con $_puntos puntos!'
                  : 'Has conseguido $_puntos puntos. ¡Inténtalo de nuevo!',
            ),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.popUntil(context, (route) => route.isFirst);
                },
                child: const Text('Salir'),
              ),
              TextButton(
                onPressed: () {
                  setState(() {
                    _indice = 0;
                    _puntos = 0;
                    _respondido = false;
                    _ordenSeleccionada = [];
                  });
                  Navigator.pop(context);
                },
                child: const Text('Reintentar'),
              ),
            ],
          ),
    );
  }

  // Construye el escenario en función del tipo: completar, ordenar o trivia
  Widget _construirEscenario() {
    final escenario = _escenarios[_indice];
    final tipo = escenario['tipo'];

    if (tipo == 'completar') {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(escenario['narrativa'], style: const TextStyle(fontSize: 18)),
          const SizedBox(height: 10),
          Text(escenario['frase'], style: const TextStyle(fontSize: 20)),
          const SizedBox(height: 20),
          ...escenario['opciones'].map<Widget>(
            (op) => Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: ElevatedButton(
                onPressed: () => _verificarRespuesta(op),
                child: Text(op),
              ),
            ),
          ),
        ],
      );
    } else if (tipo == 'ordenar') {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(escenario['narrativa'], style: const TextStyle(fontSize: 18)),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            children:
                escenario['palabras'].map<Widget>((palabra) {
                  final usada = _ordenSeleccionada.contains(palabra);
                  return ElevatedButton(
                    onPressed:
                        usada
                            ? null
                            : () =>
                                setState(() => _ordenSeleccionada.add(palabra)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: usada ? Colors.grey : Colors.deepPurple,
                      foregroundColor: Colors.white,
                    ),
                    child: Text(palabra),
                  );
                }).toList(),
          ),
          const SizedBox(height: 10),
          Text('Tu frase: ${_ordenSeleccionada.join(' ')}'),
          const SizedBox(height: 10),
          ElevatedButton(
            onPressed: _verificarOrdenar,
            child: const Text('Comprobar'),
          ),
        ],
      );
    } else if (tipo == 'trivia') {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(escenario['narrativa'], style: const TextStyle(fontSize: 18)),
          const SizedBox(height: 10),
          Text(escenario['pregunta'], style: const TextStyle(fontSize: 20)),
          const SizedBox(height: 20),
          ...escenario['opciones'].map<Widget>(
            (op) => Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: ElevatedButton(
                onPressed: () => _verificarRespuesta(op),
                child: Text(op),
              ),
            ),
          ),
        ],
      );
    }

    return const Text('Reto no válido');
  }

  // Construcción principal de la interfaz
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('👑 Reto Pro')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: SingleChildScrollView(child: _construirEscenario()),
      ),
    );
  }
}

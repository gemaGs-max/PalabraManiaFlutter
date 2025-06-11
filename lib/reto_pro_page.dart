import 'package:flutter/material.dart';
import 'package:confetti/confetti.dart';
import 'dart:math';
import 'package:audioplayers/audioplayers.dart';
import 'package:palabramania/widgets/personaje_habla.dart';
import 'package:palabramania/pantalla_juegos.dart';

class RetoProPage extends StatefulWidget {
  const RetoProPage({super.key});
  @override
  State<RetoProPage> createState() => _RetoProPageState();
}

class _RetoProPageState extends State<RetoProPage> {
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
      'narrativa': '🧠 Pregunta clave para avanzar:',
      'pregunta': 'What is the past of "run"?',
      'opciones': ['runned', 'ran', 'run', 'running'],
      'respuesta': 'ran',
    },
    {
      'tipo': 'completar',
      'narrativa': '📜 Última frase en el libro:',
      'frase': 'She has ___ her homework.',
      'opciones': ['do', 'did', 'done', 'doing'],
      'respuesta': 'done',
    },
  ];

  int _indice = 0;
  int _puntos = 0;
  String _mensajeMono = '¡Comienza el reto!';

  final ConfettiController _confettiController = ConfettiController(
    duration: const Duration(seconds: 1),
  );
  final AudioPlayer _audioPlayer = AudioPlayer();

  void _validarRespuesta(String respuestaSeleccionada) async {
    final escenario = _escenarios[_indice];
    bool acierto = false;

    if (escenario['tipo'] == 'completar' || escenario['tipo'] == 'trivia') {
      acierto = respuestaSeleccionada == escenario['respuesta'];
    } else if (escenario['tipo'] == 'ordenar') {
      acierto =
          respuestaSeleccionada.trim().toLowerCase() ==
          escenario['correcta'].trim().toLowerCase();
    }

    if (acierto) {
      setState(() {
        _puntos++;
        _mensajeMono = '¡Correcto!';
      });
      _confettiController.play();
      await _audioPlayer.play(AssetSource('audios/correcto.mp3'));
    } else {
      setState(() {
        _mensajeMono = '¡Intenta de nuevo!';
      });
      await _audioPlayer.play(AssetSource('audios/error.mp3'));
    }

    await Future.delayed(const Duration(seconds: 1));

    if (_indice < _escenarios.length - 1) {
      setState(() {
        _indice++;
        _mensajeMono = '¡Vamos al siguiente!';
      });
    } else {
      setState(() {
        if (_puntos == _escenarios.length) {
          _mensajeMono = '🎉 ¡Perfecto! ¡Eres un crack!';
        } else if (_puntos >= (_escenarios.length / 2)) {
          _mensajeMono = '😎 ¡Bien hecho, sigue así!';
        } else {
          _mensajeMono = '🙈 ¡Puedes hacerlo mejor, inténtalo otra vez!';
        }
      });
      _confettiController.play();
      Future.delayed(const Duration(seconds: 2), () => _mostrarDialogoFinal());
    }
  }

  void _mostrarDialogoFinal() {
    showDialog(
      context: context,
      builder:
          (_) => AlertDialog(
            title: const Text('¡Reto Completado!'),
            content: Text('Puntos obtenidos: $_puntos / ${_escenarios.length}'),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.pop(context);
                  _reiniciar();
                },
                child: const Text('Reintentar'),
              ),
              TextButton(
                onPressed: () {
                  Navigator.pop(context);
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(builder: (_) => const PantallaJuegos()),
                  );
                },
                child: const Text('Volver al menú'),
              ),
            ],
          ),
    );
  }

  void _reiniciar() {
    setState(() {
      _indice = 0;
      _puntos = 0;
      _mensajeMono = '¡Comienza el reto!';
    });
  }

  @override
  void dispose() {
    _confettiController.dispose();
    _audioPlayer.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final escenario = _escenarios[_indice];

    return Scaffold(
      appBar: AppBar(
        title: const Text('Reto Pro: Escape Room'),
        backgroundColor: Colors.deepOrange,
      ),
      body: Stack(
        children: [
          Column(
            children: [
              Center(child: PersonajeHabla(texto: _mensajeMono)),
              const SizedBox(height: 20),
              Text(
                escenario['narrativa'],
                style: const TextStyle(fontSize: 20),
              ),
              const SizedBox(height: 16),
              if (escenario['tipo'] == 'completar') ...[
                Text(escenario['frase'], style: const TextStyle(fontSize: 18)),
                const SizedBox(height: 10),
                ...escenario['opciones'].map<Widget>((op) {
                  return Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 4,
                    ),
                    child: ElevatedButton(
                      onPressed: () => _validarRespuesta(op),
                      child: Text(op),
                    ),
                  );
                }).toList(),
              ] else if (escenario['tipo'] == 'ordenar') ...[
                const Text('Ordena las palabras correctamente:'),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 8,
                  children:
                      (escenario['palabras'] as List<String>)
                          .map((palabra) => Chip(label: Text(palabra)))
                          .toList(),
                ),
                const SizedBox(height: 10),
                ElevatedButton(
                  onPressed:
                      () => _validarRespuesta(
                        (escenario['palabras'] as List<String>).join(' '),
                      ),
                  child: const Text('Enviar respuesta'),
                ),
              ] else if (escenario['tipo'] == 'trivia') ...[
                Text(
                  escenario['pregunta'],
                  style: const TextStyle(fontSize: 18),
                ),
                const SizedBox(height: 10),
                ...escenario['opciones'].map<Widget>((op) {
                  return Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 4,
                    ),
                    child: ElevatedButton(
                      onPressed: () => _validarRespuesta(op),
                      child: Text(op),
                    ),
                  );
                }).toList(),
              ],
              const Spacer(),
              Text('Puntos: $_puntos', style: const TextStyle(fontSize: 16)),
              const SizedBox(height: 16),
            ],
          ),
          Align(
            alignment: Alignment.topCenter,
            child: ConfettiWidget(
              confettiController: _confettiController,
              blastDirection: pi / 2,
              maxBlastForce: 15,
              minBlastForce: 5,
              emissionFrequency: 0.06,
              numberOfParticles: 25,
              gravity: 0.1,
            ),
          ),
        ],
      ),
    );
  }
}

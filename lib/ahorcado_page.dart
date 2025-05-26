import 'package:flutter/material.dart';
import 'dart:math';
import 'package:palabramania/services/firestore_service.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:confetti/confetti.dart';

class AhorcadoPage extends StatefulWidget {
  const AhorcadoPage({super.key});

  @override
  State<AhorcadoPage> createState() => _AhorcadoPageState();
}

class _AhorcadoPageState extends State<AhorcadoPage> {
  final List<String> _palabras = [
    'APPLE',
    'HOUSE',
    'DOG',
    'BOOK',
    'SCHOOL',
    'COMPUTER',
    'LANGUAGE',
  ];

  final Map<String, String> _pistas = {
    'APPLE': '🍎 Fruta',
    'HOUSE': '🏠 Lugar para vivir',
    'DOG': '🐶 Animal doméstico',
    'BOOK': '📖 Objeto para leer',
    'SCHOOL': '🏫 Lugar de aprendizaje',
    'COMPUTER': '💻 Dispositivo electrónico',
    'LANGUAGE': '🗣️ Medio de comunicación',
  };

  late String _palabraSecreta;
  late String _pistaActual;
  List<String> _letrasAdivinadas = [];
  List<String> _fallos = [];
  int _intentos = 0;
  final int _maxIntentos = 6;
  bool _juegoTerminado = false;
  bool _ganado = false;
  int _puntos = 0;
  final AudioPlayer _audioPlayer = AudioPlayer();
  late ConfettiController _confettiController;

  @override
  void initState() {
    super.initState();
    _confettiController = ConfettiController(
      duration: const Duration(seconds: 2),
    );
    _reiniciarJuego();
  }

  void _reiniciarJuego() {
    setState(() {
      _palabraSecreta = _palabras[Random().nextInt(_palabras.length)];
      _pistaActual = _pistas[_palabraSecreta] ?? 'Sin pista';
      _letrasAdivinadas.clear();
      _fallos.clear();
      _intentos = 0;
      _juegoTerminado = false;
      _ganado = false;
      _puntos = 0;
    });
  }

  void _adivinarLetra(String letra) async {
    if (_juegoTerminado ||
        _letrasAdivinadas.contains(letra) ||
        _fallos.contains(letra))
      return;

    setState(() {
      if (_palabraSecreta.contains(letra)) {
        _letrasAdivinadas.add(letra);
        _audioPlayer.play(AssetSource('audios/correcto.mp3'));

        if (_palabraSecreta
            .split('')
            .every((l) => _letrasAdivinadas.contains(l))) {
          _juegoTerminado = true;
          _ganado = true;
          _puntos = _palabraSecreta.length * 2;
          guardarPuntuacion('ahorcado', _puntos);
          _confettiController.play();
        }
      } else {
        _intentos++;
        _fallos.add(letra);
        _audioPlayer.play(AssetSource('audios/error.mp3'));

        if (_intentos >= _maxIntentos) {
          _juegoTerminado = true;
        }
      }
    });
  }

  Widget _construirPalabra() {
    return Wrap(
      alignment: WrapAlignment.center,
      spacing: 8,
      children:
          _palabraSecreta.split('').map((letra) {
            return Text(
              _letrasAdivinadas.contains(letra) ? letra : '_',
              style: const TextStyle(fontSize: 32, letterSpacing: 2),
            );
          }).toList(),
    );
  }

  Widget _construirTeclado() {
    const letras = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ';
    return Wrap(
      spacing: 4,
      runSpacing: 4,
      alignment: WrapAlignment.center,
      children:
          letras.split('').map((letra) {
            final yaUsada =
                _letrasAdivinadas.contains(letra) || _fallos.contains(letra);
            return ElevatedButton(
              onPressed:
                  yaUsada || _juegoTerminado
                      ? null
                      : () => _adivinarLetra(letra),
              style: ElevatedButton.styleFrom(
                backgroundColor:
                    _fallos.contains(letra)
                        ? Colors.redAccent
                        : Colors.blueAccent,
                disabledBackgroundColor: Colors.grey,
                minimumSize: const Size(40, 40),
              ),
              child: Text(letra),
            );
          }).toList(),
    );
  }

  Widget _construirResultado() {
    if (!_juegoTerminado) return const SizedBox.shrink();
    return Column(
      children: [
        const SizedBox(height: 20),
        Text(
          _ganado
              ? '🎉 ¡Has ganado!'
              : '❌ ¡Has perdido! La palabra era: $_palabraSecreta',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 20,
            color: _ganado ? Colors.green : Colors.red,
          ),
        ),
        const SizedBox(height: 10),
        Text(
          'Fallos: ${_fallos.join(', ')}',
          style: const TextStyle(color: Colors.redAccent),
        ),
        const SizedBox(height: 10),
        Text(
          'Puntos: $_puntos',
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 10),
        ElevatedButton(
          onPressed: _reiniciarJuego,
          child: const Text('🔁 Jugar otra vez'),
        ),
      ],
    );
  }

  Widget _construirAhorcado() {
    final path = 'assets/ahorcado/$_intentos.png';
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Image.asset(
        path,
        height: 150,
        fit: BoxFit.contain,
        errorBuilder: (context, error, stackTrace) {
          return const Text('💀 Imagen no disponible');
        },
      ),
    );
  }

  @override
  void dispose() {
    _audioPlayer.dispose();
    _confettiController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Scaffold(
          appBar: AppBar(
            backgroundColor: Colors.indigo,
            centerTitle: true,
            title: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text('🎯 Ahorcado'),
                const SizedBox(width: 16),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.amber.shade100,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    'Puntos: $_puntos',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                ),
              ],
            ),
          ),
          backgroundColor: const Color(0xFFE8EAF6),
          body: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  'Intentos: $_intentos / $_maxIntentos',
                  style: const TextStyle(fontSize: 18),
                ),
                const SizedBox(height: 5),
                Text(
                  'Pista: $_pistaActual',
                  style: const TextStyle(
                    fontSize: 16,
                    fontStyle: FontStyle.italic,
                  ),
                ),
                _construirAhorcado(),
                _construirPalabra(),
                const SizedBox(height: 30),
                _construirTeclado(),
                _construirResultado(),
              ],
            ),
          ),
        ),
        Align(
          alignment: Alignment.topCenter,
          child: ConfettiWidget(
            confettiController: _confettiController,
            blastDirection: pi / 2,
            numberOfParticles: 30,
            maxBlastForce: 15,
            minBlastForce: 5,
            gravity: 0.2,
          ),
        ),
      ],
    );
  }
}

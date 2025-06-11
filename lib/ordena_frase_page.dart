import 'package:flutter/material.dart';
import 'dart:math';
import 'package:confetti/confetti.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:palabramania/services/firestore_service.dart';
import 'package:firebase_auth/firebase_auth.dart';

class OrdenaFrasePage extends StatefulWidget {
  const OrdenaFrasePage({super.key});
  // Esta página es un juego de ordenar frases en inglés
  @override
  State<OrdenaFrasePage> createState() => _OrdenaFrasePageState();
}

class _OrdenaFrasePageState extends State<OrdenaFrasePage> {
  final List<Map<String, String>> _frases = [
    {'es': '¿Cómo estás?', 'en': 'How are you'},
    {'es': 'Yo soy estudiante', 'en': 'I am a student'},
    {'es': 'Nosotros jugamos fútbol', 'en': 'We play football'},
    {'es': 'Ella tiene un gato', 'en': 'She has a cat'},
    {'es': 'Nos gusta leer libros', 'en': 'We like to read books'},
    {'es': 'Ellos están en la escuela', 'en': 'They are at school'},
    {'es': 'Tú hablas inglés muy bien', 'en': 'You speak English very well'},
    {'es': 'Mi hermano vive en Madrid', 'en': 'My brother lives in Madrid'},
    {'es': 'Hoy es un buen día', 'en': 'Today is a good day'},
    {'es': 'Vamos al parque mañana', 'en': 'We go to the park tomorrow'},
  ];
  // Lista de frases en español e inglés para ordenar
  late Map<String, String> _fraseActual;
  List<Map<String, String>> _frasesRestantes = [];
  List<String> _palabrasDesordenadas = [];
  List<String> _respuestaUsuario = [];
  // Variables del juego
  late ConfettiController _confettiController;
  final AudioPlayer _audioPlayer = AudioPlayer();
  bool _mostrarResultado = false;
  bool _esCorrecto = false;
  int _puntos = 0;
  int _mejorPuntuacion = 0;
  // Controlador de confeti para animaciones festivas
  @override
  void initState() {
    super.initState();
    _confettiController = ConfettiController(
      duration: const Duration(seconds: 2),
    );
    _cargarMejorPuntuacion();
    _frasesRestantes = List.from(_frases)..shuffle();
    _nuevaFrase();
  }

  // Carga la mejor puntuación del usuario desde Firestore
  Future<void> _cargarMejorPuntuacion() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid != null) {
      final doc = await getPuntuacion(uid, 'ordena_frase');
      if (doc != null) {
        setState(() {
          _mejorPuntuacion = doc['puntos'] ?? 0;
        });
      }
    }
  }

  // Crea una nueva frase desordenada y reinicia el estado del juego
  void _nuevaFrase() {
    setState(() {
      _mostrarResultado = false;
      _esCorrecto = false;
      _respuestaUsuario.clear();

      if (_frasesRestantes.isEmpty) {
        _mostrarDialogoFinal();
        return;
      }

      _fraseActual = _frasesRestantes.removeAt(0);
      _palabrasDesordenadas = _fraseActual['en']!.split(' ')..shuffle();
    });
  }

  // Reinicia el juego y muestra un diálogo de finalización
  void _mostrarDialogoFinal() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder:
          (_) => AlertDialog(
            title: const Text('🎉 ¡Juego terminado!'),
            content: Text(
              'Has completado todas las frases.\n\nPuntuación final: $_puntos ⭐',
            ),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.pop(context);
                  Navigator.pop(context);
                },
                child: const Text('Salir'),
              ),
              ElevatedButton(
                onPressed: () {
                  Navigator.pop(context);
                  setState(() {
                    _puntos = 0;
                    _frasesRestantes = List.from(_frases)..shuffle();
                    _nuevaFrase();
                  });
                },
                child: const Text('Reintentar'),
              ),
            ],
          ),
    );
  }

  // Selecciona una palabra desordenada y la añade a la respuesta del usuario
  void _seleccionarPalabra(String palabra) {
    if (_mostrarResultado) return;

    setState(() {
      _respuestaUsuario.add(palabra);
      _palabrasDesordenadas.remove(palabra);
    });
  }

  // Verifica si la respuesta del usuario es correcta y actualiza el estado del juego
  void _verificar() async {
    if (_respuestaUsuario.join(' ') == _fraseActual['en']) {
      _esCorrecto = true;
      _puntos++;
      if (_puntos > _mejorPuntuacion) {
        _mejorPuntuacion = _puntos;
        await guardarPuntuacion('ordena_frase', _puntos);
      }
      _confettiController.play();
      await _audioPlayer.play(AssetSource('audios/correcto.mp3'));

      String? mensajeEspecial;
      if (_puntos == 3) mensajeEspecial = '🥉 ¡Buen comienzo!';
      if (_puntos == 5) mensajeEspecial = '🥈 ¡Muy bien! Sigue así 💪';
      if (_puntos == 10) mensajeEspecial = '🥇 ¡Increíble! Nivel experto 🔥';

      if (mensajeEspecial != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(mensajeEspecial),
            backgroundColor: Colors.deepPurple,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    } else {
      _esCorrecto = false;
      await _audioPlayer.play(AssetSource('audios/error.mp3'));
    }

    setState(() => _mostrarResultado = true);
  }

  // Construye el widget de palabras desordenadas y respuesta del usuario
  Widget _buildPalabras(List<String> palabras, void Function(String) onTap) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      alignment: WrapAlignment.center,
      children:
          palabras
              .map(
                (p) => ElevatedButton(
                  onPressed: () => onTap(p),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: Colors.black,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 3,
                  ),
                  child: Text(p, style: const TextStyle(fontSize: 18)),
                ),
              )
              .toList(),
    );
  }

  // Libera recursos al cerrar la página
  @override
  void dispose() {
    _confettiController.dispose();
    _audioPlayer.dispose();
    super.dispose();
  }

  // Construye la interfaz de usuario de la página
  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Scaffold(
          backgroundColor: const Color(0xFFFFF9C4),
          appBar: AppBar(
            backgroundColor: Colors.amber.shade700,
            centerTitle: true,
            title: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text('🔤 Ordena la frase'),
                const SizedBox(width: 16),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.orange.shade100,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    '⭐ $_puntos',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
          ),
          body: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Frase en español centrada en tarjeta
                Center(
                  child: SizedBox(
                    width: 300,
                    child: Card(
                      elevation: 3,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      color: Colors.white,
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Text(
                          'Traduce: "${_fraseActual['es']}"',
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 20),
                _buildPalabras(_respuestaUsuario, (_) {}),
                const SizedBox(height: 16),
                _buildPalabras(_palabrasDesordenadas, _seleccionarPalabra),
                const SizedBox(height: 30),

                if (!_mostrarResultado)
                  ElevatedButton(
                    onPressed: _verificar,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 30,
                        vertical: 12,
                      ),
                    ),
                    child: const Text('Verificar'),
                  ),

                if (_mostrarResultado)
                  Center(
                    child: SizedBox(
                      width: 300,
                      child: Card(
                        elevation: 4,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        color:
                            _esCorrecto
                                ? Colors.green.shade50
                                : Colors.red.shade50,
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Column(
                            children: [
                              Text(
                                _esCorrecto
                                    ? '✅ ¡Correcto!'
                                    : '❌ Intenta de nuevo',
                                style: TextStyle(
                                  fontSize: 22,
                                  color:
                                      _esCorrecto ? Colors.green : Colors.red,
                                  fontWeight: FontWeight.bold,
                                ),
                                textAlign: TextAlign.center,
                              ),
                              const SizedBox(height: 10),
                              Text(
                                'Mejor puntuación: $_mejorPuntuacion ⭐',
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontStyle: FontStyle.italic,
                                ),
                                textAlign: TextAlign.center,
                              ),
                              const SizedBox(height: 10),
                              ElevatedButton(
                                onPressed: _nuevaFrase,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.deepOrange,
                                ),
                                child: const Text('Otra frase'),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
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

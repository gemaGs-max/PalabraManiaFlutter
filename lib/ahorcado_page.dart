import 'package:flutter/material.dart';
import 'dart:math';
import 'package:palabramania/services/firestore_service.dart'; // Servicio para guardar puntuaciones en Firestore
import 'package:audioplayers/audioplayers.dart'; // Para reproducir efectos de sonido
import 'package:confetti/confetti.dart'; // Para mostrar confeti cuando se gana

/// Página del juego del Ahorcado
class AhorcadoPage extends StatefulWidget {
  const AhorcadoPage({super.key});

  @override
  State<AhorcadoPage> createState() => _AhorcadoPageState();
}

class _AhorcadoPageState extends State<AhorcadoPage> {
  // Lista de palabras posibles para adivinar
  final List<String> _palabras = [
    'APPLE',
    'HOUSE',
    'DOG',
    'BOOK',
    'SCHOOL',
    'COMPUTER',
    'LANGUAGE',
  ];

  // Diccionario de pistas asociadas a cada palabra
  final Map<String, String> _pistas = {
    'APPLE': '🍎 Fruta',
    'HOUSE': '🏠 Lugar para vivir',
    'DOG': '🐶 Animal doméstico',
    'BOOK': '📖 Objeto para leer',
    'SCHOOL': '🏫 Lugar de aprendizaje',
    'COMPUTER': '💻 Dispositivo electrónico',
    'LANGUAGE': '🗣️ Medio de comunicación',
  };

  late String _palabraSecreta; // Palabra que hay que adivinar en esta partida
  late String _pistaActual; // Pista correspondiente a la palabra secreta
  List<String> _letrasAdivinadas = []; // Letras que el jugador ya acertó
  List<String> _fallos = []; // Letras incorrectas que ha elegido el jugador
  int _intentos = 0; // Número de intentos fallidos en la partida
  final int _maxIntentos = 6; // Máximo de intentos antes de perder
  bool _juegoTerminado =
      false; // Indica si el juego ya ha terminado (victoria o derrota)
  bool _ganado = false; // Indica si el jugador ha ganado la partida
  int _puntos = 0; // Puntos obtenidos en la partida actual
  final AudioPlayer _audioPlayer = AudioPlayer(); // Reproductor de sonidos
  late ConfettiController
  _confettiController; // Controlador para el efecto confeti

  @override
  void initState() {
    super.initState();
    // Inicializamos el controlador de confeti con una duración de 2 segundos
    _confettiController = ConfettiController(
      duration: const Duration(seconds: 2),
    );
    // Reiniciamos el juego al arrancar la página (elige nueva palabra, limpia estado, etc.)
    _reiniciarJuego();
  }

  /// Reinicia todas las variables para empezar una nueva partida de Ahorcado.
  void _reiniciarJuego() {
    setState(() {
      // Elegir aleatoriamente una palabra de la lista
      _palabraSecreta = _palabras[Random().nextInt(_palabras.length)];
      // Obtener la pista asociada a esa palabra
      _pistaActual = _pistas[_palabraSecreta] ?? 'Sin pista';
      // Limpiar letras acertadas y fallidas
      _letrasAdivinadas.clear();
      _fallos.clear();
      // Reiniciar contador de intentos y estado de fin de juego
      _intentos = 0;
      _juegoTerminado = false;
      _ganado = false;
      // Resetear puntos a 0 antes de empezar
      _puntos = 0;
    });
  }

  /// Procesa la letra que el jugador ha seleccionado.
  /// Si la letra está en la palabra secreta, se añade a _letrasAdivinadas;
  /// si no, se añade a _fallos y se incrementa _intentos.
  void _adivinarLetra(String letra) async {
    // Si el juego ya terminó, o la letra ya fue usada (acertada o fallada), no hacemos nada
    if (_juegoTerminado ||
        _letrasAdivinadas.contains(letra) ||
        _fallos.contains(letra)) {
      return;
    }

    setState(() {
      // Si la palabra secreta contiene la letra
      if (_palabraSecreta.contains(letra)) {
        _letrasAdivinadas.add(letra);
        // Reproducir sonido de acierto
        _audioPlayer.play(AssetSource('audios/correcto.mp3'));

        // Si todas las letras de la palabra han sido adivinadas, el jugador gana
        if (_palabraSecreta
            .split('')
            .every((l) => _letrasAdivinadas.contains(l))) {
          _juegoTerminado = true;
          _ganado = true;
          // Asignar puntos: por ejemplo, 2 puntos por cada letra de la palabra
          _puntos = _palabraSecreta.length * 2;
          // Guardar la puntuación en Firestore (servicio externo)
          guardarPuntuacion('ahorcado', _puntos);
          // Disparar el confeti en pantalla
          _confettiController.play();
        }
      } else {
        // Si la letra NO está en la palabra secreta, sumamos un intento fallido
        _intentos++;
        _fallos.add(letra);
        // Reproducir sonido de error
        _audioPlayer.play(AssetSource('audios/error.mp3'));

        // Si se supera el número máximo de intentos, el juego termina con derrota
        if (_intentos >= _maxIntentos) {
          _juegoTerminado = true;
        }
      }
    });
  }

  /// Construye el widget que muestra la palabra con guiones y letras acertadas.
  Widget _construirPalabra() {
    return Wrap(
      alignment: WrapAlignment.center,
      spacing: 8,
      // Para cada letra de la palabra secreta, mostramos la letra si ya fue adivinada,
      // o un guión '_' en caso contrario
      children:
          _palabraSecreta.split('').map((letra) {
            return Text(
              _letrasAdivinadas.contains(letra) ? letra : '_',
              style: const TextStyle(fontSize: 32, letterSpacing: 2),
            );
          }).toList(),
    );
  }

  /// Construye el teclado de letras (A-Z) para que el jugador seleccione.
  Widget _construirTeclado() {
    const letras = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ';
    return Wrap(
      spacing: 4,
      runSpacing: 4,
      alignment: WrapAlignment.center,
      children:
          letras.split('').map((letra) {
            // Si la letra ya fue adivinada o fallada, la deshabilitamos
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
                        ? Colors
                            .redAccent // Si es fallo, botón rojo
                        : Colors.blueAccent, // Si no, botón azul
                disabledBackgroundColor:
                    Colors.grey, // Color cuando está deshabilitado
                minimumSize: const Size(40, 40), // Tamaño fijo de cada tecla
              ),
              child: Text(letra),
            );
          }).toList(),
    );
  }

  /// Muestra el resultado final (victoria o derrota) cuando el juego ha terminado.
  Widget _construirResultado() {
    // Si el juego no ha terminado, no mostramos nada
    if (!_juegoTerminado) return const SizedBox.shrink();

    return Column(
      children: [
        const SizedBox(height: 20),
        Text(
          _ganado
              ? '🎉 ¡Has ganado!' // Si ganó
              : '❌ ¡Has perdido! La palabra era: $_palabraSecreta', // Si perdió
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 20,
            color:
                _ganado
                    ? Colors.green
                    : Colors.red, // Verde en victoria, rojo en derrota
          ),
        ),
        const SizedBox(height: 10),
        // Mostramos las letras falladas
        Text(
          'Fallos: ${_fallos.join(', ')}',
          style: const TextStyle(color: Colors.redAccent),
        ),
        const SizedBox(height: 10),
        // Mostramos los puntos obtenidos
        Text(
          'Puntos: $_puntos',
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 10),
        // Botón para reiniciar el juego (jugar otra vez)
        ElevatedButton(
          onPressed: _reiniciarJuego,
          child: const Text('🔁 Jugar otra vez'),
        ),
      ],
    );
  }

  /// Muestra la imagen del ahorcado según el número de intentos fallidos (_intentos).
  Widget _construirAhorcado() {
    final path = 'assets/ahorcado/$_intentos.png';
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Image.asset(
        path,
        height: 150,
        fit: BoxFit.contain,
        // En caso de que la imagen no exista (p. ej. 6.png) mostramos un texto alternativo
        errorBuilder: (context, error, stackTrace) {
          return const Text('💀 Imagen no disponible');
        },
      ),
    );
  }

  @override
  void dispose() {
    // Liberamos los recursos del AudioPlayer y del ConfettiController
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
                // Mostramos los puntos actuales en el AppBar
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
                // Mostramos el contador de intentos
                Text(
                  'Intentos: $_intentos / $_maxIntentos',
                  style: const TextStyle(fontSize: 18),
                ),
                const SizedBox(height: 5),
                // Mostramos la pista al jugador
                Text(
                  'Pista: $_pistaActual',
                  style: const TextStyle(
                    fontSize: 16,
                    fontStyle: FontStyle.italic,
                  ),
                ),
                // Dibujamos la imagen del ahorcado
                _construirAhorcado(),
                // Dibujamos la palabra oculta con guiones y letras acertadas
                _construirPalabra(),
                const SizedBox(height: 30),
                // Dibujamos el teclado de letras
                _construirTeclado(),
                // Dibujamos el mensaje de victoria/derrota si corresponde
                _construirResultado(),
              ],
            ),
          ),
        ),
        // Colocamos el widget de confeti en la parte superior para que quede visible
        Align(
          alignment: Alignment.topCenter,
          child: ConfettiWidget(
            confettiController: _confettiController,
            blastDirection: pi / 2, // Dirección del confeti hacia abajo
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

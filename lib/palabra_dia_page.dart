import 'package:flutter/material.dart';
import 'dart:convert';
import 'dart:math';
import 'package:http/http.dart' as http;
import 'package:translator/translator.dart';
import 'package:confetti/confetti.dart';

class PalabraDelDiaPage extends StatefulWidget {
  const PalabraDelDiaPage({super.key});
  // Pantalla que muestra una palabra del día con su definición, traducción y ejemplo
  @override
  State<PalabraDelDiaPage> createState() => _PalabraDelDiaPageState();
}

class _PalabraDelDiaPageState extends State<PalabraDelDiaPage> {
  String palabra = '';
  String definicion = '';
  String ejemplo = '';
  String traduccion = '';
  bool cargando = true;

  late ConfettiController _confettiController;
  // Controlador de confeti para animaciones festivas
  @override
  void initState() {
    super.initState();
    _confettiController = ConfettiController(
      duration: const Duration(seconds: 2),
    );
    obtenerPalabraDelDia();
  }

  // Libera recursos al cerrar la pantalla
  @override
  void dispose() {
    _confettiController.dispose();
    super.dispose();
  }

  // Obtiene una palabra del día aleatoria con su definición, traducción y ejemplo
  Future<void> obtenerPalabraDelDia() async {
    setState(() {
      cargando = true;
    });

    final response = await http.get(
      Uri.parse('https://random-word-api.herokuapp.com/word'),
    );

    if (response.statusCode == 200) {
      final List palabras = jsonDecode(response.body);
      palabra = palabras.first;

      final definicionResponse = await http.get(
        Uri.parse('https://api.dictionaryapi.dev/api/v2/entries/en/$palabra'),
      );

      if (definicionResponse.statusCode == 200) {
        final List data = jsonDecode(definicionResponse.body);
        final definicionIngles =
            data[0]['meanings'][0]['definitions'][0]['definition'] ??
            'Sin definición';
        final ejemploOriginal =
            data[0]['meanings'][0]['definitions'][0]['example'];

        final traductor = GoogleTranslator();
        final traduccionResult = await traductor.translate(
          definicionIngles,
          to: 'es',
        );

        setState(() {
          definicion = definicionIngles;
          traduccion = traduccionResult.text;
          ejemplo =
              ejemploOriginal ??
              'Ejemplo generado: "${palabra[0].toUpperCase()}${palabra.substring(1)} is used in a sentence."';
          cargando = false;
        });
      } else {
        setState(() {
          definicion = 'No se encontró definición para "$palabra"';
          traduccion = '';
          ejemplo = '';
          cargando = false;
        });
      }
    } else {
      setState(() {
        palabra = 'Error';
        definicion = 'No se pudo obtener la palabra del día';
        traduccion = '';
        ejemplo = '';
        cargando = false;
      });
    }
  }

  // Muestra un diálogo al pulsar "He terminado" con opciones para repetir o volver
  void _mostrarDialogoFinal() {
    _confettiController.play(); // 🎉 Confeti al pulsar "He terminado"
    // Muestra un diálogo de alerta con opciones
    showDialog(
      context: context,
      builder:
          (_) => AlertDialog(
            title: const Text('✅ Has leído toda la palabra del día'),
            content: const Text('¿Qué deseas hacer ahora?'),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.pop(context);
                  obtenerPalabraDelDia();
                },
                child: const Text('🔁 Otra palabra'),
              ),
              TextButton(
                onPressed: () {
                  Navigator.pop(context);
                  Navigator.pop(context);
                },
                child: const Text('🚪 Volver a juegos'),
              ),
            ],
          ),
    );
  }

  // Muestra un diálogo de alerta al pulsar "He terminado" con opciones para repetir o volver
  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Scaffold(
          appBar: AppBar(
            title: const Text('📖 Palabra del día'),
            backgroundColor: const Color.fromARGB(255, 40, 147, 86),
          ),
          backgroundColor: const Color(0xFFE3F2FD),
          body:
              cargando
                  ? const Center(child: CircularProgressIndicator())
                  : Padding(
                    padding: const EdgeInsets.all(20.0),
                    child: ListView(
                      children: [
                        // PALABRA
                        Center(
                          child: SizedBox(
                            width: 320,
                            child: Card(
                              elevation: 3,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                              color: Colors.white,
                              child: Padding(
                                padding: const EdgeInsets.all(16.0),
                                child: Text(
                                  '🔤 Palabra: $palabra',
                                  style: const TextStyle(
                                    fontSize: 24,
                                    fontWeight: FontWeight.bold,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                              ),
                            ),
                          ),
                        ),

                        const SizedBox(height: 20),

                        // DEFINICIÓN
                        Center(
                          child: SizedBox(
                            width: 320,
                            child: Card(
                              color: Colors.lightBlue.shade50,
                              elevation: 2,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Padding(
                                padding: const EdgeInsets.all(14),
                                child: Column(
                                  children: [
                                    const Text(
                                      '📚 Definición:',
                                      style: TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      definicion,
                                      style: const TextStyle(
                                        fontStyle: FontStyle.italic,
                                        fontSize: 16,
                                      ),
                                      textAlign: TextAlign.center,
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),

                        const SizedBox(height: 20),

                        // TRADUCCIÓN
                        Center(
                          child: SizedBox(
                            width: 320,
                            child: Card(
                              color: Colors.green.shade50,
                              elevation: 2,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Padding(
                                padding: const EdgeInsets.all(14),
                                child: Column(
                                  children: [
                                    const Text(
                                      '🌍 Traducción:',
                                      style: TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      traduccion,
                                      style: const TextStyle(
                                        fontStyle: FontStyle.italic,
                                        fontSize: 16,
                                      ),
                                      textAlign: TextAlign.center,
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),

                        const SizedBox(height: 20),

                        // EJEMPLO
                        Center(
                          child: SizedBox(
                            width: 320,
                            child: Card(
                              color: Colors.yellow.shade50,
                              elevation: 2,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Padding(
                                padding: const EdgeInsets.all(14),
                                child: Column(
                                  children: [
                                    const Text(
                                      '📝 Ejemplo:',
                                      style: TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      ejemplo,
                                      style: const TextStyle(
                                        fontStyle: FontStyle.italic,
                                        fontSize: 16,
                                      ),
                                      textAlign: TextAlign.center,
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),

                        const SizedBox(height: 30),

                        // BOTÓN HE TERMINADO
                        Center(
                          child: ElevatedButton.icon(
                            onPressed: _mostrarDialogoFinal,
                            icon: const Icon(Icons.check),
                            label: const Text('He terminado'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF4CAF50),
                              foregroundColor: Colors.white,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
          floatingActionButton: FloatingActionButton.extended(
            onPressed: obtenerPalabraDelDia,
            label: const Text('Otra palabra'),
            icon: const Icon(Icons.refresh),
            backgroundColor: const Color.fromARGB(255, 103, 195, 221),
          ),
        ),

        // 🎉 Confetti widget
        Align(
          alignment: Alignment.topCenter,
          child: ConfettiWidget(
            confettiController: _confettiController,
            blastDirection: pi / 2,
            maxBlastForce: 20,
            minBlastForce: 5,
            emissionFrequency: 0.06,
            numberOfParticles: 25,
            gravity: 0.3,
            colors: const [Colors.green, Colors.blue, Colors.orange],
          ),
        ),
      ],
    );
  }
}

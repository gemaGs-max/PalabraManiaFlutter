import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:translator/translator.dart';

class PalabraDelDiaPage extends StatefulWidget {
  const PalabraDelDiaPage({super.key});

  @override
  State<PalabraDelDiaPage> createState() => _PalabraDelDiaPageState();
}

class _PalabraDelDiaPageState extends State<PalabraDelDiaPage> {
  String palabra = '';
  String definicion = '';
  String ejemplo = '';
  String traduccion = '';
  bool cargando = true;

  @override
  void initState() {
    super.initState();
    obtenerPalabraDelDia();
  }

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

  void _mostrarDialogoFinal() {
    showDialog(
      context: context,
      builder:
          (_) => AlertDialog(
            title: const Text('✅ Has leído toda la palabra del día'),
            content: const Text('¿Qué deseas hacer ahora?'),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.pop(context); // Cierra el diálogo
                  obtenerPalabraDelDia(); // Carga una nueva palabra
                },
                child: const Text('🔁 Otra palabra'),
              ),
              TextButton(
                onPressed: () {
                  Navigator.pop(context); // Cierra el diálogo
                  Navigator.pop(context); // Vuelve a pantalla de juegos
                },
                child: const Text('🚪 Volver a juegos'),
              ),
            ],
          ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
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
                    Text(
                      '🔤 Palabra: $palabra',
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 20),

                    const Text(
                      '📚 Definición:',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      definicion,
                      style: const TextStyle(
                        fontStyle: FontStyle.italic,
                        fontSize: 16,
                      ),
                    ),

                    const SizedBox(height: 20),
                    const Text(
                      '🌍 Traducción:',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      traduccion,
                      style: const TextStyle(
                        fontStyle: FontStyle.italic,
                        fontSize: 16,
                      ),
                    ),

                    const SizedBox(height: 20),
                    const Text(
                      '📝 Ejemplo:',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      ejemplo,
                      style: const TextStyle(
                        fontStyle: FontStyle.italic,
                        fontSize: 16,
                      ),
                    ),

                    const SizedBox(height: 30),
                    ElevatedButton.icon(
                      onPressed: _mostrarDialogoFinal,
                      icon: const Icon(Icons.check),
                      label: const Text('He terminado'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF4CAF50),
                        foregroundColor: Colors.white,
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
    );
  }
}

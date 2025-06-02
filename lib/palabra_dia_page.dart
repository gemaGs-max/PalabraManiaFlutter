// Importaciones necesarias
import 'package:flutter/material.dart';
import 'dart:convert'; // Para decodificar JSON
import 'package:http/http.dart' as http; // Para realizar peticiones HTTP
import 'package:translator/translator.dart'; // Para traducir textos

// Pantalla principal de la palabra del día
class PalabraDelDiaPage extends StatefulWidget {
  const PalabraDelDiaPage({super.key});

  @override
  State<PalabraDelDiaPage> createState() => _PalabraDelDiaPageState();
}

class _PalabraDelDiaPageState extends State<PalabraDelDiaPage> {
  // Variables para almacenar la información de la palabra
  String palabra = '';
  String definicion = '';
  String ejemplo = '';
  String traduccion = '';
  bool cargando = true; // Muestra indicador de carga

  @override
  void initState() {
    super.initState();
    obtenerPalabraDelDia(); // Al iniciar, carga una palabra
  }

  // Función principal que obtiene y traduce la palabra del día
  Future<void> obtenerPalabraDelDia() async {
    setState(() {
      cargando = true;
    });

    // Petición a API que devuelve una palabra aleatoria
    final response = await http.get(
      Uri.parse('https://random-word-api.herokuapp.com/word'),
    );

    if (response.statusCode == 200) {
      final List palabras = jsonDecode(response.body);
      palabra = palabras.first;

      // Consulta definición en API gratuita de diccionario
      final definicionResponse = await http.get(
        Uri.parse('https://api.dictionaryapi.dev/api/v2/entries/en/$palabra'),
      );

      if (definicionResponse.statusCode == 200) {
        final List data = jsonDecode(definicionResponse.body);

        // Extrae definición y ejemplo (si hay)
        final definicionIngles =
            data[0]['meanings'][0]['definitions'][0]['definition'] ??
            'Sin definición';

        final ejemploOriginal =
            data[0]['meanings'][0]['definitions'][0]['example'];

        // Traduce al español usando GoogleTranslator
        final traductor = GoogleTranslator();
        final traduccionResult = await traductor.translate(
          definicionIngles,
          to: 'es',
        );

        // Actualiza el estado con los datos
        setState(() {
          definicion = definicionIngles;
          traduccion = traduccionResult.text;
          ejemplo =
              ejemploOriginal ??
              'Ejemplo generado: "${palabra[0].toUpperCase()}${palabra.substring(1)} is used in a sentence."';
          cargando = false;
        });
      } else {
        // No se encontró definición
        setState(() {
          definicion = 'No se encontró definición para "$palabra"';
          traduccion = '';
          ejemplo = '';
          cargando = false;
        });
      }
    } else {
      // Fallo al obtener palabra
      setState(() {
        palabra = 'Error';
        definicion = 'No se pudo obtener la palabra del día';
        traduccion = '';
        ejemplo = '';
        cargando = false;
      });
    }
  }

  // Diálogo cuando el usuario ha terminado de leer
  void _mostrarDialogoFinal() {
    showDialog(
      context: context,
      builder:
          (_) => AlertDialog(
            title: const Text('✅ Has leído toda la palabra del día'),
            content: const Text('¿Qué deseas hacer ahora?'),
            actions: [
              // Botón para cargar otra palabra
              TextButton(
                onPressed: () {
                  Navigator.pop(context); // Cierra diálogo
                  obtenerPalabraDelDia(); // Carga otra palabra
                },
                child: const Text('🔁 Otra palabra'),
              ),
              // Botón para volver a la pantalla de juegos
              TextButton(
                onPressed: () {
                  Navigator.pop(context); // Cierra diálogo
                  Navigator.pop(context); // Vuelve atrás
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
              ? const Center(
                child: CircularProgressIndicator(),
              ) // Muestra carga
              : Padding(
                padding: const EdgeInsets.all(20.0),
                child: ListView(
                  children: [
                    // Palabra obtenida
                    Text(
                      '🔤 Palabra: $palabra',
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Sección de definición
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

                    // Sección de traducción
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

                    // Sección de ejemplo
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

                    // Botón para finalizar la actividad
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

      // Botón flotante para cargar otra palabra
      floatingActionButton: FloatingActionButton.extended(
        onPressed: obtenerPalabraDelDia,
        label: const Text('Otra palabra'),
        icon: const Icon(Icons.refresh),
        backgroundColor: const Color.fromARGB(255, 103, 195, 221),
      ),
    );
  }
}

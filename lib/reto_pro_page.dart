import 'package:flutter/material.dart';

class RetoProPage extends StatefulWidget {
  const RetoProPage({Key? key}) : super(key: key);

  @override
  State<RetoProPage> createState() => _RetoProPageState();
}

class _RetoProPageState extends State<RetoProPage> {
  // Aquí puedes añadir los datos del reto (palabras, temporizador, puntuación…)
  final List<String> palabras = ['flutter', 'dart', 'widget', 'state'];
  int indiceActual = 0;
  String respuestaUsuario = '';
  int puntuacion = 0;

  void _comprobarRespuesta() {
    if (respuestaUsuario.trim().toLowerCase() == palabras[indiceActual]) {
      setState(() {
        puntuacion += 1;
        indiceActual = (indiceActual + 1) % palabras.length;
        respuestaUsuario = '';
      });
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('¡Correcto!')));
    } else {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Prueba otra vez')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final palabraEnigma = palabras[indiceActual].split('').reversed.join();
    return Scaffold(
      appBar: AppBar(title: const Text('Reto Pro')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Text(
              'Decodifica la palabra:',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 24),
            Text(
              palabraEnigma,
              style: const TextStyle(fontSize: 32, letterSpacing: 2),
            ),
            const SizedBox(height: 24),
            TextField(
              onChanged: (val) => respuestaUsuario = val,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                labelText: 'Tu respuesta',
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _comprobarRespuesta,
              child: const Text('Comprobar'),
            ),
            const Spacer(),
            Text('Puntuación: $puntuacion'),
          ],
        ),
      ),
    );
  }
}

// Pantalla que muestra el perfil del usuario logueado
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'pantalla_avatar.dart';

class PantallaPerfil extends StatefulWidget {
  const PantallaPerfil({super.key});

  @override
  State<PantallaPerfil> createState() => _PantallaPerfilState();
}

class _PantallaPerfilState extends State<PantallaPerfil> {
  String email = '';
  int puntosTotales = 0;
  Map<String, int> puntuacionesPorJuego = {};
  String? avatarUrl;

  @override
  void initState() {
    super.initState();
    _cargarDatosUsuario(); // Carga los datos al iniciar la pantalla
  }

  // Calcula el nivel del usuario según los puntos
  int nivelUsuario() => (puntosTotales / 100).floor() + 1;
  // Calcula el porcentaje hacia el siguiente nivel
  double progresoNivel() => (puntosTotales % 100) / 100;

  // Carga desde Firestore los datos del usuario actual y sus puntuaciones
  Future<void> _cargarDatosUsuario() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final uid = user.uid;
    final usuarioDoc =
        await FirebaseFirestore.instance.collection('usuarios').doc(uid).get();

    if (usuarioDoc.exists) {
      setState(() {
        email = usuarioDoc.data()?['email'] ?? 'Desconocido';
        puntosTotales = usuarioDoc.data()?['puntos'] ?? 0;
        avatarUrl = usuarioDoc.data()?['fotoPerfil'];
      });
    }

    // Carga las mejores puntuaciones por minijuego desde la colección 'puntuaciones'
    final puntuacionesSnapshot =
        await FirebaseFirestore.instance
            .collection('puntuaciones')
            .where('email', isEqualTo: user.email)
            .get();

    final mapa = <String, int>{};
    for (var doc in puntuacionesSnapshot.docs) {
      final datos = doc.data();
      final juego = datos['juego'] ?? 'desconocido';
      final puntos = datos['puntos'] ?? 0;
      mapa[juego] = puntos;
    }

    setState(() {
      puntuacionesPorJuego = mapa;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('👤 Perfil de Usuario'),
        backgroundColor: const Color.fromARGB(255, 247, 90, 202),
        centerTitle: true,
      ),
      backgroundColor: const Color(0xFFEDE7F6),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: ListView(
          children: [
            // Muestra el avatar si está definido
            if (avatarUrl != null)
              Center(
                child: CircleAvatar(
                  radius: 50,
                  backgroundImage: AssetImage('assets/avatars/$avatarUrl'),
                ),
              ),
            const SizedBox(height: 16),
            Text(
              '📧 Email: $email',
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            Text(
              '🎯 Puntos Totales: $puntosTotales',
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            Text(
              '📶 Nivel: ${nivelUsuario()}',
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            LinearProgressIndicator(
              value: progresoNivel(),
              backgroundColor: Colors.grey[300],
              color: const Color.fromARGB(255, 45, 224, 129),
              minHeight: 8,
            ),
            const SizedBox(height: 4),
            Text(
              '${(progresoNivel() * 100).round()}% hasta el próximo nivel',
              style: const TextStyle(fontSize: 14, color: Colors.black54),
            ),
            const Divider(height: 30),

            // Sección de puntuaciones por minijuego
            const Text(
              '🧩 Mejores puntuaciones por minijuego:',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            if (puntuacionesPorJuego.isEmpty)
              const Text(
                'Aún no has jugado ningún minijuego.',
                style: TextStyle(fontSize: 16, fontStyle: FontStyle.italic),
              )
            else
              ...puntuacionesPorJuego.entries.map((entry) {
                return Text(
                  '• ${entry.key}: ${entry.value} puntos',
                  style: const TextStyle(fontSize: 16),
                );
              }),

            const Divider(height: 30),

            // Sección de logros desbloqueados
            const Text(
              '🏅 Logros desbloqueados:',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            if (puntosTotales > 0)
              const Text(
                '✅ Has conseguido tu primer punto 🧠',
                style: TextStyle(fontSize: 16),
              ),
            if (puntosTotales >= 100)
              const Text(
                '🏆 Has superado los 100 puntos 💯',
                style: TextStyle(fontSize: 16),
              ),
            if (puntuacionesPorJuego.length >= 3)
              const Text(
                '🧩 Has jugado a los 3 minijuegos diferentes 👏',
                style: TextStyle(fontSize: 16),
              ),

            const SizedBox(height: 30),

            // Botón para cambiar avatar
            ElevatedButton.icon(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const PantallaAvatar()),
                );
              },
              icon: const Icon(Icons.image),
              label: const Text('Cambiar avatar'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color.fromARGB(255, 219, 236, 107),
              ),
            ),

            const SizedBox(height: 10),

            // Botón para volver a la pantalla anterior
            ElevatedButton(
              onPressed: () => Navigator.pop(context),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.deepPurple,
              ),
              child: const Text(
                'Volver',
                style: TextStyle(color: Colors.white),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class PantallaRanking extends StatelessWidget {
  const PantallaRanking({super.key});

  Future<List<Map<String, dynamic>>> _obtenerRanking() async {
    final snapshot =
        await FirebaseFirestore.instance
            .collection('usuarios')
            .where('puntos', isGreaterThan: 0)
            .orderBy('puntos', descending: true)
            .limit(10)
            .get();

    return snapshot.docs.map((doc) {
      return {
        'nombre': doc.data()['nombre'] ?? 'Sin nombre',
        'email': doc.data()['email'] ?? 'Sin email',
        'puntos': doc.data()['puntos'] ?? 0,
        'fotoPerfil': doc.data()['fotoPerfil'],
      };
    }).toList();
  }

  String _medalla(int index) {
    switch (index) {
      case 0:
        return '🥇';
      case 1:
        return '🥈';
      case 2:
        return '🥉';
      default:
        return '${index + 1}.';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('🏆 Ranking de Usuarios'),
        backgroundColor: Colors.indigo,
        centerTitle: true,
      ),
      backgroundColor: const Color(0xFFE8EAF6),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: _obtenerRanking(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(
              child: Text(
                'No hay usuarios con puntuaciones todavía.',
                style: TextStyle(fontSize: 18, fontStyle: FontStyle.italic),
              ),
            );
          }

          final ranking = snapshot.data!;

          return Column(
            children: [
              Expanded(
                child: ListView.builder(
                  itemCount: ranking.length,
                  itemBuilder: (context, index) {
                    final usuario = ranking[index];
                    final medalla = _medalla(index);

                    return ListTile(
                      leading:
                          usuario['fotoPerfil'] != null
                              ? CircleAvatar(
                                backgroundImage: AssetImage(
                                  'assets/avatars/${usuario['fotoPerfil']}',
                                ),
                              )
                              : CircleAvatar(
                                backgroundColor: Colors.indigo,
                                child: Text(
                                  medalla,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 16,
                                  ),
                                ),
                              ),
                      title: Text(
                        usuario['nombre'],
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      subtitle: Text(usuario['email']),
                      trailing: Text(
                        '${usuario['puntos']} pts',
                        style: const TextStyle(fontSize: 16),
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 20),
              ElevatedButton.icon(
                onPressed: () => Navigator.pop(context),
                icon: const Icon(Icons.arrow_back),
                label: const Text('Volver'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.indigo,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 12,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
              const SizedBox(height: 20),
            ],
          );
        },
      ),
    );
  }
}

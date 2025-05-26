import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

/// Guarda la mejor puntuación en la colección `puntuaciones`
/// y actualiza el total acumulado en la colección `usuarios`.
Future<void> guardarPuntuacion(String juego, int nuevaPuntuacion) async {
  final user = FirebaseAuth.instance.currentUser;
  if (user == null) return;

  final uid = user.uid;

  final docRef = FirebaseFirestore.instance
      .collection('puntuaciones')
      .doc('${uid}_$juego');

  final doc = await docRef.get();
  int puntosAnteriores = 0;

  if (doc.exists) {
    final datos = doc.data();
    puntosAnteriores = datos?['puntos'] ?? 0;

    if (nuevaPuntuacion > puntosAnteriores) {
      await docRef.set({
        'email': user.email,
        'juego': juego,
        'puntos': nuevaPuntuacion,
        'fecha': FieldValue.serverTimestamp(),
      });
    } else {
      return;
    }
  } else {
    await docRef.set({
      'email': user.email,
      'juego': juego,
      'puntos': nuevaPuntuacion,
      'fecha': FieldValue.serverTimestamp(),
    });
  }

  // Actualiza el total acumulado en la colección `usuarios`
  final userRef = FirebaseFirestore.instance.collection('usuarios').doc(uid);
  final userDoc = await userRef.get();

  final puntosActuales = (userDoc.data()?['puntos'] ?? 0) as int;
  final puntosTotales = puntosActuales - puntosAnteriores + nuevaPuntuacion;

  await userRef.update({'puntos': puntosTotales});
}

/// Devuelve la mejor puntuación guardada de un minijuego
Future<Map<String, dynamic>?> getPuntuacion(String uid, String juego) async {
  try {
    final doc =
        await FirebaseFirestore.instance
            .collection('puntuaciones')
            .doc('${uid}_$juego')
            .get();

    return doc.exists ? doc.data() : null;
  } catch (e) {
    print('Error al obtener puntuación: $e');
    return null;
  }
}

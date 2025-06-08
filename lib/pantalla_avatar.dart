// Pantalla para que el usuario elija un avatar de perfil
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class PantallaAvatar extends StatefulWidget {
  const PantallaAvatar({super.key});

  @override
  State<PantallaAvatar> createState() => _PantallaAvatarState();
}

class _PantallaAvatarState extends State<PantallaAvatar> {
  // Lista de nombres de archivos de avatar disponibles
  final List<String> _avatares = [
    'avatar1.png',
    'avatar2.png',
    'avatar3.png',
    'avatar4.jpg',
    'avatar5.jpg',
    'avatar6.jpg',
    'avatar7.jpg',
    'avatar8.jpg',
  ];

  String? _seleccionado; // Avatar seleccionado actualmente
  bool _guardando = false; // Indica si se está guardando el cambio

  // Guarda el avatar seleccionado en Firestore
  Future<void> _guardarAvatar(String avatar) async {
    setState(() => _guardando = true);
    final uid = FirebaseAuth.instance.currentUser?.uid;

    if (uid != null) {
      // Actualiza el campo 'fotoPerfil' en el documento del usuario
      await FirebaseFirestore.instance.collection('usuarios').doc(uid).update({
        'fotoPerfil': avatar,
      });

      setState(() {
        _seleccionado = avatar;
        _guardando = false;
      });

      if (mounted) {
        // Muestra mensaje de éxito y vuelve atrás
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('✅ Avatar actualizado: $avatar')),
        );
        Navigator.pop(context); // Regresa a la pantalla anterior
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Elige tu avatar'),
        backgroundColor: Colors.indigo,
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child:
            _guardando
                ? const Center(
                  child: CircularProgressIndicator(),
                ) // Muestra carga si está guardando
                : GridView.count(
                  crossAxisCount: 2,
                  crossAxisSpacing: 10,
                  mainAxisSpacing: 10,
                  children:
                      _avatares.map((avatar) {
                        final isSelected = _seleccionado == avatar;
                        return GestureDetector(
                          onTap:
                              () =>
                                  _guardarAvatar(avatar), // Al tocar se guarda
                          child: Container(
                            decoration: BoxDecoration(
                              border: Border.all(
                                color: isSelected ? Colors.green : Colors.grey,
                                width: 3,
                              ),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(10),
                              child: Image.asset(
                                'assets/avatars/$avatar',
                                fit: BoxFit.cover,
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                ),
      ),
    );
  }
}

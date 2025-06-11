import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class PantallaAvatar extends StatefulWidget {
  const PantallaAvatar({super.key});

  @override
  State<PantallaAvatar> createState() => _PantallaAvatarState();
}

class _PantallaAvatarState extends State<PantallaAvatar> {
  final List<String> _avatares = [
    'avatar1.png',
    'avatar2.png',
    'avatar3.png',
    'avatar4.jpg',
    'avatar5.png',
    'avatar6.jpg',
    'avatar7.png',
    'avatar8.jpg',
  ];

  String? _seleccionado;
  bool _guardando = false;

  Future<void> _guardarAvatar(String avatar) async {
    setState(() => _guardando = true);
    final uid = FirebaseAuth.instance.currentUser?.uid;

    if (uid != null) {
      await FirebaseFirestore.instance.collection('usuarios').doc(uid).update({
        'fotoPerfil': avatar,
      });

      setState(() {
        _seleccionado = avatar;
        _guardando = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('✅ Avatar actualizado: $avatar')),
        );

        Navigator.pop(context);
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
                ? const Center(child: CircularProgressIndicator())
                : LayoutBuilder(
                  builder: (context, constraints) {
                    // Responsive: ajusta número de columnas según el ancho
                    final ancho = constraints.maxWidth;
                    final columnas =
                        ancho > 1000
                            ? 5
                            : ancho > 700
                            ? 4
                            : 2;

                    return GridView.builder(
                      itemCount: _avatares.length,
                      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: columnas,
                        crossAxisSpacing: 10,
                        mainAxisSpacing: 10,
                        childAspectRatio: 1,
                      ),
                      itemBuilder: (context, index) {
                        final avatar = _avatares[index];
                        final isSelected = _seleccionado == avatar;

                        return GestureDetector(
                          onTap: () => _guardarAvatar(avatar),
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
                              child: AspectRatio(
                                aspectRatio: 1,
                                child: Image.asset(
                                  'assets/avatars/$avatar',
                                  fit: BoxFit.cover,
                                  errorBuilder: (context, error, stackTrace) {
                                    return const Center(
                                      child: Icon(Icons.broken_image, size: 40),
                                    );
                                  },
                                ),
                              ),
                            ),
                          ),
                        );
                      },
                    );
                  },
                ),
      ),
    );
  }
}

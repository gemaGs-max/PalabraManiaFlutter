// ignore_for_file: use_build_context_synchronously

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

class PantallaAdmin extends StatefulWidget {
  const PantallaAdmin({super.key});

  @override
  State<PantallaAdmin> createState() => _PantallaAdminState();
}

class _PantallaAdminState extends State<PantallaAdmin> {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  String _busqueda = '';
  String _rolSeleccionado = 'Todos';

  int totalUsuarios = 0;
  int totalAdmins = 0;
  int totalNormales = 0;

  void _mostrarFormulario({DocumentSnapshot? usuarioExistente}) {
    final nombreCtrl = TextEditingController(
      text: usuarioExistente?['nombre'] ?? '',
    );
    final apellidosCtrl = TextEditingController(
      text: usuarioExistente?['apellidos'] ?? '',
    );
    final telefonoCtrl = TextEditingController(
      text: usuarioExistente?['telefono'] ?? '',
    );
    final emailCtrl = TextEditingController(
      text: usuarioExistente?['email'] ?? '',
    );
    final passCtrl = TextEditingController();
    String rol = usuarioExistente?['rol'] ?? 'usuario';

    showDialog(
      context: context,
      builder:
          (_) => StatefulBuilder(
            // Uso StatefulBuilder para permitir setState local dentro del diálogo
            builder: (contextDialog, setStateDialog) {
              return AlertDialog(
                title: Text(
                  usuarioExistente == null
                      ? 'Añadir Usuario'
                      : 'Editar Usuario',
                ),
                content: SingleChildScrollView(
                  child: Column(
                    children: [
                      TextField(
                        controller: nombreCtrl,
                        decoration: const InputDecoration(labelText: 'Nombre'),
                      ),
                      TextField(
                        controller: apellidosCtrl,
                        decoration: const InputDecoration(
                          labelText: 'Apellidos',
                        ),
                      ),
                      TextField(
                        controller: telefonoCtrl,
                        decoration: const InputDecoration(
                          labelText: 'Teléfono',
                        ),
                      ),
                      TextField(
                        controller: emailCtrl,
                        decoration: const InputDecoration(labelText: 'Email'),
                      ),
                      if (usuarioExistente == null)
                        TextField(
                          controller: passCtrl,
                          obscureText: true,
                          decoration: const InputDecoration(
                            labelText: 'Contraseña',
                          ),
                        ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          const Text(
                            'Rol:',
                            style: TextStyle(fontWeight: FontWeight.w500),
                          ),
                          const SizedBox(width: 16),
                          DropdownButton<String>(
                            value: rol,
                            onChanged: (value) {
                              setStateDialog(() {
                                rol = value ?? 'usuario';
                              });
                            },
                            items: const [
                              DropdownMenuItem(
                                value: 'usuario',
                                child: Text('Usuario'),
                              ),
                              DropdownMenuItem(
                                value: 'administrador',
                                child: Text('Administrador'),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                actions: [
                  // 1) Botón para enviar el mail de restablecimiento de contraseña
                  if (usuarioExistente != null)
                    TextButton(
                      onPressed: () async {
                        final email = emailCtrl.text.trim();
                        try {
                          await FirebaseAuth.instance.sendPasswordResetEmail(
                            email: email,
                          );
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text(
                                '✅ Email de restablecimiento enviado',
                              ),
                            ),
                          );
                        } on FirebaseAuthException catch (e) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('⚠️ Error: ${e.message}')),
                          );
                        }
                        Navigator.of(contextDialog).pop();
                      },
                      child: const Text('Resetear contraseña'),
                    ),

                  // 2) Botón “Cancelar”
                  TextButton(
                    onPressed: () => Navigator.of(contextDialog).pop(),
                    child: const Text('Cancelar'),
                  ),

                  // 3) Botón “Guardar”
                  ElevatedButton(
                    onPressed: () async {
                      final nombre = nombreCtrl.text.trim();
                      final apellidos = apellidosCtrl.text.trim();
                      final telefono = telefonoCtrl.text.trim();
                      final email = emailCtrl.text.trim();
                      final password = passCtrl.text.trim();

                      if (usuarioExistente == null) {
                        // Modo “Añadir Usuario”
                        if (email.isEmpty ||
                            password.length < 6 ||
                            nombre.isEmpty) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text(
                                '⚠️ Email, contraseña (mín.6) y nombre son obligatorios',
                              ),
                            ),
                          );
                          return;
                        }
                        try {
                          final cred = await FirebaseAuth.instance
                              .createUserWithEmailAndPassword(
                                email: email,
                                password: password,
                              );
                          await _db
                              .collection('usuarios')
                              .doc(cred.user!.uid)
                              .set({
                                'nombre': nombre,
                                'apellidos': apellidos,
                                'telefono': telefono,
                                'email': email,
                                'rol': rol,
                                'puntos': 0,
                              });
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('✅ Usuario creado correctamente'),
                            ),
                          );
                        } on FirebaseAuthException catch (e) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('⚠️ Error: ${e.message}')),
                          );
                          return;
                        }
                      } else {
                        // Modo “Editar Usuario”
                        await _db
                            .collection('usuarios')
                            .doc(usuarioExistente.id)
                            .update({
                              'nombre': nombre,
                              'apellidos': apellidos,
                              'telefono': telefono,
                              'email': email,
                              'rol': rol,
                            });
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('✅ Usuario actualizado'),
                          ),
                        );
                      }

                      Navigator.of(contextDialog).pop();
                      setState(() {});
                    },
                    child: const Text('Guardar'),
                  ),
                ],
              );
            },
          ),
    );
  }

  void _eliminarUsuario(String id) {
    showDialog(
      context: context,
      builder:
          (_) => AlertDialog(
            title: const Text('¿Eliminar usuario?'),
            content: const Text('Esta acción no se puede deshacer.'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancelar'),
              ),
              TextButton(
                onPressed: () async {
                  await _db.collection('usuarios').doc(id).delete();
                  Navigator.pop(context);
                  setState(() {});
                },
                child: const Text(
                  'Eliminar',
                  style: TextStyle(color: Colors.red),
                ),
              ),
            ],
          ),
    );
  }

  Future<void> _exportarCSV(List<QueryDocumentSnapshot> docs) async {
    final buffer = StringBuffer();
    buffer.writeln('Nombre,Apellidos,Email,Teléfono,Rol,Puntos');

    for (var doc in docs) {
      final data = doc.data() as Map<String, dynamic>?;
      if (data == null) continue;

      final nombre = data['nombre'] ?? '';
      final apellidos = data['apellidos'] ?? '';
      final email = data['email'] ?? '';
      final telefono = data['telefono'] ?? '';
      final rol = data['rol'] ?? '';
      final puntos = data['puntos'] ?? data['puntosTotales'] ?? '0';

      buffer.writeln('$nombre,$apellidos,$email,$telefono,$rol,$puntos');
    }

    final dir = await getApplicationDocumentsDirectory();
    final file = File('${dir.path}/usuarios_exportados.csv');
    await file.writeAsString(buffer.toString());

    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('✅ Archivo exportado correctamente')),
    );

    await Share.shareXFiles([
      XFile(file.path),
    ], text: 'Usuarios exportados desde PalabraManía');
  }

  Future<void> _exportarTop10RankingCSV() async {
    final snapshot =
        await _db
            .collection('usuarios')
            .orderBy('puntos', descending: true)
            .limit(10)
            .get();

    final buffer = StringBuffer();
    buffer.writeln('Ranking,Nombre,Apellidos,Email,Puntos');

    for (int i = 0; i < snapshot.docs.length; i++) {
      final data = snapshot.docs[i].data() as Map<String, dynamic>? ?? {};
      final nombre = data['nombre'] ?? '';
      final apellidos = data['apellidos'] ?? '';
      final email = data['email'] ?? '';
      final puntos = data['puntos'] ?? data['puntosTotales'] ?? '0';

      buffer.writeln('${i + 1},$nombre,$apellidos,$email,$puntos');
    }

    final dir = await getApplicationDocumentsDirectory();
    final file = File('${dir.path}/top10_ranking_palabramania.csv');
    await file.writeAsString(buffer.toString());

    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('✅ Top 10 exportado correctamente')),
    );

    await Share.shareXFiles([
      XFile(file.path),
    ], text: 'Top 10 usuarios PalabraManía');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF1F8E9),
      appBar: AppBar(
        title: const Text('Panel de Administrador'),
        backgroundColor: Colors.deepOrangeAccent,
        actions: [
          IconButton(
            icon: const Icon(Icons.download),
            tooltip: 'Exportar CSV',
            onPressed: () async {
              final snapshot = await _db.collection('usuarios').get();
              await _exportarCSV(snapshot.docs);
            },
          ),
          IconButton(
            icon: const Icon(Icons.emoji_events),
            tooltip: 'Exportar TOP 10',
            onPressed: () async => await _exportarTop10RankingCSV(),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _mostrarFormulario(),
        backgroundColor: Colors.deepOrange,
        child: const Icon(Icons.add),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12.0),
            child: Row(
              children: [
                Expanded(
                  flex: 3,
                  child: TextField(
                    decoration: const InputDecoration(
                      hintText: 'Buscar por nombre, apellidos o email...',
                      prefixIcon: Icon(Icons.search),
                      border: OutlineInputBorder(),
                      filled: true,
                      fillColor: Colors.white,
                    ),
                    onChanged:
                        (value) =>
                            setState(() => _busqueda = value.toLowerCase()),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  flex: 2,
                  child: DropdownButtonFormField<String>(
                    decoration: const InputDecoration(
                      border: OutlineInputBorder(),
                      filled: true,
                      fillColor: Colors.white,
                      labelText: 'Filtrar por rol',
                    ),
                    value: _rolSeleccionado,
                    items: const [
                      DropdownMenuItem(value: 'Todos', child: Text('Todos')),
                      DropdownMenuItem(
                        value: 'usuario',
                        child: Text('Usuarios'),
                      ),
                      DropdownMenuItem(
                        value: 'administrador',
                        child: Text('Administradores'),
                      ),
                    ],
                    onChanged:
                        (value) =>
                            setState(() => _rolSeleccionado = value ?? 'Todos'),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: _db.collection('usuarios').snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData)
                  return const Center(child: CircularProgressIndicator());

                final docs =
                    snapshot.data!.docs.where((doc) {
                      final data = doc.data() as Map<String, dynamic>?;
                      if (data == null ||
                          data['email'] == null ||
                          data['rol'] == null)
                        return false;

                      final nombre =
                          (data['nombre'] ?? '').toString().toLowerCase();
                      final apellidos =
                          (data['apellidos'] ?? '').toString().toLowerCase();
                      final email =
                          (data['email'] ?? '').toString().toLowerCase();
                      final rol = data['rol'];

                      final coincideBusqueda =
                          nombre.contains(_busqueda) ||
                          apellidos.contains(_busqueda) ||
                          email.contains(_busqueda);
                      final coincideRol =
                          _rolSeleccionado == 'Todos' ||
                          rol == _rolSeleccionado;

                      return coincideBusqueda && coincideRol;
                    }).toList();

                totalUsuarios = docs.length;
                totalAdmins =
                    docs
                        .where(
                          (d) => (d.data() as Map)['rol'] == 'administrador',
                        )
                        .length;
                totalNormales =
                    docs
                        .where((d) => (d.data() as Map)['rol'] == 'usuario')
                        .length;

                return Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(
                        left: 16,
                        right: 16,
                        bottom: 4,
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('Total: $totalUsuarios usuarios'),
                          Text(
                            'Administradores: $totalAdmins | Usuarios: $totalNormales',
                          ),
                        ],
                      ),
                    ),
                    Expanded(
                      child: ListView.builder(
                        padding: const EdgeInsets.all(12),
                        itemCount: docs.length,
                        itemBuilder: (context, index) {
                          final data =
                              docs[index].data() as Map<String, dynamic>?;
                          if (data == null ||
                              data['email'] == null ||
                              data['rol'] == null) {
                            return const SizedBox.shrink();
                          }

                          final nombre = data['nombre'] ?? '';
                          final apellidos = data['apellidos'] ?? '';
                          final nombreCompleto = '$nombre $apellidos'.trim();
                          final rol = data['rol'];
                          final email = data['email'] ?? 'Sin email';
                          final telefono = data['telefono'] ?? 'Sin teléfono';

                          if (nombre.isEmpty &&
                              apellidos.isEmpty &&
                              email.isEmpty) {
                            return const SizedBox.shrink();
                          }

                          return Card(
                            color:
                                rol == 'administrador'
                                    ? Colors.orange[100]
                                    : Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            elevation: 3,
                            margin: const EdgeInsets.symmetric(vertical: 6),
                            child: ListTile(
                              title: Text(
                                nombreCompleto.isEmpty
                                    ? 'Usuario sin nombre'
                                    : nombreCompleto,
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
                              subtitle: Padding(
                                padding: const EdgeInsets.only(top: 6),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text('Email: $email'),
                                    Text('Teléfono: $telefono'),
                                    Text('Rol: $rol'),
                                  ],
                                ),
                              ),
                              trailing: Wrap(
                                spacing: 4,
                                children: [
                                  IconButton(
                                    icon: const Icon(
                                      Icons.edit,
                                      color: Colors.blueAccent,
                                    ),
                                    onPressed:
                                        () => _mostrarFormulario(
                                          usuarioExistente: docs[index],
                                        ),
                                  ),
                                  IconButton(
                                    icon: const Icon(
                                      Icons.delete,
                                      color: Colors.red,
                                    ),
                                    onPressed:
                                        () => _eliminarUsuario(docs[index].id),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

// pantalla_admin.dart
// Pantalla de administrador con CRUD, validación de teléfono, exportación y manejo de errores en Flutter Web

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'dart:convert';
import 'dart:html' as html;

class PantallaAdmin extends StatefulWidget {
  const PantallaAdmin({super.key});

  @override
  State<PantallaAdmin> createState() => _PantallaAdminState();
}

class _PantallaAdminState extends State<PantallaAdmin> {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  String _busqueda = '';
  String _rolSeleccionado = 'Todos';

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
          (_) => AlertDialog(
            title: Text(
              usuarioExistente == null ? 'Añadir Usuario' : 'Editar Usuario',
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
                    decoration: const InputDecoration(labelText: 'Apellidos'),
                  ),
                  TextField(
                    controller: telefonoCtrl,
                    decoration: const InputDecoration(labelText: 'Teléfono'),
                    keyboardType: TextInputType.phone,
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
                  DropdownButtonFormField<String>(
                    value: rol,
                    decoration: const InputDecoration(labelText: 'Rol'),
                    onChanged:
                        (value) => setState(() => rol = value ?? 'usuario'),
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
            ),
            actions: [
              if (usuarioExistente != null)
                TextButton(
                  onPressed: () async {
                    try {
                      await FirebaseAuth.instance.sendPasswordResetEmail(
                        email: emailCtrl.text.trim(),
                      );
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('✅ Email de restablecimiento enviado'),
                        ),
                      );
                    } catch (e) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('❌ Error: ${e.toString()}')),
                      );
                    }
                    Navigator.of(context).pop();
                  },
                  child: const Text('Restablecer contraseña'),
                ),
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancelar'),
              ),
              ElevatedButton(
                onPressed: () async {
                  final nombre = nombreCtrl.text.trim();
                  final apellidos = apellidosCtrl.text.trim();
                  final telefono = telefonoCtrl.text.replaceAll(
                    RegExp(r'\s+'),
                    '',
                  );
                  final email = emailCtrl.text.trim();
                  final password = passCtrl.text.trim();

                  // Validación del teléfono: debe tener exactamente 9 dígitos numéricos
                  if (!RegExp(r'^\d{9}$').hasMatch(telefono)) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text(
                          '⚠️ El teléfono debe tener exactamente 9 dígitos.',
                        ),
                      ),
                    );
                    return;
                  }

                  if (usuarioExistente == null) {
                    // Validaciones básicas
                    if (email.isEmpty ||
                        password.length < 6 ||
                        nombre.isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text(
                            '⚠️ Email, contraseña (mín. 6) y nombre son obligatorios.',
                          ),
                        ),
                      );
                      return;
                    }

                    try {
                      // Crear usuario con Firebase Auth
                      final cred = await FirebaseAuth.instance
                          .createUserWithEmailAndPassword(
                            email: email,
                            password: password,
                          );
                      // Guardar datos en Firestore
                      await _db.collection('usuarios').doc(cred.user!.uid).set({
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
                      String mensaje = '❌ Error desconocido';
                      if (e.code == 'email-already-in-use')
                        mensaje = '⚠️ El correo ya está en uso.';
                      else if (e.code == 'invalid-email')
                        mensaje = '⚠️ El correo no es válido.';
                      else if (e.code == 'weak-password')
                        mensaje = '⚠️ La contraseña es demasiado débil.';
                      else
                        mensaje = '❌ Error: ${e.message}';
                      ScaffoldMessenger.of(
                        context,
                      ).showSnackBar(SnackBar(content: Text(mensaje)));
                    } catch (e) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('❌ Error: ${e.toString()}')),
                      );
                    }
                  } else {
                    // Actualizar usuario existente
                    try {
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
                          content: Text('✅ Usuario actualizado correctamente'),
                        ),
                      );
                    } catch (e) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('❌ Error: ${e.toString()}')),
                      );
                    }
                  }

                  Navigator.pop(context);
                  setState(() {});
                },
                child: const Text('Guardar'),
              ),
            ],
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
                  try {
                    await _db.collection('usuarios').doc(id).delete();
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('✅ Usuario eliminado')),
                    );
                  } catch (e) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('❌ Error: ${e.toString()}')),
                    );
                  }
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
      final data = doc.data() as Map<String, dynamic>? ?? {};
      final nombre = data['nombre'] ?? '';
      final apellidos = data['apellidos'] ?? '';
      final email = data['email'] ?? '';
      final telefono = data['telefono'] ?? '';
      final rol = data['rol'] ?? '';
      final puntos = data['puntos'] ?? data['puntosTotales'] ?? '0';
      buffer.writeln('$nombre,$apellidos,$email,$telefono,$rol,$puntos');
    }
    final blob = html.Blob([utf8.encode(buffer.toString())]);
    final url = html.Url.createObjectUrlFromBlob(blob);
    html.AnchorElement(href: url)
      ..setAttribute('download', 'usuarios_exportados.csv')
      ..click();
    html.Url.revokeObjectUrl(url);
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
    final blob = html.Blob([utf8.encode(buffer.toString())]);
    final url = html.Url.createObjectUrlFromBlob(blob);
    html.AnchorElement(href: url)
      ..setAttribute('download', 'top10_ranking.csv')
      ..click();
    html.Url.revokeObjectUrl(url);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
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
            onPressed: _exportarTop10RankingCSV,
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
                      final data = doc.data() as Map<String, dynamic>? ?? {};
                      final email =
                          data['email']?.toString().toLowerCase() ?? '';
                      final nombre =
                          data['nombre']?.toString().toLowerCase() ?? '';
                      final apellidos =
                          data['apellidos']?.toString().toLowerCase() ?? '';
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

                return ListView.builder(
                  padding: const EdgeInsets.all(12),
                  itemCount: docs.length,
                  itemBuilder: (context, index) {
                    final data = docs[index].data() as Map<String, dynamic>;
                    final nombre = data['nombre'] ?? '';
                    final apellidos = data['apellidos'] ?? '';
                    final email = data['email'] ?? '';
                    final telefono = data['telefono'] ?? '';
                    final rol = data['rol'] ?? '';
                    return Card(
                      color:
                          rol == 'administrador'
                              ? Colors.orange.shade100
                              : null,
                      margin: const EdgeInsets.symmetric(vertical: 6),
                      child: ListTile(
                        title: Text(
                          '$nombre $apellidos',
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Email: $email'),
                            Text('Teléfono: $telefono'),
                            Text('Rol: $rol'),
                          ],
                        ),
                        trailing: Wrap(
                          spacing: 4,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.edit, color: Colors.blue),
                              onPressed:
                                  () => _mostrarFormulario(
                                    usuarioExistente: docs[index],
                                  ),
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete, color: Colors.red),
                              onPressed: () => _eliminarUsuario(docs[index].id),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

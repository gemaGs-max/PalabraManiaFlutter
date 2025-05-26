import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'pantalla_juegos.dart';
import 'pantalla_admin.dart';

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _nombreController = TextEditingController();
  final TextEditingController _apellidosController = TextEditingController();
  final TextEditingController _telefonoController = TextEditingController();

  bool _isLogin = true;
  bool _isLoading = false;
  String _error = '';

  String traducirError(String code) {
    switch (code) {
      case 'invalid-email':
        return 'El correo electrónico no es válido.';
      case 'user-not-found':
        return 'No se encontró ningún usuario con ese correo.';
      case 'wrong-password':
        return 'La contraseña es incorrecta.';
      case 'email-already-in-use':
        return 'Este correo ya está registrado.';
      case 'weak-password':
        return 'La contraseña es demasiado débil.';
      default:
        return 'Ha ocurrido un error. Intenta de nuevo.';
    }
  }

  Future<void> _submit() async {
    final auth = FirebaseAuth.instance;

    setState(() {
      _isLoading = true;
      _error = '';
    });

    try {
      if (_nombreController.text.trim().isEmpty ||
          _emailController.text.trim().isEmpty ||
          _passwordController.text.trim().isEmpty ||
          (!_isLogin &&
              (_apellidosController.text.trim().isEmpty ||
                  _telefonoController.text.trim().isEmpty))) {
        setState(() {
          _error = 'Por favor, rellena todos los campos obligatorios.';
          _isLoading = false;
        });
        return;
      }

      if (!_emailController.text.contains('@')) {
        setState(() {
          _error = 'El correo debe tener un formato válido.';
          _isLoading = false;
        });
        return;
      }

      if (_passwordController.text.length < 6) {
        setState(() {
          _error = 'La contraseña debe tener al menos 6 caracteres.';
          _isLoading = false;
        });
        return;
      }

      UserCredential userCredential;

      if (_isLogin) {
        userCredential = await auth.signInWithEmailAndPassword(
          email: _emailController.text.trim(),
          password: _passwordController.text.trim(),
        );

        final doc =
            await FirebaseFirestore.instance
                .collection('usuarios')
                .doc(userCredential.user!.uid)
                .get();

        if (!doc.exists) {
          setState(() {
            _error = 'No se encontraron datos del usuario en Firestore.';
            _isLoading = false;
          });
          return;
        }

        final nombreGuardado =
            doc.data()?['nombre']?.toString().toLowerCase() ?? '';
        final nombreIngresado = _nombreController.text.trim().toLowerCase();

        if (nombreGuardado != nombreIngresado) {
          setState(() {
            _error = 'El nombre no coincide con el registrado.';
            _isLoading = false;
          });
          return;
        }

        // Si no tiene campo puntos, lo actualizamos
        if (!doc.data()!.containsKey('puntos')) {
          await FirebaseFirestore.instance
              .collection('usuarios')
              .doc(userCredential.user!.uid)
              .update({'puntos': 0});
        }
      } else {
        userCredential = await auth.createUserWithEmailAndPassword(
          email: _emailController.text.trim(),
          password: _passwordController.text.trim(),
        );

        await FirebaseFirestore.instance
            .collection('usuarios')
            .doc(userCredential.user!.uid)
            .set({
              'nombre': _nombreController.text.trim(),
              'apellidos': _apellidosController.text.trim(),
              'telefono': _telefonoController.text.trim(),
              'email': _emailController.text.trim(),
              'puntos': 0,
              'rol': 'usuario',
              'creado': Timestamp.now(),
            });
      }

      final doc =
          await FirebaseFirestore.instance
              .collection('usuarios')
              .doc(userCredential.user!.uid)
              .get();

      final data = doc.data();
      final rol = data?['rol'] ?? 'usuario';

      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('nombre_usuario', data?['nombre'] ?? '');

      await Future.delayed(const Duration(milliseconds: 300));

      if (rol == 'administrador') {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const PantallaAdmin()),
        );
      } else {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => PantallaJuegos()),
        );
      }
    } on FirebaseAuthException catch (e) {
      setState(() {
        _error = traducirError(e.code);
      });
    } catch (e) {
      setState(() {
        _error = 'Error inesperado: ${e.toString()}';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFF8E1),
      appBar: AppBar(
        title: Text(_isLogin ? 'Iniciar Sesión' : 'Crear Cuenta'),
        backgroundColor: Colors.deepOrangeAccent,
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Center(
          child: SingleChildScrollView(
            child: Column(
              children: [
                if (_error.isNotEmpty)
                  Text(_error, style: const TextStyle(color: Colors.red)),

                TextField(
                  controller: _nombreController,
                  decoration: const InputDecoration(labelText: 'Nombre *'),
                ),
                const SizedBox(height: 10),

                if (!_isLogin) ...[
                  TextField(
                    controller: _apellidosController,
                    decoration: const InputDecoration(labelText: 'Apellidos *'),
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: _telefonoController,
                    decoration: const InputDecoration(labelText: 'Teléfono *'),
                    keyboardType: TextInputType.phone,
                  ),
                  const SizedBox(height: 10),
                ],

                TextField(
                  controller: _emailController,
                  decoration: const InputDecoration(
                    labelText: 'Correo electrónico *',
                  ),
                  keyboardType: TextInputType.emailAddress,
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: _passwordController,
                  decoration: const InputDecoration(labelText: 'Contraseña *'),
                  obscureText: true,
                ),
                const SizedBox(height: 30),

                if (_isLoading)
                  const CircularProgressIndicator()
                else
                  ElevatedButton(
                    onPressed: _submit,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.deepOrangeAccent,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 30,
                        vertical: 15,
                      ),
                    ),
                    child: Text(
                      _isLogin ? 'Entrar' : 'Registrarse',
                      style: const TextStyle(color: Colors.white),
                    ),
                  ),

                TextButton(
                  onPressed: () {
                    setState(() {
                      _isLogin = !_isLogin;
                      _error = '';
                    });
                  },
                  child: Text(
                    _isLogin
                        ? '¿No tienes cuenta? Regístrate'
                        : '¿Ya tienes cuenta? Inicia sesión',
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

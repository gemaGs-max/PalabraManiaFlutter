import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'pantalla_juegos.dart';
import 'pantalla_admin.dart';

/// Pantalla de autenticación para iniciar sesión o registrar cuenta
class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  // Controladores para los campos de texto del formulario
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _nombreController = TextEditingController();
  final TextEditingController _apellidosController = TextEditingController();
  final TextEditingController _telefonoController = TextEditingController();

  bool _isLogin =
      true; // Indica si estamos en modo "Iniciar sesión" o "Registrar"
  bool _isLoading =
      false; // Indica si estamos esperando la respuesta del servidor
  String _error = ''; // Mensaje de error a mostrar al usuario

  /// Traduce códigos de error de FirebaseAuth a mensajes en español
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

  /// Método que se ejecuta al pulsar el botón "Entrar" o "Registrarse"
  Future<void> _submit() async {
    final auth = FirebaseAuth.instance;

    // Se activa el indicador de carga y se limpia cualquier error previo
    setState(() {
      _isLoading = true;
      _error = '';
    });

    try {
      // Validaciones básicas de campos vacíos
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

      // Validación de formato de correo
      if (!_emailController.text.contains('@')) {
        setState(() {
          _error = 'El correo debe tener un formato válido.';
          _isLoading = false;
        });
        return;
      }

      // Validación de longitud mínima de contraseña
      if (_passwordController.text.length < 6) {
        setState(() {
          _error = 'La contraseña debe tener al menos 6 caracteres.';
          _isLoading = false;
        });
        return;
      }

      late UserCredential userCredential;

      if (_isLogin) {
        // ----- MODO INICIAR SESIÓN -----
        userCredential = await auth.signInWithEmailAndPassword(
          email: _emailController.text.trim(),
          password: _passwordController.text.trim(),
        );

        // Obtiene el documento del usuario desde Firestore
        final doc =
            await FirebaseFirestore.instance
                .collection('usuarios')
                .doc(userCredential.user!.uid)
                .get();

        // Si no existe información del usuario en Firestore, mostramos error
        if (!doc.exists) {
          setState(() {
            _error = 'No se encontraron datos del usuario en Firestore.';
            _isLoading = false;
          });
          return;
        }

        // Validamos que el nombre ingresado coincida con el almacenado en Firestore
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

        // Si el documento no contiene la clave 'puntos', la inicializamos a 0
        if (!doc.data()!.containsKey('puntos')) {
          await FirebaseFirestore.instance
              .collection('usuarios')
              .doc(userCredential.user!.uid)
              .update({'puntos': 0});
        }
      } else {
        // ----- MODO REGISTRARSE -----
        // Creamos la cuenta en Firebase Auth
        userCredential = await auth.createUserWithEmailAndPassword(
          email: _emailController.text.trim(),
          password: _passwordController.text.trim(),
        );

        // Guardamos los datos del usuario en Firestore
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

      // Una vez iniciada sesión o registrado, obtenemos de nuevo los datos para leer el rol
      final doc =
          await FirebaseFirestore.instance
              .collection('usuarios')
              .doc(userCredential.user!.uid)
              .get();
      final data = doc.data();
      final rol = data?['rol'] ?? 'usuario';

      // Guardamos el nombre del usuario en SharedPreferences para uso local
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('nombre_usuario', data?['nombre'] ?? '');

      // Pequeña demora para mostrar el indicador de carga
      await Future.delayed(const Duration(milliseconds: 300));

      // Redirigimos según el rol: administrador o usuario normal
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
      // Si FirebaseAuth arroja una excepción, traducimos el código y lo mostramos
      setState(() {
        _error = traducirError(e.code);
      });
    } catch (e) {
      // Cualquier otro error imprevisto
      setState(() {
        _error = 'Error inesperado: ${e.toString()}';
      });
    } finally {
      // Desactivamos el indicador de carga
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
                // Si existe un mensaje de error, lo mostramos en rojo
                if (_error.isNotEmpty)
                  Text(_error, style: const TextStyle(color: Colors.red)),

                // Campo de Nombre (siempre obligatorio)
                TextField(
                  controller: _nombreController,
                  decoration: const InputDecoration(labelText: 'Nombre *'),
                ),
                const SizedBox(height: 10),

                // Si estamos en modo Registro, mostramos campos adicionales
                if (!_isLogin) ...[
                  // Campo de Apellidos
                  TextField(
                    controller: _apellidosController,
                    decoration: const InputDecoration(labelText: 'Apellidos *'),
                  ),
                  const SizedBox(height: 10),
                  // Campo de Teléfono
                  TextField(
                    controller: _telefonoController,
                    decoration: const InputDecoration(labelText: 'Teléfono *'),
                    keyboardType: TextInputType.phone,
                  ),
                  const SizedBox(height: 10),
                ],

                // Campo de Correo electrónico
                TextField(
                  controller: _emailController,
                  decoration: const InputDecoration(
                    labelText: 'Correo electrónico *',
                  ),
                  keyboardType: TextInputType.emailAddress,
                ),
                const SizedBox(height: 10),
                // Campo de Contraseña
                TextField(
                  controller: _passwordController,
                  decoration: const InputDecoration(labelText: 'Contraseña *'),
                  obscureText: true, // Oculta el texto ingresado
                ),
                const SizedBox(height: 30),

                // Si está cargando, mostramos un indicador circular
                if (_isLoading)
                  const CircularProgressIndicator()
                else
                  // Botón de acción (Entrar o Registrarse)
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

                // Enlace para alternar entre Login y Registro
                TextButton(
                  onPressed: () {
                    setState(() {
                      _isLogin = !_isLogin; // Cambiar el modo
                      _error = ''; // Limpiar errores al cambiar
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

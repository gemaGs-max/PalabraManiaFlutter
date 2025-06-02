import 'package:flutter/material.dart';
import 'producto.dart';

/// Página que muestra el contenido del carrito de compras.
/// Recibe un [Map<Producto, int>] con los productos y sus cantidades.
class CarritoPage extends StatefulWidget {
  final Map<Producto, int> carrito;

  const CarritoPage({super.key, required this.carrito});

  @override
  State<CarritoPage> createState() => _CarritoPageState();
}

class _CarritoPageState extends State<CarritoPage> {
  late Map<Producto, int> carritoInterno;

  @override
  void initState() {
    super.initState();
    // Creamos una copia local del carrito pasado por parámetros
    // para no modificar directamente el original que viene de la tienda.
    carritoInterno = Map.from(widget.carrito);
  }

  /// Calcula el total de monedas sumando (precio * cantidad) de cada producto.
  int calcularTotal() {
    int total = 0;
    carritoInterno.forEach((producto, cantidad) {
      total += producto.precio * cantidad;
    });
    return total;
  }

  /// Muestra un diálogo de confirmación cuando el usuario finaliza la compra.
  /// Ofrece la opción de volver a la tienda o volver a la pantalla de juegos.
  void mostrarDialogoFinal() {
    showDialog(
      context: context,
      builder:
          (_) => AlertDialog(
            title: const Text('✅ Compra completada'),
            content: const Text(
              'Gracias por tu compra. ¡Disfruta tus recompensas!',
            ),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.pop(context); // Cierra el diálogo
                  Navigator.pop(
                    context,
                  ); // Regresa a la pantalla anterior (tienda)
                },
                child: const Text('🛒 Volver a tienda'),
              ),
              TextButton(
                onPressed: () {
                  Navigator.pop(context); // Cierra el diálogo
                  Navigator.pop(context); // Regresa a la tienda
                  Navigator.pop(context); // Regresa a la pantalla de juegos
                },
                child: const Text('🎮 Volver a juegos'),
              ),
            ],
          ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Calculamos el total de monedas a pagar
    final total = calcularTotal();

    return Scaffold(
      appBar: AppBar(title: const Text('🧾 Tu Carrito')),
      body:
          carritoInterno.isEmpty
              // Si no hay productos, mostramos un mensaje centralizado
              ? const Center(child: Text('Tu carrito está vacío'))
              : Column(
                children: [
                  // Listado de productos en el carrito
                  Expanded(
                    child: ListView(
                      children:
                          carritoInterno.entries.map((entry) {
                            final producto = entry.key;
                            final cantidad = entry.value;
                            return ListTile(
                              title: Text(producto.nombre),
                              subtitle: Text(
                                'Cantidad: $cantidad x ${producto.precio} = ${producto.precio * cantidad} monedas',
                              ),
                            );
                          }).toList(),
                    ),
                  ),

                  // Sección fija en la parte inferior con el total y el botón de finalizar
                  Container(
                    padding: const EdgeInsets.all(16),
                    color: const Color(0xFFE0F2F1),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // Muestra el total de monedas a pagar
                        Text(
                          '💰 Total: $total monedas',
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 10),
                        // Botón para finalizar la compra
                        ElevatedButton.icon(
                          icon: const Icon(Icons.check_circle),
                          label: const Text('Finalizar compra'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green,
                            foregroundColor: Colors.white,
                          ),
                          onPressed: () {
                            // Al pulsar, vaciamos el carrito y mostramos el diálogo final
                            setState(() {
                              carritoInterno.clear();
                            });
                            mostrarDialogoFinal();
                          },
                        ),
                      ],
                    ),
                  ),
                ],
              ),
    );
  }
}

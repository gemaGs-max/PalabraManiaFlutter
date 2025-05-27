import 'package:flutter/material.dart';
import 'producto.dart';

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
    carritoInterno = Map.from(widget.carrito); // Copia del carrito
  }

  int calcularTotal() {
    int total = 0;
    carritoInterno.forEach((producto, cantidad) {
      total += producto.precio * cantidad;
    });
    return total;
  }

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
                  Navigator.pop(context); // cerrar diálogo
                  Navigator.pop(context); // volver a tienda
                },
                child: const Text('🛒 Volver a tienda'),
              ),
              TextButton(
                onPressed: () {
                  Navigator.pop(context); // cerrar diálogo
                  Navigator.pop(context); // volver a tienda
                  Navigator.pop(context); // volver a juegos
                },
                child: const Text('🎮 Volver a juegos'),
              ),
            ],
          ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final total = calcularTotal();

    return Scaffold(
      appBar: AppBar(title: const Text('🧾 Tu Carrito')),
      body:
          carritoInterno.isEmpty
              ? const Center(child: Text('Tu carrito está vacío'))
              : Column(
                children: [
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
                  Container(
                    padding: const EdgeInsets.all(16),
                    color: const Color(0xFFE0F2F1),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Text(
                          '💰 Total: $total monedas',
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 10),
                        ElevatedButton.icon(
                          icon: const Icon(Icons.check_circle),
                          label: const Text('Finalizar compra'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green,
                            foregroundColor: Colors.white,
                          ),
                          onPressed: () {
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

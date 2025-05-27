import 'package:flutter/material.dart';
import 'carrito_page.dart';
import 'producto.dart';

class TiendaPage extends StatefulWidget {
  const TiendaPage({super.key});

  @override
  State<TiendaPage> createState() => _TiendaPageState();
}

class _TiendaPageState extends State<TiendaPage> {
  final List<Producto> productos = [
    Producto(
      id: '1',
      nombre: 'Paquete de frases comunes',
      descripcion: 'Frases útiles del día a día',
      precio: 100,
    ),
    Producto(
      id: '2',
      nombre: 'Minijuego Trivia',
      descripcion: 'Juego adicional de preguntas',
      precio: 300,
    ),
    Producto(
      id: '3',
      nombre: 'Avatar exclusivo',
      descripcion: 'Avatar único para tu perfil',
      precio: 150,
    ),
    Producto(
      id: '4',
      nombre: 'Pack sonidos Premium',
      descripcion: 'Sonidos y efectos nuevos',
      precio: 120,
    ),
    Producto(
      id: '5',
      nombre: 'Booster de XP',
      descripcion: 'Doble experiencia durante 24h',
      precio: 200,
    ),
  ];

  final Map<Producto, int> carrito = {};

  void agregarAlCarrito(Producto producto) {
    setState(() {
      carrito.update(producto, (cantidad) => cantidad + 1, ifAbsent: () => 1);
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('${producto.nombre} añadido al carrito')),
    );
  }

  void irAlCarrito() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => CarritoPage(carrito: carrito)),
    );
  }

  int totalEnCarrito() {
    if (carrito.isEmpty) return 0;
    return carrito.values.reduce((a, b) => a + b);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('🛍️ Tienda de Idiomas'),
        actions: [
          Stack(
            alignment: Alignment.topRight,
            children: [
              IconButton(
                icon: const Icon(Icons.shopping_cart),
                onPressed: irAlCarrito,
              ),
              if (carrito.isNotEmpty)
                Positioned(
                  right: 6,
                  top: 6,
                  child: Container(
                    padding: const EdgeInsets.all(5),
                    decoration: const BoxDecoration(
                      color: Colors.red,
                      shape: BoxShape.circle,
                    ),
                    child: Text(
                      '${totalEnCarrito()}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
      body: ListView.builder(
        itemCount: productos.length,
        itemBuilder: (context, index) {
          final producto = productos[index];
          return Card(
            margin: const EdgeInsets.all(10),
            child: ListTile(
              title: Text(producto.nombre),
              subtitle: Text(
                '${producto.descripcion}\nPrecio: ${producto.precio} monedas',
              ),
              isThreeLine: true,
              trailing: ElevatedButton(
                onPressed: () => agregarAlCarrito(producto),
                child: const Text('Añadir'),
              ),
            ),
          );
        },
      ),
    );
  }
}

import 'package:flutter/material.dart';

void main() {
  runApp(const AmazonApp());
}

class AmazonApp extends StatelessWidget {
  const AmazonApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        scaffoldBackgroundColor: const Color(0xFFF3F3F3),
      ),
      home: const MainScreen(),
    );
  }
}

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _currentIndex = 0;

  final List<Widget> _screens = [
    const HomeScreen(),
    const ProfileScreen(),
    const CartScreen(),
    const CategoriesScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _screens[_currentIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) => setState(() => _currentIndex = index),
        type: BottomNavigationBarType.fixed,
        selectedItemColor: const Color(0xFF007185),
        unselectedItemColor: Colors.black87,
        showSelectedLabels: false,
        showUnselectedLabels: false,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home_outlined),
            label: 'Inicio',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person_outline),
            label: 'Perfil',
          ),
          BottomNavigationBarItem(
            icon: Badge(
              label: Text('3'),
              child: Icon(Icons.shopping_cart_outlined),
            ),
            label: 'Carrito',
          ),
          BottomNavigationBarItem(icon: Icon(Icons.menu), label: 'Menú'),
        ],
      ),
    );
  }
}

// INICIO CON OFERTA DEL DIA
class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Column(
        children: [
          const HeaderSection(),
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                children: [const CategoriesList(), const FeaturedOfferCard()],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class HeaderSection extends StatelessWidget {
  const HeaderSection({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xFF232F3E),
      padding: const EdgeInsets.fromLTRB(15, 10, 15, 12),
      child: Column(
        children: [
          Container(
            height: 45,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8),
            ),
            child: const TextField(
              decoration: InputDecoration(
                hintText: 'Buscar en Amazon',
                prefixIcon: Icon(Icons.search),
                border: InputBorder.none,
                contentPadding: EdgeInsets.symmetric(vertical: 10),
              ),
            ),
          ),
          const SizedBox(height: 12),
          const Row(
            children: [
              Icon(Icons.location_on_outlined, color: Colors.white, size: 20),
              SizedBox(width: 8),
              Text(
                'CP 12345',
                style: TextStyle(color: Colors.white, fontSize: 13),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class CategoriesList extends StatelessWidget {
  const CategoriesList({super.key});

  @override
  Widget build(BuildContext context) {
    final categories = ['Electrónica', 'Moda', 'Hogar', 'Juguetes', 'Libros'];
    return Container(
      height: 60,
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 10),
        itemCount: categories.length,
        itemBuilder: (context, index) => Padding(
          padding: const EdgeInsets.only(right: 10),
          child: ActionChip(label: Text(categories[index]), onPressed: () {}),
        ),
      ),
    );
  }
}

class FeaturedOfferCard extends StatelessWidget {
  const FeaturedOfferCard({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.all(15),
            child: Text(
              'Oferta del día',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
          ),
          const SizedBox(
            height: 180,
            child: Center(
              child: Icon(Icons.watch, size: 100, color: Colors.black),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(15),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFFCC0C39),
                        borderRadius: BorderRadius.circular(2),
                      ),
                      child: const Text(
                        '-25%',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    const Text(
                      'DINERO \$',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                const Text(
                  'APRODUCTO CON MÀS DESCUENTO',
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// PERFIL  DEL USUARIO
class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: const Color(0xFFADEBEF),
        elevation: 0,
        title: const Text(
          "Hola, USUARIO",
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
        ),
        actions: const [
          Padding(
            padding: EdgeInsets.all(10),
            child: CircleAvatar(child: Icon(Icons.person)),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(15),
        child: Column(
          children: [
            GridView.count(
              shrinkWrap: true,
              crossAxisCount: 2,
              crossAxisSpacing: 10,
              mainAxisSpacing: 10,
              childAspectRatio: 2.5,
              children: [
                _actionCard("Mis pedidos"),
                _actionCard("Lista de deseos"),
                _actionCard("Direcciones"),
                _actionCard("Mi cuenta"),
              ],
            ),
            const SizedBox(height: 20),
            const Align(
              alignment: Alignment.centerLeft,
              child: Text(
                "Pedidos recientes",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ),
            ListTile(
              leading: const Icon(Icons.headphones),
              title: const Text("PRODUCTO"),
              subtitle: const Text("ESTADO DE ENVIO"),
              trailing: const Icon(Icons.chevron_right),
            ),
          ],
        ),
      ),
    );
  }

  Widget _actionCard(String title) {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade300),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Center(
        child: Text(title, style: const TextStyle(fontWeight: FontWeight.w500)),
      ),
    );
  }
}

// MENU DEL CARRITO PARA SIMULAR LA COMPRA
class CartScreen extends StatelessWidget {
  const CartScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFF232F3E),
        title: const Text("Carrito", style: TextStyle(color: Colors.white)),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(15),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  "Subtotal SUMA \$",
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 10),
                SizedBox(
                  width: double.infinity,
                  height: 45,
                  child: ElevatedButton(
                    onPressed: () {},
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFFFD814),
                    ),
                    child: const Text(
                      "Proceder al pago",
                      style: TextStyle(color: Colors.black),
                    ),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: ListView(
              children: [
                _cartItem("PRODUCTO", "PRECIO \$", Icons.watch_outlined),
                _cartItem("PRODUCTO", "PRECIO \$", Icons.headphones),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _cartItem(String title, String price, IconData icon) {
    return ListTile(
      leading: Icon(icon, size: 50),
      title: Text(title),
      subtitle: Text(price, style: const TextStyle(color: Color(0xFFB12704))),
      trailing: const Icon(Icons.delete_outline),
    );
  }
}

// AQUI VOY A PONER EL MENU EN DONDE PUEDES NAVEGAR A LAS CATEGORIAS DE PRODUCTOS
class CategoriesScreen extends StatelessWidget {
  const CategoriesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final categories = [
      'Electrónica',
      'Moda',
      'Hogar',
      'Deportes',
      'Juguetes',
      'Libros',
      'Belleza',
      'Alimentación',
      'Jardín',
    ];

    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFF232F3E),
        title: const Text("Categorías", style: TextStyle(color: Colors.white)),
      ),
      body: GridView.builder(
        padding: const EdgeInsets.all(15),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 3,
          crossAxisSpacing: 10,
          mainAxisSpacing: 10,
        ),
        itemCount: categories.length,
        itemBuilder: (context, index) {
          return Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const CircleAvatar(
                  backgroundColor: Color(0xFFF3F3F3),
                  child: Icon(Icons.category, color: Colors.black),
                ),
                const SizedBox(height: 8),
                Text(
                  categories[index],
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 10),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

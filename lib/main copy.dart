import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'product_bloc.dart';
import 'product_repository.dart';
import 'product.dart';
import 'splash_screen.dart';
import 'category_bloc.dart';
import 'category_event.dart';
import 'category_state.dart';
import 'subcategory_bloc.dart';
import 'subcategory_event.dart';
import 'subcategory_state.dart';

class Category {
  final int id;
  final String name;

  Category({required this.id, required this.name});

  factory Category.fromJson(Map<String, dynamic> json) {
    return Category(id: json['id'] as int, name: json['name'] as String);
  }
}

class Subcategory {
  final int id;
  final String name;
  final int categoryId;

  Subcategory({required this.id, required this.name, required this.categoryId});

  factory Subcategory.fromJson(Map<String, dynamic> json) {
    return Subcategory(
      id: json['id'] as int,
      name: json['name'] as String,
      categoryId: json['parent_category_id'] as int,
    );
  }
}

class CartManager {
  static final CartManager _instance = CartManager._internal();
  factory CartManager() => _instance;
  CartManager._internal();

  final List<Product> cart = [];
  final ValueNotifier<int> cartCount = ValueNotifier<int>(0);

  void addToCart(Product product) {
    cart.add(product);
    cartCount.value = cart.length;
  }

  void clearCart() {
    cart.clear();
    cartCount.value = 0;
  }
}

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  final ProductRepository repository = ProductRepository();
  final CartManager cartManager = CartManager();

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider(create: (context) => ProductBloc(repository)),
        BlocProvider(create: (context) => CategoryBloc()),
        BlocProvider(create: (context) => SubcategoryBloc()),
      ],
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        title: 'Dorco',
        theme: ThemeData(
          primarySwatch: Colors.blue,
          elevatedButtonTheme: ElevatedButtonThemeData(
            style: ElevatedButton.styleFrom(
              padding: EdgeInsets.symmetric(vertical: 16, horizontal: 24),
              textStyle: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
          cardTheme: CardThemeData(
            elevation: 4,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            margin: EdgeInsets.symmetric(vertical: 8, horizontal: 16),
          ),
        ),
        home: SplashScreen(cartManager: cartManager),
      ),
    );
  }
}

class HomeScreen extends StatelessWidget {
  final CartManager cartManager;
  const HomeScreen({required this.cartManager});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Dorco'),
        actions: [
          ValueListenableBuilder<int>(
            valueListenable: cartManager.cartCount,
            builder: (context, count, child) {
              return Stack(
                alignment: Alignment.center,
                children: [
                  IconButton(
                    icon: Icon(Icons.shopping_cart),
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => CartScreen(
                            cart: cartManager.cart,
                            cartManager: cartManager,
                          ),
                        ),
                      );
                    },
                  ),
                  if (count > 0)
                    Positioned(
                      right: 8,
                      top: 8,
                      child: Container(
                        padding: EdgeInsets.all(2),
                        decoration: BoxDecoration(
                          color: Colors.red,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        constraints: BoxConstraints(
                          minWidth: 16,
                          minHeight: 16,
                        ),
                        child: Text(
                          '$count',
                          style: TextStyle(color: Colors.white, fontSize: 10),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                ],
              );
            },
          ),
        ],
      ),
      body: BlocBuilder<CategoryBloc, CategoryState>(
        builder: (context, state) {
          if (state is CategoryInitial) {
            context.read<CategoryBloc>().add(LoadCategories());
            return Center(child: CircularProgressIndicator());
          } else if (state is CategoryLoading) {
            return Center(child: CircularProgressIndicator());
          } else if (state is CategoryError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text('No se pudieron cargar las categorías'),
                  SizedBox(height: 10),
                  Text('Error: ${state.message}'),
                ],
              ),
            );
          } else if (state is CategoryLoaded) {
            return ListView(
              padding: EdgeInsets.all(16),
              children: [
                Center(
                  child: Column(
                    children: [
                      Image.asset('assets/images/logo.png', height: 100),
                      SizedBox(height: 20),
                      Text(
                        'Escoge una categoría',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Colors.blue[900],
                        ),
                      ),
                      SizedBox(height: 20),
                    ],
                  ),
                ),
                ...state.categories.map(
                  (category) => Card(
                    child: ListTile(
                      contentPadding: EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      title: Text(
                        category.name,
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      trailing: Icon(Icons.arrow_forward_ios, size: 16),
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => SubcategoryScreen(
                              categoryId: category.id,
                              categoryName: category.name,
                              cartManager: cartManager,
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ),
              ],
            );
          }
          return SizedBox.shrink();
        },
      ),
    );
  }
}

class SubcategoryScreen extends StatelessWidget {
  final int categoryId;
  final String categoryName;
  final CartManager cartManager;

  SubcategoryScreen({
    required this.categoryId,
    required this.categoryName,
    required this.cartManager,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(categoryName),
        actions: [
          ValueListenableBuilder<int>(
            valueListenable: cartManager.cartCount,
            builder: (context, count, child) {
              return Stack(
                alignment: Alignment.center,
                children: [
                  IconButton(
                    icon: Icon(Icons.shopping_cart),
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => CartScreen(
                            cart: cartManager.cart,
                            cartManager: cartManager,
                          ),
                        ),
                      );
                    },
                  ),
                  if (count > 0)
                    Positioned(
                      right: 8,
                      top: 8,
                      child: Container(
                        padding: EdgeInsets.all(2),
                        decoration: BoxDecoration(
                          color: Colors.red,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        constraints: BoxConstraints(
                          minWidth: 16,
                          minHeight: 16,
                        ),
                        child: Text(
                          '$count',
                          style: TextStyle(color: Colors.white, fontSize: 10),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                ],
              );
            },
          ),
        ],
      ),
      body: BlocBuilder<SubcategoryBloc, SubcategoryState>(
        builder: (context, state) {
          if (state is SubcategoryInitial) {
            context.read<SubcategoryBloc>().add(LoadSubcategories(categoryId));
            return Center(child: CircularProgressIndicator());
          } else if (state is SubcategoryLoading) {
            return Center(child: CircularProgressIndicator());
          } else if (state is SubcategoryError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text('No se pudieron cargar las subcategorías'),
                  SizedBox(height: 10),
                  Text('Error: ${state.message}'),
                ],
              ),
            );
          } else if (state is SubcategoryLoaded) {
            return ListView(
              padding: EdgeInsets.all(16),
              children: [
                Center(
                  child: Column(
                    children: [
                      Image.asset('assets/images/logo.png', height: 100),
                      SizedBox(height: 20),
                      Text(
                        'Escoge una subcategoría',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Colors.blue[900],
                        ),
                      ),
                      SizedBox(height: 20),
                    ],
                  ),
                ),
                ...state.subcategories.map(
                  (subcategory) => Card(
                    child: ListTile(
                      contentPadding: EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      title: Text(
                        subcategory.name,
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      trailing: Icon(Icons.arrow_forward_ios, size: 16),
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => ProductListScreen(
                              categoryId: categoryId,
                              categoryName: categoryName,
                              subcategoryId: subcategory.id,
                              subcategoryName: subcategory.name,
                              cartManager: cartManager,
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ),
              ],
            );
          }
          return SizedBox.shrink();
        },
      ),
    );
  }
}

class ProductListScreen extends StatefulWidget {
  final int categoryId;
  final String categoryName;
  final int subcategoryId;
  final String subcategoryName;
  final CartManager cartManager;

  ProductListScreen({
    required this.categoryId,
    required this.categoryName,
    required this.subcategoryId,
    required this.subcategoryName,
    required this.cartManager,
  });

  @override
  _ProductListScreenState createState() => _ProductListScreenState();
}

class _ProductListScreenState extends State<ProductListScreen> {
  bool showBanner = true;

  void addToCart(Product product, BuildContext context) {
    widget.cartManager.addToCart(product);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('${product.name} añadido al carrito!')),
    );
  }

  @override
  void initState() {
    super.initState();
    context.read<ProductBloc>().add(
      LoadProducts(
        categoryId: widget.categoryId,
        subcategoryId: widget.subcategoryId,
        startIndex: 0,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.subcategoryName),
        actions: [
          ValueListenableBuilder<int>(
            valueListenable: widget.cartManager.cartCount,
            builder: (context, count, child) {
              return Stack(
                alignment: Alignment.center,
                children: [
                  IconButton(
                    icon: Icon(Icons.shopping_cart),
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => CartScreen(
                            cart: widget.cartManager.cart,
                            cartManager: widget.cartManager,
                          ),
                        ),
                      );
                    },
                  ),
                  if (count > 0)
                    Positioned(
                      right: 8,
                      top: 8,
                      child: Container(
                        padding: EdgeInsets.all(2),
                        decoration: BoxDecoration(
                          color: Colors.red,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        constraints: BoxConstraints(
                          minWidth: 16,
                          minHeight: 16,
                        ),
                        child: Text(
                          '$count',
                          style: TextStyle(color: Colors.white, fontSize: 10),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                ],
              );
            },
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            if (showBanner)
              Container(
                margin: EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    color: Color(0xFF025692),
                    padding: EdgeInsets.all(16),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            'Añade tus productos de interés a la canasta de compras. Cuando termines dale click a la canasta para solicitar una cotización',
                            style: TextStyle(
                              fontSize: 16,
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                        GestureDetector(
                          onTap: () {
                            setState(() {
                              showBanner = false;
                            });
                          },
                          child: Icon(
                            Icons.close,
                            color: Colors.white,
                            size: 24,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            Expanded(
              child: BlocBuilder<ProductBloc, ProductState>(
                builder: (context, state) {
                  final products = state.products;

                  return products.isEmpty && !state.hasMore
                      ? Center(
                          child: Text('No hay productos en esta subcategoría'),
                        )
                      : ListView.builder(
                          padding: EdgeInsets.all(16),
                          itemCount: products.length + (state.hasMore ? 1 : 0),
                          itemBuilder: (context, index) {
                            if (index < products.length) {
                              final product = products[index];
                              return Card(
                                color: Colors.white,
                                child: ListTile(
                                  leading: Image.network(
                                    product.image,
                                    cacheWidth: 100,
                                    cacheHeight: 100,
                                    errorBuilder: (context, error, stackTrace) {
                                      return Icon(Icons.broken_image, size: 50);
                                    },
                                    loadingBuilder:
                                        (context, child, loadingProgress) {
                                          if (loadingProgress == null)
                                            return child;
                                          return CircularProgressIndicator();
                                        },
                                  ),
                                  title: Text(product.name),
                                  subtitle: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(product.description),
                                      SizedBox(height: 4),
                                      Text(
                                        'Código: ${product.code}',
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: Colors.grey[600],
                                        ),
                                      ),
                                    ],
                                  ),
                                  trailing: IconButton(
                                    icon: Icon(Icons.add_shopping_cart),
                                    onPressed: () =>
                                        addToCart(product, context),
                                  ),
                                ),
                              );
                            } else {
                              context.read<ProductBloc>().add(
                                LoadProducts(
                                  categoryId: widget.categoryId,
                                  subcategoryId: widget.subcategoryId,
                                  startIndex: state.products.length,
                                ),
                              );
                              return Center(child: CircularProgressIndicator());
                            }
                          },
                        );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class CartScreen extends StatelessWidget {
  final List<Product> cart;
  final CartManager cartManager;

  const CartScreen({required this.cart, required this.cartManager});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Carrito')),
      body: cart.isEmpty
          ? Center(child: Text('Tu carrito está vacío'))
          : ListView.builder(
              padding: EdgeInsets.all(16),
              itemCount: cart.length,
              itemBuilder: (context, index) {
                return Card(
                  child: ListTile(
                    leading: Image.network(
                      cart[index].image,
                      errorBuilder: (context, error, stackTrace) {
                        return Icon(Icons.broken_image, size: 50);
                      },
                    ),
                    title: Text(cart[index].name),
                    subtitle: Text(cart[index].description),
                  ),
                );
              },
            ),
      bottomNavigationBar: cart.isNotEmpty
          ? Padding(
              padding: EdgeInsets.all(16),
              child: ElevatedButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) =>
                          QuotationScreen(cart: cart, cartManager: cartManager),
                    ),
                  );
                },
                child: Text('Obtener cotización'),
              ),
            )
          : null,
    );
  }
}

class QuotationScreen extends StatelessWidget {
  final List<Product> cart;
  final CartManager cartManager;

  QuotationScreen({required this.cart, required this.cartManager});

  final TextEditingController nameController = TextEditingController();
  final TextEditingController countryController = TextEditingController();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController phoneController = TextEditingController();
  final TextEditingController messageController = TextEditingController();

  Future<void> submitQuotation(BuildContext context) async {
    try {
      final response = await http.post(
        Uri.parse('https://dorca.shop/api/quotations'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'name': nameController.text,
          'country': countryController.text,
          'email': emailController.text,
          'phone': phoneController.text,
          'message': messageController.text,
          'products': cart
              .map(
                (p) => {
                  'id': p.id,
                  'name': p.name,
                  'code': p.code,
                  'image': p.image,
                },
              )
              .toList(),
        }),
      );
      if (response.statusCode == 201) {
        cartManager.clearCart();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Cotización enviada exitosamente')),
        );
        Navigator.popUntil(context, (route) => route.isFirst);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al enviar cotización: ${response.statusCode}'),
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error al enviar cotización: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Solicitar cotización')),
      body: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(
              controller: nameController,
              decoration: InputDecoration(labelText: 'Nombre y apellido'),
            ),
            TextField(
              controller: countryController,
              decoration: InputDecoration(labelText: 'País'),
            ),
            TextField(
              controller: emailController,
              decoration: InputDecoration(labelText: 'Correo electrónico'),
            ),
            TextField(
              controller: phoneController,
              decoration: InputDecoration(labelText: 'Número de teléfono'),
            ),
            TextField(
              controller: messageController,
              decoration: InputDecoration(labelText: 'Mensaje adicional'),
            ),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: () => submitQuotation(context),
              child: Text('Enviar cotización'),
            ),
          ],
        ),
      ),
    );
  }
}

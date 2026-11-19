import 'package:flutter/material.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Lab 11 – Async Store',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.teal),
        useMaterial3: true,
      ),
      home: const StoreHomePage(),
    );
  }
}

class User {
  final String name;
  final String email;
  final String status;

  const User({
    required this.name,
    required this.email,
    required this.status,
  });
}

class Product {
  final String title;
  final double price;

  const Product({
    required this.title,
    required this.price,
  });
}

class Order {
  final String id;
  final String date;
  final double total;
  final String status;

  const Order({
    required this.id,
    required this.date,
    required this.total,
    required this.status,
  });
}

class StoreService {
  Future<User> getUser({bool simulateError = false}) async {
    await Future.delayed(const Duration(seconds: 2));
    if (simulateError) {
      throw Exception('Помилка з\'єднання з сервером магазину');
    }
    return const User(
      name: 'Тимофій Миронюк',
      email: 'timofiy.myronyuk@example.com',
      status: 'VIP-клієнт',
    );
  }

  Future<List<Product>> getProducts() async {
    await Future.delayed(const Duration(seconds: 2));
    return const [
      Product(title: 'Механічна клавіатура', price: 2899.0),
      Product(title: 'Бездротова миша', price: 1450.0),
      Product(title: 'Монітор 27" 144Hz', price: 8999.0),
    ];
  }

  Future<List<Order>> getOrders() async {
    await Future.delayed(const Duration(seconds: 3));
    return const [
      Order(id: '#1042', date: '12.11.2026', total: 4349.0, status: 'Доставлено'),
      Order(id: '#1058', date: '18.11.2026', total: 8999.0, status: 'В дорозі'),
    ];
  }
}

class StoreHomePage extends StatefulWidget {
  const StoreHomePage({super.key});

  @override
  State<StoreHomePage> createState() => _StoreHomePageState();
}

class _StoreHomePageState extends State<StoreHomePage> {
  final StoreService _storeService = StoreService();

  bool _isLoading = false;
  String? _errorMessage;
  User? _user;
  List<Product> _products = [];
  List<Order> _orders = [];

  @override
  void initState() {
    super.initState();
    _loadStoreData();
  }

  Future<void> _loadStoreData({bool simulateError = false}) async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      // Конкурентне виконання всіх трьох асинхронних запитів
      final results = await Future.wait<dynamic>([
        _storeService.getUser(simulateError: simulateError),
        _storeService.getProducts(),
        _storeService.getOrders(),
      ]);

      setState(() {
        _user = results[0] as User;
        _products = results[1] as List<Product>;
        _orders = results[2] as List<Order>;
      });
    } catch (e) {
      setState(() {
        _errorMessage = e.toString().replaceFirst('Exception: ', '');
      });
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: const Text('Інтернет-магазин (Async)'),
        centerTitle: true,
        actions: [
          IconButton(
            tooltip: 'Оновити дані',
            icon: const Icon(Icons.refresh),
            onPressed: _isLoading ? null : () => _loadStoreData(),
          ),
        ],
      ),
      body: _buildBody(),
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Row(
          children: [
            Expanded(
              child: ElevatedButton.icon(
                onPressed: _isLoading ? null : () => _loadStoreData(),
                icon: const Icon(Icons.download),
                label: const Text('Завантажити'),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: OutlinedButton.icon(
                onPressed:
                _isLoading ? null : () => _loadStoreData(simulateError: true),
                icon: const Icon(Icons.error_outline),
                label: const Text('Тест помилки'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('Завантаження даних із сервера...'),
          ],
        ),
      );
    }

    if (_errorMessage != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.cloud_off, size: 64, color: Colors.red),
              const SizedBox(height: 16),
              Text(
                _errorMessage!,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 16, color: Colors.red),
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: () => _loadStoreData(),
                child: const Text('Спробувати знову'),
              ),
            ],
          ),
        ),
      );
    }

    return ListView(
      padding: const EdgeInsets.all(16.0),
      children: [
        if (_user != null) ...[
          const Text(
            'Користувач',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Card(
            child: ListTile(
              leading: const CircleAvatar(child: Icon(Icons.person)),
              title: Text(_user!.name),
              subtitle: Text('${_user!.email}\nСтатус: ${_user!.status}'),
              isThreeLine: true,
            ),
          ),
          const SizedBox(height: 16),
        ],
        const Text(
          'Доступні товари',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        ..._products.map(
              (product) => Card(
            child: ListTile(
              leading: const Icon(Icons.shopping_bag_outlined),
              title: Text(product.title),
              trailing: Text(
                '${product.price.toStringAsFixed(0)} грн',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
          ),
        ),
        const SizedBox(height: 16),
        const Text(
          'Історія замовлень',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        ..._orders.map(
              (order) => Card(
            child: ListTile(
              leading: const Icon(Icons.receipt_long_outlined),
              title: Text('Замовлення ${order.id} від ${order.date}'),
              subtitle: Text('Статус: ${order.status}'),
              trailing: Text(
                '${order.total.toStringAsFixed(0)} грн',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
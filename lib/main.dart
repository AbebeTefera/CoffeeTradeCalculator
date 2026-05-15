import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'models/config_provider.dart';
import 'screens/standard_calculator.dart';
import 'screens/trade_calculator.dart';
import 'screens/admin_login_screen.dart';
import 'screens/settings_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await SharedPreferences.getInstance();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (context) => ConfigProvider(),
      child: MaterialApp(
        title: 'Coffee Trade Calculator',   // String, not Widget
        theme: ThemeData(
          primaryColor: const Color(0xFF1a552a),
          appBarTheme: const AppBarTheme(
            backgroundColor: Color(0xFF1a552a),
            foregroundColor: Colors.white,
          ),
          bottomNavigationBarTheme: const BottomNavigationBarThemeData(
            selectedItemColor: Color(0xFFf9a946),
            unselectedItemColor: Colors.grey,
          ),
        ),
        home: const MainScreen(),
        debugShowCheckedModeBanner: false,
      ),
    );
  }
}

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _selectedIndex = 1;

  final List<Widget> _screens = const [
    StandardCalculator(),
    TradeCalculator(),
    Center(child: Text('Admin Section', style: TextStyle(fontSize: 18))),
  ];

  void _onItemTapped(int index) {
    if (index == 2) {
      _navigateToAdminLogin();
    } else {
      setState(() {
        _selectedIndex = index;
      });
    }
  }

  Future<void> _navigateToAdminLogin() async {
    final prefs = await SharedPreferences.getInstance();
    final isLoggedIn = prefs.getBool('isAdminLoggedIn') ?? false;
    if (!context.mounted) return;
    if (isLoggedIn) {
      await Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => const SettingsScreen()),
      );
      setState(() {});
    } else {
      await Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => const AdminLoginScreen()),
      );
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            Image.asset(
              'assets/images/logo.png',
              height: 40,
            ),
            const SizedBox(width: 8),
            const Text('ECX Coffee Trader Assistant'),
          ],
        ),
        actions: [
          FutureBuilder<bool>(
            future: SharedPreferences.getInstance()
                .then((prefs) => prefs.getBool('isAdminLoggedIn') ?? false),
            builder: (context, snapshot) {
              if (snapshot.hasData && snapshot.data == true) {
                return IconButton(
                  icon: const Icon(Icons.logout),
                  tooltip: 'Admin Logout',
                  onPressed: () async {
                    final prefs = await SharedPreferences.getInstance();
                    await prefs.remove('isAdminLoggedIn');
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Admin logged out.')),
                      );
                      setState(() {});
                    }
                  },
                );
              }
              return const SizedBox.shrink();
            },
          ),
        ],
      ),
      body: _screens[_selectedIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.calculate), label: 'Standard'),
          BottomNavigationBarItem(icon: Icon(Icons.coffee), label: 'Trade'),
          BottomNavigationBarItem(icon: Icon(Icons.settings), label: 'Settings'),
        ],
      ),
    );
  }
}
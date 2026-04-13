import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:loy_herbs/services/database_service.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:loy_herbs/views/detail/herb_detail_screen.dart';
import 'package:loy_herbs/views/admin/admin_screen.dart';
import 'package:loy_herbs/data/models/herb_model.dart';

// 1. THE HERB MODEL

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    await dotenv.load(fileName: ".env");
    await Supabase.initialize(
      url: dotenv.env['SUPABASE_URL'] ?? '',
      anonKey: dotenv.env['SUPABASE_ANON_KEY'] ?? '',
    );
  } catch (e) {
    debugPrint("Initialization error: $e");
  }

  runApp(const LoyHerbsApp());
}

class LoyHerbsApp extends StatelessWidget {
  const LoyHerbsApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Loy Herbs',
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF1B5E20),
          primary: const Color(0xFF1B5E20),
        ),
        textTheme: GoogleFonts.merriweatherTextTheme(),
      ),
      home: const AuthGate(),
    );
  }
}

// 2. AUTH GATE
class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    final session = Supabase.instance.client.auth.currentSession;
    return session == null ? const LoginScreen() : const HomeScreen();
  }
}

// 3. LOGIN SCREEN
class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  Future<void> _signIn() async {
    try {
      await Supabase.instance.client.auth.signInWithPassword(
        email: _emailController.text,
        password: _passwordController.text,
      );
      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const HomeScreen()),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(e.toString())));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.eco, size: 80, color: Colors.green),
            const SizedBox(height: 20),
            Text(
              "Loy Herbs",
              style: Theme.of(context).textTheme.headlineMedium,
            ),
            const Text("Student Academic Portal"),
            const SizedBox(height: 40),
            TextField(
              controller: _emailController,
              decoration: const InputDecoration(labelText: "Email"),
            ),
            TextField(
              controller: _passwordController,
              decoration: const InputDecoration(labelText: "Password"),
              obscureText: true,
            ),
            const SizedBox(height: 20),
            ElevatedButton(onPressed: _signIn, child: const Text("Login")),
          ],
        ),
      ),
    );
  }
}

// 4. HOME SCREEN
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _supabase = Supabase.instance.client;
  List<Herb> allHerbs = [];
  List<Herb> filteredHerbs = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    fetchHerbs();
  }

  Future<void> fetchHerbs() async {
    try {
      final data = await DatabaseService().getHerbs();
      setState(() {
        allHerbs = data
            .map((e) => Herb.fromMap(e as Map<String, dynamic>))
            .toList();
        filteredHerbs = allHerbs;
        isLoading = false;
      });
    } catch (e) {
      setState(() => isLoading = false);
    }
  }

  void _filterHerbs(String query) {
    setState(() {
      filteredHerbs = allHerbs.where((herb) {
        final name = herb.name.toLowerCase();
        final description = herb.description.toLowerCase();
        final diseases = herb.diseases.join(' ').toLowerCase();
        final searchLower = query.toLowerCase();

        return name.contains(searchLower) ||
            description.contains(searchLower) ||
            diseases.contains(searchLower);
      }).toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Loy Herbs"),
        // Inside the AppBar actions list:
        actions: [
          // Only show the Admin button if the user is the Admin
          if (Supabase.instance.client.auth.currentUser?.email ==
              'makobisimon@gmail.com')
            IconButton(
              icon: const Icon(Icons.admin_panel_settings),
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const AdminScreen()),
              ),
            ),
          IconButton(
            onPressed: () async {
              /* logout logic */
            },
            icon: const Icon(Icons.logout),
          ),
        ],
      ),
      body: Column(
        children: [
          // Medical Disclaimer
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(8),
            color: Colors.amber.shade100,
            child: const Text(
              "⚠️ Disclaimer: Academic use only. Consult a professional before use.",
              style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
          ),
          // Search Bar
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              onChanged: _filterHerbs,
              decoration: InputDecoration(
                hintText: "Search herbs or diseases...",
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
          // Herb List
          Expanded(
            child: isLoading
                ? const Center(child: CircularProgressIndicator())
                : filteredHerbs.isEmpty
                ? const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.search_off, size: 60, color: Colors.grey),
                        Text("No herbs found in the database yet."),
                      ],
                    ),
                  )
                : ListView.builder(
                    itemCount: filteredHerbs.length,
                    itemBuilder: (context, index) {
                      final herb = filteredHerbs[index];
                      return ListTile(
                        leading: CircleAvatar(
                          backgroundColor: Colors.green.shade50,
                          backgroundImage: herb.imageUrl != null
                              ? NetworkImage(herb.imageUrl!)
                              : null,
                          child: herb.imageUrl == null
                              ? const Icon(Icons.eco, color: Colors.green)
                              : null,
                        ),
                        title: Text(
                          herb.name,
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        subtitle: Text(
                          herb.scientificName ?? "Species unknown",
                        ),
                        trailing: const Icon(Icons.arrow_forward_ios, size: 14),
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) =>
                                  HerbDetailScreen(herb: herb),
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

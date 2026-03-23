import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';

// If you used flutterfire configure, import this:
// import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(
    // options: DefaultFirebaseOptions.currentPlatform, // use if available
  );

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      home: TestScreen(),
    );
  }
}

class TestScreen extends StatefulWidget {
  const TestScreen({super.key});

  @override
  State<TestScreen> createState() => _TestScreenState();
}

class _TestScreenState extends State<TestScreen> {
  final emailController = TextEditingController();
  final passwordController = TextEditingController();

  String status = "Not logged in";

  Future<void> signup() async {
    try {
      await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: emailController.text.trim(),
        password: passwordController.text.trim(),
      );

      setState(() => status = "Signup Success ✅");
    } catch (e) {
      if (e is FirebaseAuthException) {
        setState(() => status = getAuthErrorMessage(e.code));
      } else {
        setState(() => status = "Signup failed");
      }
    }
  }
  String getAuthErrorMessage(String code) {
    switch (code) {
      case "invalid-email":
        return "Please enter a valid email";

      case "user-not-found":
        return "No account found with this email";

      case "wrong-password":
        return "Incorrect password";

      case "email-already-in-use":
        return "Email is already registered";

      case "weak-password":
        return "Password should be at least 6 characters";

      case "network-request-failed":
        return "Check your internet connection";

      case "too-many-requests":
        return "Too many attempts. Try again later";

      default:
        return "Something went wrong. Please try again";
    }
  }
  Future<void> login() async {
    try {
      await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: emailController.text.trim(),
        password: passwordController.text.trim(),
      );
      setState(() => status = "Login Success ✅");
    } catch (e) {
      if (e is FirebaseAuthException) {
        setState(() => status = getAuthErrorMessage(e.code));
      } else {
        setState(() => status = "Login failed");
      }
    }
  }

  Future<void> logout() async {
    await FirebaseAuth.instance.signOut();
    setState(() => status = "Logged out");
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    return Scaffold(
      appBar: AppBar(title: const Text("Firebase Test")),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Text("Status: $status"),
            const SizedBox(height: 10),

            Text("User: ${user?.email ?? "None"}"),
            const SizedBox(height: 20),

            TextField(
              controller: emailController,
              decoration: const InputDecoration(labelText: "Email"),
            ),

            TextField(
              controller: passwordController,
              decoration: const InputDecoration(labelText: "Password"),
              obscureText: true,
            ),

            const SizedBox(height: 20),

            ElevatedButton(
              onPressed: signup,
              child: const Text("Sign Up"),
            ),

            ElevatedButton(
              onPressed: login,
              child: const Text("Login"),
            ),

            ElevatedButton(
              onPressed: logout,
              child: const Text("Logout"),
            ),
          ],
        ),
      ),
    );
  }
}
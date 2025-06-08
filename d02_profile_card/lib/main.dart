import 'package:flutter/material.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Profile Card',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.teal),
        useMaterial3: true,
      ),
      home: const ProfileCard(),
    );
  }
}

class ProfileCard extends StatelessWidget {
  const ProfileCard({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.teal[50],
      appBar: AppBar(
        backgroundColor: Colors.teal,
        title: const Text('Profile Card'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.teal.shade100,
                blurRadius: 10,
                offset: const Offset(0, 5),
              )
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const CircleAvatar(
                radius: 80,
                backgroundImage: NetworkImage(
                    'https://avatars.githubusercontent.com/u/147256719?s=400&v=4'),
              ),
              const SizedBox(height: 16),
              //used when we need to style two different parts of text in single line
              RichText(
                text: const TextSpan(
                  children: [
                    TextSpan(
                      text: 'Github : ',
                      style: TextStyle(
                        fontFamily: 'OpenSans',
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: Colors.black,
                      ),
                    ),
                    TextSpan(
                      text: 'punit169',
                      style: TextStyle(
                        fontFamily: 'Pacifico',
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: Colors.black,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Flutter Intern',
                style: TextStyle(
                    fontFamily: 'OpenSans', fontSize: 18, color: Colors.grey),
              ),
              const Divider(height: 30, thickness: 1),
              const Row(
                children: [
                  Icon(Icons.email, color: Colors.teal),
                  SizedBox(width: 10),
                  Text('punitshah387@gmail.com'),
                ],
              ),
              const SizedBox(height: 10),
              const Row(
                children: [
                  Icon(Icons.location_on, color: Colors.teal),
                  SizedBox(width: 10),
                  Text('Gujarat, India'),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../services/navidrome_service.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late Future<List<dynamic>> _futureArtists;

  @override
  void initState() {
    super.initState();
    _futureArtists = context.read<NavidromeService>().getArtists();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Scrotify'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () {
              context.read<NavidromeService>().disconnect();
            },
          ),
        ],
      ),
      body: FutureBuilder<List<dynamic>>(
        future: _futureArtists,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text('No artists found'));
          }

          final artists = snapshot.data!;
          return ListView.builder(
            itemCount: artists.length,
            itemBuilder: (context, index) {
              final artist = artists[index];
              debugPrint('Artist data: $artist');
              return ListTile(
                title: Text((artist['name'] as String?) ?? (artist['artist'] as String?) ?? 'Unknown Artist'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () {},
              );
            },
          );
        },
      ),
    );
  }
}

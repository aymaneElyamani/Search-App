import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Recherche d\'Images',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: const ImageSearchPage(),
    );
  }
}

class ImageSearchPage extends StatefulWidget {
  const ImageSearchPage({super.key});

  @override
  State<ImageSearchPage> createState() => _ImageSearchPageState();
}

class _ImageSearchPageState extends State<ImageSearchPage> {
  final TextEditingController _searchController = TextEditingController();
  List<dynamic> _images = [];
  bool _isLoading = false;
  int _currentPage = 1;
  int _totalPages = 1;
  String _currentQuery = '';

  // Clés API Unsplash
  final String _accessKey = '2DNI8g0Q25qSyEGUNV2W6spOcRDBSFvYBY2oPOKYe20';

  Future<void> _searchImages(String query, {int page = 1}) async {
    if (query.isEmpty) return;

    setState(() {
      _isLoading = true;
      _currentQuery = query;
      _currentPage = page;
    });

    try {
      final response = await http.get(
        Uri.parse(
          'https://api.unsplash.com/search/photos?query=$query&per_page=30&page=$page&client_id=$_accessKey',
        ),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        setState(() {
          _images = data['results'];
          _totalPages = data['total_pages'] ?? 1;
          _isLoading = false;
        });
      } else {
        setState(() {
          _isLoading = false;
        });
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Erreur lors de la recherche')),
          );
        }
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Erreur: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Recherche d\'Images'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        elevation: 2,
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Rechercher des images...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: IconButton(
                  icon: const Icon(Icons.clear),
                  onPressed: () {
                    _searchController.clear();
                    setState(() {
                      _currentPage = 1;
                      _currentQuery = '';
                    });
                  },
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(30),
                ),
                filled: true,
                fillColor: Colors.grey[100],
              ),
              onSubmitted: (query) => _searchImages(query),
            ),
          ),
          if (_isLoading)
            const Expanded(child: Center(child: CircularProgressIndicator()))
          else if (_images.isEmpty)
            const Expanded(
              child: Center(
                child: Text(
                  'Recherchez des images en tapant un mot-clé',
                  style: TextStyle(fontSize: 16, color: Colors.grey),
                ),
              ),
            )
          else
            Expanded(
              child: GridView.builder(
                padding: const EdgeInsets.all(8),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  crossAxisSpacing: 8,
                  mainAxisSpacing: 8,
                  childAspectRatio: 0.75,
                ),
                itemCount: _images.length,
                itemBuilder: (context, index) {
                  final image = _images[index];
                  return GestureDetector(
                    onTap: () {
                      showDialog(
                        context: context,
                        builder: (context) => Dialog(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Image.network(
                                image['urls']['regular'],
                                fit: BoxFit.cover,
                              ),
                              Padding(
                                padding: const EdgeInsets.all(8.0),
                                child: Text(
                                  image['user']['name'] ?? 'Inconnu',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                    child: Card(
                      elevation: 3,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      clipBehavior: Clip.antiAlias,
                      child: Stack(
                        fit: StackFit.expand,
                        children: [
                          Image.network(
                            image['urls']['small'],
                            fit: BoxFit.cover,
                            loadingBuilder: (context, child, loadingProgress) {
                              if (loadingProgress == null) return child;
                              return const Center(
                                child: CircularProgressIndicator(),
                              );
                            },
                            errorBuilder: (context, error, stackTrace) {
                              return const Center(child: Icon(Icons.error));
                            },
                          ),
                          Positioned(
                            bottom: 0,
                            left: 0,
                            right: 0,
                            child: Container(
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  begin: Alignment.bottomCenter,
                                  end: Alignment.topCenter,
                                  colors: [
                                    Colors.black.withOpacity(0.7),
                                    Colors.transparent,
                                  ],
                                ),
                              ),
                              padding: const EdgeInsets.all(8),
                              child: Text(
                                image['user']['name'] ?? '',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          if (_images.isNotEmpty)
            Container(
              padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.withOpacity(0.3),
                    spreadRadius: 1,
                    blurRadius: 5,
                    offset: const Offset(0, -3),
                  ),
                ],
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  IconButton(
                    onPressed: _currentPage > 1
                        ? () => _searchImages(
                            _currentQuery,
                            page: _currentPage - 1,
                          )
                        : null,
                    icon: const Icon(Icons.arrow_back),
                    iconSize: 32,
                    style: IconButton.styleFrom(
                      backgroundColor: _currentPage > 1
                          ? Theme.of(context).colorScheme.primary
                          : Colors.grey[300],
                      foregroundColor: _currentPage > 1
                          ? Colors.white
                          : Colors.grey,
                      padding: const EdgeInsets.all(12),
                    ),
                  ),
                  Text(
                    'Page $_currentPage / $_totalPages',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  IconButton(
                    onPressed: _currentPage < _totalPages
                        ? () => _searchImages(
                            _currentQuery,
                            page: _currentPage + 1,
                          )
                        : null,
                    icon: const Icon(Icons.arrow_forward),
                    iconSize: 32,
                    style: IconButton.styleFrom(
                      backgroundColor: _currentPage < _totalPages
                          ? Theme.of(context).colorScheme.primary
                          : Colors.grey[300],
                      foregroundColor: _currentPage < _totalPages
                          ? Colors.white
                          : Colors.grey,
                      padding: const EdgeInsets.all(12),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }
}

import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

void main() {
  runApp(const MyApp());
}

// ---------- DATA MODELS ----------

class Ability {
  final String name;
  final bool isHidden;

  Ability({
    required this.name,
    required this.isHidden,
  });
}

class Pokemon {
  final int id;
  final String name;
  final int height;
  final int weight;
  final List<Ability> abilities;
  final List<String> types;
  final String imageUrl;

  Pokemon({
    required this.id,
    required this.name,
    required this.height,
    required this.weight,
    required this.abilities,
    required this.types,
    required this.imageUrl,
  });

  // This converts the JSON map from the API into a Pokemon object.
  factory Pokemon.fromJson(Map<String, dynamic> json) {
    final abilities = <Ability>[];

    for (final item in json['abilities'] as List) {
      final abilityData = item['ability'] as Map<String, dynamic>;

      abilities.add(
        Ability(
          name: abilityData['name'] as String,
          isHidden: item['is_hidden'] as bool,
        ),
      );
    }

    final types = <String>[];

    for (final item in json['types'] as List) {
      final typeData = item['type'] as Map<String, dynamic>;
      types.add(typeData['name'] as String);
    }

    final sprites = json['sprites'] as Map<String, dynamic>;
    final imageUrl = sprites['front_default'] as String? ?? '';

    return Pokemon(
      id: json['id'] as int,
      name: json['name'] as String,
      height: json['height'] as int,
      weight: json['weight'] as int,
      abilities: abilities,
      types: types,
      imageUrl: imageUrl,
    );
  }
}

// ---------- API FUNCTION ----------

Future<Pokemon> fetchPokemon(String pokemonName) async {
  final url = Uri.parse(
    'https://pokeapi.co/api/v2/pokemon/${pokemonName.toLowerCase()}',
  );

  final response = await http.get(url).timeout(
        const Duration(seconds: 15),
      );

  // Check the status code before reading the response as Pokémon data.
  if (response.statusCode == 404) {
    throw Exception('Pokémon not found. Please check the name and try again.');
  }

  if (response.statusCode != 200) {
    throw Exception(
      'The server returned an error (${response.statusCode}). Please try again.',
    );
  }

  // Convert the JSON text into a Dart map.
  final decoded = jsonDecode(response.body);

  if (decoded is! Map<String, dynamic>) {
    throw const FormatException('The API returned an unexpected data format.');
  }

  // Convert the map into a Pokemon object.
  return Pokemon.fromJson(decoded);
}

// ---------- HELPER FUNCTION ----------

// Example: "mr-mime" becomes "Mr Mime".
String prettify(String text) {
  return text
      .split('-')
      .map((word) => word.isEmpty
          ? word
          : word[0].toUpperCase() + word.substring(1))
      .join(' ');
}

// ---------- MAIN APP ----------

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Pokémon API Viewer',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorSchemeSeed: Colors.blue,
        brightness: Brightness.light,
      ),
      home: const PokemonPage(),
    );
  }
}

// ---------- POKEMON SCREEN ----------

class PokemonPage extends StatefulWidget {
  const PokemonPage({super.key});

  @override
  State<PokemonPage> createState() => _PokemonPageState();
}

class _PokemonPageState extends State<PokemonPage> {
  final TextEditingController searchController =
      TextEditingController(text: 'octillery');

  Pokemon? pokemon;
  bool isLoading = false;
  String? errorMessage;

  @override
  void initState() {
    super.initState();

    // Load the same Pokémon from the previous activity when the app opens.
    searchPokemon();
  }

  @override
  void dispose() {
    searchController.dispose();
    super.dispose();
  }

  Future<void> searchPokemon() async {
    final name = searchController.text.trim().toLowerCase();

    if (name.isEmpty || isLoading) {
      setState(() {
        errorMessage = 'Please enter a Pokémon name.';
      });
      return;
    }

    setState(() {
      isLoading = true;
      errorMessage = null;
      pokemon = null;
    });

    try {
      final result = await fetchPokemon(name);

      if (!mounted) return;

      setState(() {
        pokemon = result;
        isLoading = false;
      });
    } on http.ClientException {
      if (!mounted) return;

      setState(() {
        errorMessage =
            'No internet connection. Please check your connection and try again.';
        isLoading = false;
      });
    } on TimeoutException {
      if (!mounted) return;

      setState(() {
        errorMessage = 'The request took too long. Please try again.';
        isLoading = false;
      });
    } on FormatException {
      if (!mounted) return;

      setState(() {
        errorMessage = 'The Pokémon information could not be processed.';
        isLoading = false;
      });
    } catch (error) {
      if (!mounted) return;

      setState(() {
        errorMessage = error.toString().replaceFirst('Exception: ', '');
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: colors.surface,
      appBar: AppBar(
        title: const Text(
          'Pokémon API Viewer',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // ---------- SEARCH AREA ----------
            Card(
              elevation: 0,
              color: colors.primaryContainer,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Find a Pokémon',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 6),
                    const Text('Enter a Pokémon name to get its information.'),
                    const SizedBox(height: 14),
                    TextField(
                      controller: searchController,
                      textInputAction: TextInputAction.search,
                      onSubmitted: (_) {
                        if (!isLoading) searchPokemon();
                      },
                      decoration: InputDecoration(
                        hintText: 'Example: pikachu',
                        prefixIcon: const Icon(Icons.search),
                        filled: true,
                        fillColor: colors.surface,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: BorderSide.none,
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton.icon(
                        onPressed: isLoading ? null : searchPokemon,
                        icon: const Icon(Icons.search),
                        label: const Text('Search Pokémon'),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),

            // ---------- LOADING INDICATOR ----------
            if (isLoading)
              const Padding(
                padding: EdgeInsets.all(35),
                child: Column(
                  children: [
                    CircularProgressIndicator(),
                    SizedBox(height: 14),
                    Text('Getting Pokémon information...'),
                  ],
                ),
              ),

            // ---------- ERROR MESSAGE ----------
            if (!isLoading && errorMessage != null)
              Card(
                color: colors.errorContainer,
                child: Padding(
                  padding: const EdgeInsets.all(18),
                  child: Column(
                    children: [
                      Icon(
                        Icons.error_outline,
                        color: colors.onErrorContainer,
                        size: 42,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        errorMessage!,
                        textAlign: TextAlign.center,
                        style: TextStyle(color: colors.onErrorContainer),
                      ),
                      const SizedBox(height: 12),
                      OutlinedButton.icon(
                        onPressed: searchPokemon,
                        icon: const Icon(Icons.refresh),
                        label: const Text('Try Again'),
                      ),
                    ],
                  ),
                ),
              ),

            // ---------- POKEMON RESULT ----------
            if (!isLoading && pokemon != null) ...[
              _buildPokemonHeader(pokemon!, colors),
              const SizedBox(height: 16),

              Row(
                children: [
                  Expanded(
                    child: StatCard(
                      icon: Icons.tag,
                      label: 'Pokédex ID',
                      value: '#${pokemon!.id}',
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: StatCard(
                      icon: Icons.height,
                      label: 'Height',
                      value: '${pokemon!.height / 10} m',
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: StatCard(
                      icon: Icons.monitor_weight_outlined,
                      label: 'Weight',
                      value: '${pokemon!.weight / 10} kg',
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              SectionCard(
                title: 'Types',
                icon: Icons.category_outlined,
                child: Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    for (final type in pokemon!.types)
                      Chip(label: Text(prettify(type))),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              SectionCard(
                title: 'Abilities',
                icon: Icons.auto_awesome,
                child: Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    for (final ability in pokemon!.abilities)
                      Chip(
                        avatar: Icon(
                          ability.isHidden
                              ? Icons.visibility_off
                              : Icons.check_circle,
                          size: 18,
                        ),
                        label: Text(
                          ability.isHidden
                              ? '${prettify(ability.name)} (Hidden)'
                              : prettify(ability.name),
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildPokemonHeader(Pokemon pokemon, ColorScheme colors) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [colors.primary, colors.tertiary],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(28),
      ),
      child: Column(
        children: [
          Text(
            '#${pokemon.id.toString().padLeft(4, '0')}',
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 17,
            ),
          ),
          const SizedBox(height: 8),
          Container(
            width: 170,
            height: 170,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.22),
              shape: BoxShape.circle,
            ),
            child: pokemon.imageUrl.isEmpty
                ? const Icon(
                    Icons.catching_pokemon,
                    size: 90,
                    color: Colors.white,
                  )
                : Image.network(
                    pokemon.imageUrl,
                    fit: BoxFit.contain,
                    errorBuilder: (context, error, stackTrace) {
                      return const Icon(
                        Icons.broken_image,
                        size: 70,
                        color: Colors.white,
                      );
                    },
                  ),
          ),
          const SizedBox(height: 10),
          Text(
            prettify(pokemon.name),
            style: const TextStyle(
              color: Colors.white,
              fontSize: 30,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

// ---------- REUSABLE WIDGETS ----------

class StatCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const StatCard({
    super.key,
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 15, horizontal: 5),
      decoration: BoxDecoration(
        color: colors.primaryContainer,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        children: [
          Icon(icon, color: colors.onPrimaryContainer),
          const SizedBox(height: 7),
          Text(
            value,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: colors.onPrimaryContainer,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 3),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              color: colors.onPrimaryContainer,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

class SectionCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final Widget child;

  const SectionCard({
    super.key,
    required this.title,
    required this.icon,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Card(
      elevation: 0,
      color: colors.surfaceContainerHighest.withValues(alpha: 0.55),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: colors.primary),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            child,
          ],
        ),
      ),
    );
  }
}

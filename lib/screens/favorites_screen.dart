import 'dart:async';

import 'package:flutter/material.dart';

import '../models/poi.dart';
import '../services/favorites_service.dart';
import '../theme/app_theme.dart';
import 'explore_screen.dart';
import 'poi_detail_screen.dart';

class FavoritesScreen extends StatefulWidget {
  const FavoritesScreen({super.key});

  @override
  State<FavoritesScreen> createState() => _FavoritesScreenState();
}

class _FavoritesScreenState extends State<FavoritesScreen> {
  final FavoritesService _favoritesService = FavoritesService.instance;
  StreamSubscription<List<Poi>>? _favoritesSubscription;

  List<Poi> _favoritePois = const [];

  @override
  void initState() {
    super.initState();
    _subscribeToFavorites();
  }

  void _subscribeToFavorites() {
    _favoritesSubscription = _favoritesService.favoritesStream().listen((
      favorites,
    ) {
      if (!mounted) return;
      setState(() {
        _favoritePois = favorites;
      });
    });
  }

  Future<void> _loadFavorites() async {
    try {
      final favorites = await _favoritesService.loadFavorites();
      if (!mounted) return;
      setState(() {
        _favoritePois = favorites;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _favoritePois = const [];
      });
    }
  }

  Future<void> _toggleFavorite(Poi poi) async {
    await _favoritesService.toggleFavorite(poi);
    await _loadFavorites();
  }

  @override
  void dispose() {
    _favoritesSubscription?.cancel();
    super.dispose();
  }

  void _openPoiDetail(Poi poi) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => PoiDetailScreen(poi: poi)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final favoritePois = _favoritePois;

    return Scaffold(
      backgroundColor: AppColors.background,

      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        title: const Text(
          'Mes favoris',
          style: TextStyle(
            color: AppColors.textPrimary,
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),

      body: favoritePois.isEmpty
          ? _buildEmptyState()
          : ListView.builder(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 110),
              itemCount: favoritePois.length,
              itemBuilder: (context, index) {
                final poi = favoritePois[index];

                return _FavoritePoiCard(
                  poi: poi,
                  onTap: () => _openPoiDetail(poi),
                  onFavoritePressed: () async => _toggleFavorite(poi),
                );
              },
            ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 90,
              height: 90,
              decoration: BoxDecoration(
                color: AppColors.accent.withValues(alpha: 0.10),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.bookmark_border,
                color: AppColors.accent,
                size: 44,
              ),
            ),

            const SizedBox(height: 24),

            const Text(
              'Aucun favori pour le moment',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: AppColors.textPrimary,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 10),

            Text(
              'Enregistrez les lieux que vous souhaitez '
              'retrouver facilement pendant votre voyage.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: AppColors.grey,
                fontSize: 14,
                height: 1.5,
              ),
            ),

            const SizedBox(height: 24),

            ElevatedButton.icon(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const ExploreScreen(),
                  ),
                );
              },
              icon: const Icon(Icons.explore_outlined),
              label: const Text('Explorer les lieux'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.accent,
                foregroundColor: AppColors.white,
                elevation: 2,
                padding: const EdgeInsets.symmetric(
                  horizontal: 22,
                  vertical: 13,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(24),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FavoritePoiCard extends StatelessWidget {
  final Poi poi;
  final VoidCallback onTap;
  final VoidCallback onFavoritePressed;

  const _FavoritePoiCard({
    required this.poi,
    required this.onTap,
    required this.onFavoritePressed,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),

      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: const [
          BoxShadow(
            color: Color(0x12000000),
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
      ),

      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),

        child: Padding(
          padding: const EdgeInsets.all(10),

          child: Row(
            children: [
              // IMAGE
              ClipRRect(
                borderRadius: BorderRadius.circular(14),

                child: Image.asset(
                  poi.imagePath,
                  width: 105,
                  height: 105,
                  fit: BoxFit.cover,

                  errorBuilder: (context, error, stackTrace) {
                    return Container(
                      width: 105,
                      height: 105,
                      color: AppColors.background,
                      child: const Icon(
                        Icons.image_not_supported_outlined,
                        color: AppColors.grey,
                        size: 35,
                      ),
                    );
                  },
                ),
              ),

              const SizedBox(width: 12),

              // INFORMATIONS
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // catégorie
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 9,
                        vertical: 4,
                      ),

                      decoration: BoxDecoration(
                        color: AppColors.accent.withValues(alpha: 0.10),
                        borderRadius: BorderRadius.circular(20),
                      ),

                      child: Text(
                        poi.category,
                        style: const TextStyle(
                          color: AppColors.accent,
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),

                    const SizedBox(height: 7),

                    // nom
                    Text(
                      poi.name,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),

                    const SizedBox(height: 6),

                    // adresse
                    Row(
                      children: [
                        const Icon(
                          Icons.location_on_outlined,
                          color: AppColors.primary,
                          size: 15,
                        ),

                        const SizedBox(width: 4),

                        Expanded(
                          child: Text(
                            poi.address,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: AppColors.grey,
                              fontSize: 12,
                            ),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 6),

                    // note
                    Row(
                      children: [
                        const Icon(
                          Icons.star,
                          color: AppColors.accent,
                          size: 16,
                        ),

                        const SizedBox(width: 4),

                        Text(
                          poi.rating.toString(),
                          style: const TextStyle(
                            color: AppColors.textPrimary,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              // FAVORI
              IconButton(
                onPressed: onFavoritePressed,
                icon: const Icon(Icons.favorite, color: AppColors.accent),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';

import '../models/poi.dart';
import '../services/favorites_service.dart';
import '../theme/app_theme.dart';

class PoiDetailScreen extends StatefulWidget {
  final Poi poi;

  const PoiDetailScreen({super.key, required this.poi});

  @override
  State<PoiDetailScreen> createState() => _PoiDetailScreenState();
}

class _PoiDetailScreenState extends State<PoiDetailScreen> {
  final FavoritesService _favoritesService = FavoritesService.instance;

  bool _isFavorite = false;

  @override
  void initState() {
    super.initState();
    _refreshFavoriteState();
  }

  Future<void> _refreshFavoriteState() async {
    try {
      await _favoritesService.loadFavorites();
      if (!mounted) return;
      final isFavorite = await _favoritesService.isFavorite(widget.poi);
      setState(() {
        _isFavorite = isFavorite;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _isFavorite = false;
      });
    }
  }

  Future<void> _toggleFavorite() async {
    try {
      await _favoritesService.toggleFavorite(widget.poi);
      await _refreshFavoriteState();

      if (!mounted) {
        return;
      }

      final message = _isFavorite
          ? '${widget.poi.name} ajouté aux favoris'
          : '${widget.poi.name} retiré des favoris';

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 2),
        ),
      );
    } catch (_) {
      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Impossible de mettre à jour les favoris. Vérifie les règles Firebase et l’authentification.',
          ),
          behavior: SnackBarBehavior.floating,
          duration: Duration(seconds: 3),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,

      body: CustomScrollView(
        slivers: [
          //btn retour + image+btn favoris
          SliverAppBar(
            expandedHeight: 280,
            pinned: true,

            backgroundColor: AppColors.primary,

            iconTheme: const IconThemeData(color: AppColors.white),

            actions: [
              Padding(
                padding: const EdgeInsets.only(right: 12),
                child: Container(
                  decoration: BoxDecoration(
                    color: AppColors.white.withValues(alpha: 0.90),
                    shape: BoxShape.circle,
                  ),
                  child: IconButton(
                    onPressed: _toggleFavorite,
                    tooltip: _isFavorite
                        ? 'Retirer des favoris'
                        : 'Ajouter aux favoris',
                    icon: Icon(
                      _isFavorite
                          ? Icons.favorite_rounded
                          : Icons.favorite_border_rounded,
                      color: AppColors.accent,
                    ),
                  ),
                ),
              ),
            ],

            flexibleSpace: FlexibleSpaceBar(
              background: widget.poi.displayImage.startsWith('http')
                  ? Image.network(
                      widget.poi.displayImage,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return _buildImageFallback();
                      },
                    )
                  : Image.asset(
                widget.poi.displayImage,
                fit: BoxFit.cover,
                errorBuilder: (
                  context,
                  error,
                  stackTrace,
                ) {
                  return _buildImageFallback();
                },
              ),
            ),
          ),

          //contenu
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(20),

              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,

                children: [
                  //categorie
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 7,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.accent.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      widget.poi.category,
                      style: const TextStyle(
                        color: AppColors.accent,
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                      ),
                    ),
                  ),

                  const SizedBox(height: 12),

                  //nom+note
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Text(
                          widget.poi.name,
                          style: const TextStyle(
                            color: AppColors.textPrimary,
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),

                      const SizedBox(width: 12),

                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 7,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.white,
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: const [
                            BoxShadow(
                              color: Color(0x12000000),
                              blurRadius: 8,
                              offset: Offset(0, 3),
                            ),
                          ],
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.star,
                              color: AppColors.accent,
                              size: 18,
                            ),

                            const SizedBox(width: 4),

                            Text(
                              widget.poi.rating.toString(),
                              style: const TextStyle(
                                color: AppColors.textPrimary,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 14),

                  //adresse
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(
                        Icons.location_on_outlined,
                        color: AppColors.primary,
                        size: 21,
                      ),

                      const SizedBox(width: 8),

                      Expanded(
                        child: Text(
                          widget.poi.address,
                          style: TextStyle(color: AppColors.grey, fontSize: 15),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 24),

                  //description
                  const Text(
                    'À propos de ce lieu',
                    style: TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),

                  const SizedBox(height: 10),

                  Text(
                    widget.poi.description,
                    style: TextStyle(
                      color: AppColors.grey,
                      fontSize: 15,
                      height: 1.6,
                    ),
                  ),

                  const SizedBox(height: 28),

                  //info pratique
                  const Text(
                    'Informations pratiques',
                    style: TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),

                  const SizedBox(height: 14),

                  _InfoCard(
                    icon: Icons.location_on_outlined,
                    title: 'Localisation',
                    value: widget.poi.address,
                  ),

                  const SizedBox(height: 10),

                  _InfoCard(
                    icon: Icons.category_outlined,
                    title: 'Catégorie',
                    value: widget.poi.category,
                  ),

                  const SizedBox(height: 10),

                  _InfoCard(
                    icon: Icons.star_outline,
                    title: 'Note',
                    value: '${widget.poi.rating} / 5',
                  ),

                  const SizedBox(height: 30),

                  //btn "y aller"
                  SizedBox(
                    width: double.infinity,
                    height: 54,

                    child: ElevatedButton.icon(
                      onPressed: () {
                        // Navigation GPS à ajouter plus tard.
                      },

                      icon: const Icon(Icons.directions),

                      label: const Text(
                        'Y aller',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),

                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.accent,
                        foregroundColor: AppColors.white,
                        elevation: 3,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(24),
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildImageFallback() {
    return Container(
      color: AppColors.background,
      child: const Center(
        child: Icon(
          Icons.image_not_supported_outlined,
          size: 60,
        ),
      ),
    );
  }
}

//carte info
class _InfoCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String value;

  const _InfoCard({
    required this.icon,
    required this.title,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),

      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(16),

        boxShadow: const [
          BoxShadow(
            color: Color(0x10000000),
            blurRadius: 8,
            offset: Offset(0, 3),
          ),
        ],
      ),

      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,

            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.10),
              shape: BoxShape.circle,
            ),

            child: Icon(icon, color: AppColors.primary, size: 21),
          ),

          const SizedBox(width: 12),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,

              children: [
                Text(
                  title,
                  style: TextStyle(color: AppColors.grey, fontSize: 12),
                ),

                const SizedBox(height: 3),

                Text(
                  value,
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

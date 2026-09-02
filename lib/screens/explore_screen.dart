import 'package:flutter/material.dart';

import '../data/mock_pois.dart';
import '../models/poi.dart';
import '../services/poi_service.dart';
import '../theme/app_theme.dart';
import 'poi_detail_screen.dart';

class ExploreScreen extends StatefulWidget {
  const ExploreScreen({super.key});

  @override
  State<ExploreScreen> createState() => _ExploreScreenState();
}

class _ExploreScreenState extends State<ExploreScreen> {
  final TextEditingController _searchController = TextEditingController();

  String _selectedCategory = 'Tous';
  String _searchQuery = '';
  bool _isLoadingPois = true;
  List<Poi> _allPois = [];

  final List<String> _categories = [
    'Tous',
    'Monument',
    'Nature',
    'Musée',
    'Marché',
    'Restaurant',
    'Hôtel',
  ];

  String _normalizeCategory(String category) {
    return category
        .trim()
        .toLowerCase()
        .replaceAll('é', 'e')
        .replaceAll('è', 'e')
        .replaceAll('ê', 'e')
        .replaceAll('ô', 'o')
        .replaceAll('à', 'a')
        .replaceAll('ç', 'c')
        .replaceAll(' ', '');
  }

  @override
  void initState() {
    super.initState();
    _loadPois();

    _searchController.addListener(() {
      setState(() {
        _searchQuery = _searchController.text.toLowerCase().trim();
      });
    });
  }

  Future<void> _loadPois() async {
    try {
      final loadedPois = await PoiService.instance.getPois();

      if (!mounted) return;

      setState(() {
        _allPois = loadedPois.isEmpty ? mockPois : loadedPois;
        _isLoadingPois = false;
      });
    } catch (_) {
      if (!mounted) return;

      setState(() {
        _allPois = mockPois;
        _isLoadingPois = false;
      });
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<Poi> get _filteredPois {
    return _allPois.where((poi) {
      final selectedCategory = _normalizeCategory(_selectedCategory);
      final poiCategory = _normalizeCategory(poi.category);

      final matchesCategory =
          _selectedCategory == 'Tous' || poiCategory == selectedCategory;

      final matchesSearch =
          _searchQuery.isEmpty ||
          poi.name.toLowerCase().contains(_searchQuery) ||
          poiCategory.contains(_searchQuery) ||
          poi.address.toLowerCase().contains(_searchQuery);

      return matchesCategory && matchesSearch;
    }).toList();
  }

  void _selectCategory(String category) {
    setState(() {
      _selectedCategory = category;
    });
  }

  void _openPoiDetail(Poi poi) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => PoiDetailScreen(poi: poi)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final pois = _filteredPois;

    return Scaffold(
      backgroundColor: AppColors.background,

      appBar: AppBar(
        backgroundColor: AppColors.background,
        foregroundColor: AppColors.textPrimary,
        elevation: 0,

        title: const Text(
          'Explorer',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
      ),

      body: _isLoadingPois
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
                  child: _buildSearchBar(),
                ),

                _buildCategories(),

                const SizedBox(height: 16),

                Expanded(
                  child: pois.isEmpty
                      ? _buildEmptyState()
                      : ListView.separated(
                          padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),

                          itemCount: pois.length,

                          separatorBuilder: (context, index) =>
                              const SizedBox(height: 14),

                          itemBuilder: (context, index) {
                            final poi = pois[index];

                            return _PoiCard(
                              poi: poi,
                              onTap: () => _openPoiDetail(poi),
                            );
                          },
                        ),
                ),
              ],
            ),
    );
  }

  //recherche
  Widget _buildSearchBar() {
    return Container(
      height: 52,

      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(26),

        boxShadow: const [
          BoxShadow(
            color: Color(0x12000000),
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
      ),

      child: TextField(
        controller: _searchController,

        textInputAction: TextInputAction.search,

        decoration: InputDecoration(
          hintText: 'Rechercher un lieu...',
          hintStyle: TextStyle(color: AppColors.grey, fontSize: 14),

          prefixIcon: const Icon(Icons.search, color: AppColors.primary),

          suffixIcon: _searchQuery.isNotEmpty
              ? IconButton(
                  onPressed: () {
                    _searchController.clear();
                  },
                  icon: const Icon(Icons.close, color: AppColors.grey),
                )
              : const Icon(Icons.tune, color: AppColors.primary),

          border: InputBorder.none,

          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 15,
          ),
        ),
      ),
    );
  }

  //categorie
  Widget _buildCategories() {
    return SizedBox(
      height: 42,

      child: ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: 16),

        scrollDirection: Axis.horizontal,

        itemCount: _categories.length,

        separatorBuilder: (context, index) => const SizedBox(width: 8),

        itemBuilder: (context, index) {
          final category = _categories[index];

          final isSelected = category == _selectedCategory;

          return GestureDetector(
            onTap: () => _selectCategory(category),

            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),

              padding: const EdgeInsets.symmetric(horizontal: 16),

              decoration: BoxDecoration(
                color: isSelected ? AppColors.primary : AppColors.white,

                borderRadius: BorderRadius.circular(22),

                border: Border.all(
                  color: isSelected
                      ? AppColors.primary
                      : const Color(0xFFE2E8F0),
                ),
              ),

              child: Center(
                child: Text(
                  category,
                  style: TextStyle(
                    color: isSelected ? AppColors.white : AppColors.textPrimary,

                    fontSize: 13,

                    fontWeight: isSelected
                        ? FontWeight.w600
                        : FontWeight.normal,
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  //aucun resultat
  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),

        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,

          children: [
            Container(
              width: 80,
              height: 80,

              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.08),
                shape: BoxShape.circle,
              ),

              child: const Icon(
                Icons.search_off,
                color: AppColors.primary,
                size: 38,
              ),
            ),

            const SizedBox(height: 20),

            const Text(
              'Aucun lieu trouvé',
              style: TextStyle(
                color: AppColors.textPrimary,
                fontSize: 19,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 8),

            Text(
              'Essayez une autre recherche ou une autre catégorie.',
              textAlign: TextAlign.center,

              style: TextStyle(
                color: AppColors.grey,
                fontSize: 14,
                height: 1.5,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

//carte POI
class _PoiCard extends StatelessWidget {
  final Poi poi;
  final VoidCallback onTap;

  const _PoiCard({required this.poi, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.white,

      borderRadius: BorderRadius.circular(20),

      child: InkWell(
        onTap: onTap,

        borderRadius: BorderRadius.circular(20),

        child: Padding(
          padding: const EdgeInsets.all(10),

          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,

            children: [
              //image
              ClipRRect(
                borderRadius: BorderRadius.circular(14),

                child: poi.displayImage.startsWith('http')
                    ? Image.network(
                        poi.displayImage,
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
                              size: 32,
                            ),
                          );
                        },
                      )
                    : Image.asset(
                        poi.displayImage.isEmpty
                            ? 'assets/images/pois/rova.jpg'
                            : poi.displayImage,
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
                              size: 32,
                            ),
                          );
                        },
                      ),
              ),

              const SizedBox(width: 12),

              //info
              Expanded(
                child: SizedBox(
                  height: 105,

                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,

                    children: [
                      // catégorie + note
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              poi.category,

                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,

                              style: const TextStyle(
                                color: AppColors.accent,
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),

                          const Icon(
                            Icons.star,
                            color: AppColors.accent,
                            size: 16,
                          ),

                          const SizedBox(width: 3),

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

                      const SizedBox(height: 5),

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

                      const Spacer(),

                      // adresse
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,

                        children: [
                          const Icon(
                            Icons.location_on_outlined,
                            color: AppColors.primary,
                            size: 16,
                          ),

                          const SizedBox(width: 4),

                          Expanded(
                            child: Text(
                              poi.address,

                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,

                              style: TextStyle(
                                color: AppColors.grey,
                                fontSize: 12,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(width: 4),

              const Icon(Icons.chevron_right, color: AppColors.grey),
            ],
          ),
        ),
      ),
    );
  }
}

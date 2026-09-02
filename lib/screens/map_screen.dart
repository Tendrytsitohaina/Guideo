import 'dart:async';
import 'dart:convert';
import 'dart:ui' as ui;

import 'package:http/http.dart' as http;
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';

import '../services/location_service.dart';
import '../services/poi_service.dart';
import '../theme/app_theme.dart';

import '../data/mock_pois.dart';
import '../models/poi.dart';
import 'poi_detail_screen.dart';

class MapScreen extends StatefulWidget {
  const MapScreen({super.key});

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  final MapController _mapController = MapController();
  final LocationService _locationService = LocationService();
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();

  IconData _getPoiIcon(String category) {
    final normalized = category
        .trim()
        .toLowerCase()
        .replaceAll('é', 'e')
        .replaceAll('è', 'e')
        .replaceAll('ê', 'e')
        .replaceAll('ô', 'o')
        .replaceAll('à', 'a')
        .replaceAll('ç', 'c')
        .replaceAll(' ', '');

    switch (normalized) {
      case 'monument':
        return Icons.account_balance;

      case 'nature':
        return Icons.park;

      case 'musee':
        return Icons.museum;

      case 'marche':
        return Icons.storefront;

      case 'restaurant':
        return Icons.restaurant;

      case 'hotel':
        return Icons.hotel;

      default:
        return Icons.location_on;
    }
  }

  void _showPoiPreview(Poi poi) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return _PoiBottomSheet(poi: poi);
      },
    );
  }

  StreamSubscription<Position>? _positionSubscription;

  //position_utilisateur
  LatLng? _userPosition;

  bool _isLoadingLocation = true;
  List<Poi> _pois = [];
  String _searchQuery = '';
  String _selectedCategory = 'Tous';
  bool _showNearbyOnly = false;
  double _nearbyRadiusInKm = 5.0;
  Timer? _locationSearchTimer;
  List<_MapLocationResult> _locationResults = [];
  bool _isSearchingLocations = false;
  List<LatLng> _routePoints = [];
  double? _routeDistanceInMeters;
  double? _routeDurationInSeconds;
  String? _routeDestinationName;
  LatLng? _routeDestination;
  bool _isLoadingRoute = false;
  int _routeRequestId = 0;

  //position si gps indispo
  final LatLng _initialPosition = const LatLng(-18.8792, 47.5079);

  double _currentZoom = 13.0;

  String _normalizeSearchText(String text) {
    return text
        .trim()
        .toLowerCase()
        .replaceAll('é', 'e')
        .replaceAll('è', 'e')
        .replaceAll('ê', 'e')
        .replaceAll('ô', 'o')
        .replaceAll('à', 'a')
        .replaceAll('ç', 'c')
        .replaceAll('ù', 'u')
        .replaceAll('û', 'u');
  }

    List<Poi> get _visiblePois {
    final category = _normalizeSearchText(_selectedCategory);
    final userPosition = _userPosition;

    final pois = _pois.where((poi) {
      final matchesCategory =
          _selectedCategory == 'Tous' ||
          _normalizeSearchText(poi.category) == category;

      if (!matchesCategory) {
        return false;
      }

      if (!_showNearbyOnly) {
        return true;
      }

      if (userPosition == null) {
        return false;
      }

      final distance = PoiService.instance.distanceInKm(
        userPosition.latitude,
        userPosition.longitude,
        poi.latitude,
        poi.longitude,
      );

      return distance <= _nearbyRadiusInKm;
    }).toList();

    if (userPosition != null) {
      pois.sort((a, b) {
        final distanceA = PoiService.instance.distanceInKm(
          userPosition.latitude,
          userPosition.longitude,
          a.latitude,
          a.longitude,
        );

        final distanceB = PoiService.instance.distanceInKm(
          userPosition.latitude,
          userPosition.longitude,
          b.latitude,
          b.longitude,
        );

        return distanceA.compareTo(distanceB);
      });
    }

    return pois;
  }

  String _formatRadius(double radius) {
    if (radius == radius.roundToDouble()) {
      return '${radius.round()} km';
    }

    return '${radius.toStringAsFixed(1)} km';
  }

  void _toggleNearbyPois() {
    if (_userPosition == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Position actuelle indisponible. Activez la localisation.',
          ),
        ),
      );
      return;
    }

    setState(() {
      _showNearbyOnly = !_showNearbyOnly;
    });
  }

  void _setNearbyRadius(double radius) {
    if (_userPosition == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Position actuelle indisponible. Activez la localisation.',
          ),
        ),
      );
      return;
    }

    setState(() {
      _nearbyRadiusInKm = radius;
      _showNearbyOnly = true;
    });
  }

    Future<void> _openNearbyRadiusPicker() async {
    if (_userPosition == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Position actuelle indisponible. Activez la localisation.',
          ),
        ),
      );
      return;
    }

    const radiuses = [1.0, 3.0, 5.0, 10.0, 20.0];

    final selectedRadius = await showModalBottomSheet<double>(
      context: context,
      builder: (context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const ListTile(
                title: Text(
                  'Rayon de recherche',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                subtitle: Text(
                  'Afficher les POI autour de votre position',
                ),
              ),

              ...radiuses.map((radius) {
                final isSelected = radius == _nearbyRadiusInKm;

                return ListTile(
                  leading: Icon(
                    isSelected
                        ? Icons.radio_button_checked
                        : Icons.radio_button_off,
                    color: AppColors.primary,
                  ),
                  title: Text(
                    'Moins de ${_formatRadius(radius)}',
                  ),
                  onTap: () => Navigator.pop(context, radius),
                );
              }),
            ],
          ),
        );
      },
    );

    if (!mounted || selectedRadius == null) {
      return;
    }

    _setNearbyRadius(selectedRadius);
  }

  void _searchLocations(String value) {
    _locationSearchTimer?.cancel();
    final query = value.trim();

    if (query.length < 2) {
      setState(() {
        _locationResults = [];
        _isSearchingLocations = false;
      });
      return;
    }

    setState(() {
      _isSearchingLocations = true;
    });

    _locationSearchTimer = Timer(
      const Duration(milliseconds: 500),
      () => _loadLocationResults(query),
    );
  }

  Future<void> _loadLocationResults(String query) async {
    try {
      final response = await http.get(
        Uri.https(
          'nominatim.openstreetmap.org',
          '/search',
          {
            'q': query,
            'format': 'jsonv2',
            'limit': '5',
            'countrycodes': 'mg',
            'addressdetails': '1',
          },
        ),
        headers: const {
          'User-Agent': 'MadaGuide/1.0 (Flutter tourist guide)',
        },
      );

      if (!mounted || _searchController.text.trim() != query) {
        return;
      }

      if (response.statusCode != 200) {
        throw Exception('Geocoding request failed');
      }

      final data = jsonDecode(response.body) as List<dynamic>;
      final results = data
          .whereType<Map<String, dynamic>>()
          .map(_MapLocationResult.fromJson)
          .whereType<_MapLocationResult>()
          .toList();

      setState(() {
        _locationResults = results;
        _isSearchingLocations = false;
      });
    } catch (_) {
      if (!mounted || _searchController.text.trim() != query) {
        return;
      }

      setState(() {
        _locationResults = [];
        _isSearchingLocations = false;
      });
    }
  }

  void _selectLocation(_MapLocationResult location) {
    _searchController.text = location.displayName;
    _searchController.selection = TextSelection.collapsed(
      offset: _searchController.text.length,
    );
    FocusScope.of(context).unfocus();

    setState(() {
      _locationResults = [];
    });

    _mapController.move(location.position, 16.0);
    _loadRouteTo(location.position, location.name);
  }

  Future<void> _loadRouteTo(LatLng destination, String destinationName) async {
    final origin = _userPosition;
    if (origin == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Position actuelle indisponible.')),
        );
      }
      return;
    }

    final requestId = ++_routeRequestId;
    setState(() {
      _isLoadingRoute = true;
      _routeDestinationName = destinationName;
      _routeDestination = destination;
      _routePoints = [];
      _routeDistanceInMeters = null;
      _routeDurationInSeconds = null;
    });

    try {
      final response = await http.get(
        Uri.https(
          'router.project-osrm.org',
          '/route/v1/driving/${origin.longitude},${origin.latitude};'
              '${destination.longitude},${destination.latitude}',
          {
            'overview': 'full',
            'geometries': 'geojson',
            'steps': 'false',
          },
        ),
        headers: const {
          'User-Agent': 'MadaGuide/1.0 (Flutter tourist guide)',
        },
      );

      if (response.statusCode != 200) {
        throw Exception('Route request failed');
      }

      final data = jsonDecode(response.body) as Map<String, dynamic>;
      final routes = data['routes'] as List<dynamic>?;
      if (routes == null || routes.isEmpty) {
        throw Exception('No route found');
      }

      final route = routes.first as Map<String, dynamic>;
      final geometry = route['geometry'] as Map<String, dynamic>?;
      final coordinates = geometry?['coordinates'] as List<dynamic>?;
      if (coordinates == null || coordinates.isEmpty) {
        throw Exception('Route geometry missing');
      }

      final points = coordinates
          .whereType<List<dynamic>>()
          .where((point) => point.length >= 2)
          .map((point) => LatLng(
                (point[1] as num).toDouble(),
                (point[0] as num).toDouble(),
              ))
          .toList();

      if (!mounted || requestId != _routeRequestId) {
        return;
      }

      setState(() {
        _routePoints = points;
        _routeDistanceInMeters = (route['distance'] as num?)?.toDouble();
        _routeDurationInSeconds = (route['duration'] as num?)?.toDouble();
        _isLoadingRoute = false;
      });
    } catch (_) {
      if (!mounted || requestId != _routeRequestId) {
        return;
      }

      setState(() {
        _isLoadingRoute = false;
        _routePoints = [];
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Impossible de calculer cet itinéraire.'),
        ),
      );
    }
  }

  void _clearRoute() {
    ++_routeRequestId;
    setState(() {
      _routePoints = [];
      _routeDistanceInMeters = null;
      _routeDurationInSeconds = null;
      _routeDestinationName = null;
      _routeDestination = null;
      _isLoadingRoute = false;
    });
  }

  Future<void> _openCategoryFilter() async {
    const categories = [
      'Tous',
      'Monument',
      'Nature',
      'Musée',
      'Marché',
      'Restaurant',
      'Hôtel',
    ];

    final selectedCategory = await showModalBottomSheet<String>(
      context: context,
      builder: (context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: categories.map((category) {
              return ListTile(
                leading: Icon(
                  category == _selectedCategory
                      ? Icons.radio_button_checked
                      : Icons.radio_button_off,
                  color: AppColors.primary,
                ),
                title: Text(category),
                onTap: () => Navigator.pop(context, category),
              );
            }).toList(),
          ),
        );
      },
    );

    if (!mounted || selectedCategory == null) {
      return;
    }

    setState(() {
      _selectedCategory = selectedCategory;
    });
  }

  @override
  void initState() {
    super.initState();
    _loadPois();
    //recuperer position actuel
    _loadUserLocation();

    //ecoute déplacement_user
    _listenToLocation();
  }

  Future<void> _loadPois() async {
    try {
      final loadedPois = await PoiService.instance.getPois();

      if (!mounted) return;

      setState(() {
        _pois = loadedPois.isEmpty ? mockPois : loadedPois;
      });
    } catch (_) {
      if (!mounted) return;

      setState(() {
        _pois = mockPois;
      });
    }
  }

  Future<void> _loadUserLocation() async {
    final position = await _locationService.getCurrentPosition();

    if (!mounted) return;

    if (position != null) {
      final userPosition = LatLng(position.latitude, position.longitude);

      setState(() {
        _userPosition = userPosition;
        _isLoadingLocation = false;
        _currentZoom = 15.0;
      });

      _mapController.move(userPosition, 15);
    } else {
      //gps indispo ou permission refusé
      setState(() {
        _isLoadingLocation = false;
      });
    }
  }

  //suivi position user
  void _listenToLocation() {
    _positionSubscription = _locationService.getPositionStream().listen((
      position,
    ) {
      if (!mounted) return;

      setState(() {
        _userPosition = LatLng(position.latitude, position.longitude);
      });
    });
  }

  void _zoomIn() {
    final center = _mapController.camera.center;

    setState(() {
      _currentZoom = (_currentZoom + 1).clamp(5.0, 18.0);
    });

    _mapController.move(center, _currentZoom);
  }

  void _zoomOut() {
    final center = _mapController.camera.center;

    setState(() {
      _currentZoom = (_currentZoom - 1).clamp(5.0, 18.0);
    });

    _mapController.move(center, _currentZoom);
  }

  void _recenterMap() {
    if (_userPosition == null) {
      return;
    }

    setState(() {
      _currentZoom = 15.0;
    });

    _mapController.move(_userPosition!, _currentZoom);
  }

  @override
  void dispose() {
    _positionSubscription?.cancel();
    _locationSearchTimer?.cancel();
    ++_routeRequestId;
    _mapController.dispose();
    _searchController.dispose();
    _searchFocusNode.dispose();

    super.dispose();
  }

  //interface
  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        //carte
        FlutterMap(
          mapController: _mapController,

          options: MapOptions(
            initialCenter: _initialPosition,
            initialZoom: _currentZoom,
            minZoom: 5,
            maxZoom: 18,
          ),

          children: [
            TileLayer(
              urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
              userAgentPackageName: 'com.example.guide_touristique_augmente',
            ),

            if (_routePoints.isNotEmpty)
              PolylineLayer(
                polylines: [
                  Polyline(
                    points: _routePoints,
                    color: AppColors.accent,
                    strokeWidth: 5,
                  ),
                ],
              ),
 
          //position utilisateur
            MarkerLayer(
              markers: [
                if (_userPosition != null)
                  Marker(
                    point: _userPosition!,
                    width: 56,
                    height: 56,
                    child: Container(
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.15),
                        shape: BoxShape.circle,
                      ),
                      child: Center(
                        child: Container(
                          width: 22,
                          height: 22,
                          decoration: BoxDecoration(
                            color: AppColors.primary,
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: AppColors.white,
                              width: 3,
                            ),
                            boxShadow: const [
                              BoxShadow(
                                color: Color(0x33000000),
                                blurRadius: 6,
                                offset: Offset(0, 2),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),

                //poi
                ..._visiblePois.map(
                  (poi) => Marker(
                    point: LatLng(poi.latitude, poi.longitude),
                    width: 50,
                    height: 60,

                    child: GestureDetector(
                      onTap: () {
                        _loadRouteTo(
                          LatLng(poi.latitude, poi.longitude),
                          poi.name,
                        );
                        _showPoiPreview(poi);
                      },

                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 44,
                            height: 44,

                            decoration: BoxDecoration(
                              color: AppColors.accent,
                              shape: BoxShape.circle,

                              border: Border.all(
                                color: AppColors.white,
                                width: 3,
                              ),

                              boxShadow: const [
                                BoxShadow(
                                  color: Color(0x33000000),
                                  blurRadius: 8,
                                  offset: Offset(0, 3),
                                ),
                              ],
                            ),

                            child: Icon(
                              _getPoiIcon(poi.category),
                              color: AppColors.white,
                              size: 22,
                            ),
                          ),

                          // Petite pointe sous le marqueur
                          CustomPaint(
                            size: const Size(12, 6),
                            painter: _MarkerPointerPainter(
                              color: AppColors.accent,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                if (_routeDestination != null)
                  Marker(
                    point: _routeDestination!,
                    width: 48,
                    height: 48,
                    child: const Icon(
                      Icons.location_on,
                      color: AppColors.primary,
                      size: 42,
                    ),
                  ),
              ],
            ),
          ],
        ),

        if (_isLoadingLocation)
          const Positioned(
            top: 85,
            left: 0,
            right: 0,
            child: Center(
              child: Card(
                elevation: 4,
                child: Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                      SizedBox(width: 10),
                      Text('Localisation en cours...'),
                    ],
                  ),
                ),
              ),
            ),
          ),

        Positioned(top: 16, left: 16, right: 16, child: _buildSearchBar()),

        if (_locationResults.isNotEmpty || _isSearchingLocations)
          Positioned(
            top: 72,
            left: 16,
            right: 16,
            child: _buildLocationResults(),
          ),

        Positioned(
          right: 16,
          top: 100,
          child: _buildMapControls(),
        ),

        Positioned(
          left: 16,
          bottom: _routePoints.isNotEmpty || _isLoadingRoute ? 175 : 90,
          child: _buildMapInfo(),
        ),

        if (_showNearbyOnly &&
            _locationResults.isEmpty &&
            !_isSearchingLocations)
          Positioned(
            top: 78,
            left: 16,
            right: 82,
            child: _buildNearbyFilterInfo(),
          ),

        if (_routePoints.isNotEmpty || _isLoadingRoute)
          Positioned(
            left: 16,
            right: 16,
            bottom: 90,
            child: _buildRouteInfo(),
          ),
      ],
    );
  }

  //barre de recherche
  Widget _buildSearchBar() {
    return Material(
      elevation: 4,
      borderRadius: BorderRadius.circular(24),

      child: Container(
        height: 52,

        padding: const EdgeInsets.symmetric(horizontal: 16),

        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(24),
        ),

        child: Row(
          children: [
            const SizedBox(
              width: 24,
              child: Icon(
                Icons.search,
                color: AppColors.primary,
              ),
            ),

            const SizedBox(width: 12),

            Expanded(
              child: TextField(
                controller: _searchController,
                focusNode: _searchFocusNode,
                onChanged: (value) {
                  setState(() {
                    _searchQuery = value;
                  });
                  _searchLocations(value);
                },
                decoration: InputDecoration(
                  hintText: 'Rechercher un lieu...',
                  hintStyle: TextStyle(
                    color: AppColors.grey,
                    fontSize: 15,
                  ),
                  border: InputBorder.none,
                  isDense: true,
                ),
              ),
            ),

            _searchQuery.isNotEmpty
                ? IconButton(
                    onPressed: () {
                      _searchController.clear();
                      setState(() {
                        _searchQuery = '';
                        _locationResults = [];
                      });
                      _locationSearchTimer?.cancel();
                    },
                    tooltip: 'Effacer la recherche',
                    icon: const Icon(
                      Icons.close,
                      color: AppColors.grey,
                    ),
                  )
                : IconButton(
                    onPressed: _openCategoryFilter,
                    tooltip: 'Filtrer les lieux',
                    icon: const Icon(
                      Icons.tune,
                      color: AppColors.primary,
                    ),
                  ),
          ],
        ),
      ),
    );
  }

  Widget _buildLocationResults() {
    return Material(
      elevation: 4,
      borderRadius: BorderRadius.circular(16),
      color: AppColors.white,
      child: _isSearchingLocations
          ? const Padding(
              padding: EdgeInsets.all(16),
              child: Center(
                child: SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              ),
            )
          : ListView.separated(
              shrinkWrap: true,
              padding: const EdgeInsets.symmetric(vertical: 6),
              itemCount: _locationResults.length,
              separatorBuilder: (_, _) => const Divider(height: 1),
              itemBuilder: (context, index) {
                final location = _locationResults[index];
                return ListTile(
                  dense: true,
                  leading: const Icon(
                    Icons.location_on_outlined,
                    color: AppColors.primary,
                  ),
                  title: Text(
                    location.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  subtitle: Text(
                    location.displayName,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  onTap: () => _selectLocation(location),
                );
              },
            ),
    );
  }

    Widget _buildNearbyFilterInfo() {
    final count = _visiblePois.length;

    return Material(
      elevation: 4,
      borderRadius: BorderRadius.circular(18),
      color: AppColors.white,
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: 12,
          vertical: 8,
        ),
        child: Row(
          children: [
            const Icon(
              Icons.near_me,
              color: AppColors.primary,
              size: 20,
            ),

            const SizedBox(width: 8),

            Expanded(
              child: Text(
                '$count POI à moins de ${_formatRadius(_nearbyRadiusInKm)}',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                ),
              ),
            ),

            TextButton(
              onPressed: _openNearbyRadiusPicker,
              child: const Text('Rayon'),
            ),

            IconButton(
              onPressed: () {
                setState(() {
                  _showNearbyOnly = false;
                });
              },
              tooltip: 'Désactiver le filtre proche',
              icon: const Icon(
                Icons.close,
                size: 20,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMapControls() {
    return Column(
      children: [
        // Zoom +
        _MapButton(icon: Icons.add, onPressed: _zoomIn),

        const SizedBox(height: 8),

        //zoom
        _MapButton(icon: Icons.remove, onPressed: _zoomOut),

        const SizedBox(height: 8),

        //position actuel
        _MapButton(icon: Icons.my_location, onPressed: _recenterMap),
      ],
    );
  }

  Widget _buildRouteInfo() {
    return Material(
      elevation: 5,
      borderRadius: BorderRadius.circular(18),
      color: AppColors.white,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 8, 12),
        child: Row(
          children: [
            const Icon(Icons.directions_car, color: AppColors.accent),
            const SizedBox(width: 10),
            Expanded(
              child: _isLoadingRoute
                  ? const Text('Calcul de l’itinéraire...')
                  : Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          _routeDestinationName ?? 'Itinéraire',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontWeight: FontWeight.w600),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${_formatDistance(_routeDistanceInMeters!)} • '
                          '${_formatDuration(_routeDurationInSeconds!)}',
                          style: TextStyle(
                            color: AppColors.grey,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
            ),
            IconButton(
              onPressed: _clearRoute,
              tooltip: 'Effacer l’itinéraire',
              icon: const Icon(Icons.close),
            ),
          ],
        ),
      ),
    );
  }

  String _formatDistance(double meters) {
    if (meters >= 1000) {
      return '${(meters / 1000).toStringAsFixed(1)} km';
    }
    return '${meters.round()} m';
  }

  String _formatDuration(double seconds) {
    final duration = Duration(seconds: seconds.round());
    if (duration.inHours > 0) {
      return '${duration.inHours} h ${duration.inMinutes.remainder(60)} min';
    }
    return '${duration.inMinutes} min';
  }

//info carte
    Widget _buildMapInfo() {
    final count = _visiblePois.length;

    final text = _showNearbyOnly
        ? '$count POI à moins de ${_formatRadius(_nearbyRadiusInKm)}'
        : 'Explorez autour de vous';

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: _toggleNearbyPois,
        onLongPress: _openNearbyRadiusPicker,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: const EdgeInsets.symmetric(
            horizontal: 14,
            vertical: 10,
          ),

          decoration: BoxDecoration(
            color: _showNearbyOnly
                ? AppColors.primary.withValues(alpha: 0.95)
                : AppColors.white.withValues(alpha: 0.95),

            borderRadius: BorderRadius.circular(20),

            boxShadow: const [
              BoxShadow(
                color: Color(0x18000000),
                blurRadius: 12,
                offset: Offset(0, 4),
              ),
            ],
          ),

          child: Row(
            mainAxisSize: MainAxisSize.min,

            children: [
              Icon(
                _showNearbyOnly
                    ? Icons.near_me
                    : Icons.explore,
                color: _showNearbyOnly
                    ? AppColors.white
                    : AppColors.accent,
                size: 20,
              ),

              const SizedBox(width: 8),

              Text(
                text,
                style: TextStyle(
                  color: _showNearbyOnly
                      ? AppColors.white
                      : AppColors.textPrimary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

//botton
class _MapButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onPressed;

  const _MapButton({required this.icon, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return Material(
      elevation: 4,
      shape: const CircleBorder(),
      color: AppColors.white,

      child: InkWell(
        onTap: onPressed,
        customBorder: const CircleBorder(),

        child: SizedBox(
          width: 48,
          height: 48,

          child: Icon(icon, color: AppColors.primary, size: 22),
        ),
      ),
    );
  }
}

class _MapLocationResult {
  final String name;
  final String displayName;
  final LatLng position;

  const _MapLocationResult({
    required this.name,
    required this.displayName,
    required this.position,
  });

  static _MapLocationResult? fromJson(Map<String, dynamic> json) {
    final latitude = double.tryParse(json['lat']?.toString() ?? '');
    final longitude = double.tryParse(json['lon']?.toString() ?? '');

    if (latitude == null || longitude == null) {
      return null;
    }

    final displayName = json['display_name']?.toString() ?? '';
    final name = json['name']?.toString().trim();

    return _MapLocationResult(
      name: name == null || name.isEmpty ? displayName : name,
      displayName: displayName,
      position: LatLng(latitude, longitude),
    );
  }
}

class _PoiBottomSheet extends StatelessWidget {
  final Poi poi;

  const _PoiBottomSheet({required this.poi});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),

      padding: const EdgeInsets.all(16),

      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,

          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,

                decoration: BoxDecoration(
                  color: AppColors.grey.withValues(alpha: 0.4),
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),

            const SizedBox(height: 16),
            //image
            ClipRRect(
              borderRadius: BorderRadius.circular(16),

              child: poi.displayImage.startsWith('http')
                  ? Image.network(
                      poi.displayImage,
                      height: 180,
                      width: double.infinity,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return Container(
                          height: 180,
                          color: AppColors.background,
                          child: const Center(
                            child: Icon(
                              Icons.image_not_supported_outlined,
                              size: 48,
                            ),
                          ),
                        );
                      },
                    )
                  : Image.asset(
                      poi.displayImage.isEmpty
                          ? 'assets/images/pois/rova.jpg'
                          : poi.displayImage,
                      height: 180,
                      width: double.infinity,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return Container(
                          height: 180,
                          color: AppColors.background,
                          child: const Center(
                            child: Icon(
                              Icons.image_not_supported_outlined,
                              size: 48,
                            ),
                          ),
                        );
                      },
                    ),
            ),

            const SizedBox(height: 16),
            //categorie
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),

              decoration: BoxDecoration(
                color: AppColors.accent.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(20),
              ),

              child: Text(
                poi.category,
                style: const TextStyle(
                  color: AppColors.accent,
                  fontWeight: FontWeight.w600,
                  fontSize: 12,
                ),
              ),
            ),

            const SizedBox(height: 10),
            //note+nom
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,

              children: [
                Expanded(
                  child: Text(
                    poi.name,
                    style: const TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 21,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),

                const SizedBox(width: 8),

                Row(
                  children: [
                    const Icon(Icons.star, color: AppColors.accent, size: 20),

                    const SizedBox(width: 4),

                    Text(
                      poi.rating.toString(),
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
              ],
            ),

            const SizedBox(height: 8),
            //adresse
            Row(
              children: [
                const Icon(
                  Icons.location_on_outlined,
                  color: AppColors.primary,
                  size: 18,
                ),

                const SizedBox(width: 6),

                Expanded(
                  child: Text(
                    poi.address,
                    style: TextStyle(color: AppColors.grey),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 10),
            //description
            Text(
              poi.description,
              maxLines: 3,
              overflow: TextOverflow.ellipsis,

              style: TextStyle(color: AppColors.grey, height: 1.4),
            ),

            const SizedBox(height: 18),
            //bouton
            SizedBox(
              width: double.infinity,
              height: 50,

              child: ElevatedButton.icon(
                onPressed: () {
                  Navigator.pop(context);

                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => PoiDetailScreen(poi: poi),
                    ),
                  );
                },

                icon: const Icon(Icons.explore),

                label: const Text('Explorer ce lieu'),

                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.accent,
                  foregroundColor: AppColors.white,

                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(24),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MarkerPointerPainter extends CustomPainter {
  final Color color;

  _MarkerPointerPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    final path = ui.Path();

    path.moveTo(0, 0);
    path.lineTo(size.width, 0);
    path.lineTo(size.width / 2, size.height);
    path.close();

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant _MarkerPointerPainter oldDelegate) {
    return oldDelegate.color != color;
  }
}

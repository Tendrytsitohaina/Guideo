import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../models/poi.dart';

class FavoritesService {
  FavoritesService._();

  static final FavoritesService instance = FavoritesService._();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  final List<Poi> _favorites = [];

  List<Poi> get favorites => List.unmodifiable(_favorites);

  Stream<List<Poi>> favoritesStream() {
    final userId = _auth.currentUser?.uid;
    if (userId == null || _auth.currentUser!.isAnonymous) {
      return Stream.value(const <Poi>[]);
    }

    return _firestore
        .collection('favorites')
        .where('userId', isEqualTo: userId)
        .snapshots()
        .asyncMap((snapshot) async {
          final favorites = snapshot.docs
              .map((doc) {
                final poiData = doc.data()['poi'];
                if (poiData is! Map<String, dynamic>) {
                  return null;
                }
                return Poi.fromJson(Map<String, dynamic>.from(poiData));
              })
              .whereType<Poi>()
              .toList();

          _favorites
            ..clear()
            ..addAll(favorites);

          return List.unmodifiable(_favorites);
        });
  }

  Future<List<Poi>> loadFavorites() async {
    try {
      final user = _auth.currentUser;
      if (user == null || user.isAnonymous) {
        _favorites.clear();
        return const [];
      }

      final snapshot = await _firestore
          .collection('favorites')
          .where('userId', isEqualTo: user.uid)
          .get();

      final loadedFavorites = snapshot.docs
          .map((doc) {
            final poiData = doc.data()['poi'];
            if (poiData is! Map<String, dynamic>) {
              return null;
            }
            return Poi.fromJson(Map<String, dynamic>.from(poiData));
          })
          .whereType<Poi>()
          .toList();

      _favorites
        ..clear()
        ..addAll(loadedFavorites);

      return List.unmodifiable(_favorites);
    } catch (_) {
      _favorites.clear();
      rethrow;
    }
  }

  Future<bool> isFavorite(Poi poi) async {
    try {
      final user = _auth.currentUser;
      if (user == null || user.isAnonymous) {
        return false;
      }

      final doc = await _firestore
          .collection('favorites')
          .doc('${user.uid}_${poi.id}')
          .get();

      return doc.exists;
    } catch (_) {
      return _favorites.any((favorite) => favorite.id == poi.id);
    }
  }

  Future<void> toggleFavorite(Poi poi) async {
    try {
      final alreadyFavorite = await isFavorite(poi);
      if (alreadyFavorite) {
        await removeFavorite(poi);
      } else {
        await addFavorite(poi);
      }

      await loadFavorites();
    } catch (_) {
      rethrow;
    }
  }

  Future<void> addFavorite(Poi poi) async {
    final currentUser = _auth.currentUser;
    if (currentUser == null || currentUser.isAnonymous || poi.id.isEmpty) {
      return;
    }

    await _saveFavoriteToFirestore(poi, currentUser.uid);
  }

  Future<void> removeFavorite(Poi poi) async {
    final currentUser = _auth.currentUser;
    if (currentUser == null || currentUser.isAnonymous || poi.id.isEmpty) {
      return;
    }

    await _deleteFavoriteFromFirestore(poi.id, currentUser.uid);
  }

  Future<void> clearFavorites() async {
    final user = _auth.currentUser;
    if (user == null || user.isAnonymous) {
      _favorites.clear();
      return;
    }

    final snapshot = await _firestore
        .collection('favorites')
        .where('userId', isEqualTo: user.uid)
        .get();

    for (final doc in snapshot.docs) {
      await doc.reference.delete();
    }

    _favorites.clear();
  }

  Future<void> _saveFavoriteToFirestore(Poi poi, String userId) async {
    await _firestore.collection('favorites').doc('${userId}_${poi.id}').set({
      'userId': userId,
      'poiId': poi.id,
      'poi': poi.toJson(),
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> _deleteFavoriteFromFirestore(String poiId, String userId) async {
    await _firestore.collection('favorites').doc('${userId}_$poiId').delete();
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:guide_touristique_augmente/models/poi.dart';
import 'package:guide_touristique_augmente/screens/profile_screen.dart';

void main() {
  testWidgets('profile screen shows the favorites entry', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const MaterialApp(home: ProfileScreen()));

    expect(find.text('Mon profil'), findsOneWidget);
    expect(find.text('Mes favoris'), findsOneWidget);
  });

  test('firestore POI id is preserved from document id', () {
    final poi = Poi.fromJson({
      'name': 'Lac Anosy',
      'category': 'Nature',
      'description': 'Un lac',
      'latitude': -18.9,
      'longitude': 47.5,
      'address': 'Antananarivo',
      'rating': 4.5,
    }, id: 'poi_002');

    expect(poi.id, 'poi_002');
  });
}

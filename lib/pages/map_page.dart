import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart' as geo;
import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart' as mapbox;
import 'dart:math';

class MapScreen extends StatefulWidget {
  const MapScreen({super.key});

  @override
  _MapScreenState createState() => _MapScreenState();
}
final Map<String, Map<String, double>> cityCoordinates = {
  "Lyon": {"lat": 45.764, "lng": 4.8357},
  "Paris": {"lat": 48.8566, "lng": 2.3522},
  "Marseille": {"lat": 43.2965, "lng": 5.3698},
  "Toulouse": {"lat": 43.6047, "lng": 1.4442},
  "Bordeaux": {"lat": 44.8378, "lng": -0.5792},
  "Nice": {"lat": 43.7102, "lng": 7.262},
  "Nantes": {"lat": 47.2184, "lng": -1.5536},
  "Strasbourg": {"lat": 48.5734, "lng": 7.7521},
};

Future<geo.Position?> getUserLocation() async {
  bool serviceEnabled;
  geo.LocationPermission permission;

  serviceEnabled = await geo.Geolocator.isLocationServiceEnabled();
  if (!serviceEnabled) {
    print("Service de localisation désactivé");
    return null;
  }

  permission = await geo.Geolocator.checkPermission();
  if (permission == geo.LocationPermission.denied) {
    permission = await geo.Geolocator.requestPermission();
    if (permission == geo.LocationPermission.denied) {
      print("Permission refusée");
      return null;
    }
  }

  if (permission == geo.LocationPermission.deniedForever) {
    print("Permission refusée définitivement");
    return null;
  }

  return await geo.Geolocator.getCurrentPosition(
      desiredAccuracy: geo.LocationAccuracy.high);
}

double calculateDistance(double lat1, double lon1, double lat2, double lon2) {
  const double R = 6371; // Rayon de la Terre en km
  double dLat = (lat2 - lat1) * pi / 180;
  double dLon = (lon2 - lon1) * pi / 180;

  double a = sin(dLat / 2) * sin(dLat / 2) +
      cos(lat1 * pi / 180) * cos(lat2 * pi / 180) *
          sin(dLon / 2) * sin(dLon / 2);
  double c = 2 * atan2(sqrt(a), sqrt(1 - a));

  return R * c; // Distance en km
}

class _MapScreenState extends State<MapScreen> {
  geo.Position? _currentPosition;
  late mapbox.MapWidget _mapWidget;
  late mapbox.PointAnnotationManager _annotationManager;
  late mapbox.MapboxMap _mapboxMap; // ✅ Stocker la référence de la carte

  @override
  void initState() {
    super.initState();
    _getCurrentLocation();
  }

  /// ✅ Récupère la position actuelle de l'utilisateur
  Future<void> _getCurrentLocation() async {
    bool serviceEnabled;
    geo.LocationPermission permission;

    serviceEnabled = await geo.Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      print("Service de localisation désactivé");
      return;
    }

    permission = await geo.Geolocator.checkPermission();
    if (permission == geo.LocationPermission.denied) {
      permission = await geo.Geolocator.requestPermission();
      if (permission == geo.LocationPermission.denied) {
        print("Permission refusée");
        return;
      }
    }

    if (permission == geo.LocationPermission.deniedForever) {
      print("Permission refusée définitivement");
      return;
    }

    geo.Position position = await geo.Geolocator.getCurrentPosition(
        desiredAccuracy: geo.LocationAccuracy.high);

    setState(() {
      _currentPosition = position;
    });

    _addUserLocationMarker(position); // 🔥 Ajoute un marqueur à la position actuelle
  }

  /// ✅ Ajoute un marqueur sur la position actuelle de l'utilisateur
  Future<void> _addUserLocationMarker(geo.Position position) async {
    if (_annotationManager == null) return;

    await _annotationManager.create(
      mapbox.PointAnnotationOptions(
        geometry: mapbox.Point(
          coordinates: mapbox.Position(
            position.longitude,
            position.latitude,
          ),
        ),
      ),
    );
  }

  /// ✅ Centre la carte sur la position actuelle
  void _centerToUserLocation() {
    if (_currentPosition != null && _mapboxMap != null) {
      _mapboxMap.setCamera(mapbox.CameraOptions(
        center: mapbox.Point(
          coordinates: mapbox.Position(
            _currentPosition!.longitude,
            _currentPosition!.latitude,
          ),
        ),
        zoom: 15.0,
        bearing: 0,
        pitch: 0,
      ));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Carte"),
        backgroundColor: Colors.red,
        centerTitle: true,
      ),
      body: _currentPosition == null
          ? const Center(child: CircularProgressIndicator())
          : mapbox.MapWidget(
        key: const ValueKey("mapWidget"),
        cameraOptions: mapbox.CameraOptions(
          center: mapbox.Point(
            coordinates: mapbox.Position(
              _currentPosition!.longitude,
              _currentPosition!.latitude,
            ),
          ),
          zoom: 15.0,
          bearing: 0,
          pitch: 0,
        ),
        onMapCreated: (mapbox.MapboxMap mapboxMap) async {
          _mapboxMap = mapboxMap; // ✅ Stocker la référence de la carte
          _annotationManager =
          await mapboxMap.annotations.createPointAnnotationManager();
          _addUserLocationMarker(_currentPosition!);

          // ✅ Active le suivi de localisation avec un effet de pulsation en bleu
          mapboxMap.location.updateSettings(mapbox.LocationComponentSettings(
            enabled: true,
            pulsingEnabled: true,
            pulsingColor: Colors.blue.value,
          ));
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          if (_currentPosition != null && _mapboxMap != null) {
            // 🔥 Animation fluide vers la position actuelle
            _mapboxMap.easeTo(
              mapbox.CameraOptions(
                center: mapbox.Point(
                  coordinates: mapbox.Position(
                    _currentPosition!.longitude,
                    _currentPosition!.latitude,
                  ),
                ),
                zoom: 17.0, // ✅ Zoom légèrement plus proche pour un meilleur effet
                bearing: Random().nextDouble() * 360, // ✅ Ajoute une légère rotation aléatoire
                pitch: 30, // ✅ Incline la vue pour un effet plus immersif
              ),
              mapbox.MapAnimationOptions(
                duration: 1500, // ✅ Durée de l'animation en millisecondes
              ),
            );
          }
        },
        backgroundColor: Colors.red,
        child: const Icon(Icons.my_location, color: Colors.white),
      ),
    );
  }
}
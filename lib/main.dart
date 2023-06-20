import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_polyline_points/flutter_polyline_points.dart';
import 'package:geo_flutter_exam/location_service.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'dart:convert' as convert;
import 'dart:ui' as ui;

void main() => runApp(const MyApp());

Color _polygonFillColor = Color.fromRGBO(18, 99, 18, 0.494); // Color inicial

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Lead Dog Brewing Branches',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.black87),
        useMaterial3: true,
      ),
      home: const MyHomePage(),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({Key? key});

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  final Completer<GoogleMapController> _controller =
      Completer<GoogleMapController>();
  final TextEditingController _searchController = TextEditingController();
  final Set<Marker> _markers = <Marker>{};
  final Set<Polygon> _polygons = <Polygon>{};
  final List<LatLng> _polygonLatLngs = <LatLng>[];
  int _markerIdCounter = 1;
  int _polygonIdCounter = 1;
  int _polylineIdCounter = 1;
  final Set<Polyline> _polylines = <Polyline>{};

  /* Variables globales para las rutas */

  static const CameraPosition _kOrigin = CameraPosition(
    //target: LatLng(21.1220208, -101.683534),
    //zoom: 12,
    target: LatLng(20.873929, -101.225515),
    zoom: 9,
  );

  // Custom icon start
  BitmapDescriptor currentLocationIcon = BitmapDescriptor.defaultMarker;
  BitmapDescriptor allSucursalsIcon = BitmapDescriptor.defaultMarker;

  Future<Uint8List> getBytesFromAsset(String path, int width) async {
    ByteData data = await rootBundle.load(path);
    ui.Codec codec = await ui.instantiateImageCodec(data.buffer.asUint8List(),
        targetWidth: width);
    ui.FrameInfo fi = await codec.getNextFrame();
    return (await fi.image.toByteData(format: ui.ImageByteFormat.png))!
        .buffer
        .asUint8List();
  }

  Future<void> setCustomMarkerIcon() async {
    Uint8List markerIcon = await getBytesFromAsset('assets/person.png', 100);

    // BitmapDescriptor.fromBytes(markerIcon);
    currentLocationIcon = BitmapDescriptor.fromBytes(markerIcon);
  }

  Future<void> setCustomSucursalIcon() async {
    Uint8List sucursalIcon =
        await getBytesFromAsset('assets/beer-icon.png', 80);
    allSucursalsIcon = BitmapDescriptor.fromBytes(sucursalIcon);
  }

  // Custom icon end

  @override
  void initState() {
    super.initState();
    setCustomSucursalIcon();
    setCustomMarkerIcon();
    getBranches();
    setSucursals();
    _setPolygon();
  }

  Future<BitmapDescriptor> _createMarkerImageFromAsset(
      BuildContext context) async {
    final ImageConfiguration imageConfiguration =
        createLocalImageConfiguration(context, size: Size.square(50));

    final ByteData byteData = await rootBundle.load('assets/beer-icon.png');
    final Uint8List pngBytes = byteData.buffer.asUint8List();

    final ui.Codec codec = await ui.instantiateImageCodec(pngBytes,
        targetHeight: 120, targetWidth: 60);
    final ui.FrameInfo frameInfo = await codec.getNextFrame();

    final ui.Image image = frameInfo.image;
    final ByteData? resizedByteData =
        await image.toByteData(format: ui.ImageByteFormat.png);
    final Uint8List resizedPngBytes = resizedByteData!.buffer.asUint8List();

    final BitmapDescriptor resizedBitmapDescriptor =
        BitmapDescriptor.fromBytes(resizedPngBytes);

    return resizedBitmapDescriptor;
  }

  void _setMarker(LatLng point, BitmapDescriptor icon) {
    setState(() {
      final String markerIdVal = 'marker_$_markerIdCounter';
      _markerIdCounter++;
      _markers.add(
        Marker(
          markerId: MarkerId(markerIdVal),
          position: point,
          icon: icon,
        ),
      );
    });
  }

  void _setPolygon() async {
    await setSucursals();
    _polygonLatLngs.addAll(<LatLng>[
      const LatLng(20.894454, -100.678923),
      const LatLng(21.243964, -100.864543),
      const LatLng(21.188806, -101.791105),
      const LatLng(20.402177, -100.765260)
    ]);
    final String polygonIdVal = 'polygon_$_polygonIdCounter';
    //_polygonIdCounter++;
    _polygons.add(Polygon(
      polygonId: PolygonId(polygonIdVal),
      points: _polygonLatLngs,
      strokeWidth: 2,
      fillColor: Color.fromRGBO(
          18, 99, 18, 0.066), // Cambio realizado: se establece el color verde
    ));
  }

  void _changePolygonColor() {
    setState(() {
      _polygonFillColor = Colors.transparent; // Cambiar a color transparente
    });
  }

  List<Map<dynamic, dynamic>> branches = [
    <dynamic, dynamic>{},
    <dynamic, dynamic>{}
  ];
  // gets all branches from the local API
  getBranches() async {
    await setCustomSucursalIcon();
    await setCustomMarkerIcon();
    var response =
        await http.get(Uri.parse("http://192.168.100.6:4005/api/branches/all"));
    var jsonData = await response.body;
    var json = convert.jsonDecode(jsonData);
    print("JSON: ${json['features']}");

    branches = json['features'].cast<Map<dynamic, dynamic>>().toList();
  }

  //Este se va a usar cuando va del origen que ingresa el usuario hacia la primera sucursal
  Future<List> getDirectionsForBranches(
      String origin, List<dynamic> branches) async {
    final destinations = [];
    print(branches);
    await Future.forEach(branches, (branch) async {
      var arrDestination = branch['coordinates'];
      final String url =
          "https://maps.googleapis.com/maps/api/directions/json?origin=$origin&destination=$arrDestination&key=$key";
      var response =
          await http.get(Uri.parse(url)).timeout(Duration(minutes: 5));
      var json = convert.jsonDecode(response.body);
      var distanceText = json['routes'][0]['legs'][0]['distance']['text'];
      var duration = json['routes'][0]['legs'][0]['duration']['text'];
      var bounds_ne = json['routes'][0]['bounds']['northeast'];
      var bounds_sw = json['routes'][0]['bounds']['southwest'];
      var start_location = json['routes'][0]['legs'][0]['start_location'];
      var end_location = json['routes'][0]['legs'][0]['end_location'];
      var polyline = json['routes'][0]['overview_polyline']['points'];
      var polyline_decoded = PolylinePoints()
          .decodePolyline(json['routes'][0]['overview_polyline']['points']);

      destinations.add({
        'distanceText': distanceText,
        'duration': duration,
        'bounds_ne': bounds_ne,
        'bounds_sw': bounds_sw,
        'start_location': start_location,
        'end_location': end_location,
        'polyline': polyline,
        'polyline_decoded': polyline_decoded
      });
    });

    List<dynamic> sortedDestinations = destinations;

    sortedDestinations.sort((a, b) {
      String distanceA = a['distanceText'];
      String distanceB = b['distanceText'];
      return _parseDistance(distanceA).compareTo(_parseDistance(distanceB));
    });

    return sortedDestinations;
  }

  // Este se va a usar para cuando entre al else debido a que se mandan de diferente manera las coordenadas
  Future<List> getDirectionsForPlaces(
      String origin, List<dynamic> branches) async {
    final destinations = [];
    print(branches);
    await Future.forEach(branches, (branch) async {
      var latPlace = branch['end_location']["lat"];
      var lngPlace = branch['end_location']["lng"];
      final String url =
          "https://maps.googleapis.com/maps/api/directions/json?origin=$origin&destination=$latPlace,$lngPlace&key=$key";
      var response =
          await http.get(Uri.parse(url)).timeout(Duration(minutes: 5));
      var json = convert.jsonDecode(response.body);
      var distanceText = json['routes'][0]['legs'][0]['distance']['text'];
      var duration = json['routes'][0]['legs'][0]['duration']['text'];
      var bounds_ne = json['routes'][0]['bounds']['northeast'];
      var bounds_sw = json['routes'][0]['bounds']['southwest'];
      var start_location = json['routes'][0]['legs'][0]['start_location'];
      var end_location = json['routes'][0]['legs'][0]['end_location'];
      var polyline = json['routes'][0]['overview_polyline']['points'];
      var polyline_decoded = PolylinePoints()
          .decodePolyline(json['routes'][0]['overview_polyline']['points']);

      destinations.add({
        'distanceText': distanceText,
        'duration': duration,
        'bounds_ne': bounds_ne,
        'bounds_sw': bounds_sw,
        'start_location': start_location,
        'end_location': end_location,
        'polyline': polyline,
        'polyline_decoded': polyline_decoded
      });
    });

    List<dynamic> sortedDestinations = destinations;

    sortedDestinations.sort((a, b) {
      String distanceA = a['distanceText'];
      String distanceB = b['distanceText'];
      return _parseDistance(distanceA).compareTo(_parseDistance(distanceB));
    });

    return sortedDestinations;
  }

  double _parseDistance(String distanceText) {
    final distance = double.tryParse(distanceText.split(' ')[0]);
    return distance ?? 0.0;
  }

  setDirectionsRoutes() async {
    var origin = latitude.toString() + ',' + longitude.toString();

    // ============================== ORDENAR MIS SUCURSALES ==============================
    var places =
        await http.get(Uri.parse("http://192.168.100.6:4005/api/branches/all"));
    var jsonData = await places.body;
    //Se tienen todas las sucursales
    var jsonComplete = convert.jsonDecode(jsonData);
    //Aquí se guardan todos los lugares solo con su nombre y coordenadas
    List<Map<String, dynamic>> branches = [];

    for (var feature in jsonComplete['features']) {
      var properties = feature['properties'];
      var geometry = feature['geometry'];

      String name = properties['name'];
      List<dynamic> coordinates = geometry['coordinates'];

      double latitude = double.parse(coordinates[1].toString());
      double longitude = double.parse(coordinates[0].toString());

      branches.add({
        'name': name,
        'coordinates': '$latitude,$longitude',
      });
    }

    // ===================================================================================================

    // ============================== OBTENER LA RUTA MÁS CERCANA ==============================
    // Lista de lugares ordenados
    final sortedDestinations = await getDirectionsForBranches(origin, branches);
    final destinationsToRemove = List<dynamic>.from(sortedDestinations);
    var isOriginalOrigin = true;
    // Necesito revisar primero que es el origen por defecto
    for (var i = 0; i < sortedDestinations.length; i++) {
      if (isOriginalOrigin) {
        var currentLat = sortedDestinations[0]['end_location']['lat'];
        var currentLng = sortedDestinations[0]['end_location']['lng'];
        finalDuration.add(sortedDestinations[0]['duration']);
        //Aquí se ejecuta la función para pintar la ruta
        var directions = await LocationService()
            .getDirections(origin, '$currentLat,$currentLng');
        //_goToPlaces solo mueve la cámara
        _goToPlaces(
            directions['start_location']['lat'],
            directions['start_location']['lng'],
            directions['bounds_ne'],
            directions['bounds_sw']);
        _setPolyline(directions['polyline_decoded']);
        isOriginalOrigin = false;
      } else {
        final placeLat = destinationsToRemove[0]['end_location']['lat'];
        final placeLng = destinationsToRemove[0]['end_location']['lng'];
        finalDuration.add(destinationsToRemove[0]['duration']);
        destinationsToRemove.removeAt(0);
        var nextPlace = await getDirectionsForPlaces(
            '$placeLat,$placeLng', destinationsToRemove);

        var nextLat = nextPlace[0]['end_location']['lat'];
        var nextLng = nextPlace[0]['end_location']['lng'];

        //Aquí se ejecuta la función para pintar la ruta
        var directions = await LocationService()
            .getDirections('$placeLat,$placeLng', '$nextLat,$nextLng');
        //_goToPlaces solo mueve la cámara
        _goToPlaces(
            directions['start_location']['lat'],
            directions['start_location']['lng'],
            directions['bounds_ne'],
            directions['bounds_sw']);
        _setPolyline(directions['polyline_decoded']);
        isOriginalOrigin = false;
      }
    }

    //Pinta del último lugar hacia el origen
    var finalPlace = List<dynamic>.from(destinationsToRemove);
    final lastPlace = await getDirectionsForPlaces(origin, finalPlace);
    var originLastPlaceLat = lastPlace[0]['end_location']['lat'];
    var originLastPlaceLng = lastPlace[0]['end_location']['lng'];
    finalDuration.add(finalPlace[0]['duration']);

    var directions = await LocationService()
        .getDirections('$originLastPlaceLat,$originLastPlaceLng', origin);
    //_goToPlaces solo mueve la cámara
    _goToPlaces(
        directions['start_location']['lat'],
        directions['start_location']['lng'],
        directions['bounds_ne'],
        directions['bounds_sw']);
    _setPolyline(directions['polyline_decoded']);
    isOriginalOrigin = false;
  }

  void showRoutesDialog(List<String> finalDuration) {
    String totalTime = calculateTotalTime(finalDuration);

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Rutas'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              for (int i = 0; i < finalDuration.length; i++)
                Text('Ruta ${i + 1}: ${finalDuration[i]}'),
              SizedBox(height: 20),
              Text('Tiempo total: $totalTime'),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('Cerrar'),
            ),
          ],
        );
      },
    );
  }

  String calculateTotalTime(List<String> finalDuration) {
    int totalMinutes = 0;

    for (String duration in finalDuration) {
      int minutes = parseDuration(duration);
      totalMinutes += minutes;
    }

    int hours = totalMinutes ~/ 60;
    int minutes = totalMinutes % 60;

    return '${hours}h ${minutes}m';
  }

  int parseDuration(String duration) {
    List<String> parts = duration.split(',');

    int totalMinutes = 0;

    for (String part in parts) {
      String trimmedPart = part.trim();

      if (trimmedPart.contains('hour')) {
        List<String> hoursAndMinutes = trimmedPart.split('hour');

        String hoursStr = hoursAndMinutes[0].trim();
        if (hoursStr.isNotEmpty && hoursStr.contains(RegExp(r'[0-9]'))) {
          totalMinutes += int.parse(hoursStr) * 60;
        }

        if (hoursAndMinutes.length > 1) {
          String minutesStr =
              hoursAndMinutes[1].replaceAll(RegExp(r'[^0-9]'), '').trim();
          if (minutesStr.isNotEmpty) {
            totalMinutes += int.parse(minutesStr);
          }
        }
      } else if (trimmedPart.contains('hours')) {
        List<String> hoursAndMinutes = trimmedPart.split('hours');

        String hoursStr = hoursAndMinutes[0].trim();
        if (hoursStr.isNotEmpty && hoursStr.contains(RegExp(r'[0-9]'))) {
          totalMinutes += int.parse(hoursStr) * 60;
        }

        if (hoursAndMinutes.length > 1) {
          String minutesStr =
              hoursAndMinutes[1].replaceAll(RegExp(r'[^0-9]'), '').trim();
          if (minutesStr.isNotEmpty) {
            totalMinutes += int.parse(minutesStr);
          }
        }
      } else if (trimmedPart.contains('mins')) {
        String minutesStr =
            trimmedPart.replaceAll(RegExp(r'[^0-9]'), '').trim();
        if (minutesStr.isNotEmpty) {
          totalMinutes += int.parse(minutesStr);
        }
      }
    }

    return totalMinutes;
  }

  // sets all the markers from the API
  setSucursals() async {
    await getBranches();
    for (var i = 0; i < branches.length; i++) {
      LatLng origin;
      List<double> destination;
      var request = {
        origin = LatLng(10.1, -101.2),
        destination = [
          double.parse(branches[i]['geometry']['coordinates'][1]),
          double.parse(branches[i]['geometry']['coordinates'][0])
        ],
        // 'origin': LatLng(10.1, -101.2),
        // 'destination': [double.parse(branches[i]['geometry']['coordinates'][1]) , double.parse(branches[i]['geometry']['coordinates'][0])],
        // 'travelMode': webService.TravelMode.driving,
        // 'unitSystem': Unit.imperial
      };
      //_polygonLatLngs.add(LatLng(destination[0], destination[1]));
      // sets all the marks from the personal API
      _setMarker(LatLng(destination[0], destination[1]), allSucursalsIcon);
    }
  }

  bool _showInfoBox = false;
  double latitude = 0;
  double longitude = 0;
  final String key =
      ""; //AQUI PON TU API KEY
  List<String> finalDuration = [];

  void _setPolyline(List<PointLatLng> points) {
    final String polylineIdVal = 'polyline_$_polylineIdCounter';
    _polylineIdCounter++;
    _polylines.add(
      Polyline(
        polylineId: PolylineId(polylineIdVal),
        width: 2,
        color: Colors.blue,
        points: points
            .map((point) => LatLng(point.latitude, point.longitude))
            .toList(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          GoogleMap(
            mapType: MapType.normal,
            markers: _markers,
            polygons: _polygons,
            polylines: _polylines,
            initialCameraPosition: _kOrigin,
            onMapCreated: (GoogleMapController controller) {
              _controller.complete(controller);
            },
          ),
          Positioned(
            top: 40,
            left: 0,
            right: 0,
            child: GestureDetector(
              onTap: () {
                setState(() {
                  _showInfoBox = !_showInfoBox;
                });
              },
              child: Container(
                alignment: Alignment.topCenter,
                child: Image.asset(
                  'assets/leaddog-logo.png',
                  height: 40,
                ),
              ),
            ),
          ),
          Positioned(
            bottom: 20,
            left: 20,
            right: 20,
            child: Card(
              elevation: 4,
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Encuentra tu sucursal más cercana',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      'Selecciona una dirección como punto inicial',
                      style: TextStyle(
                        fontSize: 14,
                      ),
                    ),
                    SizedBox(height: 10),
                    TextFormField(
                      controller: _searchController,
                      textCapitalization: TextCapitalization.words,
                      decoration: const InputDecoration(
                        hintText: 'Escribe una locación',
                      ),
                      onChanged: (value) {
                        print(value);
                      },
                    ),
                    SizedBox(height: 10),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () async {
                          var place = await LocationService()
                              .getPlace(_searchController.text);
                          _goToPlace(place);
                          //Pintar rutas
                          await setDirectionsRoutes();
                          //Mostrar alerta
                          showRoutesDialog(finalDuration);
                        },
                        style: ElevatedButton.styleFrom(
                          primary: Colors.black,
                          onPrimary: Colors.white,
                        ),
                        child: Text('BUSCAR'),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          if (_showInfoBox)
            Positioned(
              top: 100,
              left: 100,
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(8),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.2),
                      spreadRadius: 2,
                      blurRadius: 4,
                      offset: Offset(0, 2),
                    ),
                  ],
                ),
                padding: const EdgeInsets.all(10),
                child: const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Nombre',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      'Dirección',
                      style: TextStyle(
                        fontSize: 16,
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  Future<void> _goToPlace(Map<String, dynamic> place) async {
    final double lat = place['geometry']['location']['lat'];
    final double lng = place['geometry']['location']['lng'];
    latitude = lat;
    longitude = lng;
    final GoogleMapController controller = await _controller.future;
    CameraPosition kPlaceCameraPosition =
        CameraPosition(target: LatLng(lat, lng), zoom: 12);
    controller.animateCamera(CameraUpdate.newCameraPosition(
      kPlaceCameraPosition,
    ));
    _setMarker(LatLng(lat, lng), currentLocationIcon);
  }

  Future<void> _goToPlaces(
    // Map<String, dynamic> place
    double lat,
    double lng,
    Map<String, dynamic> boundsNe,
    Map<String, dynamic> boundsSw,
  ) async {
    // final double lat = place['geometry']['location']['lat'];
    // final double lng = place['geometry']['location']['lng'];
    final GoogleMapController controller = await _controller.future;
    CameraPosition kPlaceCameraPosition =
        CameraPosition(target: LatLng(lat, lng), zoom: 12);
    controller.animateCamera(CameraUpdate.newCameraPosition(
      kPlaceCameraPosition,
    ));
    controller.animateCamera(CameraUpdate.newLatLngBounds(
        LatLngBounds(
            southwest: LatLng(boundsSw['lat'], boundsSw['lng']),
            northeast: LatLng(boundsNe['lat'], boundsNe['lng'])),
        25));
    _setMarker(LatLng(lat, lng), currentLocationIcon);
  }
}

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:geo_flutter_exam/location_service.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'dart:convert' as convert;
import 'dart:ui' as ui;

void main() => runApp(const MyApp());

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

  Future <void> setCustomMarkerIcon() async {
    Uint8List markerIcon = await getBytesFromAsset('assets/person.png', 100);

    // BitmapDescriptor.fromBytes(markerIcon);
    currentLocationIcon = BitmapDescriptor.fromBytes(markerIcon);
  }

  Future <void> setCustomSucursalIcon() async {
    Uint8List sucursalIcon =
        await getBytesFromAsset('assets/beer-icon.png', 50);
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
     fillColor: Color.fromRGBO(18, 99, 18, 0.494), // Cambio realizado: se establece el color verde
  ));
}

  List<Map<dynamic, dynamic>> branches = [
    <dynamic, dynamic>{},
    <dynamic, dynamic>{}
  ];
  // gets all branches from the local API
  getBranches() async {
    await setCustomSucursalIcon();
    await setCustomMarkerIcon();
    //const response = await fetch("http://ip:4005/api/branches/all");
    var response =
        await http.get(Uri.parse("http://172.18.69.153:4005/api/branches/all"));
    var jsonData = await response.body;
    var json = convert.jsonDecode(jsonData);
    print("JSON: ${json['features']}");

    branches = json['features'].cast<Map<dynamic, dynamic>>().toList();
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

      print(destination);
      //_polygonLatLngs.add(LatLng(destination[0], destination[1]));
      // sets all the marks from the personal API
      _setMarker(LatLng(destination[0], destination[1]), allSucursalsIcon);
    }
  }

  bool _showInfoBox = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          GoogleMap(
            mapType: MapType.normal,
            markers: _markers,
            polygons: _polygons,
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
                padding: EdgeInsets.all(10),
                child: Column(
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
    final GoogleMapController controller = await _controller.future;
    CameraPosition kPlaceCameraPosition =
        CameraPosition(target: LatLng(lat, lng), zoom: 12);
    controller.animateCamera(CameraUpdate.newCameraPosition(
      kPlaceCameraPosition,
    ));
    _setMarker(LatLng(lat, lng), currentLocationIcon);
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

void main() {
  runApp(const MyApp());
}

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
  TextEditingController _coordinatesController = TextEditingController();
  bool _showInfoBox = false;

  void _searchCoordinates() {
    // Get the coordinates from the text field and perform the search
    String coordinates = _coordinatesController.text;
    // Perform your search operation here using the coordinates
    print('Searching coordinates: $coordinates');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          FlutterMap(
            mapController: MapController(),
            options: MapOptions(
              center: LatLng(
                  21.12413566328141, -101.6859289619005), //León Guanajuato
              zoom: 10.0,
            ),
            children: [
              TileLayer(
                urlTemplate:
                    'http://mt0.google.com/vt/lyrs=m&hl=en&x={x}&y={y}&z={z}',
                subdomains: const ['a', 'b', 'c'],
              ),
            ],
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
                    TextField(
                      controller: _coordinatesController,
                      decoration: InputDecoration(
                        labelText: 'Coordinates',
                        hintText: 'Enter coordinates',
                      ),
                    ),
                    SizedBox(height: 10),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _searchCoordinates,
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
}

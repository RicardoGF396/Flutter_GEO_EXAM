import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_polyline_points/flutter_polyline_points.dart';
import 'package:http/http.dart' as http;
import 'dart:convert' as convert;

class LocationService {
  final String key =
      "AIzaSyDFanujpwtMpdwzOXmQ-3ygJrx6aXJs0Ss"; //AQUI PON TU API KEY
  Future<String> getPlaceId(String input) async {
    final String url =
        "https://maps.googleapis.com/maps/api/place/findplacefromtext/json?input=$input&inputtype=textquery&key=$key";
    var response = await http.get(Uri.parse(url));
    var json = convert.jsonDecode(response.body);
    var placeId = json['candidates'][0]['place_id'] as String;
    debugPrint(placeId);
    return placeId;
  }

  Future<Map<String, dynamic>> getPlace(String input) async {
    final placeId = await getPlaceId(input);
    final String url =
        "https://maps.googleapis.com/maps/api/place/details/json?place_id=$placeId&key=$key";
    var response = await http.get(Uri.parse(url));
    var json = convert.jsonDecode(response.body);
    var results = json['result'] as Map<String, dynamic>;
    print(results);
    return results;
  }

  Future<Map<String, dynamic>> getDirections(
      String origin, String destination) async {
    final String url =
        "https://maps.googleapis.com/maps/api/directions/json?origin=$origin&destination=$destination&key=$key";
    var response = await http.get(Uri.parse(url));
    var jsonResponse = convert.jsonDecode(response.body);
    var results = {
      'bounds_ne': jsonResponse['routes'][0]['bounds']['northeast'],
      'bounds_sw': jsonResponse['routes'][0]['bounds']['southwest'],
      'start_location': jsonResponse['routes'][0]['legs'][0]['start_location'],
      'end_location': jsonResponse['routes'][0]['legs'][0]['end_location'],
      'polyline': jsonResponse['routes'][0]['overview_polyline']['points'],
      'polyline_decoded': PolylinePoints().decodePolyline(jsonResponse['routes']
          [0]['overview_polyline']['points']) //flutter_polyline_points: ^1.0.0
    };

    //print(json);

    return results;
  }

  double _parseDistance(String distanceText) {
    final distance = double.tryParse(distanceText.split(' ')[0]);
    return distance ?? 0.0;
  }
}



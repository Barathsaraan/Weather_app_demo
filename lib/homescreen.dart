import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:permission_handler/permission_handler.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late double _latitude = 0.0;
  late double _longitude = 0.0;
  late LatLng _selectedLocation;
  late String _apiKey = "d1dd19772a6142d9c438357ee4f10cd5";
  late Map<String, dynamic> _weatherData = {};
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _selectedLocation = LatLng(0, 0);
    _fetchWeatherForSelectedLocation();
    _getLocationAndWeather();
  }

  Future<void> _fetchWeatherForSelectedLocation() async {
    setState(() {
      _isLoading = true;
    });
    String apiUrl =
        'https://api.openweathermap.org/data/2.5/weather?lat=${_selectedLocation.latitude}&lon=${_selectedLocation.longitude}&appid=$_apiKey';
    http.Response response = await http.get(Uri.parse(apiUrl));
    if (response.statusCode == 200) {
      setState(() {
        _weatherData = json.decode(response.body);
        _isLoading = false;
      });
    } else {
      setState(() {
        _isLoading = false;
      });
      throw Exception('Failed to load weather data');
    }
  }

  Future<void> _getLocationAndWeather() async {
    var status = await Permission.location.request();
    if (status.isGranted) {
      Position position = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.high);
      setState(() {
        _latitude = position.latitude;
        _longitude = position.longitude;
        _selectedLocation = LatLng(_latitude, _longitude);
      });
      _fetchWeatherForSelectedLocation();
    }
  }

  Future<void> _fetchWeather() async {
    setState(() {
      _isLoading = true;
    });
    try {
      String apiUrl =
          'https://api.openweathermap.org/data/2.5/weather?lat=$_latitude&lon=$_longitude&appid=$_apiKey';
      http.Response response = await http.get(Uri.parse(apiUrl));
      if (response.statusCode == 200) {
        setState(() {
          _weatherData = json.decode(response.body);
          _isLoading = false;
        });
      } else {
        setState(() {
          _isLoading = false;
        });
        throw Exception('Failed to load weather data');
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Weather"),
      ),
      body: Column(
        children: [
          Expanded(
            flex: 1,
            child: _buildMap(),
          ),
          Expanded(
            flex: 1,
            child: _buildWeatherInfo(),
          ),
        ],
      ),
    );
  }

  Widget _buildMap() {
    return FlutterMap(
      options: MapOptions(
        initialCenter: LatLng(_latitude, _longitude),
        initialZoom: 9.2,
        onTap: _onMapTapped,
      ),
      children: [
        TileLayer(
          urlTemplate: "https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png",
        ),
      ],
    );
  }

  Widget _buildWeatherInfo() {
    return Center(
      child: _isLoading
          ? CircularProgressIndicator()
          : _weatherData.isNotEmpty
              ? Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'Temperature: ${_weatherData['main']['temp']}',
                      style: TextStyle(fontSize: 20),
                    ),
                    SizedBox(height: 20),
                    Text(
                      'Description: ${_weatherData['weather'][0]['description']}',
                      style: TextStyle(fontSize: 20),
                    ),
                  ],
                )
              : Text(
                  'No Data',
                  style: TextStyle(fontSize: 20),
                ),
    );
  }

  void _onMapTapped(TapPosition tapPosition, LatLng latLng) {
    setState(() {
      _selectedLocation = latLng;
      _fetchWeatherForSelectedLocation();
    });
  }
}

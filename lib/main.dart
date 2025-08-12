import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'dart:io';

void main() => runApp(WeatherApp());

class WeatherApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Weather App',
      theme: ThemeData(primarySwatch: Colors.blue),
      home: WeatherScreen(),
      debugShowCheckedModeBanner: false,
    );
  }
}

class WeatherData {
  final String city;
  final double temperature;
  final String condition;
  final String description;
  final int humidity;
  final double windSpeed;

  WeatherData({
    required this.city,
    required this.temperature,
    required this.condition,
    required this.description,
    required this.humidity,
    required this.windSpeed,
  });

  factory WeatherData.fromJson(Map<String, dynamic> json) {
    return WeatherData(
      city: json['name'],
      temperature: json['main']['temp'].toDouble(),
      condition: json['weather'][0]['main'],
      description: json['weather'][0]['description'],
      humidity: json['main']['humidity'],
      windSpeed: json['wind']['speed'].toDouble(),
    );
  }
}

class WeatherScreen extends StatefulWidget {
  @override
  _WeatherScreenState createState() => _WeatherScreenState();
}

class _WeatherScreenState extends State<WeatherScreen> {
  WeatherData? weatherData;
  bool isLoading = false;
  String errorMessage = "";
  String currentCity = "London";

  // IMPORTANT: Replace this with your OpenWeatherMap API key
  // Get free key from: https://openweathermap.org/api
  final String apiKey = "4f909fd4938911393b8a8d2ed62dc083";

  @override
  void initState() {
    super.initState();
    // Start with demo data instead of API call
    _loadDemoData();
  }

  // Demo data for testing without API key
  void _loadDemoData() {
    setState(() {
      weatherData = WeatherData(
        city: "London",
        temperature: 18.5,
        condition: "Clouds",
        description: "partly cloudy",
        humidity: 65,
        windSpeed: 3.2,
      );
      isLoading = false;
      errorMessage = "";
    });
  }

  Future<void> fetchWeatherData() async {
    if (apiKey == "4f909fd4938911393b8a8d2ed62dc083") {
      // Show message about API key and use demo data
      _showApiKeyDialog();
      return;
    }

    setState(() {
      isLoading = true;
      errorMessage = "";
    });

    try {
      final url =
          'https://api.openweathermap.org/data/2.5/weather'
          '?q=$currentCity'
          '&appid=$apiKey'
          '&units=metric';

      final response = await http
          .get(Uri.parse(url), headers: {'Content-Type': 'application/json'})
          .timeout(Duration(seconds: 15));

      if (response.statusCode == 200) {
        final jsonData = json.decode(response.body);
        setState(() {
          weatherData = WeatherData.fromJson(jsonData);
          isLoading = false;
          errorMessage = "";
        });
      } else if (response.statusCode == 404) {
        setState(() {
          errorMessage = "City not found. Please check the spelling.";
          isLoading = false;
        });
      } else if (response.statusCode == 401) {
        setState(() {
          errorMessage = "Invalid API key. Please check your key.";
          isLoading = false;
        });
      } else {
        setState(() {
          errorMessage = "Weather service unavailable. Try again later.";
          isLoading = false;
        });
      }
    } on SocketException {
      setState(() {
        errorMessage = "No internet connection. Please check your network.";
        isLoading = false;
      });
    } catch (e) {
      setState(() {
        errorMessage = "Something went wrong. Please try again.";
        isLoading = false;
      });
    }
  }

  void _showApiKeyDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text("API Key Required"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("To get real weather data, you need a free API key:"),
            SizedBox(height: 10),
            Text(
              "1. Go to openweathermap.org/api",
              style: TextStyle(fontFamily: 'monospace'),
            ),
            Text(
              "2. Sign up for free account",
              style: TextStyle(fontFamily: 'monospace'),
            ),
            Text(
              "3. Get your API key",
              style: TextStyle(fontFamily: 'monospace'),
            ),
            Text(
              "4. Replace 'YOUR_API_KEY_HERE' in code",
              style: TextStyle(fontFamily: 'monospace'),
            ),
            SizedBox(height: 10),
            Text(
              "Currently showing demo data.",
              style: TextStyle(fontStyle: FontStyle.italic),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text("OK"),
          ),
        ],
      ),
    );
  }

  IconData getWeatherIcon(String condition) {
    switch (condition.toLowerCase()) {
      case 'clear':
        return Icons.wb_sunny;
      case 'clouds':
        return Icons.wb_cloudy;
      case 'rain':
        return Icons.umbrella;
      case 'drizzle':
        return Icons.grain;
      case 'snow':
        return Icons.ac_unit;
      case 'thunderstorm':
        return Icons.flash_on;
      case 'mist':
      case 'fog':
        return Icons.cloud;
      default:
        return Icons.wb_cloudy;
    }
  }

  void _showCityDialog() {
    String newCity = "";
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text("Change City"),
        content: TextField(
          onChanged: (value) => newCity = value,
          decoration: InputDecoration(
            hintText: "Enter city name",
            border: OutlineInputBorder(),
          ),
          textCapitalization: TextCapitalization.words,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text("Cancel"),
          ),
          ElevatedButton(
            onPressed: () {
              if (newCity.trim().isNotEmpty) {
                setState(() => currentCity = newCity.trim());
                Navigator.pop(context);
                fetchWeatherData();
              }
            },
            child: Text("Search"),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Weather App"),
        backgroundColor: Colors.blue[600],
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(icon: Icon(Icons.search), onPressed: _showCityDialog),
        ],
      ),
      body: Container(
        width: double.infinity,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Colors.blue[400]!, Colors.blue[700]!],
          ),
        ),
        child: isLoading
            ? Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CircularProgressIndicator(color: Colors.white),
                    SizedBox(height: 20),
                    Text(
                      "Loading weather...",
                      style: TextStyle(color: Colors.white, fontSize: 18),
                    ),
                  ],
                ),
              )
            : errorMessage.isNotEmpty
            ? Center(
                child: Padding(
                  padding: EdgeInsets.all(20),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.error_outline, size: 80, color: Colors.white),
                      SizedBox(height: 20),
                      Text(
                        "Error",
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      SizedBox(height: 10),
                      Text(
                        errorMessage,
                        textAlign: TextAlign.center,
                        style: TextStyle(color: Colors.white70, fontSize: 16),
                      ),
                      SizedBox(height: 30),
                      ElevatedButton(
                        onPressed: () {
                          setState(() => errorMessage = "");
                          fetchWeatherData();
                        },
                        child: Text("Try Again"),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.white,
                          foregroundColor: Colors.blue[700],
                        ),
                      ),
                    ],
                  ),
                ),
              )
            : weatherData != null
            ? SingleChildScrollView(
                padding: EdgeInsets.all(20),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    SizedBox(height: 50),
                    Text(
                      weatherData!.city,
                      style: TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    SizedBox(height: 20),
                    Icon(
                      getWeatherIcon(weatherData!.condition),
                      size: 120,
                      color: Colors.white,
                    ),
                    SizedBox(height: 20),
                    Text(
                      "${weatherData!.temperature.round()}°C",
                      style: TextStyle(
                        fontSize: 60,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    Text(
                      weatherData!.condition,
                      style: TextStyle(fontSize: 24, color: Colors.white),
                    ),
                    Text(
                      weatherData!.description.toUpperCase(),
                      style: TextStyle(fontSize: 16, color: Colors.white70),
                    ),
                    SizedBox(height: 40),
                    Container(
                      padding: EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(15),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          Column(
                            children: [
                              Icon(
                                Icons.water_drop,
                                color: Colors.white70,
                                size: 30,
                              ),
                              SizedBox(height: 8),
                              Text(
                                "${weatherData!.humidity}%",
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 18,
                                ),
                              ),
                              Text(
                                "Humidity",
                                style: TextStyle(
                                  color: Colors.white70,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                          Column(
                            children: [
                              Icon(Icons.air, color: Colors.white70, size: 30),
                              SizedBox(height: 8),
                              Text(
                                "${weatherData!.windSpeed.toStringAsFixed(1)} m/s",
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 18,
                                ),
                              ),
                              Text(
                                "Wind Speed",
                                style: TextStyle(
                                  color: Colors.white70,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    SizedBox(height: 40),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        ElevatedButton.icon(
                          onPressed: fetchWeatherData,
                          icon: Icon(Icons.refresh),
                          label: Text("Refresh"),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.white,
                            foregroundColor: Colors.white,
                          ),
                        ),
                        ElevatedButton.icon(
                          onPressed: _showCityDialog,
                          icon: Icon(Icons.location_city),
                          label: Text("Change City"),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.white,
                            foregroundColor: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              )
            : Center(
                child: Text(
                  "No weather data available",
                  style: TextStyle(color: Colors.white, fontSize: 18),
                ),
              ),
      ),
    );
  }
}

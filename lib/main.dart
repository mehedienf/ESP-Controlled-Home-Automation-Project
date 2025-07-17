// Import necessary packages for async operations, Flutter UI, and HTTP requests
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

// Entry point of the Flutter application
void main() => runApp(const MyApp());

// Main app widget that sets up the overall application structure
class MyApp extends StatelessWidget {
  // Constructor with optional super key parameter
  const MyApp({super.key});
  
  // Build method that creates the app's widget tree
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'ESP Controller', // App title shown in task switcher
      theme: ThemeData(primarySwatch: Colors.blue), // App theme with blue color scheme
      home: const ESPControllerPage(), // Main page widget to display
    );
  }
}

// StatefulWidget for the main ESP controller page that can change state
class ESPControllerPage extends StatefulWidget {
  // Constructor with optional super key parameter
  const ESPControllerPage({super.key});
  
  // Create the state object for this widget
  @override
  State<ESPControllerPage> createState() => _ESPControllerPageState();
}

// State class that manages the ESP controller page data and UI updates
class _ESPControllerPageState extends State<ESPControllerPage> {
  // Slider value for fan speed control (0-100)
  double _fanSliderValue = 50;
  
  // Boolean variables to track AUTO mode state for each device
  bool _lightAuto = false;     // Light auto mode toggle
  bool _fanAuto = false;       // Fan auto mode toggle
  bool _pumpAuto = false;      // Pump auto mode toggle
  bool _humidifierAuto = false; // Humidifier auto mode toggle
  
  // String variables to store ESP responses and status
  String _response = '';       // ESP command response text
  String _status = '';         // ESP status information
  
  // Timer for periodic status polling from ESP device
  Timer? _statusTimer;

  // ESP device IP address (Access Point mode)
  final String baseUrl = 'http://192.168.4.1'; // ESP AP IP

  // Initialize method called when widget is first created
  @override
  void initState() {
    super.initState(); // Call parent initialization
    _startPollingStatus(); // Start periodic status updates from ESP
  }

  // Cleanup method called when widget is removed from widget tree
  @override
  void dispose() {
    _statusTimer?.cancel(); // Cancel the status polling timer to prevent memory leaks
    super.dispose(); // Call parent dispose method
  }

  // Asynchronous method to send commands to ESP device
  Future<void> _sendCommand(String cmd) async {
    // Create URI with command parameter for ESP device
    final uri = Uri.parse('$baseUrl/send?c=$cmd');
    try {
      // Send HTTP GET request to ESP device
      final res = await http.get(uri);
      // Update UI with response from ESP device
      setState(() => _response = res.body);
    } catch (e) {
      // Handle network errors and update UI with error message
      setState(() => _response = 'Error: $e');
    }
  }

  // Method to start periodic status polling from ESP device
  void _startPollingStatus() {
    // Create timer that runs every 1 second
    _statusTimer = Timer.periodic(const Duration(seconds: 1), (timer) async {
      try {
        // Send HTTP GET request to get ESP status
        final res = await http.get(Uri.parse('$baseUrl/status'));
        // Update UI with status information
        setState(() => _status = res.body);
      } catch (e) {
        // Handle network errors and update UI with error message
        setState(() => _status = 'Error: $e');
      }
    });
  }

  // Method to build individual device control cards
  Widget _buildDeviceCard(String label, String cmd, bool autoValue, ValueChanged<bool> onAutoChanged, {bool showSlider = false}) {
    // Initialize slider widget as empty by default
    Widget sliderWidget = const SizedBox.shrink();
    
    // Add slider widget only if showSlider parameter is true
    if (showSlider) {
      sliderWidget = Slider(
        min: 0,                    // Minimum slider value
        max: 100,                  // Maximum slider value
        value: _fanSliderValue,    // Current slider value
        onChanged: (val) {         // Callback when slider value changes
          setState(() => _fanSliderValue = val); // Update slider value in state
          _sendCommand('FAN:${val.toInt()}');    // Send fan speed command to ESP
        },
      );
    }
    
    // Return card widget containing device controls
    return Card(
      child: Column(               // Vertical layout for card contents
        children: [
          Row(                     // Horizontal layout for AUTO label and switch
            children: [
              Text('AUTO'),        // AUTO mode label
              Switch(              // Toggle switch for AUTO mode
                value: autoValue,  // Current switch state
                onChanged: onAutoChanged, // Callback when switch is toggled
              ),
            ],
          ),
          ElevatedButton(          // Device control button
            onPressed: () => _sendCommand(cmd), // Send device command when pressed
            child: Text(label),    // Button text (device name)
          ),
          sliderWidget,           // Slider widget (only visible for fan)
        ],
      ),
    );
  }

  // Build method that creates the main UI layout
  @override
  Widget build(BuildContext context) {
    return Scaffold(                              // Main app structure with app bar and body
      appBar: AppBar(title: const Text('ESP Wi-Fi Controller')), // Top app bar with title
      body: Column(                               // Vertical layout for main content
        children: [
          SizedBox(                               // Fixed height container for device cards
            height: 400,                          // Set height to 400 pixels
            child: GridView.count(                // Grid layout for device cards
              crossAxisCount: 2,                  // 2 cards per row
              physics: NeverScrollableScrollPhysics(), // Disable scrolling for grid
              children: [                         // List of device cards
                // Light control card with AUTO toggle
                _buildDeviceCard('LIGHT', 'A', _lightAuto, (val) => setState(() => _lightAuto = val)),
                // Fan control card with AUTO toggle and slider
                _buildDeviceCard('FAN', 'B', _fanAuto, (val) => setState(() => _fanAuto = val), showSlider: true),
                // Pump control card with AUTO toggle
                _buildDeviceCard('PUMP', 'C', _pumpAuto, (val) => setState(() => _pumpAuto = val)),
                // Humidifier control card with AUTO toggle
                _buildDeviceCard('HUMIDIFIER', 'D', _humidifierAuto, (val) => setState(() => _humidifierAuto = val)),
              ],
            ),
          ),
          Expanded(                               // Expandable container for terminal output
            child: Container(                     // Terminal-style container
              margin: EdgeInsets.all(8),          // Outer spacing around container
              padding: EdgeInsets.all(12),        // Inner spacing inside container
              decoration: BoxDecoration(           // Container styling
                color: Colors.black,              // Black background like terminal
                border: Border.all(color: Colors.grey), // Grey border around container
                borderRadius: BorderRadius.circular(8),  // Rounded corners
              ),
              child: SingleChildScrollView(       // Scrollable content area
                child: Column(                    // Vertical layout for text content
                  crossAxisAlignment: CrossAxisAlignment.start, // Left-align text
                  children: [
                    Text(                         // ESP response text display
                      'ESP Response:\n$_response', // Label and response content
                      style: TextStyle(           // Text styling
                        color: Colors.green,      // Green text color (terminal style)
                        fontFamily: 'monospace',  // Monospace font (terminal style)
                        fontSize: 12,             // Small font size
                      ),
                    ),
                    SizedBox(height: 16),         // Vertical spacing between sections
                    Text(                         // ESP status text display
                      'ESP Status:\n$_status',    // Label and status content
                      style: TextStyle(           // Text styling
                        color: Colors.cyan,       // Cyan text color (terminal style)
                        fontFamily: 'monospace',  // Monospace font (terminal style)
                        fontSize: 12,             // Small font size
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
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
  
  // Boolean variables to track ON/OFF state for each device
  bool _lightOn = false;       // Light ON/OFF state
  bool _fanOn = false;         // Fan ON/OFF state
  bool _pumpOn = false;        // Pump ON/OFF state
  bool _humidifierOn = false;  // Humidifier ON/OFF state
  
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
    _syncFanSliderValue(); // Synchronize fan slider with ESP device on startup
    _syncAllDeviceStates(); // Synchronize all device AUTO states on startup
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

  // Method to send AUTO mode commands to ESP device
  Future<void> _sendAutoCommand(String deviceName, bool autoState) async {
    // Create URI for AUTO mode setting
    final uri = Uri.parse('$baseUrl/set${deviceName}auto?value=${autoState ? '1' : '0'}');
    try {
      // Send HTTP GET request to ESP device
      final res = await http.get(uri);
      // Update UI with response from ESP device
      setState(() => _response = res.body);
      print('AUTO command sent: $deviceName = ${autoState ? 'ON' : 'OFF'}');
    } catch (e) {
      // Handle network errors and update UI with error message
      setState(() => _response = 'Auto Error: $e');
      print('Failed to send AUTO command: $e');
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

  // Method to synchronize fan slider value with ESP device on app startup
  Future<void> _syncFanSliderValue() async {
    try {
      // Send HTTP GET request to get current fan speed from ESP
      final res = await http.get(Uri.parse('$baseUrl/fanspeed'));
      // Parse response and update slider value if valid
      final fanSpeed = double.tryParse(res.body.trim());
      if (fanSpeed != null && fanSpeed >= 0 && fanSpeed <= 100) {
        setState(() => _fanSliderValue = fanSpeed); // Update slider with ESP value
      }
    } catch (e) {
      // Handle network errors (keep default slider value)
      print('Failed to sync fan slider: $e');
    }
  }

  // Method to synchronize all device AUTO states with ESP device on app startup
  Future<void> _syncAllDeviceStates() async {
    // Synchronize light AUTO state
    await _syncDeviceState('light', (value) => _lightAuto = value);
    // Synchronize fan AUTO state
    await _syncDeviceState('fan', (value) => _fanAuto = value);
    // Synchronize pump AUTO state
    await _syncDeviceState('pump', (value) => _pumpAuto = value);
    // Synchronize humidifier AUTO state
    await _syncDeviceState('humidifier', (value) => _humidifierAuto = value);
    
    // Synchronize device ON/OFF states
    await _syncAllDeviceOnOffStates();
  }

  // Method to synchronize all device ON/OFF states with ESP device
  Future<void> _syncAllDeviceOnOffStates() async {
    // Synchronize light ON/OFF state
    await _syncDeviceOnOffState('light', (value) => _lightOn = value);
    // Synchronize fan ON/OFF state
    await _syncDeviceOnOffState('fan', (value) => _fanOn = value);
    // Synchronize pump ON/OFF state
    await _syncDeviceOnOffState('pump', (value) => _pumpOn = value);
    // Synchronize humidifier ON/OFF state
    await _syncDeviceOnOffState('humidifier', (value) => _humidifierOn = value);
  }

  // Helper method to synchronize individual device AUTO state
  Future<void> _syncDeviceState(String deviceName, Function(bool) updateState) async {
    try {
      // Send HTTP GET request to get current device AUTO state from ESP
      final res = await http.get(Uri.parse('$baseUrl/${deviceName}auto'));
      // Parse response (expecting "1" for true, "0" for false)
      final autoState = res.body.trim() == '1';
      // Update the device state in UI
      setState(() => updateState(autoState));
    } catch (e) {
      // Handle network errors (keep default state)
      print('Failed to sync $deviceName auto state: $e');
    }
  }

  // Helper method to synchronize individual device ON/OFF state
  Future<void> _syncDeviceOnOffState(String deviceName, Function(bool) updateState) async {
    try {
      // Send HTTP GET request to get current device ON/OFF state from ESP
      final res = await http.get(Uri.parse('$baseUrl/${deviceName}state'));
      // Parse response (expecting "1" for ON, "0" for OFF)
      final onOffState = res.body.trim() == '1';
      // Update the device state in UI
      setState(() => updateState(onOffState));
    } catch (e) {
      // Handle network errors (keep default state)
      print('Failed to sync $deviceName ON/OFF state: $e');
    }
  }

  // Method to build individual device control cards
  Widget _buildDeviceCard(String label, String cmd, bool autoValue, ValueChanged<bool> onAutoChanged, bool deviceOn, ValueChanged<bool> onDeviceChanged, {bool showSlider = false}) {
    // Initialize slider widget as empty by default
    Widget sliderWidget = const SizedBox.shrink();
    
    // Add slider widget only if showSlider parameter is true
    if (showSlider) {
      sliderWidget = Padding(
        padding: const EdgeInsets.symmetric(horizontal: 0.0, vertical: 0.0), // Reduced vertical padding from 6.0 to 2.0
        child: Opacity(
          opacity: (!deviceOn || autoValue) ? 0.3 : 1.0, // Make slider faded when device is OFF or AUTO mode is ON
          child: SliderTheme(
            data: SliderTheme.of(context).copyWith(
              trackHeight: 2.0,              // Thinner track for more subtle appearance
              thumbShape: RoundSliderThumbShape(enabledThumbRadius: 0.0), // Smaller thumb
              overlayShape: RoundSliderOverlayShape(overlayRadius: 10.0),  // Smaller touch area
              activeTrackColor: Colors.blue,  // Active track color
              inactiveTrackColor: Colors.grey[300], // Inactive track color
              thumbColor: Colors.blue[700],   // Thumb color
              overlayColor: Colors.blue.withAlpha(32), // Touch overlay color
            ),
            child: Slider(
              min: 0,                    // Minimum slider value
              max: 100,                  // Maximum slider value
              value: _fanSliderValue,    // Current slider value
              onChanged: (!deviceOn || autoValue) ? null : (val) { // Disable slider when device is OFF or AUTO mode is ON
                setState(() => _fanSliderValue = val); // Update slider value in state
                _sendCommand('FAN:${val.toInt()}');    // Send fan speed command to ESP
              },
            ),
          ),
        ),
      );
    }
    
    // Return card widget containing device controls with enhanced styling
    return Card(
      elevation: 4,                                  // Card shadow depth
      margin: EdgeInsets.all(4),                     // Margin around card
      // color: Colors.transparent,                      // Card background color
      shape: RoundedRectangleBorder(                 // Card shape with rounded corners
        borderRadius: BorderRadius.circular(12),
      ),
      clipBehavior: Clip.antiAlias,                  // Clip content to card bounds
      child: Column(                                 // Change to Column instead of Padding
        children: [
          // Device name/title panel at the very top
          Container(
            width: double.infinity,                  // Card এর সমান width
            padding: EdgeInsets.symmetric(vertical: 8), // Vertical padding for height
            decoration: BoxDecoration(
              color: Colors.blue[600],
              // color: Colors.transparent,              // Same blue color for all devices
              // Remove borderRadius since it's now clipped by card
            ),
            child: Text(
              label,                                 // Device name (LIGHT, FAN, PUMP, HUMIDIFIER)
              textAlign: TextAlign.center,           // Center align text
              style: TextStyle(
                fontSize: 16,                        // Font size
                fontWeight: FontWeight.bold,         // Bold text
                color: Colors.white,                 // White text on blue background
                letterSpacing: 1.0,                  // Letter spacing for better readability
              ),
            ),
          ),
          
          // Card content area
          Expanded(
            child: Padding(                          // Padding inside card content
              padding: EdgeInsets.all(12),
              child: Column(                         // Vertical layout for card contents
                children: [
                  // AUTO mode toggle section at top
                  Row(                               // Horizontal layout for AUTO label and switch
                    mainAxisAlignment: MainAxisAlignment.spaceBetween, // Space between label and switch
                    children: [
                      Text(
                        'AUTO',                      // AUTO mode label
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: autoValue ? Colors.green : Colors.grey[600],
                        ),
                      ),
                      
                      // Custom toggle switch for AUTO mode
                      GestureDetector(
                        onTap: () {
                          bool newValue = !autoValue;
                          onAutoChanged(newValue);
                          _sendAutoCommand(label.toLowerCase(), newValue);
                        },
                        child: Container(
                          width: 45,                                   // Toggle width
                          height: 24,                                  // Toggle height
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(12),   // Rounded track
                            color: autoValue 
                                ? Color(0xFF4CAF50)                    // Green background when ON
                                : Color(0xFFE0E0E0),                   // Light grey background when OFF
                          ),
                          child: AnimatedAlign(
                            duration: Duration(milliseconds: 200),     // Smooth animation
                            curve: Curves.easeInOut,                   // Natural animation curve
                            alignment: autoValue 
                                ? Alignment.centerRight               // Thumb on right when ON
                                : Alignment.centerLeft,               // Thumb on left when OFF
                            child: Container(
                              width: 20,                              // Thumb width
                              height: 20,                             // Thumb height
                              margin: EdgeInsets.all(2),              // Small margin around thumb
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,               // Perfect circle thumb
                                color: Colors.white,                  // White thumb color
                                boxShadow: [                          // Subtle shadow
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.2),
                                    offset: Offset(0, 1),
                                    blurRadius: 2,
                                    spreadRadius: 0,
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  
                  // Fixed spacing to align buttons across all cards
                  SizedBox(height: 25),                // Fixed height for consistent button position
                  
                  // Device control button - PERFECTLY ALIGNED ACROSS ALL CARDS
                  Container(
                    width: double.infinity,          // Full width button
                    padding: EdgeInsets.symmetric(horizontal: 20), // Horizontal padding
                    child: ElevatedButton(
                      onPressed: () {
                        onDeviceChanged(!deviceOn); // Toggle device ON/OFF state
                        _sendCommand(cmd);           // Send command to ESP
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: deviceOn ? Colors.green : Colors.grey, // Green when ON, grey when OFF
                        foregroundColor: Colors.white, // Always white text
                        padding: EdgeInsets.symmetric(vertical: 3), // Vertical padding
                        shape: RoundedRectangleBorder( // Button shape
                          borderRadius: BorderRadius.circular(20), // Rounded button
                        ),
                        elevation: 2,                // Shadow
                      ),
                      child: Text(
                        deviceOn ? 'ON' : 'OFF',     // Show current state
                        style: TextStyle(
                          fontSize: 14,              // Font size
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                  
                  // EXPANDED LAYOUT - Bottom space divided for slider positioning
                  Expanded(
                    child: Column(
                      children: [
                        // ADJUSTED POSITION - Slider moved lower
                        if (showSlider) ...[
                          Spacer(flex: 6),               // More space above slider (pushes slider down)
                          sliderWidget,                  // Slider widget for fan (MOVED LOWER)
                          Spacer(flex: 1),               // Less space below slider
                        ] else ...[
                          Spacer(),                      // Fill all remaining space for non-slider cards
                        ],
                      ],
                    ),
                  ),
                  
                  // Small bottom padding
                  SizedBox(height: 0),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Build method that creates the main UI layout
  @override
  Widget build(BuildContext context) {
    return Scaffold(                              // Main app structure with app bar and body
      appBar: AppBar(title: const Text('ESP Controller')), // Top app bar with title
      body: Container(
        color: Colors.white, // <-- এখানেই মূল সাদা background
        child: Column(                               // Vertical layout for main content
          children: [
            SizedBox(                               // Fixed height container for device cards
              height: 420,                          // Increased height for better card spacing
              child: GridView.count(                // Grid layout for device cards
                crossAxisCount: 2,                  // 2 cards per row
                physics: NeverScrollableScrollPhysics(), // Disable scrolling for grid
                padding: EdgeInsets.all(8),         // Padding around entire grid
                mainAxisSpacing: 8,                 // Vertical spacing between cards
                crossAxisSpacing: 8,                // Horizontal spacing between cards
                childAspectRatio: 0.85,             // Increased aspect ratio to make cards taller and prevent overflow
                children: [                         // List of device cards
                  // Light control card with AUTO toggle
                  _buildDeviceCard('LIGHT', 'A', _lightAuto, (val) => setState(() => _lightAuto = val), _lightOn, (val) => setState(() => _lightOn = val)),
                  // Fan control card with AUTO toggle and slider
                  _buildDeviceCard('FAN', 'B', _fanAuto, (val) => setState(() => _fanAuto = val), _fanOn, (val) => setState(() => _fanOn = val), showSlider: true),
                  // Pump control card with AUTO toggle
                  _buildDeviceCard('PUMP', 'C', _pumpAuto, (val) => setState(() => _pumpAuto = val), _pumpOn, (val) => setState(() => _pumpOn = val)),
                  // Humidifier control card with AUTO toggle
                  _buildDeviceCard('HUMIDIFIER', 'D', _humidifierAuto, (val) => setState(() => _humidifierAuto = val), _humidifierOn, (val) => setState(() => _humidifierOn = val)),
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
      ),
    );
  }
}
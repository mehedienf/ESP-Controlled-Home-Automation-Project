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
        padding: const EdgeInsets.symmetric(horizontal: 0.0, vertical: 6.0), // Removed horizontal padding for wider slider, reduced vertical padding
        child: Opacity(
          opacity: (!deviceOn || autoValue) ? 0.3 : 1.0, // Make slider faded when device is OFF or AUTO mode is ON
          child: SliderTheme(
            data: SliderTheme.of(context).copyWith(
              trackHeight: 2.0,              // Thinner track for more subtle appearance
              thumbShape: RoundSliderThumbShape(enabledThumbRadius: 0.0), // Smaller thumb
              overlayShape: RoundSliderOverlayShape(overlayRadius: 5.0),  // Smaller touch area
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
      elevation: 4,                // Card shadow depth
      margin: EdgeInsets.all(8),   // Margin around card
      shape: RoundedRectangleBorder( // Card shape with rounded corners
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(              // Padding inside card
        padding: EdgeInsets.all(12),
        child: Column(             // Vertical layout for card contents
          mainAxisAlignment: MainAxisAlignment.spaceAround, // Changed to spaceAround for better distribution
          children: [
            // Device name/title at the top
            Text(
              label,               // Device name (LIGHT, FAN, PUMP, HUMIDIFIER)
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.blue[800],
              ),
            ),
            
            // AUTO mode toggle section
            Row(                   // Horizontal layout for AUTO label and switch
              mainAxisAlignment: MainAxisAlignment.spaceBetween, // Space between label and switch
              children: [
                Text(
                  'AUTO',          // AUTO mode label
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: autoValue ? Colors.green : Colors.grey[600],
                  ),
                ),
                Transform.scale(   // Scale down the switch to make it smaller
                  scale: 0.8,      // Make switch 80% of original size
                  child: Switch(   // Toggle switch for AUTO mode
                    value: autoValue, // Current switch state
                    activeColor: Colors.green, // Switch color when ON
                    materialTapTargetSize: MaterialTapTargetSize.shrinkWrap, // Reduce tap target size
                    onChanged: (val) { // Callback when switch is toggled
                      onAutoChanged(val); // Update local state
                      _sendAutoCommand(label.toLowerCase(), val); // Send AUTO state to ESP
                    },
                  ),
                ),
              ],
            ),
            
            // Device control button in center with enhanced styling
            Container(
              width: double.infinity, // Full width button
              padding: EdgeInsets.symmetric(horizontal: 20), // Add horizontal padding to make button smaller
              child: ElevatedButton(
                onPressed: () {
                  onDeviceChanged(!deviceOn); // Toggle device ON/OFF state
                  _sendCommand(cmd); // Send command to ESP
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: deviceOn ? Colors.green : Colors.grey, // Green when ON, grey when OFF
                  foregroundColor: Colors.white, // Always white text
                  padding: EdgeInsets.symmetric(vertical: 3), // Reduced vertical padding for smaller button
                  shape: RoundedRectangleBorder( // Button shape
                    borderRadius: BorderRadius.circular(20), // Increased border radius for more rounded button
                  ),
                  elevation: 2, // Always has shadow
                ),
                child: Text(
                  deviceOn ? 'ON' : 'OFF', // Show current state
                  style: TextStyle(
                    fontSize: 14,    // Reduced font size for smaller button
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
            
            // Slider widget at bottom (only visible for fan)
            sliderWidget,
            
            // Show current fan speed value if slider is visible
            if (showSlider)
              Text(
                '${_fanSliderValue.toInt()}%', // Display current fan speed percentage
                style: TextStyle(
                  fontSize: 12,
                  color: (!deviceOn || autoValue) ? Colors.grey : Colors.blue, // Grey when device OFF or AUTO mode, blue otherwise
                  fontWeight: FontWeight.w500,
                ),
              ),
          ],
        ),
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
    );
  }
}
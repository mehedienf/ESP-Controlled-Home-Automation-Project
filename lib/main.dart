import 'dart:async';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

void main() => runApp(const MyApp());

class MyApp extends StatelessWidget {
  const MyApp({super.key});
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'ESP Controller',
      theme: ThemeData(primarySwatch: Colors.blue),
      home: const ESPControllerPage(),
    );
  }
}

class ESPControllerPage extends StatefulWidget {
  const ESPControllerPage({super.key});
  @override
  State<ESPControllerPage> createState() => _ESPControllerPageState();
}

class _ESPControllerPageState extends State<ESPControllerPage> {
  double _fanSliderValue = 50;
  bool _lightAuto = false;
  bool _fanAuto = false;
  bool _pumpAuto = false;
  bool _humidifierAuto = false;
  String _response = '';
  String _status = '';
  Timer? _statusTimer;

  final String baseUrl = 'http://192.168.4.1'; // ESP AP IP

  @override
  void initState() {
    super.initState();
    _startPollingStatus();
  }

  @override
  void dispose() {
    _statusTimer?.cancel();
    super.dispose();
  }

  Future<void> _sendCommand(String cmd) async {
    final uri = Uri.parse('$baseUrl/send?c=$cmd');
    try {
      final res = await http.get(uri);
      setState(() => _response = res.body);
    } catch (e) {
      setState(() => _response = 'Error: $e');
    }
  }

  void _startPollingStatus() {
    _statusTimer = Timer.periodic(const Duration(seconds: 1), (timer) async {
      try {
        final res = await http.get(Uri.parse('$baseUrl/status'));
        setState(() => _status = res.body);
      } catch (e) {
        setState(() => _status = 'Error: $e');
      }
    });
  }

  Widget _buildDeviceCard(String label, String cmd, bool autoValue, ValueChanged<bool> onAutoChanged, {bool showSlider = false}) {
    Widget sliderWidget = const SizedBox.shrink();
    if (showSlider) {
      sliderWidget = Slider(
        min: 0,
        max: 100,
        value: _fanSliderValue,
        onChanged: (val) {
          setState(() => _fanSliderValue = val);
          _sendCommand('FAN:${val.toInt()}');
        },
      );
    }
    return Card(
      child: Column(
        children: [
          Row(
            children: [
              Text('AUTO'),
              Switch(
                value: autoValue,
                onChanged: onAutoChanged,
              ),
            ],
          ),
          ElevatedButton(
            onPressed: () => _sendCommand(cmd),
            child: Text(label),
          ),
          sliderWidget,
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('ESP Wi-Fi Controller')),
      body: Column(
        children: [
          SizedBox(
            height: 400,
            child: GridView.count(
              crossAxisCount: 2,
              physics: NeverScrollableScrollPhysics(),
              children: [
                _buildDeviceCard('LIGHT', 'A', _lightAuto, (val) => setState(() => _lightAuto = val)),
                _buildDeviceCard('FAN', 'B', _fanAuto, (val) => setState(() => _fanAuto = val), showSlider: true),
                _buildDeviceCard('PUMP', 'C', _pumpAuto, (val) => setState(() => _pumpAuto = val)),
                _buildDeviceCard('HUMIDIFIER', 'D', _humidifierAuto, (val) => setState(() => _humidifierAuto = val)),
              ],
            ),
          ),
          Expanded(
            child: Container(
              margin: EdgeInsets.all(8),
              padding: EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.black,
                border: Border.all(color: Colors.grey),
                borderRadius: BorderRadius.circular(8),
              ),
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'ESP Response:\n$_response',
                      style: TextStyle(
                        color: Colors.green,
                        fontFamily: 'monospace',
                        fontSize: 12,
                      ),
                    ),
                    SizedBox(height: 16),
                    Text(
                      'ESP Status:\n$_status',
                      style: TextStyle(
                        color: Colors.cyan,
                        fontFamily: 'monospace',
                        fontSize: 12,
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
/*
 * ESP32/ESP8266 Web Server for Home Automation Controller
 * Handles endpoints for Flutter app synchronization
 * Author: Your Name
 * Date: July 17, 2025
 */

#include <WiFi.h>          // For ESP32
// #include <ESP8266WiFi.h>   // For ESP8266 (uncomment this and comment above line)
#include <WebServer.h>     // For ESP32
// #include <ESP8266WebServer.h>  // For ESP8266 (uncomment this and comment above line)

// WiFi credentials for Access Point mode
const char* ssid = "ESP_Controller";     // WiFi network name
const char* password = "12345678";       // WiFi password (min 8 characters)

// Create web server on port 80
WebServer server(80);   // For ESP32
// ESP8266WebServer server(80);  // For ESP8266

// Device state variables
bool lightAuto = false;      // Light AUTO mode state
bool fanAuto = false;        // Fan AUTO mode state  
bool pumpAuto = false;       // Pump AUTO mode state
bool humidifierAuto = false; // Humidifier AUTO mode state
int fanSpeed = 50;           // Fan speed value (0-100)

// Device control pins (adjust according to your hardware)
#define LIGHT_PIN 2          // GPIO pin for light control
#define FAN_PIN 4            // GPIO pin for fan control
#define PUMP_PIN 5           // GPIO pin for pump control
#define HUMIDIFIER_PIN 18    // GPIO pin for humidifier control
#define FAN_SPEED_PIN 19     // PWM pin for fan speed control

void setup() {
  Serial.begin(115200);
  Serial.println("Starting ESP Controller...");
  
  // Initialize GPIO pins
  pinMode(LIGHT_PIN, OUTPUT);
  pinMode(FAN_PIN, OUTPUT);
  pinMode(PUMP_PIN, OUTPUT);
  pinMode(HUMIDIFIER_PIN, OUTPUT);
  pinMode(FAN_SPEED_PIN, OUTPUT);
  
  // Set initial states
  digitalWrite(LIGHT_PIN, LOW);
  digitalWrite(FAN_PIN, LOW);
  digitalWrite(PUMP_PIN, LOW);
  digitalWrite(HUMIDIFIER_PIN, LOW);
  analogWrite(FAN_SPEED_PIN, map(fanSpeed, 0, 100, 0, 255));
  
  // Start WiFi Access Point
  WiFi.softAP(ssid, password);
  IPAddress IP = WiFi.softAPIP();
  Serial.print("Access Point IP: ");
  Serial.println(IP);
  
  // Setup web server endpoints
  setupWebServerRoutes();
  
  // Start the server
  server.begin();
  Serial.println("Web server started!");
}

void loop() {
  server.handleClient();  // Handle incoming client requests
  delay(10);              // Small delay for stability
}

// Function to setup all web server routes/endpoints
void setupWebServerRoutes() {
  
  // ============ COMMAND ENDPOINTS ============
  
  // Handle device commands from Flutter app
  server.on("/send", HTTP_GET, []() {
    String command = server.arg("c");  // Get command parameter
    String response = handleDeviceCommand(command);
    server.send(200, "text/plain", response);
    Serial.println("Command: " + command + " | Response: " + response);
  });
  
  // ============ STATUS ENDPOINT ============
  
  // Provide system status information
  server.on("/status", HTTP_GET, []() {
    String status = "Light: " + String(digitalRead(LIGHT_PIN) ? "ON" : "OFF") + 
                   " | Fan: " + String(digitalRead(FAN_PIN) ? "ON" : "OFF") +
                   " | Pump: " + String(digitalRead(PUMP_PIN) ? "ON" : "OFF") +
                   " | Humidifier: " + String(digitalRead(HUMIDIFIER_PIN) ? "ON" : "OFF") +
                   " | Fan Speed: " + String(fanSpeed) + "%";
    server.send(200, "text/plain", status);
  });
  
  // ============ SYNCHRONIZATION ENDPOINTS ============
  
  // Get current fan speed value
  server.on("/fanspeed", HTTP_GET, []() {
    server.send(200, "text/plain", String(fanSpeed));
  });
  
  // Get light AUTO mode state
  server.on("/lightauto", HTTP_GET, []() {
    server.send(200, "text/plain", lightAuto ? "1" : "0");
  });
  
  // Get fan AUTO mode state
  server.on("/fanauto", HTTP_GET, []() {
    server.send(200, "text/plain", fanAuto ? "1" : "0");
  });
  
  // Get pump AUTO mode state
  server.on("/pumpauto", HTTP_GET, []() {
    server.send(200, "text/plain", pumpAuto ? "1" : "0");
  });
  
  // Get humidifier AUTO mode state
  server.on("/humidifierauto", HTTP_GET, []() {
    server.send(200, "text/plain", humidifierAuto ? "1" : "0");
  });
  
  // ============ AUTO MODE CONTROL ENDPOINTS ============
  
  // Set light AUTO mode
  server.on("/setlightauto", HTTP_GET, []() {
    String value = server.arg("value");
    lightAuto = (value == "1");
    server.send(200, "text/plain", "Light AUTO: " + String(lightAuto ? "ON" : "OFF"));
  });
  
  // Set fan AUTO mode
  server.on("/setfanauto", HTTP_GET, []() {
    String value = server.arg("value");
    fanAuto = (value == "1");
    server.send(200, "text/plain", "Fan AUTO: " + String(fanAuto ? "ON" : "OFF"));
  });
  
  // Set pump AUTO mode
  server.on("/setpumpauto", HTTP_GET, []() {
    String value = server.arg("value");
    pumpAuto = (value == "1");
    server.send(200, "text/plain", "Pump AUTO: " + String(pumpAuto ? "ON" : "OFF"));
  });
  
  // Set humidifier AUTO mode
  server.on("/sethumidifierauto", HTTP_GET, []() {
    String value = server.arg("value");
    humidifierAuto = (value == "1");
    server.send(200, "text/plain", "Humidifier AUTO: " + String(humidifierAuto ? "ON" : "OFF"));
  });
  
  // Handle 404 errors
  server.onNotFound([]() {
    server.send(404, "text/plain", "Endpoint not found");
  });
}

// Function to handle device commands from Flutter app
String handleDeviceCommand(String command) {
  
  // Light control (Command: A)
  if (command == "A") {
    digitalWrite(LIGHT_PIN, !digitalRead(LIGHT_PIN));  // Toggle light
    return "Light " + String(digitalRead(LIGHT_PIN) ? "ON" : "OFF");
  }
  
  // Fan control (Command: B)
  else if (command == "B") {
    digitalWrite(FAN_PIN, !digitalRead(FAN_PIN));      // Toggle fan
    return "Fan " + String(digitalRead(FAN_PIN) ? "ON" : "OFF");
  }
  
  // Pump control (Command: C)
  else if (command == "C") {
    digitalWrite(PUMP_PIN, !digitalRead(PUMP_PIN));    // Toggle pump
    return "Pump " + String(digitalRead(PUMP_PIN) ? "ON" : "OFF");
  }
  
  // Humidifier control (Command: D)
  else if (command == "D") {
    digitalWrite(HUMIDIFIER_PIN, !digitalRead(HUMIDIFIER_PIN)); // Toggle humidifier
    return "Humidifier " + String(digitalRead(HUMIDIFIER_PIN) ? "ON" : "OFF");
  }
  
  // Fan speed control (Command: FAN:xx where xx is speed 0-100)
  else if (command.startsWith("FAN:")) {
    int speed = command.substring(4).toInt();  // Extract speed value
    if (speed >= 0 && speed <= 100) {
      fanSpeed = speed;
      int pwmValue = map(speed, 0, 100, 0, 255);  // Convert to PWM range
      analogWrite(FAN_SPEED_PIN, pwmValue);       // Set fan speed
      return "Fan Speed: " + String(speed) + "%";
    } else {
      return "Invalid fan speed. Use 0-100.";
    }
  }
  
  // Unknown command
  else {
    return "Unknown command: " + command;
  }
}

// Optional: Function to handle automatic mode logic
void handleAutoModes() {
  // Add your automatic control logic here
  // This function can be called periodically to handle AUTO modes
  
  if (lightAuto) {
    // Example: Turn on light based on time or sensor
    // You can add LDR sensor logic here
  }
  
  if (fanAuto) {
    // Example: Control fan based on temperature
    // You can add temperature sensor logic here
  }
  
  if (pumpAuto) {
    // Example: Control pump based on soil moisture
    // You can add moisture sensor logic here
  }
  
  if (humidifierAuto) {
    // Example: Control humidifier based on humidity
    // You can add humidity sensor logic here
  }
}

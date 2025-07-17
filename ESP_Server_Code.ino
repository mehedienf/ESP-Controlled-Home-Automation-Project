/*
 * Arduino Uno + ESP8266 WiFi Module Web Server for Home Automation Controller
 * Handles endpoints for Flutter app synchronization
 * Hardware: Arduino Uno + ESP8266 (AT Commands)
 * Author: Your Name
 * Date: July 17, 2025
 */

#include <SoftwareSerial.h>  // For ESP8266 communication
#include <String.h>

// ESP8266 WiFi module communication
SoftwareSerial esp8266(2, 3);  // RX=D2, TX=D3 for ESP8266

// WiFi credentials for Access Point mode
const String ssid = "ESP_Controller";     // WiFi network name
const String password = "12345678";       // WiFi password (min 8 characters)

// ESP8266 WiFi module communication
SoftwareSerial esp8266(2, 3);  // RX=D2, TX=D3 for ESP8266

// WiFi credentials for Access Point mode
const String ssid = "ESP_Controller";     // WiFi network name
const String password = "12345678";       // WiFi password (min 8 characters)

// Device state variables
bool lightAuto = false;      // Light AUTO mode state
bool fanAuto = false;        // Fan AUTO mode state  
bool pumpAuto = false;       // Pump AUTO mode state
bool humidifierAuto = false; // Humidifier AUTO mode state
int fanSpeed = 50;           // Fan speed value (0-100)

// Device ON/OFF states
bool lightOn = false;        // Light ON/OFF state
bool fanOn = false;          // Fan ON/OFF state
bool pumpOn = false;         // Pump ON/OFF state
bool humidifierOn = false;   // Humidifier ON/OFF state

// Device control pins (Arduino Uno digital pins)
#define LIGHT_PIN 4          // Digital pin for light control
#define FAN_PIN 5            // Digital pin for fan control
#define PUMP_PIN 6           // Digital pin for pump control
#define HUMIDIFIER_PIN 7     // Digital pin for humidifier control
#define FAN_SPEED_PIN 9      // PWM pin for fan speed control (Pin 9 has PWM)

void setup() {
  Serial.begin(9600);        // Serial monitor communication
  esp8266.begin(9600);       // ESP8266 communication
  Serial.println("Starting Arduino + ESP8266 Controller...");
  
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
  
  // Initialize ESP8266
  initializeESP8266();
  
  Serial.println("System ready!");
}

void loop() {
  // Check for incoming ESP8266 data
  if (esp8266.available()) {
    String request = esp8266.readString();
    Serial.println("Received: " + request);
    
    // Process HTTP request
    String response = processHTTPRequest(request);
    
    // Send response back through ESP8266
    if (response != "") {
      sendHTTPResponse(response);
    }
  }
  
  // Handle automatic modes (call every few seconds)
  static unsigned long lastAutoCheck = 0;
  if (millis() - lastAutoCheck > 5000) {  // Check every 5 seconds
    handleAutoModes();
    lastAutoCheck = millis();
  }
  
  delay(100);              // Small delay for stability
}

// Function to initialize ESP8266 WiFi module
void initializeESP8266() {
  Serial.println("Initializing ESP8266...");
  
  // Reset ESP8266
  sendATCommand("AT+RST", 2000);
  
  // Set WiFi mode to Access Point
  sendATCommand("AT+CWMODE=2", 1000);
  
  // Configure Access Point
  String apConfig = "AT+CWSAP=\"" + ssid + "\",\"" + password + "\",5,3";
  sendATCommand(apConfig, 3000);
  
  // Enable multiple connections
  sendATCommand("AT+CIPMUX=1", 1000);
  
  // Start server on port 80
  sendATCommand("AT+CIPSERVER=1,80", 1000);
  
  Serial.println("ESP8266 initialized as Access Point");
  Serial.println("SSID: " + ssid);
  Serial.println("Password: " + password);
}

// Function to send AT commands to ESP8266
void sendATCommand(String command, int timeout) {
  esp8266.println(command);
  Serial.println("Sent: " + command);
  
  long int time = millis();
  while ((time + timeout) > millis()) {
    while (esp8266.available()) {
      String response = esp8266.readString();
      Serial.print("ESP8266: " + response);
    }
  }
}

// Function to process HTTP requests
String processHTTPRequest(String request) {
  String response = "";
  
  // Parse GET request
  if (request.indexOf("GET /send?c=") >= 0) {
    int cmdStart = request.indexOf("c=") + 2;
    int cmdEnd = request.indexOf(" ", cmdStart);
    if (cmdEnd == -1) cmdEnd = request.indexOf("&", cmdStart);
    if (cmdEnd == -1) cmdEnd = request.length();
    
    String command = request.substring(cmdStart, cmdEnd);
    response = handleDeviceCommand(command);
  }
  else if (request.indexOf("GET /status") >= 0) {
    response = getSystemStatus();
  }
  else if (request.indexOf("GET /fanspeed") >= 0) {
    response = String(fanSpeed);
  }
  else if (request.indexOf("GET /lightstate") >= 0) {
    response = digitalRead(LIGHT_PIN) ? "1" : "0";
  }
  else if (request.indexOf("GET /fanstate") >= 0) {
    response = digitalRead(FAN_PIN) ? "1" : "0";
  }
  else if (request.indexOf("GET /pumpstate") >= 0) {
    response = digitalRead(PUMP_PIN) ? "1" : "0";
  }
  else if (request.indexOf("GET /humidifierstate") >= 0) {
    response = digitalRead(HUMIDIFIER_PIN) ? "1" : "0";
  }
  else if (request.indexOf("GET /lightauto") >= 0) {
    response = lightAuto ? "1" : "0";
  }
  else if (request.indexOf("GET /fanauto") >= 0) {
    response = fanAuto ? "1" : "0";
  }
  else if (request.indexOf("GET /pumpauto") >= 0) {
    response = pumpAuto ? "1" : "0";
  }
  else if (request.indexOf("GET /humidifierauto") >= 0) {
    response = humidifierAuto ? "1" : "0";
  }
  else if (request.indexOf("GET /setlightauto?value=") >= 0) {
    String value = extractParameter(request, "value=");
    lightAuto = (value == "1");
    response = "Light AUTO: " + String(lightAuto ? "ON" : "OFF");
  }
  else if (request.indexOf("GET /setfanauto?value=") >= 0) {
    String value = extractParameter(request, "value=");
    fanAuto = (value == "1");
    response = "Fan AUTO: " + String(fanAuto ? "ON" : "OFF");
  }
  else if (request.indexOf("GET /setpumpauto?value=") >= 0) {
    String value = extractParameter(request, "value=");
    pumpAuto = (value == "1");
    response = "Pump AUTO: " + String(pumpAuto ? "ON" : "OFF");
  }
  else if (request.indexOf("GET /sethumidifierauto?value=") >= 0) {
    String value = extractParameter(request, "value=");
    humidifierAuto = (value == "1");
    response = "Humidifier AUTO: " + String(humidifierAuto ? "ON" : "OFF");
  }
  
  return response;
}

// Function to extract parameter from HTTP request
String extractParameter(String request, String paramName) {
  int paramStart = request.indexOf(paramName) + paramName.length();
  int paramEnd = request.indexOf(" ", paramStart);
  if (paramEnd == -1) paramEnd = request.indexOf("&", paramStart);
  if (paramEnd == -1) paramEnd = request.length();
  
  return request.substring(paramStart, paramEnd);
}

// Function to send HTTP response
void sendHTTPResponse(String content) {
  String httpResponse = "HTTP/1.1 200 OK\r\n";
  httpResponse += "Content-Type: text/plain\r\n";
  httpResponse += "Content-Length: " + String(content.length()) + "\r\n";
  httpResponse += "Connection: close\r\n\r\n";
  httpResponse += content;
  
  // Send response length first
  String cipSend = "AT+CIPSEND=0," + String(httpResponse.length());
  esp8266.println(cipSend);
  delay(100);
  
  // Send actual response
  esp8266.print(httpResponse);
  delay(100);
  
  // Close connection
  esp8266.println("AT+CIPCLOSE=0");
}

// Function to get system status
String getSystemStatus() {
  String status = "Light: " + String(digitalRead(LIGHT_PIN) ? "ON" : "OFF") + 
                 " | Fan: " + String(digitalRead(FAN_PIN) ? "ON" : "OFF") +
                 " | Pump: " + String(digitalRead(PUMP_PIN) ? "ON" : "OFF") +
                 " | Humidifier: " + String(digitalRead(HUMIDIFIER_PIN) ? "ON" : "OFF") +
                 " | Fan Speed: " + String(fanSpeed) + "%";
  return status;
}



// Function to handle device commands from Flutter app
String handleDeviceCommand(String command) {
  
  // Light control (Command: A)
  if (command == "A") {
    lightOn = !lightOn;  // Toggle light state
    digitalWrite(LIGHT_PIN, lightOn ? HIGH : LOW);
    return "Light " + String(lightOn ? "ON" : "OFF");
  }
  
  // Fan control (Command: B)
  else if (command == "B") {
    fanOn = !fanOn;  // Toggle fan state
    digitalWrite(FAN_PIN, fanOn ? HIGH : LOW);
    return "Fan " + String(fanOn ? "ON" : "OFF");
  }
  
  // Pump control (Command: C)
  else if (command == "C") {
    pumpOn = !pumpOn;  // Toggle pump state
    digitalWrite(PUMP_PIN, pumpOn ? HIGH : LOW);
    return "Pump " + String(pumpOn ? "ON" : "OFF");
  }
  
  // Humidifier control (Command: D)
  else if (command == "D") {
    humidifierOn = !humidifierOn;  // Toggle humidifier state
    digitalWrite(HUMIDIFIER_PIN, humidifierOn ? HIGH : LOW);
    return "Humidifier " + String(humidifierOn ? "ON" : "OFF");
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

// Function to handle automatic mode logic
void handleAutoModes() {
  // This function can be called periodically in loop() to handle AUTO modes
  // Only control devices when they are in AUTO mode AND manually turned ON
  
  if (lightAuto && lightOn) {
    // Example: Control light based on time or LDR sensor
    // Add your automatic light control logic here
    // e.g., turn off during day, on during night
  }
  
  if (fanAuto && fanOn) {
    // Example: Control fan speed based on temperature
    // Add your automatic fan control logic here
    // e.g., adjust fanSpeed based on temperature sensor reading
  }
  
  if (pumpAuto && pumpOn) {
    // Example: Control pump based on soil moisture
    // Add your automatic pump control logic here
    // e.g., turn on when soil is dry
  }
  
  if (humidifierAuto && humidifierOn) {
    // Example: Control humidifier based on humidity
    // Add your automatic humidifier control logic here
    // e.g., turn on when humidity is low
  }
}

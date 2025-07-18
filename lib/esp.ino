/*
 * need to set upload speed 115200
 * ESP32 Web Server for Home Automation Controller
 * Handles endpoints for Flutter app synchronization
 * Hardware: ESP32
 * Author: Your Name
 * Date: July 19, 2025
 */

#include <WiFi.h>
#include <WebServer.h>

// WiFi credentials for Access Point mode
const char* ssid = "ESP_Controller";
const char* password = "12345678";

// Device state variables
bool lightAuto = false;
bool fanAuto = false;
bool pumpAuto = false;
bool humidifierAuto = false;
int fanSpeed = 50;

// Device ON/OFF states
bool lightOn = false;
bool fanOn = false;
bool pumpOn = false;
bool humidifierOn = false;

// Device control pins (adjust as needed for ESP32)
#define LIGHT_PIN 4
#define FAN_PIN 5
#define PUMP_PIN 18
#define HUMIDIFIER_PIN 19
#define FAN_SPEED_PIN 21 // PWM capable pin

WebServer server(80);

void setup() {
  Serial.begin(115200);
  pinMode(LIGHT_PIN, OUTPUT);
  pinMode(FAN_PIN, OUTPUT);
  pinMode(PUMP_PIN, OUTPUT);
  pinMode(HUMIDIFIER_PIN, OUTPUT);
  pinMode(FAN_SPEED_PIN, OUTPUT);

  digitalWrite(LIGHT_PIN, LOW);
  digitalWrite(FAN_PIN, LOW);
  digitalWrite(PUMP_PIN, LOW);
  digitalWrite(HUMIDIFIER_PIN, LOW);

  // Use analogWrite instead of ledc functions for compatibility
  analogWrite(FAN_SPEED_PIN, map(fanSpeed, 0, 100, 0, 255));

  // Improved WiFi AP configuration
  WiFi.mode(WIFI_AP);
  WiFi.softAPConfig(IPAddress(192, 168, 4, 1), IPAddress(192, 168, 4, 1), IPAddress(255, 255, 255, 0));
  
  // Use channel 6 instead of 1
  if (WiFi.softAP(ssid, password, 6, 0, 4)) {
    Serial.println("ESP32 AP Started Successfully!");
    Serial.print("AP SSID: ");
    Serial.println(ssid);
    Serial.print("AP IP address: ");
    Serial.println(WiFi.softAPIP());
  } else {
    Serial.println("Failed to start AP!");
  }

  server.on("/send", HTTP_GET, handleSend);
  server.on("/status", HTTP_GET, handleStatus);
  server.on("/fanspeed", HTTP_GET, []() {
    server.send(200, "text/plain", String(fanSpeed));
  });
  server.on("/lightstate", HTTP_GET, []() {
    server.send(200, "text/plain", digitalRead(LIGHT_PIN) ? "1" : "0");
  });
  server.on("/fanstate", HTTP_GET, []() {
    server.send(200, "text/plain", digitalRead(FAN_PIN) ? "1" : "0");
  });
  server.on("/pumpstate", HTTP_GET, []() {
    server.send(200, "text/plain", digitalRead(PUMP_PIN) ? "1" : "0");
  });
  server.on("/humidifierstate", HTTP_GET, []() {
    server.send(200, "text/plain", digitalRead(HUMIDIFIER_PIN) ? "1" : "0");
  });
  server.on("/lightauto", HTTP_GET, []() {
    server.send(200, "text/plain", lightAuto ? "1" : "0");
  });
  server.on("/fanauto", HTTP_GET, []() {
    server.send(200, "text/plain", fanAuto ? "1" : "0");
  });
  server.on("/pumpauto", HTTP_GET, []() {
    server.send(200, "text/plain", pumpAuto ? "1" : "0");
  });
  server.on("/humidifierauto", HTTP_GET, []() {
    server.send(200, "text/plain", humidifierAuto ? "1" : "0");
  });
  server.on("/setlightauto", HTTP_GET, []() {
    if (server.hasArg("value")) {
      lightAuto = server.arg("value") == "1";
      server.send(200, "text/plain", "Light AUTO: " + String(lightAuto ? "ON" : "OFF"));
    }
  });
  server.on("/setfanauto", HTTP_GET, []() {
    if (server.hasArg("value")) {
      fanAuto = server.arg("value") == "1";
      server.send(200, "text/plain", "Fan AUTO: " + String(fanAuto ? "ON" : "OFF"));
    }
  });
  server.on("/setpumpauto", HTTP_GET, []() {
    if (server.hasArg("value")) {
      pumpAuto = server.arg("value") == "1";
      server.send(200, "text/plain", "Pump AUTO: " + String(pumpAuto ? "ON" : "OFF"));
    }
  });
  server.on("/sethumidifierauto", HTTP_GET, []() {
    if (server.hasArg("value")) {
      humidifierAuto = server.arg("value") == "1";
      server.send(200, "text/plain", "Humidifier AUTO: " + String(humidifierAuto ? "ON" : "OFF"));
    }
  });

  server.begin();
  Serial.println("System ready!");
}

void loop() {
  server.handleClient();

  static unsigned long lastAutoCheck = 0;
  if (millis() - lastAutoCheck > 5000) {
    handleAutoModes();
    lastAutoCheck = millis();
  }
}

// Handle /send?c= commands
void handleSend() {
  if (!server.hasArg("c")) {
    server.send(400, "text/plain", "Missing command");
    return;
  }
  String command = server.arg("c");
  String response = handleDeviceCommand(command);
  server.send(200, "text/plain", response);
}

// Handle /status
void handleStatus() {
  String status = "Light: " + String(digitalRead(LIGHT_PIN) ? "ON" : "OFF") +
                  " | Fan: " + String(digitalRead(FAN_PIN) ? "ON" : "OFF") +
                  " | Pump: " + String(digitalRead(PUMP_PIN) ? "ON" : "OFF") +
                  " | Humidifier: " + String(digitalRead(HUMIDIFIER_PIN) ? "ON" : "OFF") +
                  " | Fan Speed: " + String(fanSpeed) + "%";
  server.send(200, "text/plain", status);
}

// Device command handler
String handleDeviceCommand(String command) {
  if (command == "A") {
    lightOn = !lightOn;
    digitalWrite(LIGHT_PIN, lightOn ? HIGH : LOW);
    return "Light " + String(lightOn ? "ON" : "OFF");
  } else if (command == "B") {
    fanOn = !fanOn;
    digitalWrite(FAN_PIN, fanOn ? HIGH : LOW);
    return "Fan " + String(fanOn ? "ON" : "OFF");
  } else if (command == "C") {
    pumpOn = !pumpOn;
    digitalWrite(PUMP_PIN, pumpOn ? HIGH : LOW);
    return "Pump " + String(pumpOn ? "ON" : "OFF");
  } else if (command == "D") {
    humidifierOn = !humidifierOn;
    digitalWrite(HUMIDIFIER_PIN, humidifierOn ? HIGH : LOW);
    return "Humidifier " + String(humidifierOn ? "ON" : "OFF");
  } else if (command.startsWith("FAN:")) {
    int speed = command.substring(4).toInt();
    if (speed >= 0 && speed <= 100) {
      fanSpeed = speed;
      analogWrite(FAN_SPEED_PIN, map(speed, 0, 100, 0, 255));
      return "Fan Speed: " + String(speed) + "%";
    } else {
      return "Invalid fan speed. Use 0-100.";
    }
  } else {
    return "Unknown command: " + command;
  }
}

// Automatic mode logic (add your own sensor code here)
void handleAutoModes() {
  if (lightAuto && lightOn) {
    // Add automatic light control logic here
  }
  if (fanAuto && fanOn) {
    // Add automatic fan control logic here
  }
  if (pumpAuto && pumpOn) {
    // Add automatic pump control logic here
  }
  if (humidifierAuto && humidifierOn) {
    // Add automatic humidifier control logic here
  }
}

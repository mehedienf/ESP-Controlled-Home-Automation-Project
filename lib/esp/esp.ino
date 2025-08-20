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
#include <DHT.h>
#include <ESP32Servo.h> 

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
#define BUZZER_PIN 35
#define SERVO_PIN 25  // Alternative servo pin - very reliable for PWM

#define LDR_PIN 13
#define MQ_PIN 34
#define DHT_PIN 14
#define MOISTURE_PIN 27

DHT dht(DHT_PIN, DHT11);
Servo myServo;

//server port
WebServer server(80);

void setup() {
  Serial.begin(115200);
  
  dht.begin();
  
  // Servo setup with explicit configuration
  myServo.attach(SERVO_PIN, 500, 2400);  // Min: 500μs, Max: 2400μs
  delay(100); // Give servo time to initialize
  
  Serial.println("Servo attached to pin " + String(SERVO_PIN));

  // Initialize hardware pins
  pinMode(LIGHT_PIN, OUTPUT);
  pinMode(FAN_PIN, OUTPUT);
  pinMode(PUMP_PIN, OUTPUT);
  pinMode(HUMIDIFIER_PIN, OUTPUT);
  pinMode(FAN_SPEED_PIN, OUTPUT);
  pinMode(BUZZER_PIN, OUTPUT);

  pinMode(LDR_PIN, INPUT);
  pinMode(MQ_PIN, INPUT);
  pinMode(DHT_PIN, INPUT);
  pinMode(MOISTURE_PIN, INPUT); // Digital moisture sensor

  // Set all devices to OFF initially
  digitalWrite(LIGHT_PIN, LOW);
  digitalWrite(FAN_PIN, LOW);
  digitalWrite(PUMP_PIN, LOW);
  digitalWrite(HUMIDIFIER_PIN, LOW);
  analogWrite(FAN_SPEED_PIN, map(fanSpeed, 0, 100, 0, 255));
  
  Serial.println("Initial device states:");
  Serial.println("Light Pin " + String(LIGHT_PIN) + ": " + String(digitalRead(LIGHT_PIN)));
  Serial.println("Fan Pin " + String(FAN_PIN) + ": " + String(digitalRead(FAN_PIN)));
  Serial.println("Pump Pin " + String(PUMP_PIN) + ": " + String(digitalRead(PUMP_PIN)));
  Serial.println("Humidifier Pin " + String(HUMIDIFIER_PIN) + ": " + String(digitalRead(HUMIDIFIER_PIN)));
  
  // Set servo to initial position based on fan speed
  int servoAngle = map(fanSpeed, 0, 100, 0, 180);
  myServo.write(servoAngle);
  delay(500); // Give servo time to move to initial position
  Serial.println("Servo initialized at " + String(servoAngle) + " degrees");

  // Configure WiFi Access Point
  WiFi.mode(WIFI_AP);
  WiFi.softAPConfig(IPAddress(192, 168, 4, 1), IPAddress(192, 168, 4, 1), IPAddress(255, 255, 255, 0));
  
  // Start Access Point
  if (WiFi.softAP(ssid, password, 6, 0, 4)) {
    Serial.println("ESP32 Ready!");
    Serial.print("WiFi: ");
    Serial.println(ssid);
    Serial.print("IP: ");
    Serial.println(WiFi.softAPIP());
  }

  server.on("/send", HTTP_GET, handleSend);
  server.on("/status", HTTP_GET, handleStatus);
  server.on("/sensors", HTTP_GET, handleSensors); // New endpoint for sensor data
  server.on("/fanspeed", HTTP_GET, []() {
    server.send(200, "text/plain", String(fanSpeed));
  });
  server.on("/lightstate", HTTP_GET, []() {
    server.send(200, "text/plain", lightOn ? "1" : "0");  // Use lightOn variable instead of digitalRead
  });
  server.on("/fanstate", HTTP_GET, []() {
    server.send(200, "text/plain", fanOn ? "1" : "0");  // Use fanOn variable instead of digitalRead
  });
  server.on("/pumpstate", HTTP_GET, []() {
    server.send(200, "text/plain", pumpOn ? "1" : "0");  // Use pumpOn variable instead of digitalRead
  });
  server.on("/humidifierstate", HTTP_GET, []() {
    server.send(200, "text/plain", humidifierOn ? "1" : "0");  // Use humidifierOn variable instead of digitalRead
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
  // MQ-02 sensor monitoring for gas detection
  int sensorValue = analogRead(MQ_PIN);
  if(sensorValue >= 750){
    digitalWrite(BUZZER_PIN, HIGH);
  } else {
    digitalWrite(BUZZER_PIN, LOW);
  }

  server.handleClient();

  // Check for automatic modes every 2 seconds
  static unsigned long lastAutoCheck = 0;
  if (millis() - lastAutoCheck > 2000) {
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
  float temperature = dht.readTemperature();
  float humidity = dht.readHumidity();
  int lightLevel = digitalRead(LDR_PIN);
  int gasLevel = analogRead(MQ_PIN);
  
  String status = "Light: " + String(lightOn ? "ON" : "OFF") +
                  " | Fan: " + String(fanOn ? "ON" : "OFF") +
                  " | Pump: " + String(pumpOn ? "ON" : "OFF") +
                  " | Humidifier: " + String(humidifierOn ? "ON" : "OFF") +
                  " | Fan Speed: " + String(fanSpeed) + "%" +
                  " | Temp: " + String(temperature) + "°C" +
                  " | Humidity: " + String(humidity) + "%";
  server.send(200, "text/plain", status);
}

// Handle /sensors - New endpoint for detailed sensor data
void handleSensors() {
  float temperature = dht.readTemperature();
  float humidity = dht.readHumidity();
  int lightLevel = digitalRead(LDR_PIN);
  int gasLevel = analogRead(MQ_PIN);
  int moistureLevel = digitalRead(MOISTURE_PIN); // Digital reading: HIGH = dry, LOW = wet
  
  String sensorData = "Temperature: " + String(temperature) + "°C" +
                     " | Humidity: " + String(humidity) + "%" +
                     " | Light: " + String(lightLevel == LOW ? "Dark" : "Bright") +
                     " | Gas: " + String(gasLevel) +
                     " | Moisture: " + String(moistureLevel == HIGH ? "Dry" : "Wet");
  server.send(200, "text/plain", sensorData);
}

// Device command handler
String handleDeviceCommand(String command) {
  Serial.println("Received command: " + command);
  
  if (command == "A") {
    lightOn = !lightOn;
    digitalWrite(LIGHT_PIN, lightOn ? HIGH : LOW);
    Serial.println("Light button pressed - State: " + String(lightOn ? "ON" : "OFF"));
    return "Light " + String(lightOn ? "ON" : "OFF");
  } else if (command == "B") {
    fanOn = !fanOn;
    digitalWrite(FAN_PIN, fanOn ? HIGH : LOW);  // Normal Active HIGH
    Serial.println("Fan button pressed - State: " + String(fanOn ? "ON" : "OFF") + ", Pin " + String(FAN_PIN) + " set to " + String(fanOn ? "HIGH" : "LOW"));
    return "Fan " + String(fanOn ? "ON" : "OFF");
  } else if (command == "C") {
    pumpOn = !pumpOn;
    digitalWrite(PUMP_PIN, pumpOn ? HIGH : LOW);
    Serial.println("Pump button pressed - State: " + String(pumpOn ? "ON" : "OFF"));
    return "Pump " + String(pumpOn ? "ON" : "OFF");
  } else if (command == "D") {
    humidifierOn = !humidifierOn;
    digitalWrite(HUMIDIFIER_PIN, humidifierOn ? HIGH : LOW);
    Serial.println("Humidifier button pressed - State: " + String(humidifierOn ? "ON" : "OFF"));
    return "Humidifier " + String(humidifierOn ? "ON" : "OFF");
  } else if (command.startsWith("FAN:")) {
    int speed = command.substring(4).toInt();
    if (speed >= 0 && speed <= 100) {
      fanSpeed = speed;
      analogWrite(FAN_SPEED_PIN, map(speed, 0, 100, 0, 255));
      
      // Always control servo with fan slider when not in AUTO mode
      if (!fanAuto) {
        // Manual mode: Use slider value to control servo
        int servoAngle = map(speed, 0, 100, 0, 180);
        servoAngle = constrain(servoAngle, 0, 180); // Safety constraint
        myServo.write(servoAngle);
        delay(15); // Small delay for servo movement
        Serial.println("Manual Mode: Fan Speed " + String(speed) + "% -> Servo " + String(servoAngle) + "°");
      }
      
      return "Fan Speed: " + String(speed) + "%";
    } else {
      return "Invalid fan speed. Use 0-100.";
    }
  } else {
    return "Unknown command: " + command;
  }
}

// Automatic mode logic with sensor integration
void handleAutoModes() {
  // Light AUTO mode - Control based on LDR sensor
  if (lightAuto && lightOn) {
    int lightState = digitalRead(LDR_PIN);
    if (lightState == LOW) {  // Dark
      digitalWrite(LIGHT_PIN, HIGH);
    } else {  // Bright
      digitalWrite(LIGHT_PIN, LOW);
    }
  }

  // Fan AUTO mode - Control servo based on DHT11 temperature
  if (fanAuto && fanOn) {
    float temperature = dht.readTemperature();
    
    if (!isnan(temperature)) {
      // Map temperature (27-40°C) to servo angle (0-180°)
      int servoAngle = map(temperature, 27, 40, 0, 180);
      servoAngle = constrain(servoAngle, 0, 180); // Ensure safe range
      
      myServo.write(servoAngle);
      delay(15); // Small delay for servo movement
      
      Serial.println("AUTO Mode - Temperature: " + String(temperature) + "°C -> Servo: " + String(servoAngle) + "°");
      
      // Also update fan speed based on temperature for PWM control
      int autoFanSpeed = map(temperature, 27, 40, 30, 100);
      autoFanSpeed = constrain(autoFanSpeed, 30, 100);
      fanSpeed = autoFanSpeed;
      analogWrite(FAN_SPEED_PIN, map(autoFanSpeed, 0, 100, 0, 255));
    } else {
      Serial.println("Failed to read temperature from DHT sensor");
    }
  }

  // Pump AUTO mode - Control based on soil moisture
  if (pumpAuto && pumpOn) {
    int moistureLevel = digitalRead(MOISTURE_PIN); // Digital reading
    // If soil is dry (HIGH), turn on pump
    if (moistureLevel == HIGH) {  // Digital sensor: HIGH = dry, LOW = wet
      digitalWrite(PUMP_PIN, HIGH);
      Serial.println("AUTO Mode - Soil is DRY, Pump ON");
    } else {
      digitalWrite(PUMP_PIN, LOW);
      Serial.println("AUTO Mode - Soil is WET, Pump OFF");
    }
  }

  // Humidifier AUTO mode - Control based on DHT11 humidity
  if (humidifierAuto && humidifierOn) {
    float humidity = dht.readHumidity();
    
    if (!isnan(humidity)) {
      // If humidity is low, turn on humidifier
      if (humidity < 50) {  // Adjust threshold as needed
        digitalWrite(HUMIDIFIER_PIN, HIGH);
      } else {
        digitalWrite(HUMIDIFIER_PIN, LOW);
      }
      
      Serial.println("AUTO Mode - Humidity: " + String(humidity) + "%");
    } else {
      Serial.println("Failed to read humidity from DHT sensor");
    }
  }
}

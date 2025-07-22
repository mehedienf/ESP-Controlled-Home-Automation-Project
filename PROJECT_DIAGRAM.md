# ESP32 Home Automation Project - System Diagram

## 🏗️ Overall System Architecture

```
┌─────────────────────────────────────────────────────────────────────────────┐
│                           ESP32 HOME AUTOMATION SYSTEM                      │
└─────────────────────────────────────────────────────────────────────────────┘

┌─────────────────┐    WiFi AP     ┌─────────────────┐    Sensors/Devices    ┌─────────────────┐
│                 │  192.168.4.1   │                 │                       │                 │
│  Flutter App    │◄──────────────►│     ESP32       │◄─────────────────────►│   Hardware      │
│   (Android)     │                │   Controller    │                       │   Components    │
│                 │                │                 │                       │                 │
└─────────────────┘                └─────────────────┘                       └─────────────────┘
```

## 📱 Flutter App Interface

```
┌─────────────────────────────────────────────────────────────────────────────┐
│                          FLUTTER MOBILE APP                                │
├─────────────────────────────────────────────────────────────────────────────┤
│                                                                             │
│  ┌─────────┐  ┌─────────┐  ┌─────────┐  ┌─────────┐                       │
│  │ LIGHT   │  │  FAN    │  │  PUMP   │  │HUMID.   │                       │
│  │ [ON/OFF]│  │ [ON/OFF]│  │ [ON/OFF]│  │ [ON/OFF]│                       │
│  │ [AUTO]  │  │ [AUTO]  │  │ [AUTO]  │  │ [AUTO]  │                       │
│  └─────────┘  └─────────┘  └─────────┘  └─────────┘                       │
│                                                                             │
│  ┌───────────────────────────────────────────────────────────────────────┐ │
│  │                    FAN SPEED SLIDER                                   │ │
│  │  0% ═══════════════════════════════════════════════════════════ 100% │ │
│  └───────────────────────────────────────────────────────────────────────┘ │
│                                                                             │
│  ┌───────────────────────────────────────────────────────────────────────┐ │
│  │                     SENSOR DATA DISPLAY                              │ │
│  │  🌡️ Temperature: 28°C  💧 Humidity: 65%                              │ │
│  │  💡 Light: Bright      ☁️ Gas: 420                                   │ │
│  │  🌱 Moisture: Wet      🔄 Auto Modes Active                          │ │
│  └───────────────────────────────────────────────────────────────────────┘ │
│                                                                             │
└─────────────────────────────────────────────────────────────────────────────┘
```

## 🔌 ESP32 Pin Configuration

```
                    ┌─────────────────────────────┐
                    │           ESP32             │
                    │                             │
            3.3V ──►│ 3.3V                    GND │◄── GND
                    │                             │
        Light ◄─────│ GPIO4                 GPIO5 │────► Fan
                    │                             │
        Pump ◄──────│ GPIO18               GPIO13 │────► LDR Sensor
                    │                             │
   Humidifier ◄─────│ GPIO19               GPIO14 │────► DHT11 (Data)
                    │                             │
    Fan Speed ◄─────│ GPIO21 (PWM)         GPIO25 │────► Servo Motor
                    │                             │
      Buzzer ◄──────│ GPIO35               GPIO27 │────► Moisture Sensor
                    │                             │
                    │ GPIO34               GPIO32 │
                    │ (MQ Gas Sensor)             │
                    └─────────────────────────────┘
```

## 🏠 Hardware Components Layout

```
┌─────────────────────────────────────────────────────────────────────────────┐
│                          PHYSICAL SETUP                                    │
├─────────────────────────────────────────────────────────────────────────────┤
│                                                                             │
│  ┌─────────────┐    ┌─────────────┐    ┌─────────────┐                     │
│  │   ESP32     │    │   DHT11     │    │    LDR      │                     │
│  │ Controller  │    │(Temp/Humid) │    │(Light Sens) │                     │
│  └─────────────┘    └─────────────┘    └─────────────┘                     │
│                                                                             │
│  ┌─────────────┐    ┌─────────────┐    ┌─────────────┐                     │
│  │   MQ-2      │    │  Moisture   │    │   Servo     │                     │
│  │(Gas Sensor) │    │   Sensor    │    │   Motor     │                     │
│  └─────────────┘    └─────────────┘    └─────────────┘                     │
│                                                                             │
│  ┌─────────────┐    ┌─────────────┐    ┌─────────────┐                     │
│  │   Light     │    │    Fan      │    │    Pump     │                     │
│  │   Bulb      │    │   Motor     │    │   Motor     │                     │
│  └─────────────┘    └─────────────┘    └─────────────┘                     │
│                                                                             │
│  ┌─────────────┐    ┌─────────────┐                                        │
│  │ Humidifier  │    │   Buzzer    │                                        │
│  │   Device    │    │ (Gas Alert) │                                        │
│  └─────────────┘    └─────────────┘                                        │
│                                                                             │
└─────────────────────────────────────────────────────────────────────────────┘
```

## 🔄 System Flow Diagram

```
┌─────────────────────────────────────────────────────────────────────────────┐
│                           SYSTEM OPERATION FLOW                            │
└─────────────────────────────────────────────────────────────────────────────┘

    [START] 
       │
       ▼
┌─────────────┐
│   ESP32     │
│   Boots Up  │
└─────────────┘
       │
       ▼
┌─────────────┐
│  WiFi AP    │
│  Created    │
│192.168.4.1  │
└─────────────┘
       │
       ▼
┌─────────────┐     ┌─────────────┐     ┌─────────────┐
│   Sensors   │────►│   AUTO      │────►│   Device    │
│  Reading    │     │   Logic     │     │  Control    │
│   Loop      │     │ Processing  │     │  Actions    │
└─────────────┘     └─────────────┘     └─────────────┘
       │                   │                   │
       ▼                   ▼                   ▼
┌─────────────┐     ┌─────────────┐     ┌─────────────┐
│   Manual    │     │  Temperature│     │   Physical  │
│  Commands   │────►│    Based    │────►│   Device    │
│ From App    │     │   Servo     │     │  Response   │
└─────────────┘     └─────────────┘     └─────────────┘
       │                   │                   │
       ▼                   ▼                   ▼
┌─────────────┐     ┌─────────────┐     ┌─────────────┐
│   HTTP      │     │  Moisture   │     │   Status    │
│ Responses   │     │    Based    │     │  Feedback   │
│  to App     │     │    Pump     │     │   to App    │
└─────────────┘     └─────────────┘     └─────────────┘
```

## 📊 AUTO Mode Decision Tree

```
                        ┌─────────────────┐
                        │   AUTO MODE     │
                        │    ENABLED?     │
                        └─────────────────┘
                                 │
                    ┌────────────┼────────────┐
                    │            │            │
                    ▼            ▼            ▼
            ┌─────────────┐ ┌─────────────┐ ┌─────────────┐
            │    LIGHT    │ │     FAN     │ │    PUMP     │
            │    AUTO     │ │    AUTO     │ │    AUTO     │
            └─────────────┘ └─────────────┘ └─────────────┘
                    │            │            │
                    ▼            ▼            ▼
            ┌─────────────┐ ┌─────────────┐ ┌─────────────┐
            │  LDR < 500  │ │  Temp Range │ │ Moisture    │
            │    Dark?    │ │  27°-40°C   │ │ HIGH=Dry    │
            └─────────────┘ └─────────────┘ └─────────────┘
                    │            │            │
                    ▼            ▼            ▼
            ┌─────────────┐ ┌─────────────┐ ┌─────────────┐
            │ Light ON/   │ │ Servo 0°-   │ │ Pump ON/    │
            │ OFF Control │ │ 180° Control│ │ OFF Control │
            └─────────────┘ └─────────────┘ └─────────────┘
```

## 🌐 Network Communication

```
┌─────────────────────────────────────────────────────────────────────────────┐
│                        NETWORK ARCHITECTURE                                │
└─────────────────────────────────────────────────────────────────────────────┘

    ┌─────────────┐
    │   Mobile    │
    │   Device    │
    └─────────────┘
           │
           │ WiFi Connection
           ▼
    ┌─────────────┐      SSID: ESP_Controller
    │   ESP32     │      Password: 12345678
    │  Access     │      IP: 192.168.4.1
    │   Point     │
    └─────────────┘
           │
           ▼
┌─────────────────────────────────────────────────────────────────────────────┐
│                            HTTP ENDPOINTS                                  │
├─────────────────────────────────────────────────────────────────────────────┤
│                                                                             │
│  GET /send?c=A          → Light Toggle                                     │
│  GET /send?c=B          → Fan Toggle                                       │
│  GET /send?c=C          → Pump Toggle                                      │
│  GET /send?c=D          → Humidifier Toggle                                │
│  GET /send?c=FAN:50     → Fan Speed Control                                │
│                                                                             │
│  GET /fanspeed          → Get Fan Speed                                    │
│  GET /status            → System Status                                    │
│  GET /sensors           → Sensor Data                                      │
│                                                                             │
│  GET /setfanauto?value=1  → Enable Fan AUTO                               │
│  GET /setpumpauto?value=1 → Enable Pump AUTO                              │
│                                                                             │
└─────────────────────────────────────────────────────────────────────────────┘
```

## ⚡ Power and Safety Features

```
┌─────────────────────────────────────────────────────────────────────────────┐
│                         SAFETY & MONITORING                                │
├─────────────────────────────────────────────────────────────────────────────┤
│                                                                             │
│  🔥 GAS DETECTION SYSTEM                                                   │
│  ┌───────────────────────────────────────────────────────────────────────┐ │
│  │  MQ-2 Sensor → Reading > 750 → Buzzer ALARM                          │ │
│  │  Continuous monitoring every loop cycle                                │ │
│  └───────────────────────────────────────────────────────────────────────┘ │
│                                                                             │
│  🔧 SERVO SAFETY LIMITS                                                   │
│  ┌───────────────────────────────────────────────────────────────────────┐ │
│  │  Angle constrained to 0°-180° range                                   │ │
│  │  15ms delay between movements                                          │ │
│  └───────────────────────────────────────────────────────────────────────┘ │
│                                                                             │
│  💧 MOISTURE PROTECTION                                                   │
│  ┌───────────────────────────────────────────────────────────────────────┐ │
│  │  Digital sensor prevents pump over-watering                           │ │
│  │  AUTO mode stops pump when soil is wet                                │ │
│  └───────────────────────────────────────────────────────────────────────┘ │
│                                                                             │
└─────────────────────────────────────────────────────────────────────────────┘
```

## 📝 Project File Structure

```
ESP-Controlled-Home-Automation-Project/
├── lib/
│   ├── main.dart                 # Flutter app main file
│   └── esp.ino                   # ESP32 Arduino code
├── android/                      # Android build files
├── build/                        # Build artifacts
├── README.md                     # Project documentation
├── PROJECT_DIAGRAM.md            # This diagram file
└── pubspec.yaml                  # Flutter dependencies
```

## 🎯 Key Features Summary

✅ **Manual Control**: Individual device ON/OFF control  
✅ **AUTO Modes**: Sensor-based automatic control  
✅ **Fan Speed Control**: 0-100% PWM control with servo integration  
✅ **Temperature Servo**: Servo angle based on DHT11 temperature  
✅ **Moisture Pump**: Automatic watering based on soil moisture  
✅ **Gas Safety**: MQ-2 sensor with buzzer alarm  
✅ **Light Sensor**: Automatic lighting based on LDR  
✅ **Real-time Monitoring**: Live sensor data display  
✅ **WiFi Communication**: Local AP mode for device control  

## 🔧 Installation Requirements

**Hardware:**
- ESP32 Development Board
- DHT11 Temperature/Humidity Sensor
- Servo Motor (SG90 or similar)
- Digital Moisture Sensor
- LDR Light Sensor
- MQ-2 Gas Sensor
- Buzzer
- Relay modules for high-power devices

**Software:**
- Arduino IDE with ESP32 board package
- DHT sensor library
- ESP32Servo library
- Flutter SDK
- Android Studio/VS Code

---
*Created for ESP32 Home Automation Project - July 2025*

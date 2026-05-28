# 🌱 The Mobile DSS — Planting Decision Support System

> This project forms the foundation of my work moving toward offline TinyML and multi-sensor systems for terraced agriculture.

A **Flutter-based mobile Decision Support System (DSS)** that helps users make smarter planting decisions using AI, real-time weather data, and on-device sensors. Whether you're a beginner or an experienced gardener, this app gives you personalised care plans, plant disease diagnosis, ambient light measurements, and an AI botanist chatbot — all in one place.

---

## ✨ Features

| Feature | Description |
|---|---|
| 🏡 **Smart Dashboard** | Displays live weather conditions, personalised planting recommendations, and your saved garden at a glance. |
| 📷 **AI Plant Scanner** | Take a photo or pick from gallery — the AI identifies the plant, detects diseases, provides cure instructions, and flags toxicity (humans & pets). |
| 💡 **Light Meter** | Uses the device's ambient light sensor to measure lux levels and suggests plants that thrive in that lighting condition. |
| 🤖 **Botanist Chat (Alifs)** | Chat with "Alifs", an AI-powered expert botanist. Ask anything about plant care, watering schedules, or troubleshooting problems. |
| 🌿 **Plant Onboarding** | Add plants with a name, location, and optional soil photo. The AI generates a personalised 3-step care plan and sets up automated watering reminders. |
| 🔔 **Smart Notifications** | Automated recurring reminders to water your plants based on AI-determined intervals. |
| 💾 **Persistent Storage** | Your garden data is saved locally using SharedPreferences — survives app restarts. |

---

## 📸 Screenshots

> _Run the app on your device to see the UI in action!_

---

## 🛠️ Tech Stack

- **Framework:** Flutter (Dart)
- **AI Backend:** [Groq API](https://groq.com/) (OpenAI-compatible endpoint)
- **AI Models:** LLaMA 3.3 70B (text) · LLaMA 3.2 90B Vision (image analysis)
- **Weather:** [Open-Meteo API](https://open-meteo.com/) (free, no key required)
- **State Management:** Provider
- **Local Storage:** SharedPreferences
- **Sensors:** `light` package (ambient light sensor), `geolocator` (GPS), `camera`
- **Notifications:** flutter_local_notifications + timezone
- **UI:** Material 3 + Google Fonts (Nunito)

---

## ⚙️ Setup & Installation

### Prerequisites

- [Flutter SDK](https://docs.flutter.dev/get-started/install) (≥ 3.2.0)
- Android Studio / VS Code with Flutter extension
- A physical Android/iOS device (camera & light sensor features require real hardware)
- A [Groq API key](https://console.groq.com/keys) (free tier available)

### 1. Clone the Repository

```bash
git clone https://github.com/aurorixsaad01/The-Mobile-DSS-Planting-Decision-Support-.git
cd The-Mobile-DSS-Planting-Decision-Support-
```

### 2. Install Dependencies

```bash
flutter pub get
```

### 3. Add Your API Key ⚠️

You need a **Groq API key** to enable AI features. Get one for free at [console.groq.com/keys](https://console.groq.com/keys).

Then open the following **4 files** and replace the placeholder values with your actual credentials:

| # | File | Line(s) |
|---|------|---------|
| 1 | `lib/services/chat_service.dart` | Lines 12–13 |
| 2 | `lib/services/gemini_service.dart` | Lines 9–10 |
| 3 | `lib/screens/ai_scanner_screen.dart` | Lines 86–87 |
| 4 | `lib/screens/botanist_chat_screen.dart` | Lines 36–37 |

In each file, find and replace:

```dart
OpenAI.baseUrl = 'YOUR_GROQ_BASE_URL';  // ← Replace with: 'https://api.groq.com/openai'
OpenAI.apiKey = 'YOUR_GROQ_API_KEY';     // ← Replace with your actual key: 'gsk_...'
```

> **Note:** The Weather API (Open-Meteo) is completely free and does **not** require any API key.

### 4. Run the App

```bash
flutter run
```

For web (limited features — no camera/light sensor):

```bash
flutter run -d chrome
```

---

## 📁 Project Structure

```
lib/
├── main.dart                          # App entry point, AppState (Provider), theme, navigation
├── models/
│   ├── plant_model.dart               # Plant data model with watering logic
│   ├── chat_message.dart              # Chat message model
│   ├── custom_image_content_item.dart # Custom content item for vision API
│   └── diagnostic_result.dart         # AI scan result model
├── screens/
│   ├── dashboard_screen.dart          # Home screen — weather, tools grid, garden list
│   ├── ai_scanner_screen.dart         # Camera/gallery plant scanner with AI diagnosis
│   ├── light_meter_screen.dart        # Ambient light sensor with plant recommendations
│   ├── botanist_chat_screen.dart      # Chat with Alifs (AI botanist)
│   └── plant_onboarding.dart          # Add plant form + AI care plan generation
└── services/
    ├── chat_service.dart              # Groq chat API + speech-to-text service
    ├── gemini_service.dart            # Groq API for care plan generation (text + vision)
    ├── notification_service.dart      # Local notification scheduling
    └── weather_service.dart           # Open-Meteo weather API + GPS location
```

---

## 🌤️ How It Works

1. **Dashboard** fetches your GPS location → calls the Open-Meteo API → displays temperature and a smart planting recommendation.
2. **Add Plant** takes a name, location, and optional soil photo → sends it to Groq (LLaMA 3.3) → generates a personalised 3-step care plan → schedules watering reminders.
3. **AI Scanner** captures/picks a photo → sends it to Groq (LLaMA 3.2 Vision) → returns plant identification, health diagnosis, cure steps, and toxicity info as structured JSON.
4. **Botanist Chat** maintains a full conversation history with Groq → provides context-aware plant care advice through "Alifs".
5. **Light Meter** reads the device's ambient light sensor in real-time → classifies light levels → suggests matching plants.

---

## 📝 Notes

- **Web/Desktop:** The app gracefully degrades on non-mobile platforms. Camera and light sensor features switch to simulation mode with gallery-based image picking.
- **Offline:** Weather and AI features require an internet connection. Plant data is stored locally and works offline.
- **Privacy:** No data is sent to external servers other than the Groq API (for AI inference) and Open-Meteo (for weather). GPS coordinates are only used for weather lookups.

---

## 📄 License & Copyright

```
MIT License

Copyright (c) 2026 Saad Ansari (@aurorixsaad01)

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.
```

See the [LICENSE](LICENSE) file for full details.

---

## 👤 Author

**Saad Ansari** — [@aurorixsaad01](https://github.com/aurorixsaad01)

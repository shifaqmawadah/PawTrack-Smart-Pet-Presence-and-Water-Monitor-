#include <WiFi.h>
#include <HTTPClient.h>
#include <ArduinoJson.h>  // Install via Library Manager

#define PIR_PIN 13
#define WATER_SENSOR_PIN 34
#define RELAY_PIN 25

const char* ssid = "sm";
const char* password = "shifaq02";

const char* insertDataURL = "https://humancc.site/shifaqmawaddah/pawtrack/insert_data.php";
const char* getCommandURL = "https://humancc.site/shifaqmawaddah/pawtrack/get_command.php";

int userId = 1;
int deviceId = 1;

void setup() {
  Serial.begin(115200);

  pinMode(PIR_PIN, INPUT);
  pinMode(WATER_SENSOR_PIN, INPUT);
  pinMode(RELAY_PIN, OUTPUT);
  digitalWrite(RELAY_PIN, LOW);

  WiFi.begin(ssid, password);
  Serial.print("Connecting to WiFi");
  while (WiFi.status() != WL_CONNECTED) {
    delay(500);
    Serial.print(".");
  }
  Serial.println("\nWiFi connected");
}

void loop() {
  int pir = digitalRead(PIR_PIN);
  int water = analogRead(WATER_SENSOR_PIN);

  Serial.println("============================");
  Serial.println("PIR Value      : " + String(pir));
  Serial.println("Water Raw Value: " + String(water));

  sendSensorData(pir, water);

  String cmd = fetchCommand();
  if (cmd != "") {
    Serial.println("Fetched Command: " + cmd);
  }

  if (cmd == "REFILL_FOOD" || cmd == "REFILL_WATER") {
    Serial.println("Executing command: " + cmd);
    triggerRelay();
    reportRelayActivation(cmd); // <== NEW: report relay ON
  }

  delay(5000);  // Delay before next loop
}

void sendSensorData(int pir, int water) {
  if (WiFi.status() == WL_CONNECTED) {
    HTTPClient http;
    http.begin(insertDataURL);
    http.addHeader("Content-Type", "application/x-www-form-urlencoded");

    String postData = "user_id=" + String(userId) +
                      "&device_id=" + String(deviceId) +
                      "&pir=" + String(pir) +
                      "&water=" + String(water);

    int httpResponseCode = http.POST(postData);
    Serial.println("Data POST response code: " + String(httpResponseCode));

    http.end();
  } else {
    Serial.println("WiFi not connected. Skipping data send.");
  }
}

String fetchCommand() {
  if (WiFi.status() == WL_CONNECTED) {
    HTTPClient http;
    String fullURL = String(getCommandURL) + "?user_id=" + userId + "&device_id=" + deviceId;
    http.begin(fullURL);

    int httpResponseCode = http.GET();
    String payload = http.getString();
    Serial.println("Command GET response code: " + String(httpResponseCode));
    Serial.println("Payload: " + payload);

    http.end();

    if (httpResponseCode == 200 && payload.length() > 0) {
      StaticJsonDocument<200> doc;
      DeserializationError error = deserializeJson(doc, payload);
      if (!error && doc.containsKey("command")) {
        return String(doc["command"].as<const char*>());
      } else {
        Serial.println("JSON parse error or no command key.");
      }
    } else {
      Serial.println("Empty or invalid payload.");
    }
  } else {
    Serial.println("WiFi not connected. Skipping command fetch.");
  }
  return "";
}

void triggerRelay() {
  Serial.println("Relay ON");
  digitalWrite(RELAY_PIN, HIGH);
  delay(2000);  // Relay ON for 2 seconds
  digitalWrite(RELAY_PIN, LOW);
  Serial.println("Relay OFF");
}

void reportRelayActivation(String command) {
  if (WiFi.status() == WL_CONNECTED) {
    HTTPClient http;
    http.begin(insertDataURL);
    http.addHeader("Content-Type", "application/x-www-form-urlencoded");

    String postData = "user_id=" + String(userId) +
                      "&device_id=" + String(deviceId) +
                      "&command=" + command +
                      "&relay=1";  // New: Mark relay was triggered

    int httpResponseCode = http.POST(postData);
    Serial.println("Relay report response code: " + String(httpResponseCode));

    http.end();
  } else {
    Serial.println("WiFi not connected. Skipping relay report.");
  }
}

#include <WiFi.h>
#include <Firebase_ESP_Client.h>
#include <addons/TokenHelper.h>
#include <DHT.h>
#include <LiquidCrystal_I2C.h>

// ── WiFi ──
#define WIFI_SSID     "Maryam"
#define WIFI_PASSWORD "Maryam2008"

// ── Firebase ──
#define DATABASE_URL    "https://florigen-control-default-rtdb.firebaseio.com/"
#define DATABASE_SECRET "32TyVFBwAM9DEqQACaWYYf1xl8IUV3AB2NmOmjha"

// ── Pins ──
#define DHT_PIN     4
#define DHT_TYPE    DHT11
#define SOIL_PIN    34
#define RELAY_LIGHT 26
#define RELAY_FAN   27
#define RELAY_PUMP  14
#define RELAY_DRAIN 12
#define MOSFET_MIST 13

// ── Objects ──
DHT dht(DHT_PIN, DHT_TYPE);
LiquidCrystal_I2C lcd(0x3F, 16, 2);
FirebaseData fbdo;
FirebaseAuth auth;
FirebaseConfig config;

// ── Timing ──
unsigned long lastSensorRead  = 0;
unsigned long lastFirebaseSend = 0;
unsigned long lastHistorySave  = 0;
const long SENSOR_INTERVAL   = 2000;
const long FIREBASE_INTERVAL  = 5000;
const long HISTORY_INTERVAL   = 60000;

// ── Thresholds ──
float tempMin = 25, tempMax = 35;
float humMin  = 60, humMax  = 65;
float soilMin = 28, soilMax = 40;

// ── Sensor values ──
float temperature  = 0;
float humidity     = 0;
float soilMoisture = 0;

// ── System state ──
bool systemOn       = true;
bool manualOverride = false;
String activePlant  = "hibiscus";

void setup() {
  Serial.begin(115200);

  pinMode(RELAY_LIGHT, OUTPUT); digitalWrite(RELAY_LIGHT, HIGH);
  pinMode(RELAY_FAN,   OUTPUT); digitalWrite(RELAY_FAN,   HIGH);
  pinMode(RELAY_PUMP,  OUTPUT); digitalWrite(RELAY_PUMP,  HIGH);
  pinMode(RELAY_DRAIN, OUTPUT); digitalWrite(RELAY_DRAIN, HIGH);
  pinMode(MOSFET_MIST, OUTPUT); digitalWrite(MOSFET_MIST, LOW);

  dht.begin();

  lcd.init();
  lcd.backlight();
  lcd.setCursor(0, 0);
  lcd.print("Florigen Control");
  lcd.setCursor(0, 1);
  lcd.print("Starting...");

  WiFi.begin(WIFI_SSID, WIFI_PASSWORD);
  Serial.print("Connecting to WiFi");
  while (WiFi.status() != WL_CONNECTED) {
    delay(500);
    Serial.print(".");
  }
  Serial.println("\nWiFi Connected!");

  config.database_url = DATABASE_URL;
  config.signer.tokens.legacy_token = DATABASE_SECRET;
  Firebase.begin(&config, &auth);
  Firebase.reconnectWiFi(true);

  lcd.clear();
  lcd.setCursor(0, 0);
  lcd.print("WiFi Connected!");
  delay(1000);
}

void loop() {
  unsigned long now = millis();

  if (now - lastSensorRead >= SENSOR_INTERVAL) {
    lastSensorRead = now;
    readSensors();
    updateLCD();
  }

  if (Firebase.ready() && now - lastFirebaseSend >= FIREBASE_INTERVAL) {
    lastFirebaseSend = now;
    sendToFirebase();
    readFromFirebase();
  }

  if (Firebase.ready() && now - lastHistorySave >= HISTORY_INTERVAL) {
    lastHistorySave = now;
    saveHistory();
  }

  if (systemOn && !manualOverride) {
    autoControl();
  }
}

void readSensors() {
  float h = dht.readHumidity();
  float t = dht.readTemperature();
  int soilRaw = analogRead(SOIL_PIN);

  if (!isnan(h) && !isnan(t)) {
    humidity    = h;
    temperature = t;
  }

  soilMoisture = map(soilRaw, 4095, 1500, 0, 100);
  soilMoisture = constrain(soilMoisture, 0, 100);

  Serial.printf("Temp: %.1f°C | Hum: %.1f%% | Soil: %.1f%%\n",
                temperature, humidity, soilMoisture);
}

void updateLCD() {
  lcd.setCursor(0, 0);
  lcd.printf("T:%.1fC H:%.1f%%  ", temperature, humidity);
  lcd.setCursor(0, 1);
  lcd.printf("Soil:%.1f%% %s  ", soilMoisture,
             manualOverride ? "MAN" : "AUTO");
}

void sendToFirebase() {
  Firebase.RTDB.setFloat(&fbdo,  "florigen/live/temperature", temperature);
  Firebase.RTDB.setFloat(&fbdo,  "florigen/live/humidity",    humidity);
  Firebase.RTDB.setFloat(&fbdo,  "florigen/live/soilMoisture", soilMoisture);
  Firebase.RTDB.setString(&fbdo, "florigen/live/timestamp",   String(millis()));

  String alert = "OK";
  if (temperature > tempMax)    alert = "HIGH_TEMP";
  else if (temperature < tempMin) alert = "LOW_TEMP";
  else if (humidity < humMin)     alert = "LOW_HUM";
  else if (soilMoisture < soilMin) alert = "DRY_SOIL";

  Firebase.RTDB.setString(&fbdo, "florigen/alerts/current", alert);

  // Actuator states to Firebase
  Firebase.RTDB.setBool(&fbdo, "florigen/actuators/fan",    digitalRead(RELAY_FAN)   == LOW);
  Firebase.RTDB.setBool(&fbdo, "florigen/actuators/pump",   digitalRead(RELAY_PUMP)  == LOW);
  Firebase.RTDB.setBool(&fbdo, "florigen/actuators/drain",  digitalRead(RELAY_DRAIN) == LOW);
  Firebase.RTDB.setBool(&fbdo, "florigen/actuators/light",  digitalRead(RELAY_LIGHT) == LOW);
  Firebase.RTDB.setBool(&fbdo, "florigen/actuators/mister", digitalRead(MOSFET_MIST) == HIGH);
}

void readFromFirebase() {
  if (Firebase.RTDB.getBool(&fbdo, "florigen/actuators/systemOn"))
    systemOn = fbdo.boolData();

  if (Firebase.RTDB.getBool(&fbdo, "florigen/control/manualOverride"))
    manualOverride = fbdo.boolData();

  if (Firebase.RTDB.getString(&fbdo, "florigen/control/activePlant")) {
    activePlant = fbdo.stringData();
    updateThresholds();
  }

  if (manualOverride) {
    if (Firebase.RTDB.getBool(&fbdo, "florigen/actuators/light"))
      setRelay(RELAY_LIGHT, fbdo.boolData());
    if (Firebase.RTDB.getBool(&fbdo, "florigen/actuators/fan"))
      setRelay(RELAY_FAN, fbdo.boolData());
    if (Firebase.RTDB.getBool(&fbdo, "florigen/actuators/pump"))
      setRelay(RELAY_PUMP, fbdo.boolData());
    if (Firebase.RTDB.getBool(&fbdo, "florigen/actuators/drain"))
      setRelay(RELAY_DRAIN, fbdo.boolData());
    if (Firebase.RTDB.getBool(&fbdo, "florigen/actuators/mister"))
      digitalWrite(MOSFET_MIST, fbdo.boolData() ? HIGH : LOW);
  }
}

void saveHistory() {
  String path = "florigen/history/" + String(millis());
  Firebase.RTDB.setFloat(&fbdo, path + "/temp", temperature);
  Firebase.RTDB.setFloat(&fbdo, path + "/hum",  humidity);
  Firebase.RTDB.setFloat(&fbdo, path + "/soil", soilMoisture);
}

void autoControl() {
  setRelay(RELAY_FAN,   temperature > tempMax);
  setRelay(RELAY_PUMP,  soilMoisture < soilMin);
  setRelay(RELAY_DRAIN, soilMoisture > soilMax + 10);
  digitalWrite(MOSFET_MIST, humidity < humMin ? HIGH : LOW);
}

void updateThresholds() {
  if (activePlant == "hibiscus") {
    tempMin = 25; tempMax = 35;
    humMin  = 60; humMax  = 65;
    soilMin = 28; soilMax = 40;
  } else if (activePlant == "sunflower") {
    tempMin = 22; tempMax = 30;
    humMin  = 50; humMax  = 60;
    soilMin = 28; soilMax = 40;
  } else if (activePlant == "taro") {
    tempMin = 24; tempMax = 30;
    humMin  = 60; humMax  = 65;
    soilMin = 80; soilMax = 90;
  }
}

void setRelay(int pin, bool state) {
  digitalWrite(pin, state ? LOW : HIGH);
}
#include <WiFi.h>
#include <HTTPClient.h>

// Pines del LoRa receptor
#define LORA_RX 16  // Conectado al TX del módulo LoRa
#define LORA_TX 17  // Conectado al RX del módulo LoRa

// Datos WiFi
const char* ssid = "TU RED WIFI"         // 🔁 Reemplaza con el nombre de tu red WiFi
const char* password = "TU CONTRASEÑA"; // 🔁 Reemplaza con tu contraseña WiFi

// URL del Apps Script desplegado (web app)
const char* serverName = "TU API KEY";

void setup() {
  Serial.begin(115200);
  Serial2.begin(9600, SERIAL_8N1, LORA_RX, LORA_TX); // LoRa

  // Conexión WiFi
  WiFi.begin(ssid, password);
  Serial.print("Conectando a WiFi");
  while (WiFi.status() != WL_CONNECTED) {
    delay(1000);
    Serial.print(".");
  }
  Serial.println("\nConectado a WiFi");
}

void loop() {
  if (Serial2.available()) {
    String mensaje = Serial2.readStringUntil('\n');
    Serial.println("Temperaturas recibidas: " + mensaje);

    float t1, t2, t3;
    sscanf(mensaje.c_str(), "T1:%f,T2:%f,T3:%f", &t1, &t2, &t3);

    if (WiFi.status() == WL_CONNECTED) {
      HTTPClient http;
      http.begin(serverName);
      http.addHeader("Content-Type", "application/json");

      // Armar JSON con los datos
      String jsonData = "{\"T1\":\"" + String(t1, 2) + "\",\"T2\":\"" + String(t2, 2) + "\",\"T3\":\"" + String(t3, 2) + "\"}";
      int httpResponseCode = http.POST(jsonData);

      Serial.print("HTTP Response: ");
      Serial.println(httpResponseCode);

      http.end();
    } else {
      Serial.println("WiFi no conectado, no se pudo enviar.");
    }
  }
  delay(1000);
}

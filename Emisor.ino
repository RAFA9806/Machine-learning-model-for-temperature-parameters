#include <OneWire.h>
#include <DallasTemperature.h>

// Pines de datos de los sensores DS18B20
#define SENSOR_PIN1 33
#define SENSOR_PIN2 32
#define SENSOR_PIN3 35

// Pines del módulo LoRa (UART)
#define LORA_RX 16  // LoRa TX se conecta aquí
#define LORA_TX 17  // LoRa RX se conecta aquí

// Crear objetos para los sensores
OneWire oneWire1(SENSOR_PIN1);
OneWire oneWire2(SENSOR_PIN2);
OneWire oneWire3(SENSOR_PIN3);

DallasTemperature sensor1(&oneWire1);
DallasTemperature sensor2(&oneWire2);
DallasTemperature sensor3(&oneWire3);

void setup() {
  Serial.begin(115200);  // Monitor serial
  Serial2.begin(9600, SERIAL_8N1, LORA_RX, LORA_TX);  // Comunicación con LoRa

  // Iniciar sensores
  sensor1.begin();
  sensor2.begin();
  sensor3.begin();

  Serial.println("ESP32 emisor listo. Iniciando transmisión LoRa...");
}

void loop() {
  // Pedir temperaturas
  sensor1.requestTemperatures();
  sensor2.requestTemperatures();
  sensor3.requestTemperatures();

  // Leer temperaturas
  float t1 = sensor1.getTempCByIndex(0);
  float t2 = sensor2.getTempCByIndex(0);
  float t3 = sensor3.getTempCByIndex(0);

  // Armar mensaje
  String mensaje = "T1:" + String(t1, 2) + ",T2:" + String(t2, 2) + ",T3:" + String(t3, 2);

  // Mostrar por monitor serial
  Serial.println("Enviando: " + mensaje);

  // Enviar por LoRa
  Serial2.println(mensaje);

  delay(5000);  // Esperar 5 segundos antes de enviar nuevamente
}

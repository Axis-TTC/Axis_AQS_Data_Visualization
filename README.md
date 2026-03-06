# Axis D6310 Air Quality M.I.N.G Stack

Docker Compose **M.I.N.G** stack (MQTT, InfluxDB, Node-RED, Grafana) for **AXIS D6310** air quality sensor.  
Ingest MQTT data, visualize in Grafana. Perfect for smart buildings/IoT.

---

## What This Stack Does


AXIS D6310 (Sensor) -> MQTT (Transmits) -> Node-RED (Transforms) -> InfluxDB (Stores) -> Grafana (Dashboard)


### Components Explained

| Component | Role | Why It Matters |
|-----------|------|----------------|
| **AXIS D6310** | Air quality sensor (temp, humidity, VOC, CO2, PM, AQI) | Publishes real-time environmental data via MQTT |
| **MQTT Broker (Mosquitto)** | Message bus | Lightweight pub/sub for sensor data and alerts |
| **Node-RED** | Data pipeline | Subscribes to MQTT, transforms JSON, writes to InfluxDB |
| **InfluxDB** | Time-series database | Stores all measurements with timestamps for querying |
| **Grafana** | Visualization & alerting | Builds dashboards, monitors thresholds, sends MQTT alerts |

---

## Features
- Simple Docker Compose
- Node-RED MQTT flows (Axis → Influx)
- Grafana dashboard setup guide

## Prerequisites
- Docker 
- AXIS D6310 sensor(s)
- Git for windows

### Deploy the Stack

***Windows***
1. Install [Docker](https://docs.docker.com/desktop/setup/install/windows-install/) and [Git](https://git-scm.com/install/windows) **(For the TTC workshop they are already installed on the workstation)**
2. Clone the repo ```git clone https://github.com/Axis-TTC/Axis_AQS_Data_Visualization```
3. ```cd Axis_AQS_Data_Visualization```
4. ```docker-compose -f docker-compose.ming.yml up -d```
   
***Linux***
1. Install [Docker](https://docs.docker.com/engine/install/)
2. ```sudo apt install docker-compose```
3. ```mkdir -p axis-aqs && cd axis-aqs```
4. ```nano docker-compose.yml```
5. Paste content of [docker-compose.ming.yml](https://github.com/Axis-TTC/Axis_AQS_Data_Visualization/blob/main/docker-compose.ming.yml)
6. Save and exit (control + x)
7. ```sudo docker-compose up -d```

### Access Services

| Service | URL | Credentials |
|---------|-----|-------------|
| **Grafana** | http://localhost:3000 | admin / password123 |
| **Node-RED** | http://localhost:1880 | (none) |
| **InfluxDB** | http://localhost:8086 | admin / password123 |
| **MQTT Broker** | tcp://localhost:1883 | (none) |

---

## Configuration

### 1. Configure AXIS D6310 Sensor

**What happens:** Sensor publishes air quality data to MQTT every second.

**(For the TTC workshop the D6310 is already configured, skip to the Node-RED Flow)**
1. Update Firmware to latest
2. Configure MQTT (http://camera-ip/environmental-sensor/index.html#/system/mqtt/publication)
   - Host: you computers IP
   - **Save** → **Connect**
5. **+ Add Condition**
   - Condition: Air quality monitoring active (this starts publishing air quality data every second)
   - **Add**
8. Take note of device serial for next step

### TTC Sensors (already publishing to mqtt.ttc.local)
D6310 Play Space: E827251A7B8B  
D6310 Learn Space: E827251A7B09  
D6310 Server Rack: E827251AA4C6  
D6310 Entrance: E827251A8AF7  

---

### 2. Configure Node-RED Flow

**What happens:** Node-RED subscribes to sensor MQTT topics, parses messages, writes structured data to InfluxDB.

1. Open Node-RED: (http://localhost:1880)
2. Import flow from [aqs_to_influx.json](https://github.com/Axis-TTC/Axis_AQS_Data_Visualization/blob/main/aqs_to_influx.json)
3. Double click **Axis D6310 MQTT node**
   - Change serial number in Topic to your device serial
   - **For the TTC workshop** click the pencil and change the broker URL to `mqtt.ttc.local`
4. In a new tab Open InfluxDB: `http://localhost:8086` (admin/password123)
   - Click **Load Data** → **API Tokens** → **Generate API Token** → **All Access API Token**
   - Name it `nodered`
   - Manauly copy the token (**DO NOT CLICK** "copy to clipboard" it doesnt always work)
10. Back in Node Red double click **InfluxDB Axis AQ** node
    - Click pencil next to "Server"
    - Paste Token in **Token** field
    - Click **Update** → **Done** → **Deploy**

---

### 3. Verify Data in InfluxDB

**What happens:** Check that sensor data is being written to the time-series database.

1. Open InfluxDB: (http://localhost:8086) (admin/password123)
2. On the left side click **Data Explorer**
   - Select **airquality**
   - Tick **air_quality**
   - Tick one of the data types eg. AQI or CO2
   - Select **Past 1h** from the drop down
7. You should see data plotted

**No data?** Check Node-RED debug panel and MQTT configuration.

---

## Build Grafana Dashboard

### Add InfluxDB Data Source

**What happens:** Connect Grafana to InfluxDB so it can query and visualize data.

1. Open InfluxDB: `http://localhost:8086` (admin/password123)
2. Click **Load Data** → **API Tokens** → **Generate API Token** → **All Access API Token**
    - Name it `grafana`
    - Manauly copy the token (**DO NOT CLICK** "copy to clipboard" it doesnt always work)
3. Open Grafana: (http://localhost:3000) (admin/password123)
4. **Connections** → **Data Sources** → **Add data source** → **InfluxDB**
   - Query language= Flux
   - URL: http://influxdb:8086
   - User: admin
   - Password: password123
   - Organization: iot
   - Paste the InfluxDB Token in **Token** field
13. **Save & Test**

---

### Create Dashboard Panels

**What happens:** Build visual panels that query InfluxDB and plot metrics over time.

1. In Grafana click **Dashboards** → **Create dashboard** → **Add visualization**
3. Select **InfluxDB**

### Temperature

1. Click **Back** near the top right corner
- Title: Temperature
- Unit: Temperature → Celsius (°C)
- Paste below into query field

```
from(bucket: "airquality")
  |> range(start: v.timeRangeStart, stop: v.timeRangeStop)
  |> filter(fn: (r) => r._measurement == "air_quality")
  |> filter(fn: (r) => r.sensor_name == "D6310")
  |> filter(fn: (r) => r._field == "Temperature")
  |> aggregateWindow(every: 1m, fn: mean, createEmpty: false)
```

**Understanding the Query:**
- `from(bucket: "airquality")` → Select the database
- `range()` → Time window from Grafana picker
- `filter(_measurement)` → Which table (air_quality)
- `filter(sensor_name)` → Which device
- `filter(_field)` → Which metric (Temperature, CO2, etc.)
- `aggregateWindow()` → Average values per minute (reduces noise)

### Increase Query Data Points (this allows displaying more than one day of data).
- Click **Query options** and change **Max data points** to `5000` 
  
### To rename the sensors
1. On the right hand side scroll all tha way to the bottom.
2. Click **+ Add field override**
3. Select **Fields with name matching regex** and use the regex ```.*camera_id="E827251A7B09".*``` to match only to the serial of the device.
4. Click **+ Add override property**
5. Select **Standard options > Display name**
6. Type the new name for the sensor
7. Repeat for other sensors

Play Space: E827251A7B8B  
Learn Space: E827251A7B09  
Server Rack: E827251AA4C6  
Entrance: E827251A8AF7  

- Click **Save Dashboard**
- Change the Dashboard **Title** to `AQS`
- Click **Save**
- Click **Back to dashboard**

---
  
### Humidity

1. Click the three dots in the top right of the **Tempreture** panel you just created
2. Select **More* then **Duplicate**
3. Click the three dots at the top right of the new panel that appears then select **Edit**

- Title: Humidity
- Unit: Misc → Percent (0-100)
- Paste below into query field

```
from(bucket: "airquality")
  |> range(start: v.timeRangeStart, stop: v.timeRangeStop)
  |> filter(fn: (r) => r._measurement == "air_quality")
  |> filter(fn: (r) => r.sensor_name == "D6310")
  |> filter(fn: (r) => r._field == "Humidity")
  |> aggregateWindow(every: 1m, fn: mean, createEmpty: false)
```

- Click **Save Dashboard**
- **Back to dashboard**

---

### VOC

1. Click the three dots in the top right of the panel you just created
2. Select **More* then **Duplicate**
3. Click the three dots at the top right of the new panel that appears then select **Edit**

- Title: VOC
- Unit: Concentraion → parts-per-million (ppm)
- Paste below into query field

```
from(bucket: "airquality")
  |> range(start: v.timeRangeStart, stop: v.timeRangeStop)
  |> filter(fn: (r) => r._measurement == "air_quality")
  |> filter(fn: (r) => r.sensor_name == "D6310")
  |> filter(fn: (r) => r._field == "VOC")
  |> aggregateWindow(every: 1m, fn: mean, createEmpty: false)
```

- Click **Save Dashboard**
- **Back to dashboard**

---

### CO2

1. Click the three dots in the top right of the panel you just created
2. Select **More* then **Duplicate**
3. Click the three dots at the top right of the new panel that appears then select **Edit**

- Title: CO2
- Units: Concentraion → parts-per-million (ppm)
- Paste below into query field

```
from(bucket: "airquality")
  |> range(start: v.timeRangeStart, stop: v.timeRangeStop)
  |> filter(fn: (r) => r._measurement == "air_quality")
  |> filter(fn: (r) => r.sensor_name == "D6310")
  |> filter(fn: (r) => r._field == "CO2")
  |> aggregateWindow(every: 1m, fn: mean, createEmpty: false)
```

- Click **Save Dashboard**
- **Back to dashboard**

---

### PM1, PM2.5, PM4, PM10

1. Click the three dots in the top right of the panel you just created
2. Select **More* then **Duplicate**
3. Click the three dots at the top right of the new panel that appears then select **Edit**

- Title: PM1, PM2.5, PM4, PM10
- Units: Concentraion → micrograms per cubic meter (µg/m³)
- Paste below into query field

```
from(bucket: "airquality")
  |> range(start: v.timeRangeStart, stop: v.timeRangeStop)
  |> filter(fn: (r) => r._measurement == "air_quality")
  |> filter(fn: (r) => r.sensor_name == "D6310")
  |> filter(fn: (r) => r._field == "PM1" or r._field == "PM25" or r._field == "PM4" or r._field == "PM10")
  |> aggregateWindow(every: 1m, fn: mean, createEmpty: false)
```

- Click **Save Dashboard**
- **Back to dashboard**

---

### AQI

1. Click the three dots in the top right of the panel you just created
2. Select **More* then **Duplicate**
3. Click the three dots at the top right of the new panel that appears then select **Edit**

- Title: AQI
- Paste below into query field

```
from(bucket: "airquality")
  |> range(start: v.timeRangeStart, stop: v.timeRangeStop)
  |> filter(fn: (r) => r._measurement == "air_quality")
  |> filter(fn: (r) => r.sensor_name == "D6310")
  |> filter(fn: (r) => r._field == "AQI")
  |> aggregateWindow(every: 1m, fn: mean, createEmpty: false)
```

- Click **Save Dashboard**
- **Back to dashboard**

---

## Connect to Historical Data (Task 2)

**What happens:** Query a separate InfluxDB that has been collecting data for days/weeks to analyze trends and anomalies.

1. In Grafana: **Connections** → **Data Sources** → Edit existing or add new InfluxDB
2. Configure historical database:
   - URL: `http://192.168.5.174:8086`
   - Token: `8x91i7sURTyiLT-Sv9kK8xyoTL7GOhRjxUZRgVeaXdVh-d7GoBOcmpUZWsvd2ZQ83VzZJDkZ-jjuUVI_uigDwQ==`
   - User: `admin` / Password: `password123`
3. **Save & Test**
4. In dashboards, change time range to **Last 7 days**
5. Look for anomalies:
   - **CO2 spikes** → High occupancy events
   - **VOC increases** → Cleaning, new materials
   - **PM spikes** → Construction, outdoor pollution events
6. **(Optional)** Review Axis camera SD card footage to correlate events with air quality changes

---

## (Bonus) Create Alerts & Axis Device Integration (Task 3) 

**What happens:** Grafana monitors thresholds and publishes MQTT alert messages that Axis devices subscribe to, triggering actions (recordings, outputs, notifications).

```
Grafana detects: VOC > 100
      ↓
Sends MQTT message to: grafana/group1/alerts
      ↓
Axis device subscribed to topic
      ↓
Triggers: Recording + Notification
```

### Step 1: Add MQTT Contact Point in Grafana

1. **Alerting** → **Contact points** → **+ Add contact point**
2. Configure:
   - Name: `MQTT Alerts`
   - Integration: **MQTT**
   - Broker URL: `tcp://mqtt.ttc.local:1883`
   - Topic: `grafana/groupX/alerts` (replace `X` with your group number)
3. **Save contact point**

### Step 2: Create Alert Rule

1. **Alerting** → **Alert rules** → **+ New alert rule**
2. Name: e.g., "High VOC Alert"
3. Add query (example for VOC):
```flux
from(bucket: "airquality")
  |> range(start: v.timeRangeStart, stop: v.timeRangeStop)
  |> filter(fn: (r) => r._measurement == "air_quality")
  |> filter(fn: (r) => r.sensor_name == "D6310")
  |> filter(fn: (r) => r._field == "VOC")
  |> aggregateWindow(every: 1m, fn: mean, createEmpty: false)
```
4. **Alert condition:**
   - Reducer: **last** (use most recent value)
   - Threshold: **is above**
   - Value: `100` (ppb for VOC)
5. **Folder:** Create "Air Quality Alerts"
6. **Evaluation behavior:**
   - New evaluation group: "Environmental Monitoring"
   - Evaluation interval: `10s` (how often to check)
   - Pending period: `10s` (must be true for 10s before firing)
7. **Notifications:** Select your MQTT contact point
8. **Save rule and exit**

### Step 3: Test with MQTT Explorer

1. Open **MQTT Explorer** → Connect to `mqtt.ttc.local:1883`
2. Subscribe to `grafana/groupX/alerts`
3. Trigger alert (exceed threshold or temporarily lower it)
4. Wait 1-2 minutes → Alert messages appear in MQTT Explorer

### Step 4: Configure Axis Device Event

1. Access Axis device web interface
2. **System** → **MQTT** → Connect to `mqtt.ttc.local:1883`
3. Add MQTT subscription: `grafana/groupX/alerts`
4. **System** → **Events** → **Device events** → **Add rule**
5. Configure:
   - Trigger: **MQTT message received**
   - Topic: `grafana/groupX/alerts`
   - Action: Activate output / Record / Send notification
6. **Save** and test by triggering alert

---

## Reference

### Recommended Alert Thresholds

| Metric | Threshold | Meaning |
|--------|-----------|---------|
| **VOC** | > 500 | Poor air quality |
| **CO2** | > 1000 ppm | Poor ventilation / high occupancy |
| **PM2.5** | > 35 µg/m³ | Unhealthy for sensitive groups |
| **Temperature** | > 26°C or < 18°C | Outside comfort zone |
| **Humidity** | > 60% or < 30% | Uncomfortable / health risk |
| **AQI** | > 100 | Unhealthy air quality |

### Troubleshooting

| Issue | Solution |
|-------|----------|
| **No MQTT data in Node-RED** | Check D6310 MQTT config, broker address, device serial in topic |
| **InfluxDB empty** | Verify bucket name `airquality`, check Node-RED InfluxDB node token |
| **Grafana shows "No data"** | Verify data source connection, check Flux query syntax |
| **Too many data points** | Increase **Max data points** to 5000-50000 in Query options |
| **Alerts don't fire** | Check threshold value, preview alert condition, ensure data is flowing |
| **Axis event doesn't trigger** | Verify MQTT subscription topic matches exactly, check event rule |
| **Historical DB unreachable** | Confirm `192.168.5.174` is accessible, verify credentials |

---

## What You've Built

**Real-time data pipeline:** Sensor → MQTT → Node-RED → InfluxDB → Grafana  
**Historical analysis:** Multi-day trends and anomaly detection  
**Automated alerting:** Threshold monitoring with MQTT notifications  
**Device integration:** Grafana alerts trigger Axis camera events  

**Next Steps:**
- Add multiple sensors and group by location
- Create custom dashboard layouts (rows, variables, templating)
- Explore Grafana's transformation functions
- Set up different alert severities (warning/critical)
- Integrate with other systems via MQTT

---

## Developed for the Axis TTC Workshop

**⭐ Star this repo if it helped you!**

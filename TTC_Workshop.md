# Axis D6310 Air Quality M.I.N.G Stack

Complete workshop guide for deploying a Docker-based **M.I.N.G** stack (MQTT, InfluxDB, Node-RED, Grafana) to monitor AXIS D6310 air quality sensors, visualize data, and trigger alerts.

---

## 📋 What This Stack Does

```
┌─────────────┐     MQTT      ┌──────────┐     Transforms    ┌──────────┐
│ AXIS D6310  │ ────────────> │ Node-RED │ ───────────────> │ InfluxDB │
│  (Sensor)   │   Messages    │  (Flow)  │    & Stores      │  (TSDB)  │
└─────────────┘               └──────────┘                   └──────────┘
                                                                    │
                                                                    │ Queries
                                                                    ▼
                              ┌──────────┐                   ┌──────────┐
                              │  Grafana │ <──────────────── │ InfluxDB │
                              │(Dashboards                    └──────────┘
                              │ & Alerts)│
                              └──────────┘
                                    │
                                    │ MQTT Alerts
                                    ▼
                              ┌──────────┐
                              │   Axis   │
                              │  Device  │
                              │ (Events) │
                              └──────────┘
```

### Components Explained

| Component | Role | Why It Matters |
|-----------|------|----------------|
| **AXIS D6310** | Air quality sensor (temp, humidity, VOC, CO2, PM, AQI) | Publishes real-time environmental data via MQTT |
| **MQTT Broker (Mosquitto)** | Message bus | Lightweight pub/sub for sensor data and alerts |
| **Node-RED** | Data pipeline | Subscribes to MQTT, transforms JSON, writes to InfluxDB |
| **InfluxDB** | Time-series database | Stores all measurements with timestamps for querying |
| **Grafana** | Visualization & alerting | Builds dashboards, monitors thresholds, sends MQTT alerts |

---

## 🚀 Quick Start

### Prerequisites
- Docker Desktop (Windows) or Docker Engine (Linux)
- AXIS D6310 sensor(s)
- Git (Windows only)

### Deploy the Stack

**Windows:**
```bash
git clone https://github.com/Axis-TTC/Axis_AQS_Data_Visualization
cd Axis_AQS_Data_Visualization
docker-compose -f docker-compose.ming.yml up -d
```

**Linux:**
```bash
sudo apt install docker-compose
mkdir -p axis-aqs && cd axis-aqs
nano docker-compose.yml
# Paste content from docker-compose.ming.yml
sudo docker-compose up -d
```

### Access Services

| Service | URL | Credentials |
|---------|-----|-------------|
| **Grafana** | http://localhost:3000 | admin / password123 |
| **Node-RED** | http://localhost:1880 | (none) |
| **InfluxDB** | http://localhost:8086 | admin / password123 |
| **MQTT Broker** | tcp://localhost:1883 | (none) |

---

## ⚙️ Configuration

### 1. Configure AXIS D6310 Sensor

**What happens:** Sensor publishes air quality data to MQTT every second.

1. Update firmware to latest version
2. Navigate to: `http://<camera-ip>/environmental-sensor/index.html#/system/mqtt/publication`
3. Set **Host** to your PC's IP (or `mqtt.ttc.local` for TTC workshop)
4. Click **Save** → **Connect**
5. Click **+ Add Condition** → Select **Air quality monitoring active** → **Add**
6. **Note the device serial** (needed for Node-RED)

---

### 2. Configure Node-RED Flow

**What happens:** Node-RED subscribes to sensor MQTT topics, parses messages, writes structured data to InfluxDB.

1. Open http://localhost:1880
2. Import flow from [aqs_to_influx.json](https://github.com/Axis-TTC/Axis_AQS_Data_Visualization/blob/main/aqs_to_influx.json)
3. Double-click **Axis D6310 MQTT** node:
   - Update **Topic** with your device serial
   - For TTC workshop: Change broker to `mqtt.ttc.local`
4. Generate InfluxDB token:
   - Open http://localhost:8086 (admin/password123)
   - **Load Data** → **API Tokens** → **Generate API Token** → **All Access API Token**
   - **Manually copy** the token (don't use clipboard button)
5. Back in Node-RED, double-click **InfluxDB Axis AQ** node:
   - Click pencil → Paste token in **Token** field
   - **Update** → **Done** → **Deploy**

---

### 3. Verify Data in InfluxDB

**What happens:** Check that sensor data is being written to the time-series database.

1. Open http://localhost:8086
2. **Data Explorer** → Select **airquality** bucket
3. Tick **air_quality** measurement and a field (e.g., CO2)
4. Set range to **Past 1h**
5. ✅ You should see data plotted

**No data?** Check Node-RED debug panel and MQTT configuration.

---

## 📊 Build Grafana Dashboards

### Add InfluxDB Data Source

**What happens:** Connect Grafana to InfluxDB so it can query and visualize data.

1. Open http://localhost:3000 (admin/password123)
2. **Connections** → **Data Sources** → **Add data source** → **InfluxDB**
3. Configure:
   - Query language: **Flux**
   - URL: `http://influxdb:8086`
   - User: `admin` / Password: `password123`
   - Organization: `iot`
4. Generate and paste InfluxDB API token (same process as step 2.4)
5. **Save & Test** (should show green ✓)

---

### Create Dashboard Panels

**What happens:** Build visual panels that query InfluxDB and plot metrics over time.

1. **Dashboards** → **Create dashboard** → **Add visualization** → Select **InfluxDB**

#### Example: Temperature Panel

**Purpose:** Monitor temperature trends and HVAC performance.

- **Title:** Temperature
- **Unit:** Temperature → Celsius (°C)
- **Query:**
```flux
from(bucket: "airquality")
  |> range(start: v.timeRangeStart, stop: v.timeRangeStop)
  |> filter(fn: (r) => r._measurement == "air_quality")
  |> filter(fn: (r) => r.sensor_name == "D6310")
  |> filter(fn: (r) => r._field == "Temperature")
  |> aggregateWindow(every: 1m, fn: mean, createEmpty: false)
```
- **Query options:** Max data points = `5000` (enables multi-day views)

#### Other Panels

Use the same pattern, changing `_field` and units:

| Panel | Field | Unit | Purpose |
|-------|-------|------|---------|
| **Humidity** | `Humidity` | Percent (0-100) | Comfort & mold risk |
| **VOC** | `VOC` | ppm | Volatile organic compounds (air quality) |
| **CO2** | `CO2` | ppm | Ventilation & occupancy |
| **PM** | `PM1`, `PM25`, `PM4`, `PM10` | µg/m³ | Particulate matter (health impact) |
| **AQI** | `AQI` | (none) | Overall air quality index |

**Understanding the Query:**
- `from(bucket: "airquality")` → Select the database
- `range()` → Time window from Grafana picker
- `filter(_measurement)` → Which table (air_quality)
- `filter(sensor_name)` → Which device
- `filter(_field)` → Which metric (Temperature, CO2, etc.)
- `aggregateWindow()` → Average values per minute (reduces noise)

---

## 📈 Connect to Historical Data (Task 2)

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

## 🚨 Create Alerts & Axis Device Integration (Task 3)

**What happens:** Grafana monitors thresholds and publishes MQTT alert messages that Axis devices subscribe to, triggering actions (recordings, outputs, notifications).

```
Grafana detects: VOC > 1000 ppb
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
   - Value: `1000` (ppb for VOC)
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

## 📚 Reference

### Recommended Alert Thresholds

| Metric | Threshold | Meaning |
|--------|-----------|---------|
| **VOC** | > 1000 ppb | Poor air quality |
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

## 🎓 What You've Built

✅ **Real-time data pipeline:** Sensor → MQTT → Node-RED → InfluxDB → Grafana  
✅ **Historical analysis:** Multi-day trends and anomaly detection  
✅ **Automated alerting:** Threshold monitoring with MQTT notifications  
✅ **Device integration:** Grafana alerts trigger Axis camera events  

**Next Steps:**
- Add multiple sensors and group by location
- Create custom dashboard layouts (rows, variables, templating)
- Explore Grafana's transformation functions
- Set up different alert severities (warning/critical)
- Integrate with other systems via MQTT

---

## 📄 License

[Add your license]

## 🙏 Acknowledgments

Developed for the Axis TTC Workshop

**⭐ Star this repo if it helped you!**

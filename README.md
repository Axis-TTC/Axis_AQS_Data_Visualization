# Axis D6310 Air Quality MING Stack 🚀

Docker Compose **MING stack** (Mosquitto MQTT, InfluxDB, Node-RED, Grafana) for **AXIS D6310** air quality sensor. Deploy via **Portainer**, ingest MQTT data, visualize at **1m resolution** in Grafana, detect **occupancy** (CO2>800ppm) & **cleaning** (PM spikes). Perfect for smart buildings/IoT.

## 📦 Features
- ✅ One-click Portainer stack deploy
- ✅ Node-RED MQTT flows (Axis → Influx)
- ✅ Grafana dashboards + Flux queries (no truncation)
- ✅ Pattern detection (occupancy/cleaning)
- ✅ Provisioning & env secrets

## 🛠️ Prerequisites
- Install and setup up [Docker](https://docs.docker.com/engine/install/) + [Portainer](https://docs.portainer.io/start/install-ce)
- AXIS D6310 or two

**MING stack Portainer Deploy**:
Portainer: https://your-host:9443/
1. Stacks → **+ Add stack**
2. Name: `axis-airquality`
3. **Web editor** → Paste contents of [docker-compose.ming.yml](https://github.com/Axis-TTC/Axis_AQS_Data_Visualization/blob/main/docker-compose.ming.yml)
4. **Deploy stack**

**Access**:
- Portainer: `http://your-host:9443` (admin/?)
- Grafana: `http://your-host:3000` (admin/password123)
- Node-RED: `http://your-host:1880`
- InfluxDB: `http://your-host:8086` (admin/password123)

## 🔧 Configuration

### D6310
- Update Firmware to latest
- http://camera-ip/environmental-sensor/index.html#/system/mqtt/publication
- Host= you computers IP
- Save => Connect
- "+ Add Condition"
- Condition = Air quality monitoring active
- Add
- Take note of device serial for next step

### Node-RED Flow
Node-RED: `http://your-host:1880`
- Import flow from [aqs_to_influx.json](https://github.com/Axis-TTC/Axis_AQS_Data_Visualization/blob/main/aqs_to_influx.json)
- Double click Axis D6310 MQTT node
- Change serial number in Topic to your device serial
- Open InfluxDB: `http://your-host:8086` (admin/password123)
- Click Load Data => API Tokens => Generate API Token => All Access API Token
- Name it anything
- Manaul copy the token (copy to clipboard doesnt always work)
- Back in Node Red double click "InfluxDB Axis AQ" node
- Click pencil next to "Server"
- Paste Token in Token field
- Click Update => Done => Deploy


## 📊 Grafana Queries (1m Resolution)

Grafana: `http://your-host:3000` (admin/password123)

### Add Data source
- Connections => Data Sources => Add data source => InfluxDB
- Query language= Flux
- URL= http://influxdb:8086
- User: admin
- Password: password123
- Organization: iot
- Open InfluxDB: `http://your-host:8086` (admin/password123)
- Click Load Data => API Tokens => Generate API Token => All Access API Token
- Name it anything
- Manaul copy the token (copy to clipboard doesnt always work)
- Paste Token in Token field
- Save & Test

## Add Dashboard
- Dashboards => Create dashboard
- Add visualization
- Click InfluxDB
- 
### Temperature
- Title: Temperature
- Paste below into query field

```
from(bucket: "airquality")
  |> range(start: v.timeRangeStart, stop: v.timeRangeStop)
  |> filter(fn: (r) => r._measurement == "air_quality")
  |> filter(fn: (r) => r.sensor_name == "D6310")
  |> filter(fn: (r) => r._field == "Temperature")
  |> aggregateWindow(every: 1m, fn: mean, createEmpty: false)
```
- Back to dashboard
- Add => Visualization
- 
### Humidity
- Title: Humidity
- Paste below into query field

```
from(bucket: "airquality")
  |> range(start: v.timeRangeStart, stop: v.timeRangeStop)
  |> filter(fn: (r) => r._measurement == "air_quality")
  |> filter(fn: (r) => r.sensor_name == "D6310")
  |> filter(fn: (r) => r._field == "Humidity")
  |> aggregateWindow(every: 1m, fn: mean, createEmpty: false)
```

- Back to dashboard
- Add => Visualization

### VOC
- Title: VOC
- Paste below into query field

```
from(bucket: "airquality")
  |> range(start: v.timeRangeStart, stop: v.timeRangeStop)
  |> filter(fn: (r) => r._measurement == "air_quality")
  |> filter(fn: (r) => r.sensor_name == "D6310")
  |> filter(fn: (r) => r._field == "VOC")
  |> aggregateWindow(every: 5m, fn: mean, createEmpty: false)
```

- Back to dashboard
- Add => Visualization

### CO2
- Title: CO2
- Paste below into query field

```
from(bucket: "airquality")
  |> range(start: v.timeRangeStart, stop: v.timeRangeStop)
  |> filter(fn: (r) => r._measurement == "air_quality")
  |> filter(fn: (r) => r.sensor_name == "D6310")
  |> filter(fn: (r) => r._field == "CO2")
  |> aggregateWindow(every: 1m, fn: mean, createEmpty: false)
```

- Back to dashboard
- Add => Visualization

### PM1, PM2.5, PM4, PM10
- Title: PM1, PM2.5, PM4, PM10
- Paste below into query field

```
from(bucket: "airquality")
  |> range(start: v.timeRangeStart, stop: v.timeRangeStop)
  |> filter(fn: (r) => r._measurement == "air_quality")
  |> filter(fn: (r) => r.sensor_name == "D6310")
  |> filter(fn: (r) => r._field == "PM1" or r._field == "PM25" or r._field == "PM4" or r._field == "PM10")
  |> aggregateWindow(every: 1m, fn: mean, createEmpty: false)
```

- Back to dashboard
- Add => Visualization

### AQI
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

- Back to dashboard
- Save Dashboard
- 
## 🎯 Pattern Detection

**Occupancy (CO2 Alert)**:
```flux
from(bucket: "airquality")
|> range(-2h)
|> filter(fn:(r)=>r._field=="CO2" and r.sensor_name=="D6310")
|> aggregateWindow(every:1m,fn:mean)
|> map(fn:(r)=>({r... occupied: r._value > 800}))
```

**Cleaning (PM Spike)**:
```flux
from(bucket: "airquality")
|> range(-1h)
|> filter(fn:(r)=>r._field=="PM2.5")
|> derivative()
|> map(fn:(r)=>({r... cleaning: math.abs(r._value) > 10}))
```

## 🐛 Troubleshooting

| Issue | Solution |
|-------|----------|
| **Too many datapoints** | Panel → Query → Max data points: `50000` |
| **No MQTT data** | Check AXIS MQTT config, Node-RED logs |
| **Influx empty** | Verify bucket `airquality`, Node-RED Influx node |
| **Grafana no data** | Check provisioning, API token |

**Logs**: `docker logs axis-airquality_[service]`

## 🏗️ Stack Components
```
AXIS D6310 ─MQTT→ Mosquitto → Node-RED → InfluxDB → Grafana
                         ↓
                   Pattern Detection
```

## 📁 Repository Structure
```
├── docker-compose.ming.yml     # Main stack
├── .env.example               # Secrets
├── mosquitto.conf             # MQTT config
├── node-red/flows.json        # Your flow
├── grafana/
│   ├── provisioning/
│   └── dashboards/
└── patterns/                  # Flux anomaly queries
```

## 🤝 Contributing
1. Fork & PR
2. Add your dashboard JSONs
3. New patterns welcome!

## 📄 License
MIT - See LICENSE

**⭐ Star if useful!** Questions? Open an issue.

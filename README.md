# Axis D6310 Air Quality MING Stack ðŸš€

[![Portainer Deploy](https://img.shields.io/badge/Deploy-Portainer-blue?logo=docker)](https://docs.portainer.io/)

Docker Compose **MING stack** (Mosquitto MQTT, InfluxDB, Node-RED, Grafana) for **AXIS D6310** air quality sensor. Deploy via **Portainer**, ingest MQTT data, visualize at **1m resolution** in Grafana, detect **occupancy** (CO2>800ppm) & **cleaning** (PM spikes). Perfect for smart buildings/IoT.

## ðŸ“¦ Features
- âœ… One-click Portainer stack deploy
- âœ… Node-RED MQTT flows (Axis â†’ Influx)
- âœ… Grafana dashboards + Flux queries (no truncation)
- âœ… Pattern detection (occupancy/cleaning)
- âœ… Provisioning & env secrets

## ðŸ› ï¸ Prerequisites
- [Docker](https://docker.com) + [Portainer](https://portainer.io)
- AXIS D6310 MQTT enabled: `http://[camera-ip]/axis-cgi/mqtt.cgi`

## ðŸš€ Quick Start
```bash
git clone https://github.com/Axis-TTC/Axis_AQS_Data_Visualization
cd Axis_AQS_Data_Visualization
cp .env.example .env  # Edit creds
# Add mosquitto.conf (see below)
```

**Portainer Deploy**:
1. Stacks â†’ **+ Add stack**
2. Name: `axis-airquality`
3. **Web editor** â†’ Paste `docker-compose.ming.yml`
4. **Deploy stack**

**Access**:
- Grafana: `http://your-host:3000` (admin/pass from .env)
- Node-RED: `http://your-host:1880`
- InfluxDB: `http://your-host:8086`

## ðŸ”§ Configuration

### .env
```bash
INFLUXDB_ADMIN_USER=admin
INFLUXDB_ADMIN_PASSWORD=SecurePass123!
GRAFANA_ADMIN_USER=admin
GRAFANA_ADMIN_PASSWORD=SecurePass123!
```

### mosquitto.conf
```
persistence true
persistence_location /mosquitto/data/
listener 1883
allow_anonymous true
```

### Node-RED Flow
- Auto-imports from `node-red/flows.json`
- MQTT topic: `axis/[serial]/event/tns:axis/AirQualityMonitor/Metadata/#`
- Output: InfluxDB `airquality` bucket (`sensor_name="D6310"`)

## ðŸ“Š Grafana Queries (1m Resolution)

**Temperature**:
```flux
from(bucket: "airquality")
  |> range(start: v.timeRangeStart, stop: v.timeRangeStop)
  |> filter(fn: (r) => r._measurement == "air_quality")
  |> filter(fn: (r) => r.sensor_name == "D6310")
  |> filter(fn: (r) => r._field == "Temperature")
  |> aggregateWindow(every: 1m, fn: mean, createEmpty: false)
```
**Panel Settings**: Max data points=50000, Min interval=1m

## ðŸŽ¯ Pattern Detection

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

## ðŸ› Troubleshooting

| Issue | Solution |
|-------|----------|
| **Too many datapoints** | Panel â†’ Query â†’ Max data points: `50000` |
| **No MQTT data** | Check AXIS MQTT config, Node-RED logs |
| **Influx empty** | Verify bucket `airquality`, Node-RED Influx node |
| **Grafana no data** | Check provisioning, API token |

**Logs**: `docker logs axis-airquality_[service]`

## ðŸ—ï¸ Stack Components
```
AXIS D6310 â”€MQTTâ†’ Mosquitto â†’ Node-RED â†’ InfluxDB â†’ Grafana
                         â†“
                   Pattern Detection
```

## ðŸ“ Repository Structure
```
â”œâ”€â”€ docker-compose.ming.yml     # Main stack
â”œâ”€â”€ .env.example               # Secrets
â”œâ”€â”€ mosquitto.conf             # MQTT config
â”œâ”€â”€ node-red/flows.json        # Your flow
â”œâ”€â”€ grafana/
â”‚   â”œâ”€â”€ provisioning/
â”‚   â””â”€â”€ dashboards/
â””â”€â”€ patterns/                  # Flux anomaly queries
```

## ðŸ¤ Contributing
1. Fork & PR
2. Add your dashboard JSONs
3. New patterns welcome!

## ðŸ“„ License
MIT - See LICENSE

**â­ Star if useful!** Questions? Open an issue.

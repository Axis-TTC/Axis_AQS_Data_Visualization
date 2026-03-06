# Axis D6310 Air Quality M.I.N.G Stack

Docker Compose **M.I.N.G** stack (MQTT (Mosquitto), InfluxDB, Node-RED, Grafana) for **AXIS D6310** air quality sensor. Ingest MQTT data, visualize in Grafana. Perfect for smart buildings/IoT.

## Features
- Simple Docker Compose
- Node-RED MQTT flows (Axis → Influx)
- Grafana dashboard setup guide

## Prerequisites
- Docker 
- AXIS D6310 or two
- Git for windows

**M.I.N.G stack Docker Compose Deploy**:

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

**Access**:
- Grafana: `http://localhost:3000` (admin/password123)
- Node-RED: `http://localhost:1880`
- InfluxDB: `http://localhost:8086` (admin/password123)
- Mosquitto: `http://localhost:1883`
  
## Configuration

### D6310 
**(For the TTC workshop the D6310 is already configured, skip to the Node-RED Flow)**
1. Update Firmware to latest
2. Configure MQTT (http://camera-ip/environmental-sensor/index.html#/system/mqtt/publication)
3. Host: you computers IP
4. **Save** → **Connect**
5. **+ Add Condition**
6. Condition: Air quality monitoring active (this starts publishing air quality data every second)
7. **Add**
8. Take note of device serial for next step

### Node-RED Flow

Node-RED: `http://localhost:1880`

1. Import flow from [aqs_to_influx.json](https://github.com/Axis-TTC/Axis_AQS_Data_Visualization/blob/main/aqs_to_influx.json)
2. Double click **Axis D6310 MQTT node**
3. Change serial number in Topic to your device serial
4. **For the TTC workshop** click the pencil and change the broker URL to `mqtt.ttc.local`
5. In a new tab Open InfluxDB: `http://localhost:8086` (admin/password123)
6. Click **Load Data** → **API Tokens** → **Generate API Token** → **All Access API Token**
7. Name it anything
8. Manauly copy the token (**DO NOT CLICK** "copy to clipboard" it doesnt always work)
9. Back in Node Red double click **InfluxDB Axis AQ** node
10. Click pencil next to "Server"
11. Paste Token in **Token** field
12. Click **Update** → **Done** → **Deploy**

## InfluxDB

InfluxDB: `http://localhost:8086` (admin/password123)

Check that data is being stored
1. On the left side click **Data Explorer**
2. Select **airquality**
3. Tick **air_quality**
4. Tick one of the data types eg. AQI or CO2
5. Select **Past 1h** from the drop down
6. You should see data, if not go back to the Node-Red flow

## Grafana

Grafana: `http://localhost:3000` (admin/password123)

### Add Data source
1. **Connections** → **Data Sources** → **Add data source** → **InfluxDB**
2. Query language= Flux
3. URL: http://influxdb:8086
4. User: admin
5. Password: password123
7. Organization: iot
8. Open InfluxDB: `http://localhost:8086` (admin/password123)
9. Click **Load Data** → **API Tokens** → **Generate API Token** → **All Access API Token**
10. Name it anything
11. Manaul copy the token (copy to clipboard doesnt always work)
12. Paste Token in **Token** field
13. **Save & Test**

## Add Dashboard
1. **Dashboards** → **Create dashboard**
2. **Add visualization**
3. Click **InfluxDB**

### Temperature
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
### To rename the sensors
1. on the right hand side scroll all tha way to the bottom.
2. Click **+ Add field override**
3. Select **Fields with name** (alternativly you can use **Fields with name matching regex** and use the regex ```.*camera_id="E827251A7B09".*``` to match only to the serial of the device, this is useful when reusing overrides accross panels.
4. In the drop down select the sensor you want to change
5. Click **+ Add override property**
6. Select **Standard options > Display name**
7. Type the new name for the sensor
8. Repeat for other sensors
  
- **Back to dashboard**
- **Add** → **Visualization**
  
### Humidity
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

- **Back to dashboard**
- **Add** → **Visualization**

### VOC
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

- **Back to dashboard**
- **Add** → **Visualization**

### CO2
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

- **Back to dashboard**
- **Add** → **Visualization**

### PM1, PM2.5, PM4, PM10
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

- **Back to dashboard**
- **Add** → **Visualization**

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

- **Back to dashboard**
- **Add** → **Save Dashboard**

## For the TTC workshop go to [Task 2](https://github.com/Axis-TTC/Axis_AQS_Data_Visualization/blob/main/Task_2.md)


## Troubleshooting

| Issue | Solution |
|-------|----------|
| **Too many datapoints** | Panel → Query → Max data points: `50000` |
| **No MQTT data** | Check AXIS MQTT config, Node-RED logs |
| **Influx empty** | Verify bucket `airquality`, Node-RED Influx node |
| **Grafana no data** | Check provisioning, API token |

**⭐ Star if useful!** Questions? Open an issue.

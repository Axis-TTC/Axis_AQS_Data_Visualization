## Create an alert (Bonus)

### Add a contact point in Grafana
1.	In the left hand menu select **alerting** then **contact points**.
2.	Click **+ create contact point**
3.	Give it a name
4.	From the **integration** drop down select **MQTT**
5.	In the URL field add `tcp://mqtt.ttc.local:1883`
6.	Topic should be `grafana/groupX/alerts` **replace the X with your group name**
7.	Click **save contact point**

### Add an alert rule in Grafana
1.	In the left menu click **Alert Rules**
2.	Click **+ New Alert Rule**
3.	Give it a name
4.	In the **define query alert** field add a query from one of your dashboards for example for **VOC’s** add the below.

```from(bucket: "airquality")
  |> range(start: v.timeRangeStart, stop: v.timeRangeStop)
  |> filter(fn: (r) => r._measurement == "air_quality")
  |> filter(fn: (r) => r.sensor_name == "D6310")
  |> filter(fn: (r) => r._field == "VOC")
  |> aggregateWindow(every: 1m, fn: mean, createEmpty: false)
```

5.	In the **alert condition** select **last** then **is above** add a value to monitor for.
6.	You can test it by clicking **preview alert rule condition**
7.	In **3. Add folder and labels** click **new folder** and give it a name.
8.	In **4. Set evaluation behavior** click **new evaluation group** and give it a name and select `10s` for the **Evaluation interval**
9.	For **Pending period** input `10s`
10.	In **5. Configure notifications** select your MQTT contact point.
11.	Click **Save**
12.	Open **MQTT explorer** on the computer and connect to `mqtt.ttc.local` you should see messages on your topic when the event is triggered.


### Create an event on an Axis device 
1.	On the axis device under MQTT connect to the broker `mqtt.ttc.local`
2.	Add an MQTT subscription to the topic `grafana/groupX/alerts` **replace the X with your group name**
3.	Add an event that is triggered by the above subscription
4.	Trigger the event and see if it works but bear in mind it take a minute or two.


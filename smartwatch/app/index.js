import document from "document";
import * as messaging from "messaging";
import { outbox } from "file-transfer";
import { encode } from "cbor";
import { Accelerometer } from "accelerometer";
import { HeartRateSensor } from "heart-rate";
import { me } from "appbit";
import { display } from "display";

display.on = true;
display.autoOff = false;

let background = document.getElementById("background");
let title = document.getElementById("title");
let accel;
let hrm;
let sentObj;

// Data from Accelerometer
if (Accelerometer) {
  // 10 readings per second, 50 readings per batch (5 sec)
  accel = new Accelerometer({ frequency: 10, batch: 50 });
  accel.addEventListener("reading", () => {
    display.poke();
    for (let index = 0; index < accel.readings.timestamp.length; index++) {
      sentObj.accelerometer.push({
        timestamp: accel.readings.timestamp[index],
        x: accel.readings.x[index],
        y: accel.readings.y[index],
        z: accel.readings.z[index]
      })
    }
    accel.stop();
    sendFile();
  })
};

// Data from Heart Rate
if (HeartRateSensor) {
  // 1 readings per second, 5 readings per batch (5 sec)
  hrm = new HeartRateSensor({ frequency: 1, batch: 5 });
  hrm.addEventListener("reading", () => {
    for (let index = 0; index < hrm.readings.timestamp.length; index++) {
      sentObj.heart_rate.push({
        timestamp: hrm.readings.timestamp[index],
        heartRate: hrm.readings.heartRate[index]
      })
    }
    hrm.stop();
  })
};

// Message is received
messaging.peerSocket.onmessage = async evt => {
  display.poke();
  console.log(`App received: ${JSON.stringify(evt)}`);
  if (evt.data === "data"){
    sentObj = {
      accelerometer: [],
      gyroscope: [],
      heart_rate: []
    }
    if (accel !== undefined)
      accel.start();
    if (hrm !== undefined) 
      hrm.start();
    background.style.fill = "white";
    title.style.fill = "black";
    title.text = "Collecting data";
  }
  else {
    if (evt.data === "true") {
      background.style.fill = "green";
      title.text = "Access granted";
    }
    else {
      background.style.fill = "red";
      title.text = "Access denied";
    }
    await new Promise(resolve => setTimeout(resolve, 3000)); // wait 3s
    me.exit();
  }
};

// Message socket opens
messaging.peerSocket.onopen = async () => {
  display.poke();
  console.log("App Socket Open");
  title.text = "Waiting for request";
};

// Message socket closes
messaging.peerSocket.onclose = () => {
  console.log("App Socket Closed");
};

// Sent data to compantion
const sendFile = async () => {
  const filename = "Data.txt";
  console.log("File name is: " + filename);
  outbox.enqueue(filename, encode(sentObj))
    .catch((err) => {
    throw new Error("Failed to queue" + filename + ". Error: " + err);
  })
  console.log("File send");
  background.style.fill = "fb-blue";
  title.text = "Waiting for result";
  display.poke();
}

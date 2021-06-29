import * as messaging from "messaging";
import { settingsStorage } from "settings";
import { inbox } from "file-transfer";
import { me as companion } from "companion";
import { encode } from "cbor";

let userEncodedId;
let token;
let websocket;

const wsUri = "wss://dfea7275805a.ngrok.io/ws";

/*
const MILLISECONDS_PER_MINUTE = 1000 * 60;

// Tell the Companion to wake after 30 minutes
companion.wakeInterval = 30 * MILLISECONDS_PER_MINUTE;

// Listen for the event
companion.addEventListener("wakeinterval", doThis);

// Event happens if the companion is launched and has been asleep
if (companion.launchReasons.wokenUp) {
  doThis();
}
*/

function makeConnectionToEndpoint() {
  console.log("Make connection to endpoint");
  if(userEncodedId !== undefined && token !== undefined) {
    websocket = new WebSocket(wsUri);

    websocket.addEventListener("open", onOpen);
    websocket.addEventListener("close", onClose);
    websocket.addEventListener("message", onMessage);
    websocket.addEventListener("error", onError);
  }
}

function onOpen(evt) {
   console.log("CONNECTED");
   websocket.send(encode({
    "closing": false,
    "userId": userEncodedId,
    "token": token,
    "data": false
  }));
}

function onClose(evt) {
   console.log("DISCONNECTED");
}

function onMessage(evt) {
  console.log(`MESSAGE: ${evt.data}`);
  if (evt.data === "Request data")
    sendVal("data");
  else
    sendVal(evt.data);
}

function onError(evt) {
   console.error(`ERROR: ${evt.data}`);
}

// Message socket opens
messaging.peerSocket.onopen = () => {
  console.log("Companion Socket Open");
};

// Message socket closes
messaging.peerSocket.onclose = () => {
  console.log("Companion Socket Closed");
};

// Process the inbox queue for files, and read their contents as text
async function processAllFiles() {
   let file;
   while ((file = await inbox.pop())) {
     console.log(`New file: ${file.name}`);
     let payload = await file.cbor();
     console.log(`file contents: ${JSON.stringify(payload)}`);
     websocket.send(encode({
        "closing": false,
        "userId": userEncodedId,
        "token": token,
        "data": payload,
     }));
   }
}

// Send data to device using Messaging API
function sendVal(data) {
  if (messaging.peerSocket.readyState === messaging.peerSocket.OPEN) {
    messaging.peerSocket.send(data);
  }
}

// A user changes Settings
settingsStorage.onchange = evt => {
  console.log("User changes Settings");
  if (evt.key === "oauth") {
    // Settings page sent us an oAuth token from which we can take the encoded ID
    let data = JSON.parse(evt.newValue);
    userEncodedId = data.user_id;
    console.log(`Get user_id from changed settings  ${userEncodedId}`);
  }
  if (evt.key === "user_token") {
    token = evt.newValue
    console.log(`Get user_token from changed settings ${token}`);
  }
};

// Restore previously saved user_id
function restoreSettingsStorage() {
  for (let index = 0; index < settingsStorage.length; index++) {
    let key = settingsStorage.key(index);
    if (key && key === "oauth") {
      // We already have an oauth token from which we can take the encoded ID
      let data = JSON.parse(settingsStorage.getItem(key));
      userEncodedId = data.user_id;
      console.log(`Get user_id from an old oauth ${userEncodedId}`);
    }
    if (key && key === "user_token") {
      token = JSON.parse(settingsStorage.getItem(key)).name;
      console.log(`Get user_token from changed settings ${token}`);
    }
  }
}

if(!userEncodedId || !token)
  restoreSettingsStorage();

// Process new files as they are received
inbox.addEventListener("newfile", processAllFiles);
// Also process any files that arrived when the companion wasn’t running
processAllFiles();
makeConnectionToEndpoint();
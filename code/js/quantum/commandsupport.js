let commandBindings = {
  playPause: '{MEDIA_PLAY_PAUSE}',
  playNext: '{MEDIA_NEXT}',
  playPrev: '{MEDIA_PREV}',
  stop: '{MEDIA_STOP}',
  mute: '{VOLUME_MUTE}',
  like: '',
  dislike: '',
  _toggle: ''
};

function getCommands () {
  return commandBindings;
}

function serializeCommandsForNative(commands) {
  return Object.entries(commands).map(([commandName, keyBinding]) => (
    `${commandName}\x1F${keyBinding}`
  )).join('\x1E');
}

let port = null;

function connectToGCS () {
  if (!port)
    port = browser.runtime.connectNative("skqgcs");
}

function listenForCommands(callback) {
  connectToGCS();
  port.onMessage.addListener(function (response) {
    console.log("Received Command: " + response);
    if (~Object.keys(commandBindings).indexOf(response)) {
      callback(response);
    }
  });
}

function updateConfig(newCommandBindings) {
  commandBindings = newCommandBindings;
  console.log(serializeCommandsForNative(newCommandBindings));
  port.postMessage(serializeCommandsForNative(newCommandBindings));
}

module.exports = {
  getCommands, listenForCommands, updateConfig
};

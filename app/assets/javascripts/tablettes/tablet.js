// jshint esversion: 6
// jshint browser: true

(() => {
'use strict';

window.setClockOffset = function (offset) {
    log("Setting clock offset to " + offset + "ms");
    clockOffset = offset;
};

let PING_INTERVAL = 2000;
var clockOffset = 0;
var currentCueTime = null;
var nextCueTimeout = null;

document.addEventListener("DOMContentLoaded", event => {
    let video = document.getElementById('tablettes-video');
    if (!video) return;

    document.getElementById('reload-button').addEventListener('click', function () {
        location.reload();
    });

    sendPing();
});

function sendPing() {
    fetch('/tablettes/ping.json', {method: 'POST'})
    .then(response => {
        return response.json();
    })
    .then(json => {
        let nextCueTime = json.next_cue_time;
        if (currentCueTime !== nextCueTime) {
            log("Received new cue time", nextCueTime);
            clearTimeout(nextCueTimeout);
            currentCueTime = nextCueTime;
            //primeVideo();
            scheduleCueTick();
        }

        setTimeout(sendPing, PING_INTERVAL);
    })
    .catch((error) => {
        log("ping failed", error);
        setTimeout(sendPing, PING_INTERVAL);
    });
}

function scheduleCueTick() {
    let now = serverNow();
    let seconds = Math.ceil((now - currentCueTime) / 1000);
    let tickTime = currentCueTime + 1000 * seconds;
    nextCueTimeout = setTimeout(cueTick, tickTime - now);
}

function cueTick() {
    let now = serverNow();
    let seconds = Math.floor((now - currentCueTime) / 1000);
    if (seconds === 0) {
        document.getElementById('tablettes-video').play();
    }
    document.getElementById('cue').innerText = "T" + (seconds < 0 ? "" : "+") + seconds + " seconds";
    scheduleCueTick();
}

function serverNow() {
    return Date.now() + clockOffset;
}

function primeVideo() {
    log('seeking to 2 second mark');
    let video = document.getElementById('tablettes-video');
    video.pause();
    video.currentTime = 2; // Start at the 2 second mark.
}

function log() {
    console.log.apply(console, arguments);
    let status = document.getElementById('status');
    status.innerText = Array.prototype.join.call(arguments, ' ');
}

})();

// jshint esversion: 6
// jshint browser: true

(() => {
'use strict';

let PING_INTERVAL = 2000;
let CLOCK_OFFSET_FILTER = 0.3;
var clockOffset = null;
var currentCueTime = null;
var nextCueTimeout = null;

document.addEventListener("DOMContentLoaded", event => {
    let video = document.getElementById('tablettes-video');
    if (!video) return;

    sendPing();
});

function sendPing() {
    let txTime = Date.now();

    var rxTime = null;
    fetch('/tablettes/ping.json', {method: 'POST'})
    .then(response => {
        rxTime = Date.now();
        return response.json();
    })
    .then(json => {
        updateClockOffset(txTime, rxTime, json);

        let nextCueTime = json.next_cue_time - clockOffset;
        if (currentCueTime !== nextCueTime) {
            log("Received new cue time", nextCueTime);
            clearTimeout(nextCueTimeout);
            currentCueTime = nextCueTime;
            primeVideo();
            scheduleCueTick();
        }

        setTimeout(sendPing, PING_INTERVAL);
    })
    .catch((error) => {
        log("ping failed", error);
        setTimeout(sendPing, PING_INTERVAL);
    });
}

// Based on NTP: https://en.wikipedia.org/wiki/Network_Time_Protocol#Clock_synchronization_algorithm
function updateClockOffset(txTime, rxTime, response) {
    // Try skipping clock sync, relying just on OS time.
    return;

    let theta = ((response.rx_time - txTime) + (response.tx_time - rxTime)) / 2;
    let delta = (rxTime - txTime) - (response.tx_time - response.rx_time);
    if (clockOffset === null) {
        clockOffset = theta;
        log("initial clock offset set to " + theta + " round-trip: " + delta);
    } else {
        clockOffset = clockOffset * (1 - CLOCK_OFFSET_FILTER) + theta * CLOCK_OFFSET_FILTER;
        log("clock offset updated to " + Math.round(clockOffset, 2), "this theta: " + theta, "head: " + (response.rx_time - txTime), "tail: " + (response.tx_time - rxTime), "round-trip: " + delta);
    }
}

function scheduleCueTick() {
    let now = Date.now();
    let seconds = Math.ceil((now - currentCueTime) / 1000);
    let tickTime = currentCueTime + 1000 * seconds;
    nextCueTimeout = setTimeout(cueTick, tickTime - now);
}

function cueTick() {
    let now = Date.now();
    let seconds = Math.floor((now - currentCueTime) / 1000);
    if (seconds === 0) {
        document.getElementById('tablettes-video').play();
    }
    document.getElementById('cue').innerText = "T" + (seconds < 0 ? "" : "+") + seconds + " seconds";
    scheduleCueTick();
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

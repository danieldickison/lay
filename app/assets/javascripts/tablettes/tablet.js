// jshint esversion: 6
// jshint browser: true

(() => {
'use strict';

let PING_INTERVAL = 2000;
let CLOCK_OFFSET_FILTER = 0.3;
var clockOffset = null;
var nextCueTimeout = null;

document.addEventListener("DOMContentLoaded", event => {
    let status = document.getElementById('status');
    let video = document.getElementById('tablettes-video');
    if (!video) return;

    // Try to preload the video so it starts quickly when triggered.
    // I don't think this helps, since the <video> tag already specifies preload which gets things buffered.
    /*
    video.addEventListener('loadedmetadata', function () {
        log('seeking to 2 second mark');
        video.pause();
        video.currentTime = 2; // Start at the 2 second mark.
    });
    video.play();
    */

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

        clearTimeout(nextCueTimeout);
        let nextCueTime = json.next_cue_time - clockOffset;
        let now = Date.now();
        if (nextCueTime > now) {
            setTimeout(triggerCue, nextCueTime - now);
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

function triggerCue() {
    log("triggering cue now!");
    document.getElementById('tablettes-video').play();
}

function log() {
    console.log.apply(console, arguments);
    let status = document.getElementById('status');
    status.innerHTML = Array.prototype.join.call(arguments, ' ');
}

})();

// jshint esversion: 6
// jshint browser: true

(() => {
'use strict';

window.setClockOffset = function (offset) {
    log("Setting clock offset to " + offset + "ms");
    clockOffset = offset;
};

let PING_INTERVAL = 1000;
var clockOffset = 0;
var currentCueTime = null;
var nextCueTimeout = null;

let LOGO_BG_INTERVAL = 20000;
var currentLogoBgIndex = 0;

document.addEventListener("DOMContentLoaded", event => {
    let isIndexPage = document.getElementById('tablettes-index');
    if (!isIndexPage) return;

    document.getElementById('reload-button').addEventListener('click', function () {
        location.reload();
    });

    setInterval(cycleLogoBg, LOGO_BG_INTERVAL);

    sendPing();
});

function sendPing() {
    fetch('/tablettes/ping.json', {method: 'POST'})
    .then(response => {
        return response.json();
    })
    .then(json => {
        let nextCueTime = json.next_cue_time;
        let nextCueFile = json.next_cue_file;
        let nextSeekTime = json.next_seek_time;
        if (currentCueTime !== nextCueTime && nextCueFile) {
            log("Received new cue time", nextCueTime);
            clearTimeout(nextCueTimeout);
            currentCueTime = nextCueTime;
            scheduleCueTick();
            layNativeInterface.setVideoCue("/videos/" + encodeURIComponent(nextCueFile), nextCueTime, nextSeekTime);
        }

        setTimeout(sendPing, PING_INTERVAL);
    })
    .catch(error => {
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
    document.getElementById('cue').innerText = "T" + (seconds < 0 ? "" : "+") + seconds + " seconds";
    scheduleCueTick();
}

function serverNow() {
    return Date.now() + clockOffset;
}

function log() {
    console.log.apply(console, arguments);
    let status = document.getElementById('status');
    status.innerText = Array.prototype.join.call(arguments, ' ');
}

function cycleLogoBg() {
    let list = document.querySelectorAll('#logo-bg > li');
    currentLogoBgIndex = (currentLogoBgIndex + 1) % list.length;
    list.forEach((el, i) => {
        el.classList.toggle('logo-bg-active', i === currentLogoBgIndex);
    });
}

})();

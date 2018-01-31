// jshint esversion: 6
// jshint browser: true

(() => {
'use strict';

window.setClockOffset = function (offset) {
    document.getElementById('clock-offset').innerText = "Clock offset: " + offset + " ms";
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
        if (currentCueTime !== nextCueTime) {
            log("Received new cue time", nextCueTime, nextCueFile);
            clearTimeout(nextCueTimeout);
            currentCueTime = nextCueTime;
            scheduleCueTick();
            let path = nextCueFile && nextCueFile.replace(/([\/:]?)([^\/:]+)([\/:]?)/g, function (match, p1, p2, p3) {
                return p1 + encodeURIComponent(p2) + p3;
            });
            layNativeInterface.setVideoCue(path, nextCueTime, nextSeekTime);
        }

        document.getElementById('tablet-id').innerText = "Tablet #" + json.tablet_number + " — " + json.tablet_ip;

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

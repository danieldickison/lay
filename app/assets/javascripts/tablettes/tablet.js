// jshint esversion: 6
// jshint browser: true

(() => {
'use strict';

window.setClockOffsets = function (offsets) {
    let latest = offsets[0];
    let len = offsets.length;
    let sum = offsets.reduce((accum, val) => accum + val, 0);
    let mean = sum / offsets.length;
    offsets.sort((a, b) => a - b);
    let median = offsets[Math.floor(offsets.length / 2)];
    let stdev = Math.sqrt(offsets.reduce((accum, val) => accum + Math.pow(val - mean, 2)) / Math.max(1, (len - 1)));
    document.getElementById('clock-offset').innerText = "Clock offset (ms): latest=" + latest + " mean=" + latest.toFixed(1) + " median=" + median + " stdev=" + stdev.toFixed(1);
    clockOffset = median;
};

window.setNowPlaying = function (np) {
    nowPlaying = np;
};

window.clearNowPlaying = function (np) {
    if (nowPlaying.path == np.path) {
        nowPlaying = {};
    }
};

let PING_INTERVAL = 100;
var clockOffset = 0;
var currentCueTime = null;
var nextCueTimeout = null;
var currentPreload = null;

var nowPlaying = {};

let LOGO_BG_INTERVAL = 20000;
var currentLogoBgIndex = 0;

document.addEventListener("DOMContentLoaded", event => {
    let isIndexPage = document.getElementById('tablettes-index');
    if (!isIndexPage) return;

    document.getElementById('reload-button').addEventListener('click', function () {
        location.reload();
    });

    //setInterval(cycleLogoBg, LOGO_BG_INTERVAL);
    setInterval(sendPing, PING_INTERVAL);
    setInterval(cueTick, 100);

    sendPing();
});

function sendPing() {
    let body = new URLSearchParams();
    body.append('now_playing_path', nowPlaying.path);
    fetch('/tablettes/ping.json', {method: 'POST', body: body})
    .then(response => {
        return response.json();
    })
    .then(json => {
        let nextCueTime = json.next_cue_time;
        let nextCueFile = json.next_cue_file;
        let nextSeekTime = json.next_seek_time;
        if (currentCueTime !== nextCueTime) {
            log("Received new cue time", lz(nextCueTime % 10000, 4), nextCueFile);
            // clearTimeout(nextCueTimeout);
            currentCueTime = nextCueTime;
            // scheduleCueTick();
            let path = uriEscapePath(nextCueFile);
            layNativeInterface.setVideoCue(path, nextCueTime, nextSeekTime);
        }

        if (!arraysEqual(json.preload_files, currentPreload)) {
            if (json.preload_files) {
                log("Received new preload files", json.preload_files);
            } else {
                log("Clearing preload cache");
            }
            currentPreload = json.preload_files;
            let paths = currentPreload && currentPreload.map(p => uriEscapePath(p));
            layNativeInterface.setPreloadFiles(paths);
        }

        document.getElementById('tablet-id').innerText = "Tablet #" + json.tablet_number + " — " + json.tablet_ip;

        // setTimeout(sendPing, PING_INTERVAL);
    })
    .catch(error => {
        log("ping failed", error);
        // setTimeout(sendPing, PING_INTERVAL);
    });
}

function lz(num, size) {
    let p = "";
    if (num < 10 && size >= 2)
        p += "0";
    if (num < 100 && size >= 3)
        p += "0";
    if (num < 1000 && size >= 4)
        p += "0";
    if (num < 10000 && size >= 5)
        p += "0";

    return p + num;
}

function scheduleCueTick() {
    let now = serverNow();
    let seconds = Math.ceil((now - currentCueTime) / 1000);
    let tickTime = currentCueTime + 1000 * seconds;
//    nextCueTimeout = setTimeout(cueTick, tickTime - now);
    // nextCueTimeout = setTimeout(cueTick, 100);
}

function cueTick() {
    let now = serverNow();
    let cue_msg = "";
    if (currentCueTime) {
        let seconds = now - currentCueTime;
        cue_msg = "   T" + (seconds < 0 ? "" : "+") + seconds + "ms";
    }
    document.getElementById('cue').innerText = "now " + lz(now % 10000, 4)  + cue_msg;
    // scheduleCueTick();
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

function arraysEqual(a1, a2) {
    if (a1 == a2) return true; // e.g. both null
    if (a1 == null || a2 == null) return false; // one is null.
    if (a1.length !== a2.length) return false;
    for (var i = 0; i < a1.length; i++) {
        if (a1[i] !== a2[i]) return false;
    }
    return true;
}

function uriEscapePath(path) {
    return path && path.replace(/([\/:]?)([^\/:]+)([\/:]?)/g, (m, p1, p2, p3) => p1 + encodeURIComponent(p2) + p3);
}

})();

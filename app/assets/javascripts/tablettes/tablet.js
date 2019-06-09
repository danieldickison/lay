// jshint esversion: 6
// jshint browser: true

(() => {
'use strict';

window.setClockOffsets = function (offsets, lastSuccess) {
    let latest = offsets[0];
    let len = offsets.length;
    let sum = offsets.reduce((accum, val) => accum + val, 0);
    let mean = sum / offsets.length;
    offsets.sort((a, b) => a - b);
    let median = offsets[Math.floor(offsets.length / 2)];
    let stdev = Math.sqrt(offsets.reduce((accum, val) => accum + Math.pow(val - mean, 2), 0) / Math.max(1, (len - 1)));
    clockInfo = "latest=" + latest + " mean=" + latest.toFixed(1) + " median=" + median + " stdev=" + stdev.toFixed(1);
    document.getElementById('clock-offset').innerText = "Clock offset (ms): " + clockInfo;
    clockOffset = median;
    lastNtpSuccess = lastSuccess;
};

window.setNowPlaying = function (np) {
    console.log("set now playing: " + np.path);
    nowPlaying = np;
    fadeLogo(false);
};

window.clearNowPlaying = function (np) {
    console.log("clear now playing: " + np.path + "; currently: " + nowPlaying.path);
    if (nowPlaying.path == np.path) {
        nowPlaying = {};
        fadeLogo(true);
    }
};

let PING_INTERVAL = 500;
let PING_TIMEOUT = 3000;
var pingStartTime = null;
var clockOffset = 0;
var clockInfo = null;
var lastNtpSuccess = 0;
var currentCueTime = null;
var nextCueTimeout = null;
var currentPreload = null;

var nowPlaying = {};

let LOGO_BG_INTERVAL = 20000;
var currentLogoBgIndex = 0;

let BATTERY_INTERVAL = 60000;
var batteryPercent = -2;

document.addEventListener("DOMContentLoaded", event => {
    let isIndexPage = document.getElementById('tablettes-index');
    if (!isIndexPage) return;

    document.body.classList.add('tablet');

    document.getElementById('reload-button').addEventListener('click', function () {
        location.reload();
    });

    // Help local debugging in chrome
    if (!window.layNativeInterface) {
        window.layNativeInterface = {
            getBuildName: function () { return 'fake native interface'; },
            getCacheInfo: function () { return ''; },
            getBatteryPercent: function () { return -1; },
            setVideoCue: function () {},
            downloadFile: function () {},
            hideChrome: function () {},
        };
    }

    let version = document.getElementById('version');
    version.innerText = "Build: " + layNativeInterface.getBuildName();

    //setInterval(cycleLogoBg, LOGO_BG_INTERVAL);
    setInterval(sendPing, PING_INTERVAL);
    setInterval(cueTick, 100);
    setInterval(updateBatteryStatus, BATTERY_INTERVAL);

    sendPing();
    updateBatteryStatus();

    preShowInit();
});

function preShowInit() {
    var params;

    let introButton = document.getElementById('intro-button');
    let dataEntry = document.getElementById('pre-show-data-entry');
    let programNumber = document.getElementById('program-number-input');
    let drinkMenu = document.getElementById('drink-menu');
    let optOutButton = document.getElementById('opt-out-button');
    let optInButton = document.getElementById('opt-in-button');
    let popup = document.getElementById('consent-popup');

    introButton.addEventListener('click', function () {
        params = new URLSearchParams();
        introButton.style.display = 'none';
        dataEntry.style.display = 'block';
        programNumber.focus();
    });
    document.getElementById('no-drink-button').addEventListener('click', () => {
        drinkMenu.style.display = 'none';
        showConsentPopup();
    });
    document.getElementById('yes-drink-button').addEventListener('click', () => {
        drinkMenu.style.display = 'block';
    });
    document.querySelectorAll('#drink-menu button').forEach(button => {
        button.addEventListener('click', () => {
            params.set('drink', button.innerText);
            showConsentPopup();
        });
    });
    
    function showConsentPopup() {
        popup.style.display = 'block';
        layNativeInterface.hideChrome();
    }

    optOutButton.addEventListener('click', () => {
        params.set('opt', 'N');
        submit();
    });
    optInButton.addEventListener('click', () => {
        params.set('opt', 'Y');
        submit();
    });

    function submit() {
        optInButton.disabled = true;
        optOutButton.disabled = true;

        params.set('patron_id', programNumber.value);
        fetch('/tablettes/update_patron.json', {method: 'POST', body: params})
        .then(response => {
            return response.json();
        });
        // Don't wait for fetch to complete. Fail silently.
        reset();
    }

    function failed() {
        alert("Please double check your program number and try again.");
        optInButton.disabled = false;
        optOutButton.disabled = false;
        popup.style.display = 'none';
    }

    function reset() {
        optInButton.disabled = false;
        optOutButton.disabled = false;
        popup.style.display = 'none';
        dataEntry.style.display = 'none';
        drinkMenu.style.display = 'none';
        introButton.style.display = 'block';
        programNumber.value = '';
        document.getElementById('consent-popup-box').scrollTop = 0;
    }
}

function sendPing() {
    if (pingStartTime) {
        let timeSincePing = Date.now() - pingStartTime;
        if (timeSincePing > PING_TIMEOUT) {
            log("Forcing ping request; previous one stuck for " + timeSincePing + "ms");
        } else {
            log("Skipping ping while another one is in flight for " + timeSincePing + "ms");
            return;
        }
    }

    let body = new URLSearchParams();
    body.append('now_playing_path', nowPlaying.path);
    body.append('clock_info', clockInfo + " timeSince=" + (Date.now() - lastNtpSuccess));
    body.append('cache_info', layNativeInterface.getCacheInfo());
    body.append('battery_percent', batteryPercent);
    let startTime = Date.now();
    pingStartTime = startTime;
    var endTime;
    fetch('/tablettes/ping.json', {method: 'POST', body: body})
    .then(response => {
        endTime = Date.now();
        if (endTime - startTime > PING_TIMEOUT) {
            log("Slow ping response beyond timeout: " + (endTime - startTime) + "ms; ignoring response");
            return null;
        } else if (endTime - startTime > 100) {
            log("Slow ping response: " + (endTime - startTime) + "ms");
        }
        return response.json();
    })
    .then(json => {
        if (!json) return;

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

        (json.commands || []).forEach((cmd) => {
            log('Last command: ' + cmd.join('; '));
            switch (cmd[0]) {
                case 'load':
                    layNativeInterface.downloadFile(uriEscapePath(cmd[1]));
                    break;
                case 'reload':
                    location.reload();
                    break;
            }
        });

        if (json.text_feed) {
            triggerTextFeed(json.text_feed);
        }

        document.getElementById('tablet-id').innerText = "Tablet #" + json.tablet_number + " — " + json.tablet_ip;
        document.getElementById('tablettes-debug').classList.toggle('visible', json.debug);
        
        let preShow = document.getElementById('tablettes-pre-show');
        if (json.show_time) {
            if (preShow.style.display != 'none') {
                layNativeInterface.hideChrome();
            }
            preShow.style.display = 'none';
        } else {
            preShow.style.display = 'block';
            preShow.style.backgroundImage = 'url(' + json.preshow_bg + ')';
        }

        pingStartTime = null;
        // setTimeout(sendPing, PING_INTERVAL);
    })
    .catch(error => {
        log("ping failed", error);
        // setTimeout(sendPing, PING_INTERVAL);
        pingStartTime = null;
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

function fadeLogo(visible) {
    console.log("fadeLogo: " + visible);
    let list = document.querySelectorAll('#logo-bg > li');
    list.item(0).classList.toggle('logo-bg-active', visible);
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

function triggerTextFeed(strings) {
    let container = document.getElementById('tablettes-text-feed');
    container.innerHTML = '';
    strings.forEach((str, i) => {
        let p = document.createElement('p');
        p.innerText = str;
        p.classList.add('depth-' + (i % 3));
        p.style.animationDelay = (7 * Math.floor(i / 3) + 3 * Math.random()) + 's';
        p.style.left = Math.round(300 * Math.random()) + 'px';
        container.appendChild(p);
        p.addEventListener('animationend', () => {
            if (p.parentNode === container) container.removeChild(p);
        });
    });
}
window.triggerTextFeed = triggerTextFeed; // for testing in console

function updateBatteryStatus() {
    batteryPercent = layNativeInterface.getBatteryPercent();
    log('batteryPercent updated to ' + batteryPercent);
}

})();

// jshint esversion: 6
// jshint browser: true

(() => {
'use strict';

// Help local debugging in chrome
if (!window.layNativeInterface) {
    window.layNativeInterface = {
        getTabletNumber: function () { return 26; },
        getBuildName: function () { return 'fake'; },
        getCacheInfo: function () { return ''; },
        getBatteryPercent: function () { return -1; },
        setVideoCue: function () {},
        setVolume: function () {},
        setAssets: function () {},
        hideChrome: function () {},
        setScreenBrightness: function () {},
        resetOSC: function () {},
        resetNTP: function () {},
    };
}

window.updateClockOffset = function (offset, lastSuccess) {
    pastClockOffsets.push(offset);
    if (pastClockOffsets.length > PAST_OFFSETS_COUNT) {
        pastClockOffsets.splice(0, pastClockOffsets.length - PAST_OFFSETS_COUNT);
    }
    let offsets = pastClockOffsets.slice().sort((a, b) => a - b);
    let len = offsets.length;
    let sum = offsets.reduce((accum, val) => accum + val, 0);
    let mean = sum / offsets.length;
    let median = offsets[Math.floor(offsets.length / 2)];
    let stdev = Math.sqrt(offsets.reduce((accum, val) => accum + Math.pow(val - mean, 2), 0) / Math.max(1, (len - 1)));
    clockInfo = "latest=" + offset + " mean=" + mean.toFixed(1) + " median=" + median + " stdev=" + stdev.toFixed(1);
    document.getElementById('clock-offset').innerText = "Clock offset (ms): " + clockInfo;
    clockOffset = median;
    lastNTP = lastSuccess;
    return median;
};

window.updateOSCPing = function (serverTime) {
    //console.log("got osc server time: " + serverTime);
    lastOSCPing = serverTime;
};

window.setLastOSCMessage = function (msg) {
    let el = document.getElementById('last-osc-message');
    el.innerText = msg;
};

window.setNowPlaying = function (np) {
    console.log("set now playing " + np.playerIndex + ":" + np.path);
    nowPlaying = np;
};

window.clearNowPlaying = function (np) {
    console.log("clear now playing " + np.playerIndex + ":" + np.path + "; currently " + nowPlaying.playerIndex + ":" + nowPlaying.path);
    if (nowPlaying.path === np.path && nowPlaying.playerIndex === np.playerIndex) {
        nowPlaying = {};
    }
};

var TABLET_NUMBER = layNativeInterface.getTabletNumber();
window.debugSetTabletNumber = function (number) {
    TABLET_NUMBER = number;
};
let IS_LOBBY = TABLET_NUMBER >= 100;
let BUILD_NAME = layNativeInterface.getBuildName();

let EMPLOYEE_ID_PREFIXES = {
    1:  'A-VX###-', //'RIXA', // Applied Validation
    2:  'B-AX###-', //'RIXB', // Biofinity Architecture
    3:  'C-LX###-', //'RIXC', // Cell Logics
    4:  'D-RX###-', //'RIXD', // Disaster Recovery
    5:  'E-DX###-', //'RIXE', // Embedded Datamatics
    6:  'F-AX###-', //'RIXF', // Failure Analysis
    7:  'G-FX###-', //'RIXG', // Geoframeworking
    8:  'H-FX###-', //'RIXH', // Human Factors
    9:  'I-PX###-', //'RIXI', // Illocution Processing
    10: 'J-PX###-', //'RIXJ', // Juice Platforming 
    11: 'K-VX###-', //'RIXK', // Ketogenesis Validation
    12: 'L-MX###-', //'RIXL', // Life Cycle Metrics
    13: 'M-EX###-', //'RIXM', // Machine Evangelism
    14: 'N-LX###-', //'RIXN', // Natural Language Illocution
    15: 'O-VX###-', //'RIXO', // Orange Mandarin Visioning
    16: 'P-AX###-', //'RIXP', // Physiology Analytics
    17: 'Q-RX###-', //'RIXQ', // Quartermaster Research
    18: 'R-EX###-', //'RIXR', // Retrieval Environments
    19: 'S-RX###-', //'RIXS', // Substance Restriction
    20: 'T-FX###-', //'RIXT', // Thin Film Interface
    21: 'U-SX###-', //'RIXU', // UX Sculpting
    22: 'V-NX###-', //'RIXV', // Vibration & Noise
    23: 'W-RX###-', //'RIXW', // Wagonette Rendering
    24: 'X-YX###-', //'RIXX', // Xylographics
    25: 'Y-AX###-', //'RIXY', // Yellowback Algoretrieval
    26: 'Z-GX###-', //'RIXZ',
};
let TABLE_TITLES = {
    1: 'Applied Validation',
    2: 'Biofinity Architecture',
    3: 'Cell Logics',
    4: 'Disaster Recovery',
    5: 'Embedded Datamatics',
    6: 'Failure Analysis',
    7: 'Geoframeworking',
    8: 'Human Factors',
    9: 'Illocution Processing',
    10: 'Juice Platforming ',
    11: 'Ketogenesis Validation',
    12: 'Life Cycle Metrics',
    13: 'Machine Evangelism',
    14: 'Natural Language Illocution',
    15: 'Orange Mandarin Visioning',
    16: 'Physiology Analytics',
    17: 'Quartermaster Research',
    18: 'Retrieval Environments',
    19: 'Substance Restriction',
    20: 'Thin Film Interface',
    21: 'UX Sculpting',
    22: 'Vibration & Noise',
    23: 'Wagonette Rendering',
    24: 'Xylographics',
    25: 'Yellowback Algoretrieval',
    26: 'Zebra Genomics',
};

let PING_INTERVAL = 1000;
let PING_TIMEOUT = 3000;
var pingStartTime = null;

let WATCHDOG_INTERVAL = 5000;
let NTP_TIMEOUT = 180000; // 3 minutes
let OSC_TIMEOUT = 15000;
var lastNTPReset = Date.now();
var lastOSCReset = Date.now();

let PAST_OFFSETS_COUNT = 20;
var pastClockOffsets = [];
var clockOffset = 0;
var clockInfo = null;
var lastNTP = 0;
var lastOSCPing = 0;

var currentCueTime = null;
var nextCueTimeout = null;
var currentPreload = null;
var currentVolume = -1;
var currentAssetsStr = '';

var nowPlaying = {};

let BATTERY_INTERVAL = 60000;
var batteryPercent = -2;

var currentSequence = null;

document.addEventListener("DOMContentLoaded", event => {
    let isIndexPage = document.getElementById('tablettes-index');
    if (!isIndexPage) return;

    document.body.classList.add('tablet');

    document.getElementById('reload-button').addEventListener('click', function () {
        location.reload();
    });

    let version = document.getElementById('version');
    version.innerText = BUILD_NAME;

    document.getElementById('dupe-tablet-warning__number').innerText = TABLET_NUMBER;

    setInterval(sendPing, PING_INTERVAL);
    //setInterval(cueTick, 100);
    setInterval(watchdog, WATCHDOG_INTERVAL);
    sendPing();

    setInterval(updateBatteryStatus, BATTERY_INTERVAL);
    updateBatteryStatus();

    preShowInit();
});


// PreShow.reset will be set to function that resets its state. Kind of a silly way to expose the reset method to the outside world, but this is quickest way without refactoring preShowInit.
let PreShow = {};

function preShowInit() {
    var params;

    let preShow = document.getElementById('tablettes-pre-show');
    let dataEntry = document.getElementById('pre-show-data-entry');
    let loginForm = document.getElementById('login-form');
    let tableLetter = document.getElementById('table-letter-input');
    let loginID = document.getElementById('login-id-input');
    let loginContinue = document.getElementById('login-continue-button')
    let teamBondingPanel = document.getElementById('team-bonding-panel');
    let teamBondingFeedback = document.getElementById('team-bonding-feedback');
    let agePanel = document.getElementById('age-button-panel');
    let drinkMenu = document.getElementById('drink-menu');
    let optOutButton = document.getElementById('opt-out-button');
    let optInButton = document.getElementById('opt-in-button');
    let popup = document.getElementById('consent-popup');
    let thankYou = document.getElementById('pre-show-thank-you');

    document.getElementById('employee-id-prefix').innerText = EMPLOYEE_ID_PREFIXES[TABLET_NUMBER] || '-XXXXX-';
    document.getElementById('pre-show-table-title').innerText = ''; //TABLE_TITLES[TABLET_NUMBER] || '';
    if (IS_LOBBY) {
        document.getElementById('pre-show-checkin-prompt').style.display = 'none';
    } else {
        tableLetter.style.display = 'none';
    }

    preShow.addEventListener('click', event => {
        if (dataEntry.style.display === 'block') return;

        params = new URLSearchParams();
        dataEntry.style.display = 'block';
        if (IS_LOBBY) {
            tableLetter.focus();
        } else {
            loginID.focus();
        }
    });
    tableLetter.addEventListener('input', event => {
        if (tableLetter.value.length === 1) {
            tableLetter.value = tableLetter.value.toUpperCase();
            loginID.focus();
        }
    });
    loginID.addEventListener('input', () => {
        let valid = loginID.value.trim().length >= 1;
        loginContinue.disabled = !valid;
    });
    loginID.addEventListener('keydown', event => {
        //log("got keydown " + event.keyCode);
        if (event.keyCode === 9) {
            loginContinueClicked(event);
        }
    });
    loginForm.addEventListener('submit', loginContinueClicked);
    function loginContinueClicked(event) {
        event.preventDefault();
        loginID.blur();
        if (IS_LOBBY) {
            agePanel.style.display = 'block';
        } else {
            teamBondingPanel.style.display = 'block';
        }
    }
    document.getElementById('not-21-button').addEventListener('click', () => {
        params.set('age_21', 'N');
        drinkMenu.style.display = 'block';
        drinkMenu.querySelectorAll('.alcoholic').forEach(button => button.disabled = true);
    });
    document.getElementById('yes-21-button').addEventListener('click', () => {
        params.set('age_21', 'Y');
        drinkMenu.style.display = 'block';
        drinkMenu.querySelectorAll('.alcoholic').forEach(button => button.disabled = false);
    });
    drinkMenu.querySelectorAll('button').forEach(button => {
        button.addEventListener('click', () => {
            params.set('drink', button.innerText);
            showConsentPopup();
        });
    });
    teamBondingPanel.querySelectorAll('button').forEach(button => {
        button.addEventListener('click', () => {
            layNativeInterface.hideChrome();
            teamBondingFeedback.style.display = 'block';
            setTimeout(() => {
                preShow.style.opacity = 0;
            }, 3000);
            setTimeout(reset, 4000);
        });
    });
    
    function showConsentPopup() {
        popup.style.display = 'block';
        layNativeInterface.hideChrome();
    }

    optOutButton.addEventListener('click', () => {
        event.stopPropagation();
        params.set('opt', 'N');
        submit();
    });
    optInButton.addEventListener('click', event => {
        event.stopPropagation();
        params.set('opt', 'Y');
        submit();
    });

    function submit() {
        optInButton.disabled = true;
        optOutButton.disabled = true;

        params.set('tablet', TABLET_NUMBER);
        params.set('table', tableLetter.value);
        params.set('login_id', loginID.value);
        fetch('/tablettes/update_patron.json', {method: 'POST', body: params})
        .then(response => {
            return response.json();
        })
        .then(json => {
            if (json.error) throw json.error;
            else sing();
        })
        .catch(error => {
            log("login submit error: ", error);
            alert("Please double check your Employee ID number and try again.");
            // native alert brings up the back button so hide it again.
            layNativeInterface.hideChrome();
            reset();
        });
    }

    function sing() {
        // TODO: get real videos
        if (params.get('opt') === 'Y') {
            layNativeInterface.setVideoCue('/playback/media_tablets/000-Preshow/thank-you-placeholder.mp4', serverNow() + 1000, 0);
            setTimeout(() => {
                thankYou.style.opacity = 1;
                preShow.style.opacity = 0;
            }, 1000);
            setTimeout(() => {
                //layNativeInterface.setVideoCue(null, 0, 0);
                reset();
            }, 5000);
        } else {
            // A sadface video for opt-outs?
            reset();
        }
    }

    function reset() {
        preShow.style.opacity = 1
        thankYou.style.opacity = 0;
        optInButton.disabled = false;
        optOutButton.disabled = false;
        popup.style.display = 'none';
        dataEntry.style.display = 'none';
        agePanel.style.display = 'none';
        drinkMenu.style.display = 'none';
        teamBondingPanel.style.display = 'none';
        teamBondingFeedback.style.display = 'none';
        tableLetter.value = '';
        loginID.value = '';
        loginContinue.disabled = true;
        document.getElementById('consent-popup-box').scrollTop = 0;
        layNativeInterface.hideChrome();
        layNativeInterface.setScreenBrightness(1);
    }

    PreShow.reset = reset;
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
    body.append('tablet_number', TABLET_NUMBER);
    body.append('build', BUILD_NAME);
    body.append('now_playing_path', nowPlaying.path);
    body.append('clock_info', clockInfo || '');
    body.append('last_ntp', lastNTP);
    body.append('osc_ping', lastOSCPing);
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
        } else if (endTime - startTime > 500) {
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
            handleCommand(cmd[0], cmd.slice(1));
        });

        if (currentVolume !== json.volume) {
            currentVolume = json.volume;
            layNativeInterface.setVolume(json.volume);
        }

        let newAssetsStr = json.assets.map(a => a.path + ';' + a.mod_date).join("\n");
        if (newAssetsStr && currentAssetsStr !== newAssetsStr) {
            console.log("assets changed:\n" + newAssetsStr);
            currentAssetsStr = newAssetsStr;
            layNativeInterface.setAssets(newAssetsStr);
        }

        document.getElementById('tablet-id').innerText = "Tablet #" + json.tablet_number + " Group #" + json.tablet_group + " — " + json.tablet_ip;
        document.getElementById('tablettes-debug').classList.toggle('visible', json.debug);
        document.getElementById('dupe-tablet-warning').classList.toggle('visible', json.dupe);
        
        setShowTime(json.show_time, json.preshow_bg);

        pingStartTime = null;
    })
    .catch(error => {
        log("ping failed", error);
        pingStartTime = null;
    });
}

function setShowTime(showTime, bgImage) {
    let preShow = document.getElementById('tablettes-pre-show');
    let preShowVisible = preShow.classList.contains('visible');
    if (showTime) {
        if (preShowVisible) {
            layNativeInterface.hideChrome();
        }
        preShow.classList.remove('visible');
    } else {
        if (!preShowVisible) {
            PreShow.reset();
        }
        preShow.classList.add('visible');
        if (bgImage) {
            preShow.style.backgroundImage = 'url(' + bgImage + ')';
        }
    }
}

function watchdog() {
    let now = Date.now();
    if (now - lastNTP > NTP_TIMEOUT && now - lastNTPReset > NTP_TIMEOUT) {
        console.log("NTP appears to be stalled; resetting");
        lastNTPReset = now;
        layNativeInterface.resetNTP();
    }
    if (now - lastOSCPing > OSC_TIMEOUT && now - lastOSCReset > OSC_TIMEOUT) {
        console.log("OSC appears to be stalled; resetting");
        lastOSCReset = now;
        layNativeInterface.resetOSC();
    }
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
    let text = Array.prototype.join.call(arguments, ' ');
    console.log(text);
    let status = document.getElementById('status');
    status.innerText = text;
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

function triggerSequence(constructor, args) {
    //stop(); // don't do this because server sends a stop command when necessary, and for geek trio we need next set of images to be sequenced while previous one is still finishing.
    args.unshift(constructor);
    currentSequence = new (constructor.bind.apply(constructor, args));
}

function stop() {
    if (currentSequence) currentSequence.stop();

    let preShow = document.getElementById('tablettes-pre-show');
    let debug = document.getElementById('tablettes-debug');
    if (preShow.classList.contains('visible')) {
        PreShow.reset();
    } else if (debug.classList.contains('visible')) {
        layNativeInterface.setScreenBrightness(0.2);
    }
}

function Ghosting(time, duration, srcs) {
    let delay = time - serverNow();
    let div = document.createElement('div');
    div.setAttribute('id', 'ghosting');
    div.classList.add('ghosting-preroll');
    srcs.forEach((src) => {
        let i = new Image(180, 180);
        i.src = src;
        div.appendChild(i);
    });
    document.body.appendChild(div);

    this.prerollTimeout = setTimeout(() => {
            div.classList.remove('ghosting-preroll');
            //let rect = div.getBoundingClientRect();
            //log("ghosting rect " + rect.left + ", " + rect.top + ", " + rect.right + ", " + rect.bottom);
            setTimeout(() => {
                    div.classList.add('ghosting-fadeout');
                    div.addEventListener('transitionend', removeDiv);
                },
                duration
            );
        },
        delay
    );

    this.stop = function () {
        clearTimeout(this.prerollTimeout);
        removeDiv();
    };

    function removeDiv() {
        if (div.parentNode === document.body) {
            document.body.removeChild(div);
            div.removeEventListener('transitionend', removeDiv);
        }
    }
}

function GeekTrio(start_time, interval, duration, images) {
    log("GeekTrio starting in " + (start_time - serverNow()) + " ms");

    let div = document.createElement('div');
    div.classList.add('geek-trio-set');
    document.body.appendChild(div);

    images.forEach((src, i) => {
        let img = document.createElement('img');
        img.src = src;
        img.style.transitionDelay = (i * interval) + 'ms';
        div.appendChild(img);
    });

    let timeout = setTimeout(() => {
        div.classList.add('geek-trio-set--active');
    }, start_time - serverNow());

    setTimeout(() => {
        div.classList.add('geek-trio-set--fade-out');
        div.addEventListener('transitionend', () => this.stop());
    }, start_time + duration - serverNow());

    this.stop = function () {
        if (div.parentNode === document.body) {
            document.body.removeChild(div);
        }
        clearTimeout(timeout);
    };
}

// "low motion" variation of exterminator: just show one image with conclusion text.
// params: in_time, conclusion_time, [out_time OR fade_out_time], src, conclusion
function ExterminatorLite(params) {
    log("ExterminatorLite starting in " + (params.in_time - serverNow()) + " ms");

    let div = document.createElement('div');
    div.classList.add('exterminator-lite');
    document.body.appendChild(div);

    // The initial "Grouping…" bit doesn't have an image
    var img;
    if (params.src) {
        img = document.createElement('div');
        img.classList.add('img');
        img.style.backgroundImage = 'url(' + params.src + ')';
        div.appendChild(img);
    }

    let titleOuter = document.createElement('div');
    titleOuter.classList.add('category-title');
    div.appendChild(titleOuter);
    let titleInner = document.createElement('div');
    titleInner.innerText = params.title;
    titleOuter.appendChild(titleInner);

    // The initial "Grouping…" bit doesn't have an assessment
    if (params.conclusion) {
        let assessmentOuter = document.createElement('div');
        assessmentOuter.classList.add('assessment');
        div.appendChild(assessmentOuter);
        let assessmentInner = document.createElement('div');
        assessmentInner.innerText = 'assessment:';
        assessmentOuter.appendChild(assessmentInner);

        let conclusionOuter = document.createElement('div');
        conclusionOuter.classList.add('conclusion');
        div.appendChild(conclusionOuter);
        let conclusionInner = document.createElement('div');
        conclusionInner.innerText = params.conclusion;
        conclusionOuter.appendChild(conclusionInner);

        setTimeout(() => {
            div.classList.add('exterminator-lite--conclusion');
        }, params.conclusion_time - serverNow());
    }

    setTimeout(() => {
        div.classList.add('exterminator-lite--in');
    }, params.in_time - serverNow());

    if (params.out_time) {
        setTimeout(() => {
            div.classList.add('exterminator-lite--out');
            img.addEventListener('transitionend', () => this.stop());
        }, params.out_time - serverNow());
    } else {
        setTimeout(() => {
            div.classList.add('exterminator-lite--fade-out');
            div.addEventListener('transitionend', () => this.stop());
        }, params.fade_out_time - serverNow());
    }

    this.stop = function () {
        if (div.parentNode === document.body) {
            document.body.removeChild(div);
        }
    };
}

function OffTheRails(items) {
    log("OffTheRails start with " + items.length + " feed items");

    let div = document.createElement('div');
    div.setAttribute('id', 'offtherails');
    document.body.appendChild(div);

    let count = 2; // on screen at a time
    var i = 0;
    for (var j = 0; j < count; j++) {
        triggerOneItem(j * 25); // seconds before triggering, based on preading them out with each one taking 30-60s to complete
    }

    function triggerOneItem(delay) {
        if (div.parentNode !== document.body) {
            log("offtherails not in dom; skipping item");
            return;
        }

        if (i >= items.length) i = 0;
        let item = items[i++];

        let container = document.createElement('div');
        if (item.tweet) {
            container.classList.add('tweet');

            let img = document.createElement('img');
            img.src = item.profile_img;
            container.appendChild(img);

            let p = document.createElement('p');
            p.innerText = item.tweet;
            container.appendChild(p);
        } else if (item.photo) {
            container.classList.add('photo');

            let img = document.createElement('img');
            img.src = item.photo;
            container.appendChild(img);
        } else {
            log("unknown OTR item format");
        }
        let depth = Math.floor(2 * Math.random());
        container.classList.add('depth-' + depth);
        delay = 1000 * (delay || 0);
        container.style.animationDelay = delay + 'ms';
        container.style.left = Math.round(200 * Math.random() - 50) + 'px';
        div.appendChild(container);
        container.addEventListener('animationend', () => {
            if (container.parentNode === div) {
                div.removeChild(container);
                triggerOneItem();
            }
        });
    }

    this.stopTimeout = setTimeout(() => this.stop(), 200000); // 3m20s

    this.stop = function () {
        if (div.parentNode === document.body) {
            document.body.removeChild(div);
        }
        clearTimeout(this.stopTimeout);
    };
}

function ProductLaunch(images, targetXTime) {
    let div = document.createElement('div');
    div.setAttribute('id', 'product-launch');
    document.body.appendChild(div);

    let targetX = document.createElement('div');
    targetX.classList.add('target-x');
    div.appendChild(targetX);

    var imgTimeout = null;
    var prevSpec = null;
    var prevImg = null;

    let targetXTimeout = setTimeout(() => {
        div.classList.add('show-target-x');
    }, targetXTime - serverNow());

    queueNextImage();

    function queueNextImage() {
        var spec = images.shift();
        if (!spec) {
            div.classList.add('final-fade-out');
            setTimeout(removeDiv, 2000); // wait for last image to fade out before removing.
            return;
        }

        var img = document.createElement('img');
        img.src = spec.src;
        img.classList.add(spec.position);
        div.appendChild(img);

        imgTimeout = setTimeout(() => {
            if (!prevSpec || prevSpec.position !== spec.position) {
                img.classList.add('fade-in');
                animateImgOut(prevImg, 'fade-out');
            } else {
                img.classList.add('slide-in');
                animateImgOut(prevImg, 'slide-out');
            }

            if (spec.out_time) {
                setTimeout(() => {
                    animateImgOut(img, 'fade-out');
                    prevImg = null;
                    prevSpec = null;
                    queueNextImage();
                }, spec.out_time - serverNow());
            } else {
                prevSpec = spec;
                prevImg = img;
                queueNextImage();
            }
        }, spec.in_time - serverNow())
    }

    this.stop = function () {
        clearTimeout(imgTimeout);
        clearTimeout(targetXTimeout);
        removeDiv();
    };

    function removeDiv() {
        if (div.parentNode === document.body) {
            document.body.removeChild(div);
        }
    }

    function animateImgOut(img, animation) {
        if (!img) return;
        img.classList.remove('fade-in');
        img.classList.remove('slide-in');
        img.classList.add(animation);
    }
}

function updateBatteryStatus() {
    batteryPercent = layNativeInterface.getBatteryPercent();
    document.getElementById('battery-level').innerText = batteryPercent + '%';
}

function handleCommand(cmd, args) {
    log('Last command: ' + cmd + ' - ' + args.join(', '));
    switch (cmd) {
        case 'clear_cache':
            layNativeInterface.setAssets(null);
            break;
        case 'reset_osc':
            layNativeInterface.resetOSC();
            break;
        case 'reload':
            location.reload();
            break;
        case 'stop':
            stop();
            break;
        case 'ghosting':
            triggerSequence(Ghosting, args);
            break;
        case 'geektrio':
            triggerSequence(GeekTrio, args);
            break;
        case 'exterminator_lite':
            triggerSequence(ExterminatorLite, args);
            break;
        case 'offtherails':
            triggerSequence(OffTheRails, args);
            break;
        case 'productlaunch':
            triggerSequence(ProductLaunch, args);
            break;
        default:
            log('unknown command: ' + cmd);
    }
}
window.handleCommand = handleCommand;

})();

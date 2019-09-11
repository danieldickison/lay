// jshint esversion: 6
// jshint browser: true

(() => {
'use strict';

let STATS_INTERVAL = 250;
let PING_ALERT = 10000;

var messagesDiv;
var serverError, prevServerError = null;
var buttonMsg, prevButtonMsg = null;

document.addEventListener("DOMContentLoaded", event => {
    messagesDiv = document.getElementById('director-messages');
    if (!messagesDiv) return;

    function addButton(letter) {
        document.getElementById('button-' + letter).addEventListener('click', event => {
            event.preventDefault();
            fetch('/tablettes/button_' + letter + '.json', {method: 'POST'})
            .then(response => {
                return response.json();
            })
            .then(json => {
                updateButtons(json.buttons);
            })
            .catch(err => {
                alert(err);
            });
        });
    }

    addButton('a');
    addButton('b');
    addButton('c');
    addButton('d');
    addButton('clear');

    document.getElementById('toggle-deets-link').addEventListener('click', event => {
        event.preventDefault();
        document.getElementById('director-deets').classList.toggle('director-deets--show');
    });

    let assetsForm = document.getElementById('assets-form');
    assetsForm.addEventListener('submit', event => {
        event.preventDefault();
        let assets = assetsForm.elements.assets.value;
        let body = new URLSearchParams();
        body.append('assets', assets);
        fetch('/tablettes/assets.json', {method: 'POST', body: body});
    });

    document.getElementById('play-timecode-button').addEventListener('click', event => {
        event.preventDefault();
        fetch('/tablettes/play_timecode.json', {method: 'POST'});
    });

    document.getElementById('stop-tablets-button').addEventListener('click', event => {
        event.preventDefault();
        fetch('/tablettes/stop_cue.json', {method: 'POST'});
    });

    document.getElementById('reload-tablets-button').addEventListener('click', event => {
        event.preventDefault();
        queueTabletCommand('reload');
    });

    let cueForm = document.getElementById('cue-form');
    cueForm.addEventListener('submit', event => {
        event.preventDefault();
        let cue = cueForm.elements.cue.value;
        let body = new URLSearchParams();
        body.append('cue', cue);
        fetch('/tablettes/start_cue.json', {method: 'POST', body: body});
    });

    document.querySelectorAll('[name="director-pre-show-radio"]').forEach(el => {
        el.addEventListener('change', event => {
            let body = new URLSearchParams();
            body.append('show_time', el.value);
            fetch('/tablettes/set_show_time', {method: 'POST', body: body});
        });
    });

    document.getElementById('performance-select').addEventListener('change', event => {
        console.log("performance-select event target:", event.target);
        event.target.disabled = true;
        let body = new URLSearchParams();
        body.append('performance_number', event.target.value);
        fetch('/tablettes/set_current_performance.json', {method: 'POST', body: body})
            .then(response => {
                if (!response.ok) {
                    alert("failed to set performance: status " + response.status);
                }
            })
            .catch(() => alert("failed to set performance due to network error"))
            .finally(() => event.target.disabled = false);
    });

    setInterval(fetchStats, STATS_INTERVAL);
});

function queueTabletCommand(command, oscMessage) {
    let body = new URLSearchParams();
    body.append('command', command);
    if (oscMessage) {
        body.append('osc_message', oscMessage);
    }
    fetch('/tablettes/queue_tablet_command.json', {method: 'POST', body: body});
}

function updateButton(buttons, letter) {
    let check = document.getElementById('button-' + letter + '-check');
    let button = document.getElementById('button-' + letter);
    let ch = buttons[letter];

    check.innerHTML = ch;

    if (ch == "!") {
        check.classList.add('warn');
        button.classList.add('warn');

        check.classList.remove('done');
        button.classList.remove('done');
    } else if (ch == "✓") {
        check.classList.add('done');
        button.classList.add('done');

        check.classList.remove('warn');
        button.classList.remove('warn');
    } else {
        check.classList.remove('done');
        button.classList.remove('done');
        check.classList.remove('warn');
        button.classList.remove('warn');
    }
}

function updateButtons(buttons) {
    updateButton(buttons, 'a');
    updateButton(buttons, 'b');
    updateButton(buttons, 'c');
    updateButton(buttons, 'd');
    buttonMsg = buttons.msg;
}

function fetchStats() {
    let body = new URLSearchParams();
    body.append('volume', document.getElementById('volume-input').value);
    body.append('debug', document.getElementById('debug-checkbox').checked ? '1' : '0');
    fetch('/tablettes/stats.json', {method: 'POST', body: body})
    .then(response => {
        return response.json();
    })
    .then(json => {
        if (!json) throw "response json is null";
        if (!json.tablets) throw "response json missing tablets key";

        serverError = null;

        updateButtons(json.buttons);

        document.getElementById('pre-show-radio').checked = !json.show_time;
        document.getElementById('show-time-radio').checked = json.show_time;

        document.getElementById('performance-select').value = json.performance_number;

        let table = document.getElementById('tablet-stats');
        let oldTbody = document.getElementById('tablet-stats-body');
        if (oldTbody) table.removeChild(oldTbody);

        let tbody = document.createElement('tbody');
        tbody.setAttribute('id', 'tablet-stats-body');
        json.tablets.forEach(tablet => {
            let isLagging = parseInt(tablet.ping) > PING_ALERT;
            let isOSCLagging = parseInt(tablet.osc_ping) > PING_ALERT;
            let tr = document.createElement('tr');
            tr.appendChild(td(tablet.id + ' ' + String.fromCharCode('A'.charCodeAt(0) + tablet.id - 1) + (tablet.dupe ?  ' DUPE' : ''), tablet.dupe ? 'red' : null));
            // tr.appendChild(td(tablet.group || ''));
            tr.appendChild(td(tablet.ip || 'missing', !tablet.ip ? 'red' : null));
            tr.appendChild(td(tablet.build || ''));
            tr.appendChild(td(formatPing(tablet.ping), isLagging ? 'red' : null));
            tr.appendChild(td(formatPing(tablet.osc_ping), isOSCLagging ? 'red' : null));
            tr.appendChild(td(tablet.battery !== null ? tablet.battery + '%' : '', tablet.battery < 10 ? 'red' : tablet.battery < 20 ? 'orange' : null));
            tr.appendChild(td(tablet.clock && tablet.clock.median !== undefined ? tablet.clock.median + ' ms' : ''));
            tr.appendChild(td(tablet.clock && tablet.clock.stdev !== undefined ? tablet.clock.stdev + ' ms' : '', 
               table.clock && tablet.clock.stdev > 1000 ? 'orange' : null));

            let cacheIncomplete = tablet.cache && tablet.cache.some(f => !f.end);
            let cacheComplete = tablet.cache && tablet.cache.filter(f => f.end).length;
            let cacheTD = td(tablet.cache ? cacheComplete + '/' + tablet.cache.length : '', cacheIncomplete ? 'orange' : null);
            cacheTD.classList.add('cache');
            tr.appendChild(cacheTD);
            buildCacheHover(cacheTD, tablet.cache)

            tr.appendChild(td(tablet.playing));

            tbody.appendChild(tr);
        });
        table.appendChild(tbody);
    })
    .catch(err => {
        console.log("server error:", err);
        serverError = "" + err;
    })
    .finally(updateMessages);

    function formatPing(ping) {
        if (ping === null || ping === undefined) {
            return '';
        } else if (ping > 3600000) {
            return '>1 hour';
        } else if (ping > 60000) {
            return Math.floor(ping / 60000) + ' min';
        } else {
            return (ping / 1000).toFixed(1) + ' s';
        }
    }

    function td(text, color) {
        let td = document.createElement('td');
        td.append(text);
        if (color) {
            td.style.color = color;
        }
        return td;
    }

    function buildCacheHover(td, cache) {
        if (!cache || cache.length === 0) {
            // debug
            cache = [
                {path: "/lay/test/done", start: Date.now()/1000 - 10, end: Date.now()/1000, error: null},
                {path: "/lay/test/dling", start: Date.now()/1000 - 3, end: null, error: null},
                {path: "/lay/test/error", start: Date.now()/1000 - 60, end: null, error: "This is some error message"},
            ];
        }

        cache.sort((a, b) => a.path.localeCompare(b.path));

        let ul = document.createElement('ul');
        ul.classList.add('cache-info');
        cache.forEach(function (c) {
            let li = document.createElement('li');
            var str = c.path + " " + Math.round(0.000001 * (c.size || 0)) + "MB";
            if (c.error) {
                str += " failed: " + c.error;
            } else if (c.end && c.end !== c.start) {
                str += " (" + Math.round(0.001*(c.end - c.start)) + "s)";
            } else if (!c.end) {
                str += " (…)";
            }
            li.innerText = str;
            ul.appendChild(li);
        });
        td.appendChild(ul);
    }


    function updateMessages() {
        var ps = [], i, diff, update = false;

        if (prevServerError !== serverError) {
            if (serverError) {
                let p = document.createElement('p');
                p.classList.add('warning');
                p.innerText = "Restart playback server!";
                ps.push(p);
            }
            prevServerError = serverError;
            update = true;
        }


        diff = true;
        if (Array.isArray(prevButtonMsg) && Array.isArray(buttonMsg)) {
            if (prevButtonMsg.length == buttonMsg.length) {
                diff = false;
                for (i = 0; i < buttonMsg.length; ++i) {
                    if (buttonMsg[i] != prevButtonMsg[i]) {
                        diff = true;
                        break;
                    }
                }
            }
        }

        if (diff) {
            if (buttonMsg) {
                for (i = 0; i < buttonMsg.length; ++i) {
                    let p = document.createElement('p');
                    p.classList.add('warning');
                    p.innerText = buttonMsg[i];
                    ps.push(p);
                }
            }
            prevButtonMsg = buttonMsg;
            update = true;
        }


        if (update) {
            messagesDiv.innerHTML = '';
            if (ps.length == 0) {
                messagesDiv.style.display = "none";
            } else {
                messagesDiv.style.display = "block";           
                for (i = 0; i < ps.length; ++i) {
                    messagesDiv.appendChild(ps[i]);
                }
            }
        }
    }
}
})();

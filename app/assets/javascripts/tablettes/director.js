// jshint esversion: 6
// jshint browser: true

(() => {
'use strict';

let STATS_INTERVAL = 1000;
let PING_ALERT = 10000;

document.addEventListener("DOMContentLoaded", event => {
    let assetsForm = document.getElementById('assets-form');
    if (!assetsForm) return;

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
        queueTabletCommand('stop', '/tablet/stop');
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

function fetchStats() {
    fetch('/tablettes/stats.json', {method: 'POST'})
    .then(response => {
        return response.json();
    })
    .then(json => {
        if (!json) return;
        if (!json.tablets) return;

        let table = document.getElementById('tablet-stats');
        let oldTbody = document.getElementById('tablet-stats-body');
        if (oldTbody) table.removeChild(oldTbody);

        let tbody = document.createElement('tbody');
        tbody.setAttribute('id', 'tablet-stats-body');
        json.tablets.forEach(tablet => {
            let isLagging = parseInt(tablet.ping) > PING_ALERT;
            let isOSCLagging = parseInt(tablet.osc_ping) > PING_ALERT;
            if (isLagging || isOSCLagging) {
                console.log("tablet " + tablet.id + " is lagging http: " + tablet.ping + "ms" + " osc: " + tablet.osc_ping, tablet);
            }
            let tr = document.createElement('tr');
            tr.appendChild(td(tablet.id));
            tr.appendChild(td(tablet.group));
            tr.appendChild(td(tablet.ip));
            tr.appendChild(td(tablet.build));
            tr.appendChild(td(tablet.ping + ' ms', isLagging ? 'red' : null));
            tr.appendChild(td(tablet.osc_ping + ' ms', isOSCLagging ? 'red' : null));
            tr.appendChild(td(tablet.battery + '%'));
            tr.appendChild(td(tablet.clock && tablet.clock.median + ' ms'));
            tr.appendChild(td(tablet.clock && tablet.clock.stdev + ' ms'));

            let cacheIncomplete = tablet.cache && tablet.cache.some(f => !f.end);
            let cacheTD = td(tablet.cache && tablet.cache.length, cacheIncomplete ? 'orange' : null);
            cacheTD.classList.add('cache');
            tr.appendChild(cacheTD);
            buildCacheHover(cacheTD, tablet.cache)

            tr.appendChild(td(tablet.playing));

            tbody.appendChild(tr);
        });
        table.appendChild(tbody);
    });

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
}
})();

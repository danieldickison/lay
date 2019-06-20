// jshint esversion: 6
// jshint browser: true

(() => {
'use strict';

let STATS_INTERVAL = 1000;
let PING_ALERT = 10000;

document.addEventListener("DOMContentLoaded", event => {
    let cueForm = document.getElementById('cue-form');
    if (!cueForm) return;

    cueForm.addEventListener('submit', event => {
        event.preventDefault();
        let tablet = parseInt(cueForm.elements.tablet.value);
        let seconds = parseInt(cueForm.elements.seconds.value);
        let time = Date.now() + seconds * 1000;
        cueForm.elements.time.value = new Date(time).toString();
        let body = new URLSearchParams();
        body.append('tablet', tablet);
        body.append('time', time);
        body.append('file', cueForm.elements.file.value);
        body.append('seek', cueForm.elements.seek.value);
        fetch('/tablettes/cue.json', {method: 'POST', body: body});
    });

    let assetsForm = document.getElementById('assets-form');
    assetsForm.addEventListener('submit', event => {
        event.preventDefault();
        let assets = assetsForm.elements.assets.value;
        let body = new URLSearchParams();
        body.append('assets', assets);
        fetch('/tablettes/assets.json', {method: 'POST', body: body});
    });

    setInterval(fetchStats, STATS_INTERVAL);
});

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
            if (isLagging) {
                console.log("tablet " + tablet.tablet + " is lagging by " + tablet.ping + "ms", tablet);
            }
            let tr = document.createElement('tr');
            tr.appendChild(td(tablet.id));
            tr.appendChild(td(tablet.ip));
            tr.appendChild(td(tablet.build));
            tr.appendChild(td(tablet.ping + 'ms', isLagging ? 'red' : null));
            tr.appendChild(td(tablet.battery + '%'));
            tr.appendChild(td(tablet.clock && tablet.clock.median + 'ms'));
            tr.appendChild(td(tablet.clock && tablet.clock.latest + 'ms'));
            tr.appendChild(td(tablet.clock && tablet.clock.timeSince + 'ms'));

            let cacheTD = td(tablet.cache && tablet.cache.length);
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

        let ul = document.createElement('ul');
        ul.classList.add('cache-info');
        cache.forEach(function (c) {
            let li = document.createElement('li');
            li.innerText = c.path +
                (c.error ? " failed: " + c.error : c.end ? " (" + Math.round(0.001*(c.end - c.start)) + "s)" : " (…)");
            ul.appendChild(li);
        });
        td.appendChild(ul);
    }
}
})();

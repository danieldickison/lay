// jshint esversion: 6
// jshint browser: true

(() => {
'use strict';

let STATS_INTERVAL = 1000;

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

    let preloadForm = document.getElementById('preload-form');
    preloadForm.addEventListener('submit', event => {
        event.preventDefault();
        let tablet = parseInt(preloadForm.elements.tablet.value);
        let files = preloadForm.elements.files.value;
        let body = new URLSearchParams();
        body.append('tablet', tablet);
        body.append('files', files);
        fetch('/tablettes/preload.json', {method: 'POST', body: body});
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
            let tr = document.createElement('tr');
            tr.appendChild(td(tablet.tablet));
            tr.appendChild(td(tablet.ping + ' ms'));
            tr.appendChild(td(tablet.battery + '%'));
            tr.appendChild(td(tablet.clock && tablet.clock.median + ' ms'));
            tr.appendChild(td(tablet.clock && tablet.clock.latest + ' ms'));
            tr.appendChild(td(tablet.clock && tablet.clock.timeSince + ' ms'));
            tr.appendChild(td(tablet.cache && tablet.cache.length));
            tr.appendChild(td(tablet.playing));
            tbody.appendChild(tr);
        });
        table.appendChild(tbody);
    });

    function td(text) {
        let td = document.createElement('td');
        td.append(text);
        return td;
    }
}
})();

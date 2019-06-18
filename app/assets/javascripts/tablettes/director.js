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
            let isLagging = parseInt(tablet.ping) > 1000;
            if (isLagging) {
                console.log("tablet " + tablet.tablet + " is lagging by " + tablet.ping + " ms", tablet);
            }
            let tr = document.createElement('tr');
            tr.appendChild(td(tablet.tablet));
            tr.appendChild(td(tablet.ping + ' ms', isLagging ? 'red' : null));
            tr.appendChild(td(tablet.battery + '%'));
            tr.appendChild(td(tablet.clock && tablet.clock.median + ' ms'));
            tr.appendChild(td(tablet.clock && tablet.clock.latest + ' ms'));
            tr.appendChild(td(tablet.clock && tablet.clock.timeSince + ' ms'));

            let cacheTD = td(tablet.cache && tablet.cache.length);
            cacheTD.classList.add('cache');
            tr.appendChild(cacheTD);
            if (tablet.cache) {
                buildCacheHover(cacheTD, tablet.cache)
            }

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
        if (!cache) return;

        let ul = document.createElement('ul');
        ul.classList.add('cache-info');
        cache.forEach(function (c) {
            let li = document.createElement('li');
            li.innerText = c.path + (c.error ? " error: " + error : '');
            ul.appendChild(li);
        });
        td.appendChild(ul);
    }
}
})();

// jshint esversion: 6
// jshint browser: true

(() => {
'use strict';

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
});
})();

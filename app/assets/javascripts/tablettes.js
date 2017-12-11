// jshint esversion: 6
// jshint browser: true
(() => {
'use strict';

document.addEventListener("DOMContentLoaded", event => {
    let status = document.getElementById('status');
    let video = document.getElementById('tablettes-video');
    status.innerHTML = 'starting playback in 2 seconds';
    setTimeout(() => {
        status.innerHTML = 'starting playback now';
        video.play();
    }, 2000);
});

})();

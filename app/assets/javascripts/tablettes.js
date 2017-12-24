// jshint esversion: 6
// jshint browser: true

(() => {
'use strict';

let PING_INTERVAL = 1000;

document.addEventListener("DOMContentLoaded", event => {
    let status = document.getElementById('status');
    let video = document.getElementById('tablettes-video');
    sendPing();
});

function sendPing() {
    let txTime = Date.now();
    var rxTime = null;
    fetch('/tablettes/ping.json')
    .then((response) => {
        rxTime = Date.now();
        return response.json();
    })
    .then((json) => {
        let status = document.getElementById('status');
        console.log(json.rx_time());
        status.innerHTML = json.toString();
    })
    .finally(() => {
        setTimeout(sendPing, PING_INTERVAL);
    });
}

})();

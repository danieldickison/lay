// jshint esversion: 6
// jshint browser: true

(() => {
'use strict';

let SPECTATORS_INTERVAL = 2000;

$(function () {
    var view = $("#secrets-vm")[0];
    if (view)
        ko.applyBindings(new SecretsVM(view), view);
});

function SecretsVM(view) {
    var vm = this;
    var values = $(view).data('values');

    window._vm = vm;

    vm.view = view;
    vm.text = ko.observable(values.text || "");
    vm.submitable = ko.computed(function () {
        return vm.text().length > 0;
    });
    vm.spectators = new SpectatorsList([]);

    vm.submit = function () {
        alert("submitted");
    };

    fetchSpectators(vm);
}

function fetchSpectators(vm) {
    fetch('/secrets/api_fetch_spectators.json', {method: 'POST'})
    .then(response => {
        return response.json();
    })
    .then(response => {
        vm.spectators.update(response.spectators);
        // setTimeout(fetchSpectators, SPECTATORS_INTERVAL);
    })
    .catch((error) => {
        console.log("ping failed", error);
        // setTimeout(fetchSpectators, SPECTATORS_INTERVAL);
    });
}

function SpectatorsList(initial_spectators) {
    var self = this, spectatorsArray;

    self.update = function (newArray) {
        spectatorsArray(newArray);
    };

    spectatorsArray = ko.observableArray(initial_spectators);

    self.list = ko.computed(function () {
        var spectators = spectatorsArray.slice(0);
        spectators.sort(function (a, b) {
            a = a.name.toLowerCase();
            b = b.name.toLowerCase();
            return a < b ? -1 : a > b ? 1 : 0;
        });
        return spectators;
    }).extend({throttle: 1});
}

})();

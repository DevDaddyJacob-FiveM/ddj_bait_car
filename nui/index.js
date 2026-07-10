"use strict";

// Origin is https://cfx-nui-<resource>/, so derive the resource name rather
// than hard-coding it.
const RESOURCE = window.location.hostname.replace(/^cfx-nui-/, "");

const remoteEl = document.getElementById("remote");
const fobEl = document.querySelector(".fob");
const scrIndex = document.getElementById("scr-index");
const scrModel = document.getElementById("scr-model");
const scrPlate = document.getElementById("scr-plate");
const keyPower = document.querySelector('.key[data-action="power"]');
const keyDoors = document.querySelector('.key[data-action="doors"]');

function sendAction(action) {
    fetch("https://" + RESOURCE + "/baitcar:action", {
        method: "POST",
        headers: { "Content-Type": "application/json; charset=UTF-8" },
        body: JSON.stringify({ action: action })
    }).catch(function () {
        // Game script not ready; ignore.
    });
}

function open() {
    remoteEl.classList.remove("hidden");
}

function close() {
    remoteEl.classList.add("hidden");
}

function renderEmpty() {
    fobEl.classList.add("fob--disabled");
    scrIndex.textContent = "0 / 0";
    scrModel.textContent = "NO UNITS";
    scrPlate.innerHTML = "&mdash;";
    keyPower.classList.remove("key--active");
    keyDoors.classList.remove("key--active");
}

function renderStatus(msg) {
    fobEl.classList.remove("fob--disabled");

    const car = msg.car || {};
    scrIndex.textContent = (msg.index || 0) + " / " + (msg.total || 0);
    scrModel.textContent = car.model || "UNKNOWN";
    scrPlate.textContent = car.plate && car.plate.length ? car.plate : "NO PLATE";

    // POWER reflects the engine being killed; LOCKS reflects the door state.
    keyPower.classList.toggle("key--active", car.engineDisabled === true);
    keyDoors.classList.toggle("key--active", car.doorsLocked === true);
}

window.addEventListener("message", function (event) {
    const msg = event.data || {};

    switch (msg.action) {
        case "open":
            open();
            break;
        case "close":
            close();
            break;
        case "status":
            renderStatus(msg);
            break;
        case "empty":
            renderEmpty();
            break;
    }
});

// Wire every element that declares a data-action.
document.querySelectorAll("[data-action]").forEach(function (el) {
    el.addEventListener("click", function () {
        sendAction(el.getAttribute("data-action"));
    });
});

document.addEventListener("keydown", function (event) {
    if (event.key === "Escape") {
        sendAction("close");
    }
});

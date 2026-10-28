"use strict";

// Origin is https://cfx-nui-<resource>/, so derive the resource name rather
// than hard-coding it.
const RESOURCE = window.location.hostname.replace(/^cfx-nui-/, "");

const remoteElem = document.getElementById("remote");
const fobElem = document.querySelector(".fob");
const lcdIndexElem = document.getElementById("lcd-index");
const lcdModelElem = document.getElementById("lcd-model");
const lcdPlateElem = document.getElementById("lcd-plate");
const lcdRangeElem = document.getElementById("lcd-range");
const btnPowerElem = document.querySelector('.btn[data-action="power"]');
const btnDoorsElem = document.querySelector('.btn[data-action="doors"]');

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
    remoteElem.classList.remove("hidden");
}

function close() {
    remoteElem.classList.add("hidden");
}

function renderEmpty() {
    fobElem.classList.add("fob-disabled");
    fobElem.classList.remove("out-of-range");
    lcdIndexElem.textContent = "0 / 0";
    lcdModelElem.textContent = "NO UNITS";
    lcdPlateElem.innerHTML = "&mdash;";
    lcdRangeElem.classList.add("hidden");
    btnPowerElem.classList.remove("btn-active");
    btnDoorsElem.classList.remove("btn-active");
}

function renderStatus(msg) {
    fobElem.classList.remove("fob-disabled");

    const car = msg.car || {};
    lcdIndexElem.textContent = (msg.index || 0) + " / " + (msg.total || 0);
    lcdModelElem.textContent = car.model || "UNKNOWN";
    lcdPlateElem.textContent = car.plate && car.plate.length ? car.plate : "NO PLATE";

    // POWER reflects the engine being killed; LOCKS reflects the door state.
    btnPowerElem.classList.toggle("btn-active", car.engineDisabled === true);
    btnDoorsElem.classList.toggle("btn-active", car.doorsLocked === true);

    // Out of range: keep the unit on screen but lock its controls and flag
    // the readout red until the operator is back within range.
    const outOfRange = car.inRange === false;
    fobElem.classList.toggle("out-of-range", outOfRange);
    lcdRangeElem.classList.toggle("hidden", !outOfRange);
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

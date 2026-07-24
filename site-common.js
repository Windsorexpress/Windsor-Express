(function () {
  "use strict";

  var CONSENT_KEY = "we_cookie_consent";
  var ANALYTICS_ID = "G-3ZJFVJ5NDH";
  // Static landing-page links can call gtag safely even when analytics is rejected.
  window.gtag = window.gtag || function () {};

  function getChoice() {
    try {
      return window.localStorage.getItem(CONSENT_KEY);
    } catch (error) {
      return null;
    }
  }

  function saveChoice(choice) {
    try {
      window.localStorage.setItem(CONSENT_KEY, choice);
    } catch (error) {
      // The banner still closes when storage is unavailable.
    }
  }

  function loadAnalytics() {
    if (window.__windsorAnalyticsLoaded) return;
    window.__windsorAnalyticsLoaded = true;
    window.dataLayer = window.dataLayer || [];
    window.gtag = function () { window.dataLayer.push(arguments); };
    window.gtag("js", new Date());
    window.gtag("config", ANALYTICS_ID, { anonymize_ip: true });

    var script = document.createElement("script");
    script.async = true;
    script.src = "https://www.googletagmanager.com/gtag/js?id=" + encodeURIComponent(ANALYTICS_ID);
    document.head.appendChild(script);
  }

  function removeBanner() {
    var current = document.getElementById("we-cookie-banner");
    if (current) current.remove();
  }

  function showBanner() {
    removeBanner();
    var banner = document.createElement("section");
    banner.id = "we-cookie-banner";
    banner.className = "we-cookie-banner";
    banner.setAttribute("role", "dialog");
    banner.setAttribute("aria-modal", "true");
    banner.setAttribute("aria-labelledby", "we-cookie-title");
    banner.innerHTML =
      '<div class="we-cookie-inner">' +
        '<div class="we-cookie-copy">' +
          '<h2 id="we-cookie-title">Your privacy choices</h2>' +
          '<p>We use essential storage to run this website. With your permission, Google Analytics helps us understand which pages and booking routes are useful. You can accept or reject analytics.</p>' +
          '<a href="/privacy.html#cookies">Read our privacy and cookie policy</a>' +
        '</div>' +
        '<div class="we-cookie-actions">' +
          '<button type="button" class="we-cookie-reject" data-cookie-choice="rejected">Reject analytics</button>' +
          '<button type="button" class="we-cookie-accept" data-cookie-choice="granted">Accept analytics</button>' +
        '</div>' +
      '</div>';
    document.body.appendChild(banner);

    banner.querySelectorAll("[data-cookie-choice]").forEach(function (button) {
      button.addEventListener("click", function () {
        var choice = button.getAttribute("data-cookie-choice");
        saveChoice(choice);
        if (choice === "granted") loadAnalytics();
        removeBanner();
      });
    });
  }

  document.addEventListener("DOMContentLoaded", function () {
    var choice = getChoice();
    if (choice === "granted") loadAnalytics();
    if (!choice) showBanner();

    document.addEventListener("click", function (event) {
      var trigger = event.target.closest("[data-cookie-settings]");
      if (!trigger) return;
      event.preventDefault();
      showBanner();
    });
  });
})();

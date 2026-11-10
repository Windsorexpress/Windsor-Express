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


  // Mobile call / WhatsApp / directions bar. Most repair customers arrive on a
  // phone and want to ring, not fill in a form, so keep the call one tap away.
  var CALL_BAR_SKIP = /\/(admin|connection-test|phones-for-sale-windsor)\.html$/;
  var REWARDS_URL = "https://rewards.windsor-express.co.uk/join";
  // The homepage app renders its own bottom bar (Call / WhatsApp / Repair / Buy
  // Phone). Two fixed bars stacked on top of each other hid that one completely.
  var IS_HOME = /^\/(index\.html)?$/.test(window.location.pathname);
  function addCallBar() {
    if (IS_HOME || CALL_BAR_SKIP.test(window.location.pathname)) return;
    if (document.getElementById("we-callbar") || document.querySelector(".mobile-buybar")) return;
    var bar = document.createElement("nav");
    bar.id = "we-callbar";
    bar.className = "we-callbar";
    bar.setAttribute("aria-label", "Contact Windsor Express");
    // In-stock phone pages: the bar's main job is to sell the phone on screen,
    // so lead with a Buy button that carries the price.
    var buy = document.querySelector('a.buy-btn[href*="?phone="]');
    var price = document.querySelector(".price-block .price");
    if (buy && price) {
      bar.className = "we-callbar we-callbar-buy";
      bar.setAttribute("aria-label", "Buy this phone");
      bar.innerHTML =
        '<a class="we-callbar-call" data-track="mobile_buy_click"></a>' +
        '<a class="we-callbar-wa" target="_blank" rel="noopener" data-track="whatsapp_click">WhatsApp</a>' +
        '<a class="we-callbar-rewards" href="' + REWARDS_URL + '" data-track="rewards_click">Rewards</a>';
      var links = bar.querySelectorAll("a");
      links[0].href = buy.getAttribute("href");
      links[0].textContent = "Buy now \u00B7 " + price.textContent.trim();
      var ask = document.querySelector("a.ask-btn");
      links[1].href = ask ? ask.getAttribute("href") : "https://wa.me/447912150397";
      document.body.appendChild(bar);
      document.body.classList.add("we-has-callbar");
      return;
    }
    bar.innerHTML =
      '<a class="we-callbar-call" href="tel:+447912150397" data-track="call_click" aria-label="Call Windsor Express on 07912 150397">Call us</a>' +
      '<a class="we-callbar-wa" href="https://wa.me/447912150397" target="_blank" rel="noopener" data-track="whatsapp_click">WhatsApp</a>' +
      '<a class="we-callbar-map" href="https://www.google.com/maps/dir/?api=1&amp;destination=Windsor%20Express%2C%203%20Peascod%20St%2C%20Windsor%20SL4%201DG" target="_blank" rel="noopener" data-track="directions_click">Directions</a>' +
      '<a class="we-callbar-rewards" href="' + REWARDS_URL + '" data-track="rewards_click">Rewards</a>';
    document.body.appendChild(bar);
    document.body.classList.add("we-has-callbar");
  }

  // Loyalty link in the header of every static page. Before this the only
  // Rewards link on the whole site was in the homepage's desktop-only menu.
  function addRewardsLink() {
    if (IS_HOME || /\/(admin|connection-test)\.html$/.test(window.location.pathname)) return;
    if (document.querySelector(".we-rewards-link")) return;
    var link = document.createElement("a");
    link.className = "we-rewards-link";
    link.href = REWARDS_URL;
    link.setAttribute("data-track", "rewards_click");
    link.setAttribute("aria-label", "Windsor Express Rewards loyalty card");
    link.innerHTML = '<span aria-hidden="true">\uD83C\uDF81</span><span class="we-rw-label">&nbsp;Rewards</span>';
    var shopNav = document.querySelector("header .navlinks");
    var cta = document.querySelector("header .nav > .cta");
    if (shopNav) shopNav.insertBefore(link, shopNav.querySelector(".nav-cta"));
    else if (cta) cta.parentNode.insertBefore(link, cta);
  }

  // "Find us" notice while the shop's outside signs are down. Customers arriving
  // from Google Maps look for a fascia that isn't there, so tell them what to
  // look for instead. Set SHOW_FIND_US_NOTICE to false once the new shopfront
  // signs are up.
  var SHOW_FIND_US_NOTICE = true;
  var FIND_US_SKIP = /\/(admin|connection-test)\.html$/;
  function addFindUsNotice() {
    if (!SHOW_FIND_US_NOTICE || FIND_US_SKIP.test(window.location.pathname)) return;
    if (document.getElementById("we-findus")) return;
    var note = document.createElement("div");
    note.id = "we-findus";
    note.className = "we-findus";
    note.setAttribute("role", "note");
    note.innerHTML =
      '<span class="we-findus-pin" aria-hidden="true">📍</span>' +
      '<span class="we-findus-long"><strong>Open as normal.</strong> Our outside signs are temporarily down. ' +
      'Find us at 3 Queen Annes Court, the bottom of Peascod Street. ' +
      'Look for the Windsor Express poster in the window.</span>' +
      // Phones get a two-line version: the full notice took a fifth of the screen.
      '<span class="we-findus-short"><strong>Open as normal</strong> — signs are down. ' +
      '3 Queen Annes Court, bottom of Peascod St.</span>' +
      '<a href="https://maps.app.goo.gl/pZWxtjh1QgyAGVUZ9" target="_blank" rel="noopener" data-track="findus_directions_click">Directions</a>';
    document.body.insertBefore(note, document.body.firstChild);
  }

  // Record taps on any phone, WhatsApp or directions link as GA4 events.
  document.addEventListener("click", function (event) {
    var link = event.target.closest && event.target.closest("a[href]");
    if (!link) return;
    var href = link.getAttribute("href") || "";
    var name = link.getAttribute("data-track") ||
      (href.indexOf("tel:") === 0 ? "call_click" :
       href.indexOf("wa.me") !== -1 ? "whatsapp_click" :
       href.indexOf("rewards.windsor-express.co.uk") !== -1 ? "rewards_click" :
       /google\.[^/]+\/maps|maps\.app\.goo\.gl/.test(href) ? "directions_click" : "");
    if (name) window.gtag("event", name, { link_url: href, page_path: window.location.pathname });
  }, true);

  document.addEventListener("DOMContentLoaded", function () {
    addFindUsNotice();
    addCallBar();
    addRewardsLink();
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

/* ============================================================
   review-form.js
   Submits a first-party product review to Supabase.

   Reviews arrive with approved=false and verified=false (enforced
   by row-level security) and stay invisible until approved in the
   admin panel. Nothing here can publish a review directly.
   ============================================================ */
(function () {
  "use strict";

  var SUPABASE_URL = "https://hqjnhwkkqctuymvzzszy.supabase.co";
  var SUPABASE_KEY = "sb_publishable_mbRgGL97wHJVQhYDBFJhmQ_63dFxWMH";

  function setNote(form, message, isError) {
    var note = form.querySelector(".review-form-note");
    if (!note) return;
    note.textContent = message;
    note.style.color = isError ? "#dc2626" : "#059669";
  }

  document.querySelectorAll(".review-form").forEach(function (form) {
    form.addEventListener("submit", function (event) {
      event.preventDefault();

      var button = form.querySelector("button[type=submit]");
      var data = new FormData(form);
      var rating = parseInt(data.get("rating"), 10);

      if (!rating || rating < 1 || rating > 5) {
        setNote(form, "Please choose a rating.", true);
        return;
      }

      button.disabled = true;
      button.textContent = "Sending…";

      fetch(SUPABASE_URL + "/rest/v1/product_reviews", {
        method: "POST",
        headers: {
          apikey: SUPABASE_KEY,
          Authorization: "Bearer " + SUPABASE_KEY,
          "Content-Type": "application/json",
          Prefer: "return=minimal"
        },
        body: JSON.stringify({
          model_key: form.dataset.modelKey,
          model_label: form.dataset.modelLabel,
          rating: rating,
          title: (data.get("title") || "").toString().slice(0, 80) || null,
          body: (data.get("body") || "").toString().slice(0, 1200),
          reviewer_name: (data.get("reviewer_name") || "").toString().slice(0, 60),
          approved: false,
          verified: false
        })
      })
        .then(function (res) {
          if (!res.ok) throw new Error("Request failed: " + res.status);
          form.reset();
          button.textContent = "Thank you";
          setNote(form, "Thanks — we'll check this against our order records and publish it shortly.", false);
        })
        .catch(function () {
          button.disabled = false;
          button.textContent = "Submit review";
          setNote(form, "Sorry, that didn't send. Please call 07912 150397 and we'll add it for you.", true);
        });
    });
  });
})();

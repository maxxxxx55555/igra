// THE LAST STREETLIGHT — release landing page interactions.
// Vanilla, dependency-free. Respects prefers-reduced-motion.
(function () {
  "use strict";

  // Sticky nav state
  var nav = document.getElementById("nav");
  if (nav) {
    var onScroll = function () {
      if (window.scrollY > 24) nav.classList.add("is-stuck");
      else nav.classList.remove("is-stuck");
    };
    window.addEventListener("scroll", onScroll, { passive: true });
    onScroll();
  }

  // Scroll reveal
  var reveals = document.querySelectorAll(".reveal");
  if ("IntersectionObserver" in window && !motionReduced()) {
    var io = new IntersectionObserver(
      function (entries) {
        entries.forEach(function (e) {
          if (e.isIntersecting) {
            e.target.classList.add("is-in");
            io.unobserve(e.target);
          }
        });
      },
      { threshold: 0.12, rootMargin: "0px 0px -8% 0px" }
    );
    reveals.forEach(function (el) { io.observe(el); });
  } else {
    reveals.forEach(function (el) { el.classList.add("is-in"); });
  }

  // Lightbox for gallery screenshots
  var box = document.getElementById("lightbox");
  var boxImg = document.getElementById("lightboxImg");
  var boxClose = document.getElementById("lightboxClose");
  if (box && boxImg) {
    document.querySelectorAll(".shot img").forEach(function (img) {
      img.addEventListener("click", function () {
        boxImg.src = img.src;
        boxImg.alt = img.alt || "";
        box.hidden = false;
        document.body.style.overflow = "hidden";
      });
    });
    var closeBox = function () {
      box.hidden = true;
      boxImg.src = "";
      document.body.style.overflow = "";
    };
    if (boxClose) boxClose.addEventListener("click", closeBox);
    box.addEventListener("click", function (ev) {
      if (ev.target === box) closeBox();
    });
    document.addEventListener("keydown", function (ev) {
      if (ev.key === "Escape" && !box.hidden) closeBox();
    });
  }

  function motionReduced() {
    return (
      window.matchMedia &&
      window.matchMedia("(prefers-reduced-motion: reduce)").matches
    );
  }
})();

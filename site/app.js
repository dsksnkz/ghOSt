// Sections rise in once as they arrive; the install commands can be copied.
const reveals = document.querySelectorAll(".reveal");
if ("IntersectionObserver" in window) {
  const observer = new IntersectionObserver(entries => {
    for (const entry of entries) {
      if (entry.isIntersecting) {
        entry.target.classList.add("in");
        observer.unobserve(entry.target);
      }
    }
  }, {rootMargin: "0px 0px -8% 0px"});
  reveals.forEach(element => observer.observe(element));
} else {
  reveals.forEach(element => element.classList.add("in"));
}

const copy = document.getElementById("copy");
let reset;
copy.addEventListener("click", async () => {
  try {
    await navigator.clipboard.writeText(document.getElementById(copy.dataset.copy).textContent);
    copy.textContent = "Copied";
  } catch {
    copy.textContent = "Select and copy";
  }
  clearTimeout(reset);
  reset = setTimeout(() => { copy.textContent = "Copy"; }, 2000);
});

// One-shot motion only. No timers or background animation loops.
export function revealOrder(count, previous = [], random = Math.random) {
  const order = Array.from({length: count}, (_, index) => index);
  for (let index = count - 1; index > 0; index--) {
    const chosen = Math.floor(random() * (index + 1));
    [order[index], order[chosen]] = [order[chosen], order[index]];
  }
  if (count > 1 && order.join() === previous.join()) order.push(order.shift());
  return order;
}

export function entranceFrames(kind) {
  const direction = kind === "sidebar" ? "translateX(-24px)" : "translateY(-28px)";
  return [{opacity: 0, transform: direction}, {opacity: 1, transform: "translate(0)"}];
}

export function groupFrames(kind) {
  if (kind === "sidebar") {
    return [{opacity: 0, transform: "translateX(-18px)"}, {opacity: 1, transform: "translateX(0)"}];
  }
  // A single restrained contrast dip, not repeated high-contrast flashing.
  return [
    {opacity: 0, offset: 0},
    {opacity: 1, offset: 0.45},
    {opacity: 0.82, offset: 0.65},
    {opacity: 1, offset: 1},
  ];
}

export function groupTiming(kind, rank) {
  return {
    delay: 280 + rank * (kind === "calendar" ? 200 : 110),
    duration: kind === "calendar" ? 180 : 220,
    easing: "ease-out",
    fill: "both",
  };
}

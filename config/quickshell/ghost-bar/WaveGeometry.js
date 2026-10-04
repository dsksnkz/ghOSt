.pragma library

// Precompute the fixed horizontal basis. The addition identity preserves the
// exact old wave while using two trig calls per layer, not one per vertex.
function samples(width, step) {
    const points = [];
    if (width <= 0 || step <= 0) return points;
    for (let x = 0; x <= width; x += step) {
        const angle = x / width * 6.28;
        points.push([x, Math.sin(angle), Math.cos(angle)]);
    }
    return points;
}

function trace(context, points, phase, waterY, amplitude, width, height) {
    const sine = Math.sin(phase), cosine = Math.cos(phase);
    context.beginPath();
    context.moveTo(0, height);
    for (const point of points)
        context.lineTo(point[0], waterY + (point[1] * cosine + point[2] * sine) * amplitude);
    context.lineTo(width, height);
    context.closePath();
}

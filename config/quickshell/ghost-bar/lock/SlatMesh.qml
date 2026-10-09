import QtQuick
import QtQuick3D.Helpers

// A thin crowned sheet, not a box: front/back curvature and closed rolled edges.
ProceduralMesh {
    property real bladeWidth: 1000
    property real bladeHeight: 38
    property real crown: 5
    property real thickness: 1.1
    readonly property var mesh: build()
    positions: mesh.positions
    normals: mesh.normals
    uv0s: mesh.uvs
    indexes: mesh.indexes

    function build() {
        const positions = [], normals = [], uvs = [], indexes = [];
        const half = bladeHeight / 2;
        function profile(t, back) {
            const end = 6 * (1 - Math.sqrt(Math.max(0, 1 - t * t)));
            return Qt.vector3d(bladeWidth / 2 - end, t * half, crown * (1 - t * t) - (back ? thickness : 0));
        }
        function normal(t, back) {
            const sign = back ? -1 : 1;
            return Qt.vector3d(0, sign * 2 * crown * t / half, sign).normalized();
        }
        function left(v) { return Qt.vector3d(-v.x, v.y, v.z); }
        function quad(points, directions) {
            const first = positions.length;
            for (let i = 0; i < 4; i++) {
                positions.push(points[i]);
                normals.push(directions[i]);
                uvs.push(Qt.vector2d(points[i].x / bladeWidth + 0.5, points[i].y / bladeHeight + 0.5));
            }
            indexes.push(first, first + 1, first + 2, first, first + 2, first + 3);
        }
        for (let i = 0; i < 32; i++) {
            const a = -1 + i / 16, b = -1 + (i + 1) / 16;
            const fa = profile(a, false), fb = profile(b, false);
            const ba = profile(a, true), bb = profile(b, true);
            quad([left(fa), fa, fb, left(fb)], [normal(a, false), normal(a, false), normal(b, false), normal(b, false)]);
            quad([ba, left(ba), left(bb), bb], [normal(a, true), normal(a, true), normal(b, true), normal(b, true)]);
            quad([fa, ba, bb, fb], Array(4).fill(Qt.vector3d(1, 0, 0)));
            quad([left(ba), left(fa), left(fb), left(bb)], Array(4).fill(Qt.vector3d(-1, 0, 0)));
        }
        for (const t of [-1, 1]) {
            const front = profile(t, false), back = profile(t, true);
            quad([left(front), front, back, left(back)], Array(4).fill(Qt.vector3d(0, t, 0)));
        }
        return { positions, normals, uvs, indexes };
    }
}

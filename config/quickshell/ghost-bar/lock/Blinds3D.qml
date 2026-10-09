import QtQuick
import QtQuick3D

View3D {
    id: view
    property real opening: 0
    readonly property int count: Math.max(1, Math.ceil((height - 52) / 36))
    readonly property real pitch: (height - 52) / count
    readonly property real frameOpacity: 1 - Math.max(0, (opening - 0.6) / 0.4)
    environment: SceneEnvironment {
        backgroundMode: SceneEnvironment.Transparent
        antialiasingMode: SceneEnvironment.MSAA
        antialiasingQuality: SceneEnvironment.High
        aoStrength: 0.3
        aoDistance: 10
        aoSoftness: 50
    }
    OrthographicCamera { z: 1000; clipNear: 1; clipFar: 3000 }
    DirectionalLight {
        eulerRotation: Qt.vector3d(-32, -18, 0)
        brightness: 1.25
        ambientColor: "#454545"
        castsShadow: true
        shadowMapQuality: Light.ShadowMapQualityVeryHigh
        shadowMapFar: 2500
        shadowBias: 0.05
        shadowFactor: 75
        shadowFilter: 4
    }
    DirectionalLight {
        eulerRotation: Qt.vector3d(20, 45, 0)
        brightness: 0.35
        color: "#c7c7c7"
    }
    SlatMesh { id: bladeMesh; bladeWidth: view.width - 36; bladeHeight: view.pitch + 4 }
    PrincipledMaterial { id: railFinish; baseColor: "#454545"; metalness: 0.45; roughness: 0.28 }
    PrincipledMaterial { id: cordFinish; baseColor: "#292929"; roughness: 0.95 }
    Repeater3D {
        model: view.count
        Model {
            required property int index
            readonly property real turn: Math.max(0, Math.min(1, (view.opening - index / view.count * 0.15) / 0.85))
            y: view.height / 2 - 28 - (index + 0.5) * view.pitch
            z: 8
            eulerRotation: Qt.vector3d(8 + 82 * turn, 0, 0)
            opacity: 1 - Math.max(0, (turn - 0.92) / 0.08)
            geometry: bladeMesh
            materials: CustomMaterial {
                property real bladeSeed: index * 3.71
                fragmentShader: "slat-metal.frag"
                cullMode: Material.NoCulling
            }
        }
    }
    // Paired front/back ladder cords and short rungs support each blade.
    Repeater3D {
        model: 8
        Model {
            required property int index
            source: "#Cylinder"
            x: (index < 4 ? -1 : 1) * view.width * 0.3 + (index % 2 ? 2 : -2)
            z: index % 4 < 2 ? 18 : -4
            scale: Qt.vector3d(0.014, (view.height - 28) / 100, 0.014)
            opacity: view.frameOpacity
            materials: cordFinish
        }
    }
    Repeater3D {
        model: view.count * 2
        Model {
            required property int index
            source: "#Cube"
            x: (index % 2 ? 1 : -1) * view.width * 0.3
            y: view.height / 2 - 28 - (Math.floor(index / 2) + 1) * view.pitch
            z: 7
            scale: Qt.vector3d(0.055, 0.014, 0.24)
            opacity: view.frameOpacity
            materials: cordFinish
        }
    }
    Model {
        source: "#Cube"
        y: view.height / 2 - 14
        z: 10
        scale: Qt.vector3d((view.width - 24) / 100, 0.28, 0.22)
        opacity: view.frameOpacity
        materials: railFinish
    }
    Model {
        source: "#Cube"
        y: -view.height / 2 + 12
        z: 9
        scale: Qt.vector3d((view.width - 30) / 100, 0.24, 0.18)
        opacity: view.frameOpacity
        materials: railFinish
    }
}

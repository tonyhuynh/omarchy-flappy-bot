import QtQuick
import qs.Commons

// A compact side-view robot sprite. Pure presentation: the parent owns
// position, scale, rotation, and animation phases. Colors are injected so the
// bot tracks the active Omarchy theme (see Overlay.qml).
Item {
  id: root

  // Authored in a 100x72 box; the parent scales this item to fit.
  readonly property real baseW: 100
  readonly property real baseH: 72

  property color bodyColor: Color.accent
  property color highlightColor: Qt.lighter(root.bodyColor, 1.28)
  property color panelColor: Qt.darker(root.bodyColor, 1.28)
  property color visorColor: Color.background
  property color displayColor: Color.foreground
  property color accentColor: Color.urgent

  // Animation values supplied by the parent. wingPhase is the ambient cycle
  // retained by the sprite contract; boostPulse is a short tap-driven burst.
  property real wingPhase: 0
  property real boostPulse: 0
  readonly property real antennaAngle: Math.sin(root.wingPhase * Math.PI * 2) * 8
  readonly property real statusOpacity: 0.62 + Math.sin(root.wingPhase * Math.PI * 2) * 0.28
  readonly property real boostAmount: Math.max(0, Math.min(1, root.boostPulse))

  // A quick ignition flash and two air streaks make every tap visible. The
  // effect stays inside the authored box and fades completely between taps.
  Item {
    x: 0
    y: 20
    width: 29
    height: 38
    opacity: root.boostAmount
    scale: 0.76 + root.boostAmount * 0.24
    transformOrigin: Item.Right

    Rectangle {
      x: 3 * root.boostAmount
      y: 5
      width: 15
      height: 4
      radius: 2
      color: root.displayColor
      opacity: 0.38
    }

    Rectangle {
      x: 5 * root.boostAmount
      y: 29
      width: 12
      height: 4
      radius: 2
      color: root.displayColor
      opacity: 0.3
    }

    Rectangle {
      x: 2
      y: 13
      width: 13
      height: 13
      radius: 3
      rotation: 45
      color: root.displayColor
      opacity: 0.34
    }

    Rectangle {
      x: 10
      y: 12
      width: 15
      height: 15
      radius: 4
      rotation: 45
      color: root.accentColor
      opacity: 0.9
    }
  }

  // The forward-offset antenna mirrors the bar icon and establishes the
  // direction of flight.
  Item {
    id: antenna
    x: 67
    y: 0
    width: 8
    height: 21
    transform: Rotation {
      axis.x: 0
      axis.y: 0
      axis.z: 1
      angle: root.antennaAngle
      origin.x: antenna.width / 2
      origin.y: antenna.height
    }

    Rectangle {
      width: 4
      height: 15
      radius: 2
      color: root.panelColor
      anchors.horizontalCenter: parent.horizontalCenter
      anchors.bottom: parent.bottom
    }

    Rectangle {
      width: 10
      height: 10
      radius: 5
      color: root.accentColor
      anchors.horizontalCenter: parent.horizontalCenter
      anchors.top: parent.top
      opacity: root.statusOpacity
    }
  }

  // Rear thruster housing. Its inner glow is faint at rest and flashes with
  // the tap-driven boost.
  Rectangle {
    x: 17
    y: 27
    width: 14
    height: 30
    radius: 5
    color: root.panelColor

    Rectangle {
      width: 6
      height: 18
      radius: 3
      anchors.left: parent.left
      anchors.leftMargin: 2
      anchors.verticalCenter: parent.verticalCenter
      color: root.accentColor
      opacity: 0.28 + root.boostAmount * 0.72
    }
  }

  // Two feet retain the friendly full-body silhouette at playfield scale.
  Rectangle {
    x: 43
    y: 58
    width: 19
    height: 14
    radius: 5
    color: root.panelColor
  }

  Rectangle {
    x: 68
    y: 58
    width: 19
    height: 14
    radius: 5
    color: root.panelColor
  }

  // Main chassis is longer than it is tall, matching the flying bar icon.
  Rectangle {
    x: 25
    y: 13
    width: 65
    height: 52
    radius: 16
    color: root.bodyColor
    border.width: 2
    border.color: root.panelColor

    Rectangle {
      width: parent.width * 0.58
      height: 5
      radius: 3
      color: root.highlightColor
      anchors.right: parent.right
      anchors.rightMargin: 9
      anchors.top: parent.top
      anchors.topMargin: 5
      opacity: 0.82
    }
  }

  // Rounded front cap gives the bot a clear nose without resembling a beak.
  Rectangle {
    x: 86
    y: 27
    width: 14
    height: 29
    radius: 6
    color: root.panelColor
  }

  // Dark visor with two simple display sensors, biased toward the direction
  // of flight like the bar icon.
  Rectangle {
    x: 47
    y: 25
    width: 37
    height: 23
    radius: 8
    color: root.visorColor
    border.width: 2
    border.color: root.panelColor

    Rectangle {
      x: 7
      anchors.verticalCenter: parent.verticalCenter
      width: 8
      height: 8
      radius: 3
      color: root.displayColor
    }

    Rectangle {
      anchors.right: parent.right
      anchors.rightMargin: 7
      anchors.verticalCenter: parent.verticalCenter
      width: 8
      height: 8
      radius: 3
      color: root.displayColor
    }
  }

  // Small urgent-color status light links the chassis to the exhaust color.
  Rectangle {
    x: 35
    y: 34
    width: 8
    height: 8
    radius: 4
    color: root.accentColor
    opacity: root.statusOpacity
  }
}

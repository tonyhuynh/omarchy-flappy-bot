import QtQuick
import qs.Commons

// A compact robot sprite. Pure presentation: the parent owns position,
// scale, rotation, and the animation phase. Colors are injected so the bot
// tracks the active Omarchy theme (see Overlay.qml).
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

  // 0..1 animation cycle supplied by the parent.
  property real wingPhase: 0
  readonly property real antennaAngle: Math.sin(root.wingPhase * Math.PI * 2) * 8
  readonly property real statusOpacity: 0.62 + Math.sin(root.wingPhase * Math.PI * 2) * 0.28

  // Antenna and signal lamp sit behind the head shell.
  Item {
    id: antenna
    x: 46
    y: 0
    width: 8
    height: 22
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

  // Side modules keep the silhouette readable when the sprite is tiny.
  Rectangle {
    x: 0
    y: 28
    width: 16
    height: 28
    radius: 6
    color: root.panelColor
  }

  Rectangle {
    x: 84
    y: 28
    width: 16
    height: 28
    radius: 6
    color: root.panelColor
  }

  // Feet.
  Rectangle {
    x: 22
    y: 58
    width: 22
    height: 14
    radius: 5
    color: root.panelColor
  }

  Rectangle {
    x: 56
    y: 58
    width: 22
    height: 14
    radius: 5
    color: root.panelColor
  }

  // Main rounded chassis.
  Rectangle {
    x: 10
    y: 13
    width: 80
    height: 52
    radius: 16
    color: root.bodyColor
    border.width: 2
    border.color: root.panelColor

    Rectangle {
      width: parent.width * 0.68
      height: 5
      radius: 3
      color: root.highlightColor
      anchors.horizontalCenter: parent.horizontalCenter
      anchors.top: parent.top
      anchors.topMargin: 5
      opacity: 0.82
    }
  }

  // Dark visor with two simple display sensors.
  Rectangle {
    x: 22
    y: 25
    width: 56
    height: 23
    radius: 8
    color: root.visorColor
    border.width: 2
    border.color: root.panelColor

    Rectangle {
      x: 10
      anchors.verticalCenter: parent.verticalCenter
      width: 9
      height: 9
      radius: 3
      color: root.displayColor
    }

    Rectangle {
      anchors.right: parent.right
      anchors.rightMargin: 10
      anchors.verticalCenter: parent.verticalCenter
      width: 9
      height: 9
      radius: 3
      color: root.displayColor
    }
  }

  // Small urgent-color status light breaks up the lower panel.
  Rectangle {
    x: 45
    y: 53
    width: 10
    height: 6
    radius: 3
    color: root.accentColor
    opacity: root.statusOpacity
  }
}

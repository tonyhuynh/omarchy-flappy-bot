import QtQuick

// One pipe pair (top + bottom) with a gap. `gapCenterY` and `gapHeight`
// describe the opening; the parent sets `x` and `width`. Colors are injected
// so pipes track the active theme.
Item {
  id: root

  property real gapCenterY: 0
  property real gapHeight: 0
  property color pipeColor: "#3b4252"
  property color capColor: "#2e3440"
  // Cap lip thickness as a fraction of the pipe width.
  readonly property real capH: Math.min(width * 0.32, 26)

  readonly property real topH: gapCenterY - gapHeight / 2
  readonly property real bottomTop: gapCenterY + gapHeight / 2

  // Top pipe body.
  Rectangle {
    x: 0
    y: 0
    width: root.width
    height: Math.max(0, root.topH)
    color: root.pipeColor
    clip: true

    Rectangle {
      // Subtle left-edge highlight for a bit of roundness.
      width: parent.width * 0.16
      height: parent.height
      color: Qt.lighter(root.pipeColor, 1.18)
      anchors.left: parent.left
      opacity: 0.7
    }
  }

  // Top pipe cap (the wide lip at the gap edge).
  Rectangle {
    x: -width * 0.08
    y: root.topH - root.capH
    width: root.width * 1.16
    height: root.capH
    radius: Math.min(root.capH * 0.5, root.width * 0.18)
    color: root.capColor
    visible: root.topH > 0
  }

  // Bottom pipe body.
  Rectangle {
    x: 0
    y: root.bottomTop
    width: root.width
    height: Math.max(0, root.height - root.bottomTop)
    color: root.pipeColor
    clip: true

    Rectangle {
      width: parent.width * 0.16
      height: parent.height
      color: Qt.lighter(root.pipeColor, 1.18)
      anchors.left: parent.left
      opacity: 0.7
    }
  }

  // Bottom pipe cap.
  Rectangle {
    x: -width * 0.08
    y: root.bottomTop
    width: root.width * 1.16
    height: root.capH
    radius: Math.min(root.capH * 0.5, root.width * 0.18)
    color: root.capColor
    visible: root.bottomTop < root.height
  }
}

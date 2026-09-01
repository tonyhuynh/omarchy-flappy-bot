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
  readonly property real capOverhang: width * 0.08
  // Matching the radius to the overhang keeps the square stem fully hidden
  // behind the rounded, gap-facing edge of each cap.
  readonly property real capRadius: Math.min(capH * 0.5, capOverhang)

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
    x: -root.capOverhang
    y: root.topH - root.capH
    width: root.width + root.capOverhang * 2
    height: root.capH
    radius: root.capRadius
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
    x: -root.capOverhang
    y: root.bottomTop
    width: root.width + root.capOverhang * 2
    height: root.capH
    radius: root.capRadius
    color: root.capColor
    visible: root.bottomTop < root.height
  }
}

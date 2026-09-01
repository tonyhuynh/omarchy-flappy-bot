import QtQuick
import qs.Ui

// Bar-widget entry point for the centered/fullscreen Flappy Bot game.
BarWidget {
  id: root
  moduleName: "tonyhuynh.flappy-bot"

  // Material Design robot (U+F06A9). Use fromCodePoint because QML's \u
  // escape form only consumes four hexadecimal digits.
  readonly property string icon: String.fromCodePoint(0xF06A9)

  implicitWidth: button.implicitWidth
  implicitHeight: button.implicitHeight

  BarIconButton {
    id: button
    anchors.fill: parent
    bar: root.bar
    text: root.icon
    tooltipText: "Flappy Bot"
    onPressed: function(buttonCode) {
      if (buttonCode === Qt.LeftButton && root.bar && root.bar.shell
          && typeof root.bar.shell.toggle === "function")
        root.bar.shell.toggle(root.moduleName, "")
    }
  }
}

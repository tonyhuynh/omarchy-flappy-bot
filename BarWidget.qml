import QtQuick
import qs.Commons
import qs.Ui

// Bar-widget entry point for the centered/fullscreen Flappy Bot game.
BarWidget {
  id: root
  moduleName: "tonyhuynh.flappy-bot"

  implicitWidth: button.implicitWidth
  implicitHeight: button.implicitHeight

  // A side-on flying counterpart to Bot.qml. Its wide, tilted chassis and
  // separated thruster keep it distinct from Omarchy's upright robot-head
  // glyph while retaining the bot's antenna, visor, sensors, and feet.
  Component {
    id: botIcon

    Item {
      id: icon
      readonly property real u: Math.min(width, height) / 16
      readonly property color panelColor: Qt.darker(Color.accent, 1.28)

      Item {
        id: flyer
        anchors.centerIn: parent
        width: 16 * icon.u
        height: 14 * icon.u
        rotation: -8
        transformOrigin: Item.Center

        // Urgent-colored exhaust is detached from the rear module so the
        // silhouette reads as a bot in flight instead of a round head.
        Rectangle {
          x: -1.25 * icon.u
          y: 6.25 * icon.u
          width: 2.5 * icon.u
          height: 2.5 * icon.u
          radius: 0.5 * icon.u
          rotation: 45
          color: Color.urgent
        }
        Rectangle {
          x: 1.25 * icon.u
          y: 5 * icon.u
          width: 2 * icon.u
          height: 5 * icon.u
          radius: icon.u
          color: Color.muted
        }

        // Offset antenna and signal lamp mirror the playfield character while
        // avoiding the centered antenna used by the Agents icon.
        Rectangle {
          x: 9.25 * icon.u
          y: 0.75 * icon.u
          width: 1.25 * icon.u
          height: 4 * icon.u
          radius: width / 2
          color: icon.panelColor
        }
        Rectangle {
          x: 8.5 * icon.u
          y: 0
          width: 2.75 * icon.u
          height: 2.75 * icon.u
          radius: width / 2
          color: Color.urgent
        }

        // Two separated feet keep the full-body silhouette at bar scale.
        Rectangle {
          x: 5 * icon.u
          y: 11.5 * icon.u
          width: 3 * icon.u
          height: 2.5 * icon.u
          radius: icon.u
          color: icon.panelColor
        }
        Rectangle {
          x: 10 * icon.u
          y: 11.5 * icon.u
          width: 3 * icon.u
          height: 2.5 * icon.u
          radius: icon.u
          color: icon.panelColor
        }

        // Long chassis with the visor biased toward the direction of flight.
        Rectangle {
          x: 3.5 * icon.u
          y: 3.25 * icon.u
          width: 11 * icon.u
          height: 9 * icon.u
          radius: 2.5 * icon.u
          color: Color.accent
          border.width: Math.max(1, icon.u)
          border.color: icon.panelColor

          Rectangle {
            anchors.top: parent.top
            anchors.topMargin: icon.u
            anchors.horizontalCenter: parent.horizontalCenter
            width: 6 * icon.u
            height: icon.u
            radius: height / 2
            color: Qt.lighter(Color.accent, 1.28)
            opacity: 0.82
          }
        }
        Rectangle {
          x: 14.75 * icon.u
          y: 5.5 * icon.u
          width: 2.25 * icon.u
          height: 4.5 * icon.u
          radius: icon.u
          color: Color.muted
        }

        Rectangle {
          x: 7 * icon.u
          y: 6 * icon.u
          width: 6 * icon.u
          height: 3.5 * icon.u
          radius: 1.25 * icon.u
          color: Color.background
          border.width: Math.max(1, icon.u * 0.75)
          border.color: icon.panelColor

          Rectangle {
            x: icon.u
            anchors.verticalCenter: parent.verticalCenter
            width: 1.25 * icon.u
            height: 1.25 * icon.u
            radius: 0.4 * icon.u
            color: Color.foreground
          }
          Rectangle {
            anchors.right: parent.right
            anchors.rightMargin: icon.u
            anchors.verticalCenter: parent.verticalCenter
            width: 1.25 * icon.u
            height: 1.25 * icon.u
            radius: 0.4 * icon.u
            color: Color.foreground
          }
        }

        Rectangle {
          x: 5 * icon.u
          y: 7 * icon.u
          width: 1.5 * icon.u
          height: 1.5 * icon.u
          radius: width / 2
          color: Color.urgent
        }
      }
    }
  }

  BarIconButton {
    id: button
    anchors.fill: parent
    bar: root.bar
    iconComponent: botIcon
    tooltipText: "Flappy Bot"
    onPressed: function(buttonCode) {
      if (buttonCode === Qt.LeftButton && root.bar && root.bar.shell
          && typeof root.bar.shell.toggle === "function")
        root.bar.shell.toggle(root.moduleName, "")
    }
  }
}

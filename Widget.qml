import QtQuick
import Quickshell
import Quickshell.Services.Mpris
import qs.Commons
import qs.Ui

BarWidget {
  id: root
  moduleName: "fatlj.mpris"

  readonly property int playerCount: Mpris.players.values.length
  property bool opened: false

  function open() { opened = true }
  function close() { opened = false }
  function toggle() { opened = !opened }

  visible: playerCount > 0
  implicitWidth: visible ? button.implicitWidth : 0
  implicitHeight: button.implicitHeight

  onPlayerCountChanged: if (playerCount === 0) close()

  BarIconButton {
    id: button
    anchors.fill: parent
    bar: root.bar
    text: "󰝚"
    tooltipText: "Media players"
    onPressed: root.toggle()
  }

  KeyboardPanel {
    id: popup
    anchorItem: button
    bar: root.bar
    owner: root
    open: root.opened
    contentWidth: popup.fittedContentWidth(Style.space(380))
    contentHeight: popup.fittedContentHeight(content.implicitHeight)

    Column {
      id: content
      anchors.fill: parent
      spacing: Style.space(14)

      Item {
        width: parent.width
        implicitHeight: Math.max(heroIcon.implicitHeight, heroLabels.implicitHeight)

        Text {
          id: heroIcon
          anchors.left: parent.left
          anchors.verticalCenter: parent.verticalCenter
          text: "󰝚"
          color: root.bar.foreground
          font.family: root.bar.fontFamily
          font.pixelSize: Style.font.display
        }

        Column {
          id: heroLabels
          anchors.left: heroIcon.right
          anchors.leftMargin: Style.space(14)
          anchors.right: parent.right
          anchors.verticalCenter: parent.verticalCenter
          spacing: Style.space(2)

          Text {
            width: parent.width
            text: "Media Players"
            color: root.bar.foreground
            font.family: root.bar.fontFamily
            font.pixelSize: Style.font.title
            font.bold: true
            elide: Text.ElideRight
          }

          Text {
            width: parent.width
            text: root.playerCount + (root.playerCount === 1 ? " PLAYER" : " PLAYERS")
            color: Qt.darker(root.bar.foreground, 1.4)
            font.family: root.bar.fontFamily
            font.pixelSize: Style.font.caption
            font.bold: true
            font.letterSpacing: 1.2
            elide: Text.ElideRight
          }
        }
      }

      PanelSeparator {
        foreground: root.bar.foreground
      }

      Repeater {
        model: Mpris.players

        delegate: Item {
          required property var modelData
          readonly property var player: modelData
          readonly property string appQuery: String(player.dbusName || "").indexOf(".brave.") >= 0
            ? "brave-browser"
            : (player.desktopEntry || player.identity)
          readonly property var app: DesktopEntries.heuristicLookup(appQuery)

          width: content.width
          implicitHeight: Math.max(appIcon.height, labels.implicitHeight, control.implicitHeight)

          Image {
            id: appIcon
            anchors.left: parent.left
            anchors.verticalCenter: parent.verticalCenter
            width: Style.font.iconLarge
            height: width
            source: Quickshell.iconPath(app ? app.icon : "application-x-executable", true)
            fillMode: Image.PreserveAspectFit
          }

          Column {
            id: labels
            anchors.left: appIcon.right
            anchors.leftMargin: Style.space(8)
            anchors.right: control.left
            anchors.rightMargin: Style.space(8)
            anchors.verticalCenter: parent.verticalCenter
            spacing: Style.space(2)

            Text {
              width: parent.width
              text: player.trackTitle || player.identity || player.desktopEntry || player.dbusName
              color: root.bar.foreground
              font.family: root.bar.fontFamily
              font.pixelSize: Style.font.body
              elide: Text.ElideRight
              clip: true
            }

            Text {
              width: parent.width
              text: player.trackArtist
                + (player.trackArtist && player.trackAlbum ? " · " : "")
                + player.trackAlbum
              visible: text !== ""
              color: Qt.darker(root.bar.foreground, 1.4)
              font.family: root.bar.fontFamily
              font.pixelSize: Style.font.caption
              elide: Text.ElideRight
              clip: true
            }
          }

          Button {
            id: control
            anchors.right: parent.right
            anchors.verticalCenter: parent.verticalCenter
            iconText: player.isPlaying ? "󰏤" : "󰐊"
            tooltipText: player.isPlaying ? "Pause" : "Play"
            foreground: root.bar.foreground
            enabled: player.canTogglePlaying
            opacity: enabled ? 1.0 : 0.4
            onClicked: player.togglePlaying()
          }
        }
      }
    }
  }
}

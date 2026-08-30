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
          id: playerRow

          required property var modelData
          readonly property var player: modelData
          readonly property string appQuery: String(player.dbusName || "").indexOf(".brave.") >= 0
            ? "brave-browser"
            : (player.desktopEntry || player.identity)
          readonly property var app: DesktopEntries.heuristicLookup(appQuery)

          property bool expanded: false

          function formatTime(seconds) {
            var total = Math.max(0, Math.floor(Number(seconds) || 0))
            var hours = Math.floor(total / 3600)
            var minutes = Math.floor((total % 3600) / 60)
            var secs = total % 60
            var paddedMinutes = hours > 0 && minutes < 10 ? "0" + minutes : String(minutes)
            var paddedSeconds = secs < 10 ? "0" + secs : String(secs)
            return hours > 0
              ? hours + ":" + paddedMinutes + ":" + paddedSeconds
              : minutes + ":" + paddedSeconds
          }

          width: content.width
          implicitHeight: playerContent.implicitHeight

          MouseArea {
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: playerRow.expanded = !playerRow.expanded
          }

          Timer {
            interval: 1000
            repeat: true
            running: playerRow.expanded && player.isPlaying && !progressSlider.dragging
            onTriggered: player.positionChanged()
          }

          Column {
            id: playerContent
            width: parent.width
            spacing: playerRow.expanded ? Style.space(8) : 0

            Item {
              id: summary
              width: parent.width
              implicitHeight: Math.max(appIcon.height, labels.implicitHeight,
                summaryControl.visible ? summaryControl.implicitHeight : 0)

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
                anchors.right: playerRow.expanded ? parent.right : summaryControl.left
                anchors.rightMargin: playerRow.expanded ? 0 : Style.space(8)
                anchors.verticalCenter: parent.verticalCenter
                spacing: Style.space(2)

                Text {
                  width: parent.width
                  text: player.trackTitle || player.identity || player.desktopEntry || player.dbusName
                  color: root.bar.foreground
                  font.family: root.bar.fontFamily
                  font.pixelSize: Style.font.body
                  wrapMode: playerRow.expanded ? Text.Wrap : Text.NoWrap
                  elide: playerRow.expanded ? Text.ElideNone : Text.ElideRight
                  clip: true
                }

                Text {
                  width: parent.width
                  text: player.trackArtist
                    + (player.trackArtist && player.trackAlbum ? " · " : "")
                    + player.trackAlbum
                  visible: !playerRow.expanded && text !== ""
                  color: Qt.darker(root.bar.foreground, 1.4)
                  font.family: root.bar.fontFamily
                  font.pixelSize: Style.font.caption
                  elide: Text.ElideRight
                  clip: true
                }
              }

              Button {
                id: summaryControl
                visible: !playerRow.expanded
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

            Column {
              width: parent.width
              visible: playerRow.expanded
              spacing: Style.space(4)

              Image {
                width: Style.space(96)
                height: width
                anchors.horizontalCenter: parent.horizontalCenter
                visible: player.trackArtUrl !== "" && status !== Image.Error
                source: player.trackArtUrl
                fillMode: Image.PreserveAspectFit
              }

              Text {
                width: parent.width
                visible: player.trackArtist !== ""
                text: "Artist · " + player.trackArtist
                color: Qt.darker(root.bar.foreground, 1.4)
                font.family: root.bar.fontFamily
                font.pixelSize: Style.font.bodySmall
                wrapMode: Text.Wrap
              }

              Text {
                width: parent.width
                visible: player.trackAlbum !== ""
                text: "Album · " + player.trackAlbum
                color: Qt.darker(root.bar.foreground, 1.4)
                font.family: root.bar.fontFamily
                font.pixelSize: Style.font.bodySmall
                wrapMode: Text.Wrap
              }

              Column {
                width: parent.width
                visible: player.positionSupported && player.lengthSupported && player.length > 0
                spacing: Style.space(2)

                PanelSlider {
                  id: progressSlider
                  width: parent.width
                  bar: root.bar
                  minimum: 0
                  maximum: Math.max(1, player.length)
                  value: player.position
                  step: 5
                  enabled: player.canSeek
                  opacity: enabled ? 1.0 : 0.4
                  onReleased: function(value) {
                    if (!enabled) return
                    var target = Math.max(0, Math.min(value, player.length - 0.1))
                    console.info("[fatlj.mpris] seek", player.dbusName,
                      "target=" + target, "length=" + player.length)
                    player.position = target
                  }
                }

                Item {
                  width: parent.width
                  implicitHeight: Math.max(elapsedTime.implicitHeight, totalTime.implicitHeight)

                  Text {
                    id: elapsedTime
                    anchors.left: parent.left
                    text: playerRow.formatTime(progressSlider.dragging
                      ? progressSlider.liveValue
                      : player.position)
                    color: Qt.darker(root.bar.foreground, 1.4)
                    font.family: root.bar.fontFamily
                    font.pixelSize: Style.font.caption
                  }

                  Text {
                    id: totalTime
                    anchors.right: parent.right
                    text: playerRow.formatTime(player.length)
                    color: Qt.darker(root.bar.foreground, 1.4)
                    font.family: root.bar.fontFamily
                    font.pixelSize: Style.font.caption
                  }
                }
              }

              Item {
                width: parent.width
                implicitHeight: controls.implicitHeight

                Row {
                  id: controls
                  anchors.horizontalCenter: parent.horizontalCenter
                  spacing: Style.space(8)

                  Button {
                    iconText: "󰒮"
                    tooltipText: "Previous track"
                    foreground: root.bar.foreground
                    enabled: player.canGoPrevious
                    opacity: enabled ? 1.0 : 0.4
                    onClicked: player.previous()
                  }

                  Button {
                    iconText: player.isPlaying ? "󰏤" : "󰐊"
                    tooltipText: player.isPlaying ? "Pause" : "Play"
                    foreground: root.bar.foreground
                    iconSize: Style.font.iconLarge
                    horizontalPadding: Style.spacing.panelGap
                    enabled: player.canTogglePlaying
                    opacity: enabled ? 1.0 : 0.4
                    onClicked: player.togglePlaying()
                  }

                  Button {
                    iconText: "󰒭"
                    tooltipText: "Next track"
                    foreground: root.bar.foreground
                    enabled: player.canGoNext
                    opacity: enabled ? 1.0 : 0.4
                    onClicked: player.next()
                  }
                }
              }
            }
          }
        }
      }
    }
  }
}

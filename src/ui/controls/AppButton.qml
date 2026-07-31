import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import "../theme/Theme.js" as Theme

Button {
    id: root

    property bool quiet: false
    hoverEnabled: true

    implicitHeight: Theme.controlHeight
    implicitWidth: root.quiet
                   ? (implicitContentWidth + leftPadding + rightPadding)
                   : Math.max(96, implicitContentWidth + leftPadding + rightPadding)
    leftPadding: 14
    rightPadding: 14
    topPadding: 9
    bottomPadding: 9
    spacing: 8

    contentItem: Item {
        implicitWidth: contentRow.width
        implicitHeight: Math.max(contentRow.height, 18)

        Row {
            id: contentRow
            anchors.centerIn: parent
            spacing: root.spacing
            layoutDirection: root.mirrored ? Qt.RightToLeft : Qt.LeftToRight

            Image {
                visible: root.icon.source.toString().length > 0
                source: root.icon.source
                width: 18
                height: 18
                fillMode: Image.PreserveAspectFit
                opacity: root.enabled ? 1.0 : 0.45
            }

            Text {
                visible: root.text.length > 0
                text: root.text
                font: root.font
                color: !root.enabled ? Theme.textSubtle : Theme.text
            }
        }
    }

    background: Rectangle {
        radius: Theme.radiusMedium
        border.width: root.quiet ? 0 : 1
        border.color: !root.enabled
                      ? Theme.border
                      : (root.down || root.hovered ? Theme.borderStrong : Theme.border)
        color: !root.enabled
               ? Theme.surfaceSunken
               : root.quiet
                 ? (root.down ? Theme.selection : root.hovered ? Theme.accentSoft : "transparent")
                 : (root.down ? Theme.selection : root.hovered ? Theme.surface : Theme.surfaceRaised)
    }
}

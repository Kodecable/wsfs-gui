import QtQuick
import QtQuick.Controls
import "../theme/Theme.js" as Theme

SpinBox {
    id: root

    implicitHeight: Theme.controlHeight
    editable: true
    leftPadding: 30
    rightPadding: 30
    textFromValue: function(value, locale) {
        return Number(value).toString()
    }
    valueFromText: function(text, locale) {
        return Number(text)
    }

    contentItem: TextInput {
        z: 2
        text: root.displayText
        font: root.font
        color: Theme.text
        selectionColor: Theme.accent
        selectedTextColor: Theme.surfaceRaised
        horizontalAlignment: Qt.AlignHCenter
        verticalAlignment: Qt.AlignVCenter
        readOnly: !root.editable
        validator: root.validator
        inputMethodHints: Qt.ImhFormattedNumbersOnly
        padding: 0

        ContextMenu.menu: AppTextContextMenu {
            editor: parent
        }
    }

    down.indicator: Rectangle {
        x: 0
        y: 0
        width: 30
        height: parent.height
        color: root.up.pressed ? Theme.selection : "transparent"
        border.width: 0

        HoverHandler {
            cursorShape: Qt.PointingHandCursor
        }

        Text {
            anchors.centerIn: parent
            text: "−"
            color: Theme.textMuted
            font.pixelSize: 16
            font.bold: true
        }
    }

    up.indicator: Rectangle {
        x: parent.width - 30
        y: 0
        width: 30
        height: parent.height
        color: root.down.pressed ? Theme.selection : "transparent"
        border.width: 0

        HoverHandler {
            cursorShape: Qt.PointingHandCursor
        }

        Text {
            anchors.centerIn: parent
            text: "+"
            color: Theme.textMuted
            font.pixelSize: 16
            font.bold: true
        }
    }

    background: Rectangle {
        radius: Theme.radiusMedium
        border.width: 1
        border.color: root.activeFocus ? Theme.accent : Theme.border
        color: Theme.surfaceRaised

        Rectangle {
            x: 30
            width: 1
            height: parent.height - 10
            anchors.verticalCenter: parent.verticalCenter
            color: Theme.border
        }

        Rectangle {
            x: parent.width - 31
            width: 1
            height: parent.height - 10
            anchors.verticalCenter: parent.verticalCenter
            color: Theme.border
        }
    }
}

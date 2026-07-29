import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import "../theme/Theme.js" as Theme

Dialog {
    id: root

    property string dialogTitle: ""
    property string messageText: ""
    property alias buttons: buttonRow.data
    property real bodySpacing: 14
    property real contentMargin: 16
    property real buttonSpacing: 8
    readonly property bool hasMessage: root.messageText.length > 0
    readonly property bool hasButtons: buttonRow.children.length > 1

    parent: Overlay.overlay
    modal: true
    closePolicy: Popup.NoAutoClose
    padding: 0

    x: Math.round(((parent ? parent.width : 0) - width) / 2)
    y: Math.round(((parent ? parent.height : 0) - height) / 2)

    background: AppPanel {
        color: Theme.surfaceRaised
        radius: Theme.radiusLarge
    }

    Overlay.modal: Rectangle {
        color: "#00000018"
    }

    contentItem: Item {
        implicitWidth: root.width
        implicitHeight: dialogColumn.implicitHeight + root.contentMargin * 2

        ColumnLayout {
            id: dialogColumn
            anchors.fill: parent
            anchors.margins: root.contentMargin
            spacing: root.bodySpacing

            Label {
                text: root.dialogTitle
                color: Theme.text
                font.pixelSize: 18
                Layout.fillWidth: true
            }

            Rectangle {
                Layout.fillWidth: true
                height: 1
                color: Theme.border
            }

            Label {
                visible: root.hasMessage
                text: root.messageText
                wrapMode: Text.Wrap
                color: Theme.text
                Layout.fillWidth: true
            }

            RowLayout {
                id: buttonRow
                visible: root.hasButtons
                Layout.fillWidth: true
                spacing: root.buttonSpacing

                Item {
                    Layout.fillWidth: true
                }
            }
        }
    }
}

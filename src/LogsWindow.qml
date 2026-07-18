import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

Window {
    id: root
    title: profileId.length > 0
           ? qsTr("Runtime Logs - %1").arg(profileName)
           : qsTr("Runtime Logs")
    width: 980
    height: 540
    visible: false
    modality: Qt.ApplicationModal
    color: "#f3f4f6"

    property bool hasModel: false
    property var appModel: null
    property string profileId: ""
    property string profileName: ""
    property bool autoFollow: false

    function scrollToBottom() {
        if (!logScroll || !logMirror)
            return
        logMirror.cursorPosition = logMirror.length
        Qt.callLater(function() {
            const flick = logScroll.contentItem
            if (flick && flick.contentHeight !== undefined && flick.height !== undefined)
                flick.contentY = Math.max(0, flick.contentHeight - flick.height)
            if (logScroll.ScrollBar.vertical) {
                const sb = logScroll.ScrollBar.vertical
                sb.position = Math.max(0, 1 - sb.size)
            }
        })
    }

    ColumnLayout {
        anchors.fill: parent
        spacing: 0

        Rectangle {
            color: "#dee0e2"
            Layout.fillWidth: true
            height: 50

            RowLayout {
                anchors.fill: parent
                anchors.margins: 8

                Label {
                    text: root.profileId.length > 0
                          ? qsTr("Logs - %1").arg(root.profileName)
                          : qsTr("Logs")
                }
                Item { Layout.fillWidth: true }
                Switch {
                    text: qsTr("Auto Follow")
                    checked: root.autoFollow
                    onToggled: {
                        root.autoFollow = checked
                        if (checked)
                            root.scrollToBottom()
                    }
                }
            }
        }

        Rectangle {
            color: "#d1d5db"
            Layout.fillWidth: true
            height: 2
        }

        ScrollView {
            id: logScroll
            Layout.fillWidth: true
            Layout.fillHeight: true

            TextArea {
                id: logMirror
                property string _logTick: root.hasModel && root.appModel ? root.appModel.logs : ""
                font.family: "monospace"
                width: logScroll.availableWidth
                padding: 10
                text: {
                    const trigger = _logTick
                    return root.profileId.length > 0
                        ? (root.hasModel && root.appModel ? root.appModel.logsForProfile(root.profileId) : "")
                        : trigger
                }
                onTextChanged: {
                    if (root.autoFollow)
                        root.scrollToBottom()
                }
                readOnly: true
                wrapMode: Text.WrapAnywhere
                background: Rectangle {
                    color: "white"
                    radius: 0
                    border.color: "#d1d5db"
                }
            }
        }
    }
}

import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import "ui/controls"
import "ui/theme/Theme.js" as Theme

Window {
    id: root
    title: profileId.length > 0
           ? qsTr("Runtime Logs - %1").arg(profileName)
           : qsTr("Runtime Logs")
    width: 980
    height: 540
    visible: false
    modality: Qt.ApplicationModal
    color: Theme.window

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

        AppSectionHeader {
            Layout.fillWidth: true
            title: root.profileId.length > 0
                   ? qsTr("Logs - %1").arg(root.profileName)
                   : qsTr("Logs")

            AppSwitch {
                text: qsTr("Auto Follow")
                checked: root.autoFollow
                onToggled: {
                    root.autoFollow = checked
                    if (checked)
                        root.scrollToBottom()
                }
            }
        }

        Rectangle {
            color: Theme.border
            Layout.fillWidth: true
            height: 1
        }

        AppPanel {
            id: outerPanel
            Layout.fillWidth: true
            Layout.fillHeight: true
            Layout.margins: 16

            ScrollView {
                id: logScroll
                anchors.fill: parent
                anchors.margins: 0
                ScrollBar.vertical: AppScrollBar {}

                TextArea {
                    id: logMirror
                    property string _logTick: root.hasModel && root.appModel ? root.appModel.logs : ""
                    font.family: "monospace"
                    color: Theme.text
                    width: Math.max(0, logScroll.width - 16)
                    padding: 14
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
                        color: Theme.surface
                        radius: Theme.radiusMedium
                        border.width: 1
                        border.color: Theme.border
                    }
                }
            }
        }
    }
}

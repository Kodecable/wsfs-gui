import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

Item {
    id: root
    required property var profileData
    property bool selected: false

    signal profileEnabledToggled(string profileId, bool enabled)
    signal configureRequested(string profileId)
    signal logsRequested(string profileId)
    signal deleteRequested(string profileId)
    signal selectedRequested(string profileId)

    function stateText(state) {
        if (state === "Running")
            return qsTr("Running")
        if (state === "Starting")
            return qsTr("Starting")
        if (state === "Retrying")
            return qsTr("Retrying")
        if (state === "Stopping")
            return qsTr("Stopping")
        if (state === "Failed")
            return qsTr("Failed")
        return qsTr("Stopped")
    }

    function stateTextWithPid(state, pid, lastError) {
        if (state === "Running" && pid !== undefined && pid > 0)
            return qsTr("Running (%1)").arg(String(Math.trunc(Number(pid))))
        else if (state === "Retrying" && lastError && lastError.length > 0)
            return qsTr("Retrying (Last error: %1)").arg(lastError)
        else if (state === "Failed" && lastError && lastError.length > 0)
            return qsTr("Failed (Last error: %1)").arg(lastError)
        return stateText(state)
    }

    height: 64
    width: ListView.view ? ListView.view.width : 0

    Rectangle {
        anchors.fill: parent
        anchors.leftMargin: 16
        anchors.rightMargin: 16
        radius: 6
        color: "transparent"
        border.color: root.selected ? "#d1d5db" : "transparent"

        RowLayout {
            anchors.fill: parent
            anchors.margins: 8
            spacing: 6

            ColumnLayout {
                Layout.fillWidth: true
                Layout.leftMargin: 16
                Layout.rightMargin: 16
                Label {
                    Layout.fillWidth: true
                    text: root.profileData.name || qsTr("(Unnamed)")
                    font.bold: true
                    elide: Text.ElideRight
                }
                Label {
                    Layout.fillWidth: true
                    text: qsTr("State: %1").arg(root.stateTextWithPid(root.profileData.state || "Stopped", root.profileData.pid, root.profileData.lastError))
                    color: "#374151"
                    elide: Text.ElideRight
                }
            }

            Button {
                text: root.profileData.enabled ? qsTr("Stop") : qsTr("Start")
                icon.source: root.profileData.enabled
                            ? "qrc:/assets/icons/stop.svg"
                            : "qrc:/assets/icons/start.svg"
                Layout.leftMargin: 16
                Layout.rightMargin: 16
                leftPadding: 10
                rightPadding: 10
                Layout.preferredWidth: Math.max(72, implicitContentWidth + leftPadding + rightPadding)
                Layout.maximumWidth: Layout.preferredWidth
                Layout.alignment: Qt.AlignVCenter | Qt.AlignRight
                onClicked: root.profileEnabledToggled(root.profileData.id, !root.profileData.enabled)
            }
        }

        TapHandler {
            acceptedButtons: Qt.RightButton
            onTapped: function() {
                root.selectedRequested(root.profileData.id)
                rowMenu.popup()
            }
        }

        TapHandler {
            acceptedButtons: Qt.LeftButton
            onTapped: function() {
                root.selectedRequested(root.profileData.id)
            }
        }

        Menu {
            id: rowMenu
            MenuItem {
                text: qsTr("Config")
                icon.source: "qrc:/assets/icons/settings.svg"
                onTriggered: root.configureRequested(root.profileData.id)
            }
            MenuItem {
                text: qsTr("Logs")
                icon.source: "qrc:/assets/icons/logs.svg"
                onTriggered: root.logsRequested(root.profileData.id)
            }
            MenuItem {
                text: qsTr("Delete")
                icon.source: "qrc:/assets/icons/delete.svg"
                onTriggered: root.deleteRequested(root.profileData.id)
            }
        }
    }
}

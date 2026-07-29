import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import "ui/controls"
import "ui/theme/Theme.js" as Theme

Item {
    id: root
    property bool hasModel: false
    property var profiles: []
    property string selectedProfileId: ""

    signal createRequested()
    signal stopAllRequested()
    signal profileEnabledToggled(string profileId, bool enabled)
    signal configureRequested(string profileId)
    signal logsRequested(string profileId)
    signal deleteRequested(string profileId)
    signal selectedRequested(string profileId)

    Layout.fillWidth: true
    Layout.fillHeight: true
    ColumnLayout {
        anchors.fill: parent
        spacing: Theme.panelGap

        RowLayout {
            Layout.fillWidth: true

            Label {
                text: qsTr("Mount List")
                color: Theme.text
                font.pixelSize: 18
                font.bold: false
            }
            Item { Layout.fillWidth: true }
            AppButton {
                text: qsTr("New")
                icon.source: "qrc:/assets/icons/add.svg"
                onClicked: root.createRequested()
            }
            AppButton {
                text: qsTr("Stop All")
                icon.source: "qrc:/assets/icons/stop-circle.svg"
                enabled: root.hasModel
                onClicked: root.stopAllRequested()
            }
        }

        AppPanel {
            Layout.fillWidth: true
            Layout.fillHeight: true

            ScrollView {
                anchors.top: parent.top
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.bottom: parent.bottom
                anchors.margins: 8
                clip: true

                ScrollBar.vertical: AppScrollBar {}

                ListView {
                    id: profileList
                    width: parent.availableWidth
                    model: root.profiles
                    spacing: 8

                    header: Item {
                        width: parent.width
                        height: 8
                    }

                    delegate: ProfileListDelegate {
                        required property var modelData
                        profileData: modelData
                        selected: root.selectedProfileId === modelData.id
                        onProfileEnabledToggled: function(profileId, enabled) {
                            root.profileEnabledToggled(profileId, enabled)
                        }
                        onConfigureRequested: function(profileId) {
                            root.configureRequested(profileId)
                        }
                        onLogsRequested: function(profileId) {
                            root.logsRequested(profileId)
                        }
                        onDeleteRequested: function(profileId) {
                            root.deleteRequested(profileId)
                        }
                        onSelectedRequested: function(profileId) {
                            root.selectedRequested(profileId)
                        }
                    }
                }
            }
        }
    }
}

import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

Rectangle {
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
    color: "#f4f5f7"

    ColumnLayout {
        anchors.fill: parent
        spacing: 8

        RowLayout {
            Layout.fillWidth: true
            Layout.leftMargin: 16
            Layout.rightMargin: 16

            Label { text: qsTr("Mount List") }
            Item { Layout.fillWidth: true }
            Button {
                text: qsTr("New")
                icon.source: "qrc:/assets/icons/add.svg"
                onClicked: root.createRequested()
            }
            Button {
                text: qsTr("Stop All")
                icon.source: "qrc:/assets/icons/stop-circle.svg"
                enabled: root.hasModel
                onClicked: root.stopAllRequested()
            }
        }
        
        Rectangle {
            Layout.fillWidth: true
            Layout.fillHeight: true
            color: "#FFFFFF"

            Rectangle {
                id: borderRectangle
                color: "#d1d5db"
                height: 1.6
                anchors.top: parent.top
                anchors.left: parent.left
                anchors.right: parent.right
            }

            ScrollView {
                anchors.top: borderRectangle.top
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.bottom: parent.bottom
                clip: true

                ScrollBar.vertical.policy: ScrollBar.AsNeeded

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

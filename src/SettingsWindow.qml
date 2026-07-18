import QtQuick
import QtQuick.Controls
import QtQuick.Dialogs
import QtQuick.Layouts

Window {
    id: root
    title: qsTr("Settings")
    width: 520
    height: 360
    visible: false
    modality: Qt.ApplicationModal
    color: "#f3f4f6"

    property bool hasModel: false
    property var appModel: null

    onClosing: {
        root.appModel.wsfsExecutablePath = wsfsPathField.text.trim()
    }

    FileDialog {
        id: wsfsPathDialog
        title: qsTr("Select wsfs Executable")
        fileMode: FileDialog.OpenFile
        onAccepted: {
            if (!root.hasModel)
                return
            const p = selectedFile && selectedFile.toLocalFile
                    ? selectedFile.toLocalFile()
                    : selectedFile.toString().replace(/^file:\/\//, "")
            wsfsPathField.text = p.trim()
            root.appModel.wsfsExecutablePath = p.trim()
        }
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
                    text: qsTr("Application Settings")
                    Layout.alignment: Qt.AlignVCenter
                }
                Item { Layout.fillWidth: true }
            }
        }

        Rectangle {
            color: "#d1d5db"
            Layout.fillWidth: true
            height: 2
        }

        ColumnLayout {
            Layout.fillWidth: true
            Layout.fillHeight: true
            Layout.margins: 14
            spacing: 12

            Label {
                text: qsTr("WSFS Path")
            }
            RowLayout {
                Layout.fillWidth: true
                TextField {
                    id: wsfsPathField
                    Layout.fillWidth: true
                    placeholderText: qsTr("Empty = auto lookup")
                    text: root.hasModel && root.appModel ? root.appModel.wsfsExecutablePath : ""
                    onEditingFinished: {
                        if (root.hasModel)
                            root.appModel.wsfsExecutablePath = text.trim()
                    }
                }
                Button {
                    text: qsTr("Browse")
                    onClicked: wsfsPathDialog.open()
                }
            }

            CheckBox {
                text: qsTr("Start at Login")
                checked: root.hasModel && root.appModel ? root.appModel.autoStartOnBoot : false
                onToggled: {
                    if (root.hasModel)
                        root.appModel.autoStartOnBoot = checked
                }
            }

            CheckBox {
                text: qsTr("Minimize to Tray on Launch")
                checked: root.hasModel && root.appModel ? root.appModel.minimizeToTrayOnLaunch : false
                onToggled: {
                    if (root.hasModel)
                        root.appModel.minimizeToTrayOnLaunch = checked
                }
            }

            CheckBox {
                text: qsTr("Restore Enabled Mounts on Launch")
                checked: root.hasModel && root.appModel ? root.appModel.restoreEnabledProfilesOnLaunch : false
                onToggled: {
                    if (root.hasModel)
                        root.appModel.restoreEnabledProfilesOnLaunch = checked
                }
            }

            CheckBox {
                text: qsTr("Use system credential store")
                checked: root.hasModel && root.appModel ? root.appModel.useSystemCredentialStore : false
                enabled: root.hasModel && root.appModel ? !root.appModel.credentialOperationInProgress : false
                onToggled: {
                    if (root.hasModel && checked !== root.appModel.useSystemCredentialStore)
                        root.appModel.setUseSystemCredentialStore(checked)
                }
            }

            Item { Layout.fillHeight: true }

            RowLayout {
                Layout.fillWidth: true
                Label {
                    text: (root.hasModel && root.appModel && root.appModel.wsfsGuiVersion.length > 0)
                          ? root.appModel.wsfsGuiVersion
                          : qsTr("WSFS-GUI")
                    color: "#4b5563"
                    horizontalAlignment: Text.AlignLeft
                }
                Item { Layout.fillWidth: true }
                Label {
                    text: (root.hasModel && root.appModel && root.appModel.wsfsVersionLine.length > 0)
                          ? root.appModel.wsfsVersionLine
                          : qsTr("(WSFS version unavailable)")
                    color: "#4b5563"
                    horizontalAlignment: Text.AlignRight
                }
            }
        }
    }
}

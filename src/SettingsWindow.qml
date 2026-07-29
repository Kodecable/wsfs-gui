import QtQuick
import QtQuick.Controls
import QtQuick.Dialogs
import QtQuick.Layouts
import "ui/controls"
import "ui/theme/Theme.js" as Theme

Window {
    id: root
    title: qsTr("Settings")
    width: 520
    height: 420
    visible: false
    modality: Qt.ApplicationModal
    color: Theme.window

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

        AppSectionHeader {
            Layout.fillWidth: true
            title: qsTr("Application Settings")
        }

        Rectangle {
            color: Theme.border
            Layout.fillWidth: true
            height: 1
        }

        AppPanel {
            Layout.fillWidth: true
            Layout.fillHeight: true
            Layout.margins: 16

            ColumnLayout {
                anchors.fill: parent
                anchors.margins: Theme.panelPadding
                spacing: 4

                Label {
                    text: qsTr("WSFS Path")
                    color: Theme.text
                    font.bold: false
                }

                RowLayout {
                    Layout.fillWidth: true

                    AppTextField {
                        id: wsfsPathField
                        Layout.fillWidth: true
                        placeholderText: qsTr("Empty = auto lookup")
                        text: root.hasModel && root.appModel ? root.appModel.wsfsExecutablePath : ""
                        onEditingFinished: {
                            if (root.hasModel)
                                root.appModel.wsfsExecutablePath = text.trim()
                        }
                    }

                    AppButton {
                        text: qsTr("Browse")
                        onClicked: wsfsPathDialog.open()
                    }
                }

                Item {
                    height: 6
                }

                AppCheckBox {
                    text: qsTr("Start at Login")
                    checked: root.hasModel && root.appModel ? root.appModel.autoStartOnBoot : false
                    onToggled: {
                        if (root.hasModel)
                            root.appModel.autoStartOnBoot = checked
                    }
                }

                AppCheckBox {
                    text: qsTr("Minimize to Tray on Launch")
                    checked: root.hasModel && root.appModel ? root.appModel.minimizeToTrayOnLaunch : false
                    onToggled: {
                        if (root.hasModel)
                            root.appModel.minimizeToTrayOnLaunch = checked
                    }
                }

                AppCheckBox {
                    text: qsTr("Restore Enabled Mounts on Launch")
                    checked: root.hasModel && root.appModel ? root.appModel.restoreEnabledProfilesOnLaunch : false
                    onToggled: {
                        if (root.hasModel)
                            root.appModel.restoreEnabledProfilesOnLaunch = checked
                    }
                }

                AppCheckBox {
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
                        color: Theme.textMuted
                        horizontalAlignment: Text.AlignLeft
                    }

                    Item { Layout.fillWidth: true }

                    Label {
                        text: (root.hasModel && root.appModel && root.appModel.wsfsVersionLine.length > 0)
                              ? root.appModel.wsfsVersionLine
                              : qsTr("(WSFS version unavailable)")
                        color: Theme.textMuted
                        horizontalAlignment: Text.AlignRight
                    }
                }
            }
        }
    }
}

import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

Item {
    id: root
    readonly property int formWidth: 420
    readonly property bool isLinux: Qt.platform.os === "linux"
    readonly property bool isUnix: isLinux || Qt.platform.os === "osx" || Qt.platform.os === "unix"
    readonly property bool isWindows: Qt.platform.os === "windows"

    implicitWidth: formWidth
    implicitHeight: formItem.implicitHeight

    property var profile: ({})

    function isComplete() {
        return nameField.text.trim().length > 0
               && mountPointField.text.trim().length > 0
               && hostField.text.trim().length > 0
    }

    function normalizeWindowsMountPoint(value) {
        if (!root.isWindows)
            return value
        const trimmed = String(value).trim()
        if (trimmed.length === 0)
            return trimmed
        if (/^[a-zA-Z]:(\\|\/|$)/.test(trimmed))
            return trimmed
        let result = trimmed.replace(/[^a-zA-Z]/g, "").toUpperCase()
        if (result.length > 0)
            result = result[0] + ":"
        return result
    }

    function loadProfile(nextProfile) {
        profile = nextProfile || ({})
        if (!profile || profile.id === undefined)
            return

        nameField.text = profile.name || ""
        schemeField.currentIndex = Math.max(0, schemeField.find(profile.scheme || "wsfs"))
        hostField.text = profile.host || "localhost"
        portField.value = Math.max(1, Math.min(65535, parseInt(profile.port) || 20001))
        pathField.text = profile.path || "/"
        appendWsfsQuery.checked = profile.appendWsfsQuery !== false
        usernameField.text = profile.username || ""
        passwordField.text = ""
        mountPointField.text = normalizeWindowsMountPoint(profile.mountPoint || "")
        logLevelField.currentIndex = logLevelField.indexOfValue(profile.logLevel || "info")
        structTimeoutField.text = (profile.structTimeout !== undefined && profile.structTimeout >= 0)
                                  ? String(profile.structTimeout)
                                  : ""

        directMountBox.checked = !!profile.directMount
        uidField.text = (profile.uid !== undefined && profile.uid >= 0) ? String(profile.uid) : ""
        gidField.text = (profile.gid !== undefined && profile.gid >= 0) ? String(profile.gid) : ""
        otherUidField.text = (profile.otherUid !== undefined && profile.otherUid >= 0)
                              ? String(profile.otherUid)
                              : ""
        otherGidField.text = (profile.otherGid !== undefined && profile.otherGid >= 0)
                              ? String(profile.otherGid)
                              : ""

        pingIntervalField.text = (profile.pingInterval !== undefined && profile.pingInterval >= 0)
                                  ? String(profile.pingInterval)
                                  : ""
        certHashField.text = profile.certHash || ""
        flockModeField.currentIndex = Math.max(0, flockModeField.find(profile.flockMode || ""))

        volumeLabelField.text = profile.volumeLabel || ""
        masqueradeAsNtfsBox.checked = !!profile.masqueradeAsNtfs
    }

    function payload() {
        const data = {
            name: nameField.text,
            scheme: schemeField.currentText,
            host: hostField.text,
            port: portField.value,
            path: pathField.text,
            appendWsfsQuery: appendWsfsQuery.checked,
            username: usernameField.text,
            mountPoint: normalizeWindowsMountPoint(mountPointField.text),
            logLevel: logLevelField.currentValue,
            structTimeout: structTimeoutField.text.trim(),
            directMount: directMountBox.checked,
            uid: uidField.text.trim(),
            gid: gidField.text.trim(),
            otherUid: otherUidField.text.trim(),
            otherGid: otherGidField.text.trim(),
            pingInterval: pingIntervalField.text.trim(),
            certHash: certHashField.text.trim(),
            flockMode: flockModeField.currentValue,
            volumeLabel: volumeLabelField.text.trim(),
            masqueradeAsNtfs: masqueradeAsNtfsBox.checked
        }
        if (passwordField.text.length > 0)
            data.password = passwordField.text
        return data
    }

    function payloadFromProfile(source) {
        if (!source || source.id === undefined)
            return null

        return {
            name: source.name || "",
            scheme: source.scheme || "wsfs",
            host: source.host || "localhost",
            port: parseInt(source.port),
            path: source.path || "/",
            appendWsfsQuery: source.appendWsfsQuery !== false,
            username: source.username || "",
            mountPoint: normalizeWindowsMountPoint(source.mountPoint || ""),
            logLevel: source.logLevel || "info",
            structTimeout: (source.structTimeout !== undefined && parseInt(source.structTimeout) >= 0)
                           ? String(parseInt(source.structTimeout))
                           : "",
            directMount: !!source.directMount,
            uid: (source.uid !== undefined && parseInt(source.uid) >= 0) ? String(parseInt(source.uid)) : "",
            gid: (source.gid !== undefined && parseInt(source.gid) >= 0) ? String(parseInt(source.gid)) : "",
            otherUid: (source.otherUid !== undefined && parseInt(source.otherUid) >= 0)
                       ? String(parseInt(source.otherUid))
                       : "",
            otherGid: (source.otherGid !== undefined && parseInt(source.otherGid) >= 0)
                       ? String(parseInt(source.otherGid))
                       : "",
            pingInterval: (source.pingInterval !== undefined && parseInt(source.pingInterval) >= 0)
                           ? String(parseInt(source.pingInterval))
                           : "",
            certHash: source.certHash || "",
            flockMode: source.flockMode || "",
            volumeLabel: source.volumeLabel || "",
            masqueradeAsNtfs: !!source.masqueradeAsNtfs
        }
    }

    function hasChanges() {
        const baseline = payloadFromProfile(profile)
        if (!baseline)
            return false
        return JSON.stringify(payload()) !== JSON.stringify(baseline)
    }

    Item {
        id: formItem
        anchors.fill: parent
        anchors.topMargin: formGrid.columnSpacing
        anchors.bottomMargin: formGrid.columnSpacing
        implicitHeight: formGrid.implicitHeight + formGrid.columnSpacing * 2

        GridLayout {
            id: formGrid
            anchors.horizontalCenter: parent.horizontalCenter
            columns: 2
            columnSpacing: 12
            rowSpacing: 8
            width: root.formWidth

            Label {
                text: qsTr("Name")
                horizontalAlignment: Text.AlignRight
                Layout.preferredWidth: 160
                Layout.alignment: Qt.AlignRight | Qt.AlignVCenter
            }
            TextField {
                id: nameField
                Layout.fillWidth: true
            }

            Rectangle {
                Layout.columnSpan: 2
                Layout.fillWidth: true
                height: 1
                color: "#d1d5db"
            }

            Label {
                text: qsTr("Mount Point")
                horizontalAlignment: Text.AlignRight
                Layout.preferredWidth: 160
                Layout.alignment: Qt.AlignRight | Qt.AlignVCenter
            }
            TextField {
                id: mountPointField
                Layout.fillWidth: true
                onEditingFinished: {
                    if (root.isWindows)
                        text = normalizeWindowsMountPoint(text)
                }
            }

            Label {
                text: qsTr("Log Level")
                horizontalAlignment: Text.AlignRight
                Layout.preferredWidth: 160
                Layout.alignment: Qt.AlignRight | Qt.AlignVCenter
            }
            ComboBox {
                id: logLevelField
                model: [
                    { text: "trace", value: "trace" },
                    { text: "debug", value: "debug" },
                    { text: "info", value: "info" },
                    { text: "warning", value: "warning" },
                    { text: "error", value: "error" },
                    { text: "fatal", value: "fatal" },
                    { text: "panic", value: "panic" }
                ]
                textRole: "text"
                valueRole: "value"
                currentIndex: 2
                Layout.fillWidth: true
            }

            Label {
                text: qsTr("Struct cache timeout")
                horizontalAlignment: Text.AlignRight
                Layout.preferredWidth: 160
                Layout.alignment: Qt.AlignRight | Qt.AlignVCenter
            }
            TextField {
                id: structTimeoutField
                Layout.fillWidth: true
                placeholderText: qsTr("Empty = default")
            }

            Label {
                text: qsTr("Append WSFS query automatically")
                horizontalAlignment: Text.AlignRight
                Layout.preferredWidth: 160
                Layout.alignment: Qt.AlignRight | Qt.AlignVCenter
            }
            CheckBox {
                id: appendWsfsQuery
                checked: true
                Layout.fillWidth: true
            }

            Rectangle {
                Layout.columnSpan: 2
                Layout.fillWidth: true
                height: 1
                color: "#d1d5db"
            }

            Label {
                text: qsTr("Scheme")
                horizontalAlignment: Text.AlignRight
                Layout.preferredWidth: 160
                Layout.alignment: Qt.AlignRight | Qt.AlignVCenter
            }
            ComboBox {
                id: schemeField
                model: ["wsfs", "wsfss"]
                currentIndex: 0
                Layout.fillWidth: true
            }

            Label {
                text: qsTr("Host")
                horizontalAlignment: Text.AlignRight
                Layout.preferredWidth: 160
                Layout.alignment: Qt.AlignRight | Qt.AlignVCenter
            }
            TextField {
                id: hostField
                text: "localhost"
                Layout.fillWidth: true
            }

            Label {
                text: qsTr("Port")
                horizontalAlignment: Text.AlignRight
                Layout.preferredWidth: 160
                Layout.alignment: Qt.AlignRight | Qt.AlignVCenter
            }
            SpinBox {
                id: portField
                from: 1
                to: 65535
                value: 20001
                editable: true
                Layout.fillWidth: true
            }

            Label {
                text: qsTr("Path")
                horizontalAlignment: Text.AlignRight
                Layout.preferredWidth: 160
                Layout.alignment: Qt.AlignRight | Qt.AlignVCenter
            }
            TextField {
                id: pathField
                text: "/"
                Layout.fillWidth: true
                placeholderText: qsTr("Empty = default")
            }

            Label {
                text: qsTr("Ping Interval")
                horizontalAlignment: Text.AlignRight
                Layout.preferredWidth: 160
                Layout.alignment: Qt.AlignRight | Qt.AlignVCenter
            }
            TextField {
                id: pingIntervalField
                Layout.fillWidth: true
                placeholderText: qsTr("Empty = default")
            }

            Label {
                text: qsTr("Cert Hash")
                horizontalAlignment: Text.AlignRight
                Layout.preferredWidth: 160
                Layout.alignment: Qt.AlignRight | Qt.AlignVCenter
            }
            TextField {
                id: certHashField
                Layout.fillWidth: true
                placeholderText: qsTr("Empty = none")
            }

            Label {
                text: qsTr("Username")
                horizontalAlignment: Text.AlignRight
                Layout.preferredWidth: 160
                Layout.alignment: Qt.AlignRight | Qt.AlignVCenter
            }
            TextField {
                id: usernameField
                Layout.fillWidth: true
                placeholderText: qsTr("Empty = anonymous")
            }

            Label {
                text: qsTr("Password")
                horizontalAlignment: Text.AlignRight
                Layout.preferredWidth: 160
                Layout.alignment: Qt.AlignRight | Qt.AlignVCenter
            }
            TextField {
                id: passwordField
                echoMode: TextInput.Password
                Layout.fillWidth: true
                placeholderText: qsTr("Leave blank to keep current password")
            }

            Rectangle {
                Layout.columnSpan: 2
                Layout.fillWidth: true
                height: 1
                color: "#d1d5db"
                visible: root.isUnix || root.isWindows
            }

            Label {
                text: qsTr("Bypass fusemount")
                horizontalAlignment: Text.AlignRight
                visible: root.isLinux
                Layout.preferredWidth: 160
                Layout.alignment: Qt.AlignRight | Qt.AlignVCenter
            }
            CheckBox {
                id: directMountBox
                visible: root.isLinux
                Layout.fillWidth: true
            }

            Label {
                text: qsTr("UID")
                horizontalAlignment: Text.AlignRight
                visible: root.isUnix
                Layout.preferredWidth: 160
                Layout.alignment: Qt.AlignRight | Qt.AlignVCenter
            }
            TextField {
                id: uidField
                visible: root.isUnix
                Layout.fillWidth: true
                placeholderText: qsTr("Empty = default")
            }

            Label {
                text: qsTr("GID")
                horizontalAlignment: Text.AlignRight
                visible: root.isUnix
                Layout.preferredWidth: 160
                Layout.alignment: Qt.AlignRight | Qt.AlignVCenter
            }
            TextField {
                id: gidField
                visible: root.isUnix
                Layout.fillWidth: true
                placeholderText: qsTr("Empty = default")
            }

            Label {
                text: qsTr("Other UID")
                horizontalAlignment: Text.AlignRight
                visible: root.isUnix
                Layout.preferredWidth: 160
                Layout.alignment: Qt.AlignRight | Qt.AlignVCenter
            }
            TextField {
                id: otherUidField
                visible: root.isUnix
                Layout.fillWidth: true
                placeholderText: qsTr("Empty = default")
            }

            Label {
                text: qsTr("Other GID")
                horizontalAlignment: Text.AlignRight
                visible: root.isUnix
                Layout.preferredWidth: 160
                Layout.alignment: Qt.AlignRight | Qt.AlignVCenter
            }
            TextField {
                id: otherGidField
                visible: root.isUnix
                Layout.fillWidth: true
                placeholderText: qsTr("Empty = default")
            }

            Label {
                text: qsTr("BSD Flock Mode")
                horizontalAlignment: Text.AlignRight
                visible: root.isLinux
                Layout.preferredWidth: 160
                Layout.alignment: Qt.AlignRight | Qt.AlignVCenter
            }
            ComboBox {
                id: flockModeField
                visible: root.isLinux
                model: [
                    { text: qsTr("default"), value: "" },
                    { text: "ofd", value: "ofd" },
                    { text: "unsupported", value: "unsupported" },
                    { text: "noop", value: "noop" }
                ]
                textRole: "text"
                valueRole: "value"
                currentIndex: 0
                Layout.fillWidth: true
            }

            Rectangle {
                Layout.columnSpan: 2
                Layout.fillWidth: true
                height: 1
                color: "#d1d5db"
                visible: root.isWindows
            }

            Label {
                text: qsTr("Volume label")
                horizontalAlignment: Text.AlignRight
                visible: root.isWindows
                Layout.preferredWidth: 160
                Layout.alignment: Qt.AlignRight | Qt.AlignVCenter
            }
            TextField {
                id: volumeLabelField
                visible: root.isWindows
                Layout.fillWidth: true
                placeholderText: qsTr("Empty = default")
            }

            Label {
                text: qsTr("Masquerade as NTFS")
                horizontalAlignment: Text.AlignRight
                visible: root.isWindows
                Layout.preferredWidth: 160
                Layout.alignment: Qt.AlignRight | Qt.AlignVCenter
            }
            CheckBox {
                id: masqueradeAsNtfsBox
                visible: root.isWindows
                Layout.fillWidth: true
            }
        }
    }
}

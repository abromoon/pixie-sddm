/*
    Pixie SDDM - KDE Plasma 5 lock screen port
    Copyright (c) 2026 xCaptaiN09
    License: MIT
*/
import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Layouts 1.15
import QtGraphicalEffects 1.15

import org.kde.plasma.core 2.0 as PlasmaCore
import org.kde.plasma.components 3.0 as PlasmaComponents3
import org.kde.plasma.workspace.components 2.0 as PW

import "components"

PlasmaCore.ColorScope {
    id: lockScreenUi
    colorGroup: PlasmaCore.Theme.ComplementaryColorGroup

    // ---- Palette (config-driven, with safe fallbacks) ----
    property color accentColor: (typeof config !== "undefined" && config.accentColor !== undefined) ? config.accentColor : "#A9C78F"
    property color baseColor: (typeof config !== "undefined" && config.backgroundColor !== undefined) ? config.backgroundColor : "#1A1C18"
    property color textColor: (typeof config !== "undefined" && config.textColor !== undefined) ? config.textColor : "#E3E3DC"
    property color surfaceColor: Qt.lighter(baseColor, 1.3)
    property color surfaceVariantColor: Qt.lighter(baseColor, 1.6)
    property bool use24HourClock: !(typeof config !== "undefined" && config.use24HourClock !== undefined) || config.use24HourClock === true
    property bool showMediaControls: typeof config === "undefined" || config.showMediaControls !== false

    property bool hadPrompt: false
    property bool showNoPasswordUnlock: false

    // ---- Fonts ----
    FontLoader { id: fontRegular; source: "assets/fonts/FlexRounded-R.ttf" }
    FontLoader { id: fontMedium; source: "assets/fonts/FlexRounded-M.ttf" }
    FontLoader { id: fontBold; source: "assets/fonts/FlexRounded-B.ttf" }
    FontLoader { id: iconFont; source: "assets/fonts/MaterialDesignIcons.ttf" }

    PlasmaCore.DataSource {
        id: keystateSource
        engine: "keystate"
        connectedSources: "Caps Lock"
    }

    function authenticate() {
        passwordField.forceActiveFocus();
        authenticator.respond(passwordField.text);
    }

    Connections {
        target: authenticator
        function onFailed() {
            lockScreenUi.hadPrompt = false;
            loginState.isError = true;
            shakeAnimation.restart();
            passwordField.text = "";
            passwordField.forceActiveFocus();
            graceLockTimer.restart();
        }
        function onSucceeded() {
            if (lockScreenUi.hadPrompt) {
                Qt.quit();
            } else {
                lockScreenUi.showNoPasswordUnlock = true;
            }
        }
        function onInfoMessage(msg) {
            if (root.notification) root.notification += "\n";
            root.notification += msg;
            lockScreenUi.hadPrompt = true;
        }
        function onErrorMessage(msg) {
            if (root.notification) root.notification += "\n";
            root.notification += msg;
        }
        function onPrompt(msg) {
            root.notification = msg;
            lockScreenRoot.uiVisible = true;
            lockScreenUi.hadPrompt = true;
            passwordField.forceActiveFocus();
        }
        function onPromptForSecret(msg) {
            lockScreenRoot.uiVisible = true;
            lockScreenUi.hadPrompt = true;
            passwordField.forceActiveFocus();
        }
    }

    // ---- Background: sharp wallpaper when idle, blurred + darkened when prompting ----
    Rectangle {
        anchors.fill: parent
        color: lockScreenUi.baseColor
        visible: typeof wallpaper === "undefined"
    }

    FastBlur {
        id: backgroundBlur
        anchors.fill: parent
        source: (typeof wallpaper !== "undefined") ? wallpaper : null
        radius: lockScreenRoot.uiVisible ? 64 : 0
        Behavior on radius { NumberAnimation { duration: 400; easing.type: Easing.InOutQuad } }
    }

    Rectangle {
        anchors.fill: parent
        color: "black"
        opacity: lockScreenRoot.uiVisible ? 0.6 : 0.4
        Behavior on opacity { NumberAnimation { duration: 400 } }
    }

    // ---- Root interaction / idle->prompt toggle ----
    MouseArea {
        id: lockScreenRoot
        anchors.fill: parent
        focus: true

        property bool uiVisible: false
        property bool calledUnlock: false

        onClicked: {
            uiVisible = true;
            wakeUp();
        }

        Keys.onPressed: {
            uiVisible = true;
            wakeUp();
            event.accepted = false;
        }

        Keys.onEscapePressed: {
            if (uiVisible) {
                uiVisible = false;
                passwordField.text = "";
                root.clearPassword();
            }
        }

        function wakeUp() {
            fadeoutTimer.restart();
            if (!calledUnlock) {
                calledUnlock = true;
                authenticator.tryUnlock();
            }
        }
    }

    Timer {
        id: fadeoutTimer
        interval: 10000
        onTriggered: {
            if (passwordField.text.length === 0 && !lockScreenUi.showNoPasswordUnlock) {
                lockScreenRoot.uiVisible = false;
            }
        }
    }
    Timer {
        id: graceLockTimer
        interval: 3000
        onTriggered: {
            passwordField.text = "";
            authenticator.tryUnlock();
        }
    }

    // ---- Idle: big clock + date + hint ----
    Clock {
        id: mainClock
        anchors.centerIn: parent
        fontFamily: fontRegular.name
        baseAccent: lockScreenUi.accentColor
        use24HourClock: lockScreenUi.use24HourClock
        opacity: lockScreenRoot.uiVisible ? 0 : 1
        Behavior on opacity { NumberAnimation { duration: 300 } }
    }

    Text {
        id: dateText
        text: Qt.formatDateTime(new Date(), "dddd, MMMM d")
        color: lockScreenUi.accentColor
        font.pixelSize: 22
        font.family: fontRegular.name
        anchors {
            top: mainClock.bottom
            topMargin: 24
            horizontalCenter: parent.horizontalCenter
        }
        opacity: lockScreenRoot.uiVisible ? 0 : 1
        Behavior on opacity { NumberAnimation { duration: 300 } }
    }

    Text {
        text: "Press any key to unlock"
        color: lockScreenUi.textColor
        font.pixelSize: 16
        font.family: fontRegular.name
        anchors {
            bottom: parent.bottom
            horizontalCenter: parent.horizontalCenter
            bottomMargin: 100
        }
        opacity: (lockScreenRoot.uiVisible || lockScreenUi.showNoPasswordUnlock) ? 0 : 0.5
        Behavior on opacity { NumberAnimation { duration: 300 } }
    }

    // ---- Login card ----
    Item {
        id: loginState
        anchors.fill: parent
        visible: lockScreenRoot.uiVisible && !lockScreenUi.showNoPasswordUnlock
        opacity: visible ? 1 : 0
        Behavior on opacity { NumberAnimation { duration: 400 } }

        property bool isError: false

        onVisibleChanged: {
            if (visible) passwordField.forceActiveFocus();
        }

        SequentialAnimation {
            id: shakeAnimation
            loops: 2
            PropertyAnimation { target: loginCard; property: "x"; from: (parent.width - loginCard.width)/2; to: (parent.width - loginCard.width)/2 - 10; duration: 50; easing.type: Easing.InOutQuad }
            PropertyAnimation { target: loginCard; property: "x"; from: (parent.width - loginCard.width)/2 - 10; to: (parent.width - loginCard.width)/2 + 10; duration: 50; easing.type: Easing.InOutQuad }
            PropertyAnimation { target: loginCard; property: "x"; from: (parent.width - loginCard.width)/2 + 10; to: (parent.width - loginCard.width)/2; duration: 50; easing.type: Easing.InOutQuad }
            onStopped: isError = false
        }

        Rectangle {
            id: loginCard
            width: 380
            height: 460
            x: (parent.width - width) / 2
            y: (parent.height - height) / 2
            color: loginState.isError ? "#442222" : lockScreenUi.baseColor
            opacity: 0.7
            radius: 32

            Behavior on color { ColorAnimation { duration: 200 } }

            ColumnLayout {
                anchors.fill: parent
                anchors.margins: 40
                spacing: 15

                // Avatar
                Item {
                    Layout.preferredWidth: 100
                    Layout.preferredHeight: 100
                    Layout.alignment: Qt.AlignHCenter

                    Rectangle {
                        anchors.fill: parent
                        color: lockScreenUi.surfaceColor
                        radius: width / 2
                        visible: avatar.status !== Image.Ready

                        Text {
                            anchors.centerIn: parent
                            text: (typeof kscreenlocker_userName !== "undefined" && kscreenlocker_userName) ? kscreenlocker_userName.charAt(0).toUpperCase() : "U"
                            color: lockScreenUi.accentColor
                            font.pixelSize: 42
                            font.family: fontBold.name
                            font.weight: Font.Bold
                        }
                    }

                    Image {
                        id: avatar
                        anchors.fill: parent
                        fillMode: Image.PreserveAspectCrop
                        smooth: true
                        visible: false
                        source: (typeof kscreenlocker_userImage !== "undefined" && kscreenlocker_userImage) ? kscreenlocker_userImage : ""
                        onStatusChanged: {
                            if (status === Image.Error) source = "";
                        }
                    }

                    Rectangle {
                        id: avatarMask
                        anchors.fill: parent
                        radius: width / 2
                        visible: false
                    }

                    OpacityMask {
                        anchors.fill: parent
                        source: avatar
                        maskSource: avatarMask
                        visible: avatar.status === Image.Ready
                    }
                }

                // Username
                Text {
                    Layout.alignment: Qt.AlignHCenter
                    text: (typeof kscreenlocker_userName !== "undefined" && kscreenlocker_userName) ? kscreenlocker_userName : "User"
                    color: "white"
                    font.pixelSize: 24
                    font.weight: Font.Bold
                    font.family: fontRegular.name
                }

                // Password field
                TextField {
                    id: passwordField
                    Layout.topMargin: 15
                    echoMode: TextInput.Password
                    Layout.fillWidth: true
                    horizontalAlignment: Text.AlignHCenter
                    font.pixelSize: 18
                    color: "white"
                    enabled: !authenticator.graceLocked

                    background: Rectangle {
                        color: lockScreenUi.surfaceColor
                        radius: 16
                        border.width: parent.activeFocus ? 2 : 0
                        border.color: lockScreenUi.accentColor
                        opacity: parent.enabled ? 1.0 : 0.5
                    }

                    Text {
                        text: "Enter Password"
                        color: "gray"
                        font.pixelSize: 16
                        font.family: fontRegular.name
                        visible: !parent.text
                        anchors.centerIn: parent
                        opacity: 0.5
                    }

                    onAccepted: lockScreenUi.authenticate()
                }

                // Caps Lock indicator
                Text {
                    id: capsIndicator
                    text: "Caps Lock is on"
                    color: lockScreenUi.accentColor
                    font.pixelSize: 14
                    font.family: fontRegular.name
                    font.weight: Font.Medium
                    Layout.alignment: Qt.AlignHCenter
                    visible: (typeof keystateSource !== "undefined" && keystateSource.data["Caps Lock"] && keystateSource.data["Caps Lock"]["Locked"]) ? true : false
                }

                // Notification / error message
                Text {
                    id: notificationLabel
                    Layout.alignment: Qt.AlignHCenter
                    text: root.notification ? root.notification : ""
                    color: loginState.isError ? "#FF9A9A" : lockScreenUi.textColor
                    font.pixelSize: 14
                    font.family: fontRegular.name
                    horizontalAlignment: Text.AlignHCenter
                    visible: text.length > 0
                    wrapMode: Text.WordWrap
                    Layout.fillWidth: true
                }

                Item { Layout.fillHeight: true }

                // Login button
                RoundButton {
                    id: loginButton
                    Layout.alignment: Qt.AlignHCenter
                    Layout.preferredWidth: 64
                    Layout.preferredHeight: 64
                    focusPolicy: Qt.NoFocus

                    contentItem: Text {
                        text: "→"
                        color: "white"
                        font.pixelSize: 32
                        horizontalAlignment: Text.AlignHCenter
                        verticalAlignment: Text.AlignVCenter
                    }

                    background: Rectangle {
                        color: loginButton.pressed ? Qt.darker(lockScreenUi.accentColor, 1.1) : lockScreenUi.accentColor
                        radius: 32
                    }

                    onClicked: lockScreenUi.authenticate()
                }

                Item { Layout.fillHeight: true }
            }
        }
    }

    // ---- No-password unlock (shown after biometric/grace unlock) ----
    Item {
        id: noPasswordState
        anchors.fill: parent
        visible: lockScreenUi.showNoPasswordUnlock
        opacity: visible ? 1 : 0
        Behavior on opacity { NumberAnimation { duration: 400 } }

        Rectangle {
            width: 320
            height: 180
            x: (parent.width - width) / 2
            y: (parent.height - height) / 2
            color: lockScreenUi.baseColor
            opacity: 0.85
            radius: 28

            ColumnLayout {
                anchors.fill: parent
                anchors.margins: 30
                spacing: 20

                Text {
                    Layout.alignment: Qt.AlignHCenter
                    text: (typeof kscreenlocker_userName !== "undefined" && kscreenlocker_userName) ? kscreenlocker_userName : "User"
                    color: "white"
                    font.pixelSize: 22
                    font.weight: Font.Bold
                    font.family: fontRegular.name
                }

                RoundButton {
                    Layout.alignment: Qt.AlignHCenter
                    text: "Unlock"
                    onClicked: Qt.quit()
                    Keys.onEnterPressed: clicked()
                    Keys.onReturnPressed: clicked()

                    contentItem: Text {
                        text: "Unlock"
                        color: "white"
                        font.pixelSize: 16
                        font.family: fontRegular.name
                        horizontalAlignment: Text.AlignHCenter
                        verticalAlignment: Text.AlignVCenter
                    }

                    background: Rectangle {
                        color: lockScreenUi.accentColor
                        radius: 18
                    }
                }
            }
        }
    }

    // ---- Media controls ----
    Loader {
        id: mediaControls
        active: lockScreenUi.showMediaControls
        source: "MediaControls.qml"
        anchors {
            horizontalCenter: parent.horizontalCenter
            bottom: footer.top
            bottomMargin: PlasmaCore.Units.largeSpacing
        }
        opacity: lockScreenRoot.uiVisible && !lockScreenUi.showNoPasswordUnlock ? 1 : 0
        visible: opacity > 0
        Behavior on opacity { NumberAnimation { duration: 300 } }
    }

    // ---- Footer: suspend / hibernate / battery ----
    RowLayout {
        id: footer
        anchors {
            bottom: parent.bottom
            right: parent.right
            margins: PlasmaCore.Units.smallSpacing * 4
        }
        spacing: PlasmaCore.Units.smallSpacing
        opacity: lockScreenRoot.uiVisible ? 1 : 0
        Behavior on opacity { NumberAnimation { duration: 300 } }

        PlasmaComponents3.ToolButton {
            focusPolicy: Qt.TabFocus
            icon.name: "system-suspend"
            Accessible.name: "Sleep"
            onClicked: root.suspendToRam()
            visible: root.suspendToRamSupported
        }

        PlasmaComponents3.ToolButton {
            focusPolicy: Qt.TabFocus
            icon.name: "system-suspend-hibernate"
            Accessible.name: "Hibernate"
            onClicked: root.suspendToDisk()
            visible: root.suspendToDiskSupported
        }

        Battery {}
    }
}

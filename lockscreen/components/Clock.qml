/*
    Pixie SDDM - KDE Plasma 5 lock screen port
    Copyright (c) 2026 xCaptaiN09
    License: MIT
*/
import QtQuick 2.15

Item {
    id: clock

    property color baseAccent: "#A9C78F"
    property string fontFamily: "FlexRounded"
    property bool use24HourClock: true
    property string timeStr: "0000"

    property color defaultHoursColor: "#AED68A"
    property color defaultMinutesColor: "#D4E4BC"
    property color smartHoursColor: defaultHoursColor
    property color smartMinutesColor: defaultMinutesColor

    // The clock's 2x2 digit grid renders to this fixed footprint, which lets
    // the parent anchor other elements (e.g. the date) below it.
    width: 260
    height: 365

    function updateColors() {
        var base = clock.baseAccent;

        if (base.hsvSaturation < 0.15) {
            clock.smartHoursColor = Qt.lighter(base, 1.3);
            clock.smartMinutesColor = Qt.darker(base, 1.4);
            return;
        }

        if (base.hsvValue < 0.5) {
            clock.smartHoursColor = Qt.hsva(base.hsvHue, 0.7, 0.9, 1.0);
            clock.smartMinutesColor = Qt.hsva(base.hsvHue, 0.45, 0.85, 1.0);
        } else if (base.hsvValue > 0.8 && base.hsvSaturation < 0.2) {
            clock.smartHoursColor = Qt.hsva(base.hsvHue, 0.8, 0.7, 1.0);
            clock.smartMinutesColor = Qt.hsva(base.hsvHue, 0.5, 0.75, 1.0);
        } else {
            clock.smartHoursColor = Qt.hsva(base.hsvHue, Math.min(1.0, base.hsvSaturation * 1.3), 0.95, 1.0);
            clock.smartMinutesColor = Qt.hsva(base.hsvHue, Math.min(1.0, base.hsvSaturation * 0.75), 0.92, 1.0);
        }
    }

    onBaseAccentChanged: updateColors()
    Component.onCompleted: updateColors()

    Row {
        anchors.centerIn: parent
        spacing: 0

        // First Column: Tens Digit
        Item {
            width: 130
            // DYNAMIC HEIGHT: Calculates exactly where the bottom text ends!
            height: tensMinutes.y + tensMinutes.height

            Text {
                id: tensHours
                anchors.top: parent.top
                anchors.horizontalCenter: parent.horizontalCenter
                text: clock.timeStr.charAt(0)
                color: clock.smartHoursColor
                font.pixelSize: 200
                font.family: clock.fontFamily
                font.weight: Font.Medium
                width: 130
                horizontalAlignment: Text.AlignHCenter
                antialiasing: true
            }
            Text {
                id: tensMinutes
                anchors.top: tensHours.bottom
                anchors.topMargin: -35 // Your perfect gap
                anchors.horizontalCenter: parent.horizontalCenter
                text: clock.timeStr.charAt(2)
                color: clock.smartMinutesColor
                font.pixelSize: 200
                font.family: clock.fontFamily
                font.weight: Font.Medium
                width: 130
                horizontalAlignment: Text.AlignHCenter
                antialiasing: true
            }
        }

        // Second Column: Ones Digit
        Item {
            width: 130
            // DYNAMIC HEIGHT: Calculates exactly where the bottom text ends!
            height: onesMinutes.y + onesMinutes.height

            Text {
                id: onesHours
                anchors.top: parent.top
                anchors.horizontalCenter: parent.horizontalCenter
                text: clock.timeStr.charAt(1)
                color: clock.smartHoursColor
                font.pixelSize: 200
                font.family: clock.fontFamily
                font.weight: Font.Medium
                width: 130
                horizontalAlignment: Text.AlignHCenter
                antialiasing: true
            }
            Text {
                id: onesMinutes
                anchors.top: onesHours.bottom
                anchors.topMargin: -35 // Your perfect gap
                anchors.horizontalCenter: parent.horizontalCenter
                text: clock.timeStr.charAt(3)
                color: clock.smartMinutesColor
                font.pixelSize: 200
                font.family: clock.fontFamily
                font.weight: Font.Medium
                width: 130
                horizontalAlignment: Text.AlignHCenter
                antialiasing: true
            }
        }
    }

    Timer {
        interval: 1000
        running: true
        repeat: true
        triggeredOnStart: true
        onTriggered: {
            var date = new Date();
            var hours = date.getHours();
            var minutes = date.getMinutes();

            if (!clock.use24HourClock) {
                hours = hours % 12;
                if (hours === 0) hours = 12;
            }

            var hStr = hours < 10 ? "0" + hours : "" + hours;
            var mStr = minutes < 10 ? "0" + minutes : "" + minutes;

            clock.timeStr = hStr + mStr;
        }
    }
}

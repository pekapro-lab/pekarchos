import QtQuick 2.15
import SddmComponents 2.0

Rectangle {
    id: root
    width: 1920
    height: 1080
    color: "#070712"

    property int sessionIndex: session.index

    TextConstants { id: textConstants }

    Image {
        anchors.fill: parent
        source: config.background || "/usr/share/pekarchos/wallpaper.png"
        fillMode: Image.PreserveAspectCrop
        asynchronous: false
        cache: true
    }

    Rectangle {
        anchors.fill: parent
        color: "#070712"
        opacity: 0.28
    }

    Text {
        anchors.horizontalCenter: parent.horizontalCenter
        y: parent.height * 0.08
        text: "PekarchOS"
        color: "#00f0ff"
        font.pixelSize: 64
        font.bold: true
    }

    Clock {
        id: clock
        anchors.top: parent.top
        anchors.right: parent.right
        anchors.margins: 32
        color: "#00f0ff"
        timeFont.family: "monospace"
        timeFont.pixelSize: 28
        dateFont.pixelSize: 14
    }

    Rectangle {
        anchors.centerIn: parent
        width: 420
        height: 300
        radius: 18
        color: "#e60c0c1c"
        border.color: "#ff2bd6"
        border.width: 2

        Column {
            anchors.fill: parent
            anchors.margins: 28
            spacing: 8

            Text {
                text: textConstants.userName
                color: "#bdf6ff"
                font.pixelSize: 14
            }

            TextBox {
                id: name
                width: parent.width
                height: 36
                text: userModel.lastUser
                font.pixelSize: 16
                Keys.onPressed: function(event) {
                    if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter) {
                        password.forceActiveFocus()
                        event.accepted = true
                    }
                }
            }

            Text {
                text: textConstants.password
                color: "#bdf6ff"
                font.pixelSize: 14
            }

            PasswordBox {
                id: password
                width: parent.width
                height: 36
                font.pixelSize: 16
                focus: true
                Keys.onPressed: function(event) {
                    if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter) {
                        sddm.login(name.text, password.text, sessionIndex)
                        event.accepted = true
                    }
                }
            }

            Button {
                id: loginButton
                width: parent.width
                text: textConstants.login
                onClicked: sddm.login(name.text, password.text, sessionIndex)
            }
        }
    }

    Row {
        anchors.left: parent.left
        anchors.bottom: parent.bottom
        anchors.margins: 24
        spacing: 12

        ComboBox {
            id: session
            width: 260
            height: 36
            model: sessionModel
            index: sessionModel.lastIndex
            arrowIcon: "/usr/share/pekarchos/logo.png"
        }
    }
}

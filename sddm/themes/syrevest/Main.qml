import QtQuick 2.15
import SddmComponents 2.0

Rectangle {
    id: root
    width: 1920
    height: 1080
    color: "#ffffff"

    property int sessionIndex: session.index

    Connections {
        target: sddm
        function onLoginFailed() {
            password.text = ""
            password.forceActiveFocus()
        }
    }

    Image {
        anchors.fill: parent
        source: "syrevest.jpg"
        fillMode: Image.PreserveAspectCrop
        asynchronous: false
    }

    // Полупрозрачная подложка для читаемости
    Rectangle {
        anchors.centerIn: parent
        width: 360
        height: 250
        radius: 16
        color: "#f5ffffff"
        border.color: "#55ffffff"

        Column {
            anchors.fill: parent
            anchors.margins: 28
            spacing: 14

            Text {
                text: "syrevest"
                color: "#111111"
                font.pixelSize: 30
                font.bold: true
                anchors.horizontalCenter: parent.horizontalCenter
            }

            TextBox {
                id: username
                width: parent.width
                height: 40
                text: userModel.lastUser
                font.pixelSize: 15
                KeyNavigation.tab: password
            }

            PasswordBox {
                id: password
                width: parent.width
                height: 40
                font.pixelSize: 15

                Keys.onPressed: function(event) {
                    if (event.key === Qt.Key_Return ||
                        event.key === Qt.Key_Enter) {
                        sddm.login(username.text, password.text, sessionIndex)
                        event.accepted = true
                    }
                }
            }

            Rectangle {
                width: parent.width
                height: 42
                radius: 8
                color: "#111111"

                Text {
                    anchors.centerIn: parent
                    text: "Log in"
                    color: "#ffffff"
                    font.pixelSize: 15
                    font.bold: true
                }

                MouseArea {
                    anchors.fill: parent
                    onClicked: sddm.login(username.text, password.text, sessionIndex)
                }
            }
        }
    }

    // Выбор сессии сохраняем, но не показываем лишние надписи.
    ComboBox {
        id: session
        visible: false
        model: sessionModel
        index: sessionModel.lastIndex
    }

    Component.onCompleted: {
        if (username.text === "")
            username.forceActiveFocus()
        else
            password.forceActiveFocus()
    }
}

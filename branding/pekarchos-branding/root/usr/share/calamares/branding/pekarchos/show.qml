import QtQuick 2.15

Rectangle {
    id: root
    color: "#070712"

    property int indice: 0
    property var diapositivas: [
        "PekarchOS copia este sistema en vivo, con Plasma en Wayland, y luego puedes añadir escritorios.",
        "XFCE, Cinnamon y MATE son X11. GNOME es Wayland. LXQt puede las dos. La sesión se elige en SDDM.",
        "La gráfica libre (Mesa, nouveau, AMD e Intel) ya está. NVIDIA moderna pide red. La serie 390 llega en otra fase.",
        "Puedes borrar el disco, instalar al lado de Windows o particionar a mano. GRUB detecta Windows.",
        "El instalador de terminal sigue en el menú, por si prefieres la consola."
    ]

    Image {
        id: logo
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.top: parent.top
        anchors.topMargin: 28
        width: Math.min(parent.width * 0.42, 280)
        height: width
        fillMode: Image.PreserveAspectFit
        source: "file:///usr/share/pekarchos/logo-full.png"
    }

    Text {
        id: texto
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.top: logo.bottom
        anchors.bottom: puntos.top
        anchors.margins: 28
        text: root.diapositivas[root.indice]
        color: "#e2f4ff"
        font.pixelSize: 22
        wrapMode: Text.WordWrap
        horizontalAlignment: Text.AlignHCenter
        verticalAlignment: Text.AlignVCenter
    }

    Row {
        id: puntos
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.bottom: parent.bottom
        anchors.bottomMargin: 18
        spacing: 8
        Repeater {
            model: root.diapositivas.length
            Rectangle {
                width: 10
                height: 10
                radius: 5
                color: index === root.indice ? "#ff2bd6" : "#00f0ff"
            }
        }
    }

    Timer {
        interval: 7000
        running: true
        repeat: true
        onTriggered: root.indice = (root.indice + 1) % root.diapositivas.length
    }

    MouseArea {
        anchors.fill: parent
        onClicked: root.indice = (root.indice + 1) % root.diapositivas.length
    }
}

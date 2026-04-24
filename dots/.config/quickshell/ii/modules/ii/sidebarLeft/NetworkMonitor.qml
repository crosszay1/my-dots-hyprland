import qs.modules.common
import qs.modules.common.widgets
import qs.services
import QtQuick
import QtQuick.Layouts

/**
 * Network download/upload monitor for the left sidebar.
 * Shows compact real-time speeds; expands on hover to reveal
 * mini graphs and average speeds.
 */
Rectangle {
    id: root

    color: Appearance.colors.colLayer1
    radius: Appearance.rounding.normal

    implicitWidth: parent ? parent.width : 200
    implicitHeight: mainColumn.implicitHeight + 16

    // ── Hover detection ──────────────────────────────────────────
    property bool isHovered: hoverArea.containsMouse

    MouseArea {
        id: hoverArea
        anchors.fill: parent
        hoverEnabled: true
        acceptedButtons: Qt.NoButton
    }

    // ── Layout ───────────────────────────────────────────────────
    ColumnLayout {
        id: mainColumn
        anchors {
            left: parent.left
            right: parent.right
            top: parent.top
            margins: 8
        }
        spacing: 6

        // Compact row – always visible
        RowLayout {
            Layout.fillWidth: true
            spacing: 6

            // Download
            RowLayout {
                spacing: 4
                Layout.fillWidth: true

                MaterialSymbol {
                    text: "arrow_downward"
                    iconSize: Appearance.font.pixelSize.normal
                    color: Appearance.colors.colPrimary
                }

                StyledText {
                    text: NetworkSpeed.downloadSpeedString
                    font.pixelSize: Appearance.font.pixelSize.small
                    color: Appearance.colors.colOnLayer1
                    Layout.fillWidth: true
                }
            }

            // Upload
            RowLayout {
                spacing: 4
                Layout.fillWidth: true

                MaterialSymbol {
                    text: "arrow_upward"
                    iconSize: Appearance.font.pixelSize.normal
                    color: Appearance.m3colors.m3tertiary
                }

                StyledText {
                    text: NetworkSpeed.uploadSpeedString
                    font.pixelSize: Appearance.font.pixelSize.small
                    color: Appearance.colors.colOnLayer1
                    Layout.fillWidth: true
                }
            }
        }

        // Expanded section – revealed on hover
        Revealer {
            id: expandedRevealer
            vertical: true
            reveal: root.isHovered
            Layout.fillWidth: true

            ColumnLayout {
                width: mainColumn.width
                spacing: 6

                // Divider
                Rectangle {
                    Layout.fillWidth: true
                    height: 1
                    color: Appearance.colors.colLayer0Border
                }

                // Download graph + average
                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 2

                    RowLayout {
                        Layout.fillWidth: true
                        spacing: 4

                        MaterialSymbol {
                            text: "arrow_downward"
                            iconSize: Appearance.font.pixelSize.small
                            color: Appearance.colors.colPrimary
                        }

                        StyledText {
                            text: Translation.tr("Download")
                            font.pixelSize: Appearance.font.pixelSize.small
                            color: Appearance.colors.colSubtext
                        }

                        Item { Layout.fillWidth: true }

                        StyledText {
                            text: Translation.tr("avg ") + NetworkSpeed.avgDownloadString
                            font.pixelSize: Appearance.font.pixelSize.small
                            color: Appearance.colors.colSubtext
                        }
                    }

                    Graph {
                        Layout.fillWidth: true
                        height: 36
                        values: NetworkSpeed.downloadHistory
                        color: Appearance.colors.colPrimary
                        fillOpacity: 0.3
                        alignment: Graph.Alignment.Right
                    }
                }

                // Upload graph + average
                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 2

                    RowLayout {
                        Layout.fillWidth: true
                        spacing: 4

                        MaterialSymbol {
                            text: "arrow_upward"
                            iconSize: Appearance.font.pixelSize.small
                            color: Appearance.m3colors.m3tertiary
                        }

                        StyledText {
                            text: Translation.tr("Upload")
                            font.pixelSize: Appearance.font.pixelSize.small
                            color: Appearance.colors.colSubtext
                        }

                        Item { Layout.fillWidth: true }

                        StyledText {
                            text: Translation.tr("avg ") + NetworkSpeed.avgUploadString
                            font.pixelSize: Appearance.font.pixelSize.small
                            color: Appearance.colors.colSubtext
                        }
                    }

                    Graph {
                        Layout.fillWidth: true
                        height: 36
                        values: NetworkSpeed.uploadHistory
                        color: Appearance.m3colors.m3tertiary
                        fillOpacity: 0.3
                        alignment: Graph.Alignment.Right
                    }
                }
            }
        }
    }
}

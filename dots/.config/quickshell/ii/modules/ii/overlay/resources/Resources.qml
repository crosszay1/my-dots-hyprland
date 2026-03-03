pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell
import Quickshell.Hyprland
import Qt5Compat.GraphicalEffects
import qs
import qs.services
import qs.modules.common
import qs.modules.common.widgets
import qs.modules.ii.overlay

StyledOverlayWidget {
    id: root
    minimumWidth: 300
    minimumHeight: 300
 




    property list<var> resources: [
        {
            icon: "planner_review",
            name: Translation.tr("CPU"),
            history: ResourceUsage.cpuUsageHistory,
            maxAvailableString: ResourceUsage.maxAvailableCpuString,
            available: true,
              extraProperties: [
                {
                    icon: "bolt",
                    label: Translation.tr("Load:"),
                    value: `${Math.round(ResourceUsage.cpuUsage  * 100)}%`
 
                },
                {
                    icon: "planner_review",
                    label: Translation.tr("Freq:"),
                    value: ` ${Math.round(ResourceUsage.cpuFreqency  * 100) /100} GHz`
                },
                {
                    icon: "thermometer",
                    label: Translation.tr("Temp:"),
                    value: ` ${Math.round(ResourceUsage.cpuTemperature)} °C`
                }
            ]
        },
        {
            icon: "memory",
            name: Translation.tr("RAM"),
            history: ResourceUsage.memoryUsageHistory,
            maxAvailableString: ResourceUsage.maxAvailableMemoryString,
            available: true,
            extraProperties: [
                {
                    icon: "clock_loader_60",
                    label: Translation.tr("Used:"),
                    value: ResourceUsage.kbToGbString(ResourceUsage.memoryUsed)
                },
                {
                    icon: "check_circle",
                    label: Translation.tr("Free:"),
                    value: ResourceUsage.kbToGbString(ResourceUsage.memoryFree)
                },
                {
                    icon: "empty_dashboard",
                    label: Translation.tr("Total:"),
                    value: ResourceUsage.kbToGbString(ResourceUsage.memoryTotal)
                }
            ]
        },
        {
            icon: "swap_horiz",
            name: Translation.tr("Swap"),
            history: ResourceUsage.swapUsageHistory,
            maxAvailableString: ResourceUsage.maxAvailableSwapString,
            available: true,
              extraProperties: [
                {
                    icon: "clock_loader_60",
                    label: Translation.tr("Used:"),
                    value: ResourceUsage.kbToGbString(ResourceUsage.swapUsed)
                },
                {
                    icon: "check_circle",
                    label: Translation.tr("Free:"),
                    value: ResourceUsage.kbToGbString(ResourceUsage.swapFree)
                },
                {
                    icon: "empty_dashboard",
                    label: Translation.tr("Total:"),
                    value: ResourceUsage.kbToGbString(ResourceUsage.swapTotal)
                }
            ]
            
        },
    ].filter(r => r.available) 

    contentItem: OverlayBackground {
        id: contentItem
        radius: root.contentRadius
        property real padding: 4
        ColumnLayout {
            id: contentColumn
            anchors {
                fill: parent
                margins: parent.padding
            }
            spacing: 8

            SecondaryTabBar {
                id: tabBar

                currentIndex: Persistent.states.overlay.resources.tabIndex
                onCurrentIndexChanged: {
                    Persistent.states.overlay.resources.tabIndex = tabBar.currentIndex;
                }

                Repeater {
                    model: root.resources.length
                    delegate: SecondaryTabButton {
                        required property int index
                        property var modelData: root.resources[index]
                        buttonIcon: modelData.icon
                        buttonText: modelData.name
                    }
                }
            }

            ResourceSummary {
                Layout.margins: 8
                history: root.resources[tabBar.currentIndex]?.history ?? []
                maxAvailableString: root.resources[tabBar.currentIndex]?.maxAvailableString ?? "--"
            }

            ExtraInfo {
                Layout.margins: 8
                Layout.topMargin: 0
                extraProperties: root.resources[tabBar.currentIndex]?.extraProperties ?? []
            }
        }
    }

    component ResourceSummary: RowLayout {
        id: resourceSummary
        required property list<real> history
        required property string maxAvailableString

        Layout.fillWidth: true
        Layout.fillHeight: true
        spacing: 12

        ColumnLayout {
            spacing: 2
            StyledText {
                text: (resourceSummary.history[resourceSummary.history.length - 1] * 100).toFixed(1) + "%"
                font {
                    family: Appearance.font.family.numbers
                    variableAxes: Appearance.font.variableAxes.numbers
                    pixelSize: Appearance.font.pixelSize.huge
                }
            }
            StyledText {
                text: Translation.tr("of %1").arg(resourceSummary.maxAvailableString)
                font.pixelSize: Appearance.font.pixelSize.smallie
                color: Appearance.colors.colSubtext
            }
            Item {
                Layout.fillHeight: true
            }
        }
        Rectangle {
            id: graphBg
            Layout.fillWidth: true
            Layout.fillHeight: true
            radius: Appearance.rounding.small
            color: Appearance.colors.colSecondaryContainer
            layer.enabled: true
            layer.effect: OpacityMask {
                maskSource: Rectangle {
                    width: graphBg.width
                    height: graphBg.height
                    radius: graphBg.radius
                }
            }
            Graph {
                anchors.fill: parent
                values: root.resources[tabBar.currentIndex]?.history ?? []
                points: ResourceUsage.historyLength
                alignment: Graph.Alignment.Right
            }
        }
    }

    component ExtraInfo: ColumnLayout {
        id: extraInfo
        required property list<var> extraProperties
        visible: extraProperties.length > 0
        spacing: 4

        Repeater {
            model: ScriptModel {
                values: extraInfo.extraProperties
                objectProp: "icon" // A prop that doesn't change
            }
            delegate: RowLayout {
                id: extraInfoRow
                required property var modelData

                spacing: 4
                MaterialSymbol {
                    text: extraInfoRow.modelData.icon
                    color: Appearance.colors.colOnSurfaceVariant
                    iconSize: Appearance.font.pixelSize.large
                }
                StyledText {
                    text: extraInfoRow.modelData.label ?? ""
                    color: Appearance.colors.colOnSurfaceVariant
                }
                StyledText {
                    Layout.fillWidth: true
                    horizontalAlignment: Text.AlignRight
                    visible: extraInfoRow.modelData.value !== ""
                    color: Appearance.colors.colOnSurfaceVariant
                    text: extraInfoRow.modelData.value ?? ""
                }
            }
        }
    }
}

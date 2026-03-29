import qs
import qs.services
import qs.modules.common
import qs.modules.common.widgets
import qs.modules.common.functions
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Qt5Compat.GraphicalEffects
import Quickshell
import Quickshell.Io

Item {
    id: root

    // ── Public state ──────────────────────────────────────────────────────────
    property bool useDarkMode: Appearance.m3colors.darkmode

    // ── Carousel sizing ───────────────────────────────────────────────────────
    readonly property int itemWidth: 220    // card width in the strip
    readonly property int itemHeight: 155   // card height in the strip
    readonly property real selectedScale: 1.12
    readonly property real normalScale:   0.84

    // ── Helpers ───────────────────────────────────────────────────────────────
    function selectWallpaperPath(filePath) {
        if (filePath && filePath.length > 0) {
            Wallpapers.select(filePath, root.useDarkMode);
            searchField.text = "";
        }
    }

    function scrollToCurrentWallpaper() {
        const current = Config.options.background.wallpaperPath;
        for (let i = 0; i < Wallpapers.folderModel.count; i++) {
            if (Wallpapers.folderModel.get(i, "filePath") === current) {
                carousel.currentIndex = i;
                return;
            }
        }
        carousel.currentIndex = 0;
    }

    // ── Keyboard navigation ───────────────────────────────────────────────────
    Keys.onPressed: event => {
        if (event.key === Qt.Key_Escape) {
            GlobalStates.wallpaperSelectorOpen = false;
            event.accepted = true;
        } else if (event.key === Qt.Key_Left) {
            carousel.decrementCurrentIndex();
            event.accepted = true;
        } else if (event.key === Qt.Key_Right) {
            carousel.incrementCurrentIndex();
            event.accepted = true;
        } else if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter) {
            const fp = Wallpapers.folderModel.get(carousel.currentIndex, "filePath");
            const isDir = Wallpapers.folderModel.get(carousel.currentIndex, "fileIsDir");
            if (fp) {
                if (isDir) Wallpapers.setDirectory(fp);
                else root.selectWallpaperPath(fp);
            }
            event.accepted = true;
        } else if (event.key === Qt.Key_Backspace) {
            searchField.text = searchField.text.slice(0, -1);
            searchField.forceActiveFocus();
            event.accepted = true;
        } else if (event.text.length > 0 && !(event.modifiers & Qt.ControlModifier)) {
            searchField.text += event.text;
            searchField.cursorPosition = searchField.text.length;
            searchField.forceActiveFocus();
            event.accepted = true;
        }
    }

    // ── Visual shell ──────────────────────────────────────────────────────────
    StyledRectangularShadow {
        target: panelBg
    }

    Rectangle {
        id: panelBg
        anchors {
            fill: parent
            margins: Appearance.sizes.elevationMargin
        }
        focus: true
        color: Appearance.colors.colLayer0
        radius: Appearance.rounding.screenRounding
        border.width: 1
        border.color: Appearance.colors.colLayer0Border

        ColumnLayout {
            anchors.fill: parent
            spacing: 0

            // ─── Top Controls Bar ─────────────────────────────────────────────
            Rectangle {
                id: topBar
                Layout.fillWidth: true
                implicitHeight: 48
                color: Appearance.colors.colLayer1
                radius: panelBg.radius

                // Flatten the bottom corners so it merges with the carousel area
                Rectangle {
                    anchors.bottom: parent.bottom
                    anchors.left:   parent.left
                    anchors.right:  parent.right
                    height: panelBg.radius
                    color:  parent.color
                }

                RowLayout {
                    anchors {
                        fill: parent
                        leftMargin:  14
                        rightMargin: 10
                        topMargin:    6
                        bottomMargin: 6
                    }
                    spacing: 8

                    // Icon + label
                    MaterialSymbol {
                        text: "wallpaper"
                        iconSize: Appearance.font.pixelSize.larger
                        color: Appearance.colors.colPrimary
                    }
                    StyledText {
                        text: Translation.tr("Wallpapers")
                        font.pixelSize: Appearance.font.pixelSize.normal
                        font.weight: Font.Medium
                        color: Appearance.colors.colOnLayer1
                    }

                    // Quick-access folder chips
                    ListView {
                        id: chipList
                        Layout.fillWidth: true
                        Layout.fillHeight: true
                        orientation: ListView.Horizontal
                        clip: true
                        spacing: 6
                        ScrollBar.horizontal: StyledScrollBar { policy: ScrollBar.AlwaysOff }
                        model: [
                            { icon: "wallpaper", name: Translation.tr("Wallpapers"), path: `${Directories.pictures}/Wallpapers` },
                            { icon: "image",     name: Translation.tr("Pictures"),   path: Directories.pictures },
                            { icon: "download",  name: Translation.tr("Downloads"),  path: Directories.downloads },
                            { icon: "home",      name: Translation.tr("Home"),       path: Directories.home },
                        ].concat(Config.options.policies.weeb === 1
                            ? [{ icon: "favorite", name: Translation.tr("Homework"), path: `${Directories.pictures}/homework` }]
                            : [])
                        delegate: Rectangle {
                            id: chip
                            required property var modelData
                            property bool active: Wallpapers.directory === Qt.resolvedUrl(modelData.path)
                            width: chipRow.implicitWidth + 20
                            height: chipList.height
                            radius: height / 2
                            color: active
                                ? Appearance.colors.colPrimary
                                : chipMouse.containsMouse
                                    ? Appearance.colors.colLayer2Hover
                                    : Appearance.colors.colLayer2
                            Behavior on color {
                                animation: Appearance.animation.elementMoveFast.colorAnimation.createObject(this)
                            }
                            MouseArea {
                                id: chipMouse
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onClicked: Wallpapers.setDirectory(chip.modelData.path)
                            }
                            Row {
                                id: chipRow
                                anchors.centerIn: parent
                                spacing: 4
                                MaterialSymbol {
                                    text: chip.modelData.icon
                                    iconSize: Appearance.font.pixelSize.small
                                    color: chip.active ? Appearance.colors.colOnPrimary : Appearance.colors.colOnLayer2
                                    anchors.verticalCenter: parent.verticalCenter
                                }
                                StyledText {
                                    text: chip.modelData.name
                                    font.pixelSize: Appearance.font.pixelSize.smaller
                                    color: chip.active ? Appearance.colors.colOnPrimary : Appearance.colors.colOnLayer2
                                    anchors.verticalCenter: parent.verticalCenter
                                }
                            }
                        }
                    }

                    // Search field
                    ToolbarTextField {
                        id: searchField
                        placeholderText: focus ? Translation.tr("Search wallpapers") : Translation.tr("Hit \"/\" to search")
                        Layout.fillHeight: true
                        implicitWidth: 160
                        onTextChanged: Wallpapers.searchQuery = text
                        Keys.onPressed: event => {
                            if (event.key === Qt.Key_Escape) {
                                text = "";
                                panelBg.forceActiveFocus();
                                event.accepted = true;
                            }
                        }
                    }

                    // Action: random
                    IconToolbarButton {
                        implicitWidth: height
                        onClicked: Wallpapers.randomFromCurrentFolder()
                        text: "ifl"
                        StyledToolTip { text: Translation.tr("Pick random from this folder") }
                    }

                    // Action: dark / light mode toggle
                    IconToolbarButton {
                        implicitWidth: height
                        onClicked: root.useDarkMode = !root.useDarkMode
                        text: root.useDarkMode ? "dark_mode" : "light_mode"
                        StyledToolTip { text: Translation.tr("Toggle light/dark mode (applied when wallpaper is chosen)") }
                    }

                    // Action: close
                    IconToolbarButton {
                        implicitWidth: height
                        onClicked: GlobalStates.wallpaperSelectorOpen = false
                        text: "close"
                        StyledToolTip { text: Translation.tr("Close wallpaper selector") }
                    }
                }
            }

            // ─── Carousel Area ────────────────────────────────────────────────
            Item {
                id: carouselContainer
                Layout.fillWidth: true
                Layout.fillHeight: true
                clip: true

                // Left-edge fade
                Rectangle {
                    anchors { left: parent.left; top: parent.top; bottom: parent.bottom }
                    width: 90
                    z: 3
                    gradient: Gradient {
                        orientation: Gradient.Horizontal
                        GradientStop { position: 0.0; color: Appearance.colors.colLayer0 }
                        GradientStop { position: 1.0; color: "transparent" }
                    }
                }
                // Right-edge fade
                Rectangle {
                    anchors { right: parent.right; top: parent.top; bottom: parent.bottom }
                    width: 90
                    z: 3
                    gradient: Gradient {
                        orientation: Gradient.Horizontal
                        GradientStop { position: 0.0; color: "transparent" }
                        GradientStop { position: 1.0; color: Appearance.colors.colLayer0 }
                    }
                }

                // Horizontal carousel
                ListView {
                    id: carousel
                    anchors.fill: parent
                    anchors.topMargin: 8
                    anchors.bottomMargin: 8
                    orientation: ListView.Horizontal
                    clip: false

                    // Always keep current item centred
                    highlightRangeMode: ListView.StrictlyEnforceRange
                    preferredHighlightBegin: width  / 2 - root.itemWidth / 2
                    preferredHighlightEnd:   width  / 2 + root.itemWidth / 2
                    snapMode: ListView.SnapToItem

                    cacheBuffer: root.itemWidth * 5
                    spacing: 12

                    model: Wallpapers.folderModel
                    ScrollBar.horizontal: StyledScrollBar { policy: ScrollBar.AlwaysOff }

                    Component.onCompleted: {
                        root.scrollToCurrentWallpaper();
                        Wallpapers.generateThumbnail(
                            Images.thumbnailSizeNameForDimensions(root.itemWidth, root.itemHeight)
                        );
                    }

                    // Mouse-wheel / touchpad scroll → move current index
                    WheelHandler {
                        target: null        // handle ourselves
                        acceptedDevices: PointerDevice.Mouse | PointerDevice.TouchPad
                        onWheel: event => {
                            const d = event.angleDelta.x !== 0
                                ? event.angleDelta.x : event.angleDelta.y;
                            if (d < 0) carousel.incrementCurrentIndex();
                            else       carousel.decrementCurrentIndex();
                        }
                    }

                    // ── Delegate ──────────────────────────────────────────────
                    delegate: Item {
                        id: card
                        required property int   index
                        required property var   modelData

                        property bool isCurrent:  ListView.isCurrentItem
                        property bool isDir:      modelData.fileIsDir
                        property bool isApplied:  modelData.filePath === Config.options.background.wallpaperPath
                        property bool isVideo: {
                            const n = (modelData.fileName ?? "").toLowerCase();
                            return n.endsWith(".mp4")  || n.endsWith(".webm") ||
                                   n.endsWith(".mkv")  || n.endsWith(".avi")  ||
                                   n.endsWith(".mov")  || n.endsWith(".m4v")  ||
                                   n.endsWith(".ogv");
                        }
                        property bool useThumbnail: Images.isValidImageByName(modelData.fileName) || isVideo

                        // Outer item occupies full carousel height so the
                        // centred card can scale up without clipping siblings.
                        width:  root.itemWidth
                        height: carousel.height - 16

                        // ── Scale / opacity animation ─────────────────────────
                        property real cardScale:   isCurrent ? root.selectedScale : root.normalScale
                        property real cardOpacity: isCurrent ? 1.0 : (isApplied ? 0.80 : 0.55)

                        Behavior on cardScale {
                            NumberAnimation {
                                duration: Appearance.animation.elementMoveFast.duration
                                easing.type: Appearance.animation.elementMoveFast.type
                                easing.bezierCurve: Appearance.animation.elementMoveFast.bezierCurve
                            }
                        }
                        Behavior on cardOpacity {
                            NumberAnimation {
                                duration: Appearance.animation.elementMoveFast.duration
                                easing.type: Appearance.animation.elementMoveFast.type
                                easing.bezierCurve: Appearance.animation.elementMoveFast.bezierCurve
                            }
                        }

                        // ── Card visual ───────────────────────────────────────
                        Rectangle {
                            id: cardRect
                            anchors.centerIn: parent
                            width:  root.itemWidth
                            height: root.itemHeight
                            radius: Appearance.rounding.normal
                            scale:   card.cardScale
                            opacity: card.cardOpacity
                            z: card.isCurrent ? 2 : 1

                            color: card.isCurrent  ? Appearance.colors.colPrimaryContainer
                                 : card.isApplied  ? Appearance.colors.colSecondaryContainer
                                 :                   Appearance.colors.colLayer1
                            border.width: card.isCurrent ? 2 : (card.isApplied ? 1 : 0)
                            border.color: card.isCurrent ? Appearance.colors.colPrimary
                                        :                  Appearance.colors.colSecondaryContainer

                            Behavior on color {
                                animation: Appearance.animation.elementMoveFast.colorAnimation.createObject(this)
                            }

                            // Glow halo on selected card
                            Loader {
                                active: card.isCurrent
                                anchors {
                                    fill:    parent
                                    margins: -10
                                }
                                z: -1
                                sourceComponent: StyledRectangularShadow {
                                    target: cardRect
                                    anchors.fill: parent
                                    blur:   0.7 * Appearance.sizes.elevationMargin
                                    spread: 3
                                    color:  ColorUtils.transparentize(Appearance.colors.colPrimary, 0.45)
                                }
                            }

                            // ── Thumbnail / directory icon ─────────────────────
                            Item {
                                id: imageArea
                                anchors {
                                    top:    parent.top
                                    left:   parent.left
                                    right:  parent.right
                                    bottom: nameRow.top
                                    margins: 5
                                    bottomMargin: 3
                                }

                                // Directory icon (when isDir)
                                Loader {
                                    active: card.isDir
                                    anchors.fill: parent
                                    sourceComponent: DirectoryIcon {
                                        fileModelData: card.modelData
                                        sourceSize.width:  imageArea.width
                                        sourceSize.height: imageArea.height
                                    }
                                }

                                // Wallpaper thumbnail
                                Loader {
                                    id: thumbLoader
                                    active: !card.isDir && card.useThumbnail
                                    anchors.fill: parent
                                    sourceComponent: ThumbnailImage {
                                        id: thumbImg
                                        generateThumbnail: false
                                        sourcePath: card.modelData.filePath
                                        fillMode: Image.PreserveAspectCrop
                                        clip: true
                                        sourceSize.width:  imageArea.width
                                        sourceSize.height: imageArea.height

                                        Connections {
                                            target: Wallpapers
                                            function onThumbnailGenerated(directory) {
                                                if (thumbImg.status !== Image.Error) return;
                                                if (FileUtils.parentDirectory(thumbImg.sourcePath) !==
                                                        FileUtils.trimFileProtocol(directory)) return;
                                                thumbImg.source = "";
                                                thumbImg.source = thumbImg.thumbnailPath;
                                            }
                                            function onThumbnailGeneratedFile(filePath) {
                                                if (thumbImg.status !== Image.Error) return;
                                                if (Qt.resolvedUrl(thumbImg.sourcePath) !== Qt.resolvedUrl(filePath)) return;
                                                thumbImg.source = "";
                                                thumbImg.source = thumbImg.thumbnailPath;
                                            }
                                        }

                                        layer.enabled: true
                                        layer.effect: OpacityMask {
                                            maskSource: Rectangle {
                                                width:  imageArea.width
                                                height: imageArea.height
                                                radius: Appearance.rounding.small
                                            }
                                        }
                                    }
                                }

                                // Video badge
                                Loader {
                                    active: card.isVideo
                                    anchors { top: parent.top; left: parent.left; margins: 6 }
                                    sourceComponent: MaterialSymbol {
                                        text: "video_library"
                                        iconSize: Appearance.font.pixelSize.large
                                        color: Appearance.colors.colPrimary
                                        fill: 1
                                    }
                                }

                                // "Currently applied" checkmark badge
                                Loader {
                                    active: card.isApplied && !card.isDir
                                    anchors { top: parent.top; right: parent.right; margins: 6 }
                                    sourceComponent: Rectangle {
                                        radius: height / 2
                                        color: Appearance.colors.colPrimary
                                        implicitWidth:  checkSymbol.implicitWidth  + 10
                                        implicitHeight: checkSymbol.implicitHeight + 6
                                        MaterialSymbol {
                                            id: checkSymbol
                                            anchors.centerIn: parent
                                            text: "check"
                                            iconSize: Appearance.font.pixelSize.smaller
                                            color: Appearance.colors.colOnPrimary
                                        }
                                    }
                                }
                            }

                            // ── Filename label ─────────────────────────────────
                            Item {
                                id: nameRow
                                anchors {
                                    bottom: parent.bottom
                                    left:   parent.left
                                    right:  parent.right
                                    margins: 6
                                    bottomMargin: 5
                                }
                                implicitHeight: nameLabel.implicitHeight

                                StyledText {
                                    id: nameLabel
                                    anchors { left: parent.left; right: parent.right }
                                    horizontalAlignment: Text.AlignHCenter
                                    elide: Text.ElideRight
                                    font.pixelSize: Appearance.font.pixelSize.smaller
                                    color: card.isCurrent ? Appearance.colors.colOnPrimaryContainer
                                         : card.isApplied  ? Appearance.colors.colOnSecondaryContainer
                                         :                   Appearance.colors.colOnLayer1
                                    text: card.modelData.fileName
                                    Behavior on color {
                                        animation: Appearance.animation.elementMoveFast.colorAnimation.createObject(this)
                                    }
                                }
                            }
                        } // cardRect

                        // ── Interaction ────────────────────────────────────────
                        MouseArea {
                            anchors.centerIn: parent
                            width:  cardRect.width  * cardRect.scale
                            height: cardRect.height * cardRect.scale
                            hoverEnabled: true
                            cursorShape:  Qt.PointingHandCursor
                            onEntered: carousel.currentIndex = card.index
                            onClicked: {
                                if (card.isDir)
                                    Wallpapers.setDirectory(card.modelData.filePath);
                                else
                                    root.selectWallpaperPath(card.modelData.filePath);
                            }
                        }
                    } // delegate Item
                } // ListView

                // Thumbnail generation progress indicators
                StyledProgressBar {
                    visible: Wallpapers.thumbnailGenerationRunning && value > 0
                    value:   Wallpapers.thumbnailGenerationProgress
                    anchors { bottom: parent.bottom; left: parent.left; right: parent.right; margins: 4 }
                    z: 4
                }
                StyledIndeterminateProgressBar {
                    visible: Wallpapers.thumbnailGenerationRunning && Wallpapers.thumbnailGenerationProgress === 0
                    anchors { bottom: parent.bottom; left: parent.left; right: parent.right; margins: 4 }
                    z: 4
                }
            } // carouselContainer
        } // ColumnLayout
    } // panelBg

    // ── Connections ────────────────────────────────────────────────────────────
    Connections {
        target: GlobalStates
        function onWallpaperSelectorOpenChanged() {
            if (GlobalStates.wallpaperSelectorOpen) {
                panelBg.forceActiveFocus();
                Qt.callLater(root.scrollToCurrentWallpaper);
            }
        }
    }

    Connections {
        target: Wallpapers
        function onDirectoryChanged() {
            Qt.callLater(root.scrollToCurrentWallpaper);
            Wallpapers.generateThumbnail(
                Images.thumbnailSizeNameForDimensions(root.itemWidth, root.itemHeight)
            );
        }
        function onChanged() {
            GlobalStates.wallpaperSelectorOpen = false;
        }
    }
}


import QtQuick
import QtQuick.Layouts
import "../shared"

// Shared tile for both the "s " (Steam/Epic games) and "m " (Prism/Minecraft
// instances) prefix grids. entry just needs a `name`; onActivate gets the
// whole entry back so the caller can dispatch by its own shape
// (Games.launchGame wants {id, source}, Games.launchMinecraftInstance
// wants {root, id}).
Rectangle {
    id: tile

    required property var entry
    required property int index
    required property string glyph
    // file:// candidates, tried in order (Steam/Epic have a couple of
    // possible cache paths, Prism has at most one resolved icon file) -
    // falls back to the plain glyph+name layout once every candidate 404s,
    // or immediately if the list is empty (most Prism instances use one of
    // Prism's own built-in icons, which aren't files on disk at all)
    required property var iconCandidates
    // a plain callback property, not a signal handler - named to avoid the
    // "onXxx" convention on purpose, since that's reserved for handlers of
    // an actual signal named "xxx" and this isn't one
    required property var activateFn

    readonly property bool selected: tile.index === Launcher.selectedIndex
    property int iconTryIndex: 0
    readonly property bool iconFailed: tile.iconTryIndex >= tile.iconCandidates.length

    // same fixed square as AppTile/PinnedTile/BookmarkTile, so every grid lines up the same way
    implicitWidth: 96
    implicitHeight: 96
    radius: 6
    clip: true
    color: tile.iconFailed && (tile.selected || hover.hovered) ? Theme.menuItemHoverBg : "transparent"

    HoverHandler {
        id: hover
    }

    MouseArea {
        anchors.fill: parent
        cursorShape: Qt.PointingHandCursor
        onClicked: tile.activateFn(tile.entry)
    }

    // Qt Quick's `clip` only clips to this Rectangle's bounding box, not
    // its rounded shape (radius has no effect on clip - a standing Qt
    // Quick limitation), and real alpha-masking (QtQuick.Effects.MultiEffect,
    // layer.enabled per tile) turned out not to scale to a 47-tile grid -
    // each layered/masked item needs its own offscreen GPU framebuffer, and
    // with that many at once every image silently failed to rasterize
    // ("buffer size is too big, ignoring" in the log) instead of erroring
    // in a way QML could catch and fall back from. Cheap alternative below
    // (cornerCover) instead: a plain border-only Rectangle, same technique
    // as the selection ring, no GPU layer involved at all
    Item {
        id: art
        anchors.fill: parent
        visible: !tile.iconFailed

        Image {
            id: icon
            asynchronous: true
            smooth: true
            mipmap: true
            // without this, an SVG (Prism's default instance icons)
            // rasterizes at its tiny native viewBox size and then gets
            // stretched blurry to fill the tile - this makes it rasterize
            // crisp at (near enough) the tile's own resolution instead.
            // Also lets raster art (Steam/Epic box art) downsample cleanly
            // rather than loading full-res
            sourceSize: Qt.size(192, 192)
            fillMode: Image.PreserveAspectCrop
            source: tile.iconFailed ? "" : tile.iconCandidates[tile.iconTryIndex]

            // most cover art is portrait (eg. Steam's 300x450 "Cover"),
            // taller than the square tile - PreserveAspectCrop's default
            // centering then crops it around whatever happens to land in
            // the vertical middle, which for a tall cover is often just
            // plain background, not the actual artwork/logo near the top.
            // Anchoring to the top instead (and letting the overflow hang
            // off the bottom, cut off by `tile`'s own clip: true) keeps
            // that top part in view. Landscape/square sources (header art,
            // the 32x32 icon) have no such vertical overflow to begin with
            // - anchors.fill still applies to them via the height binding
            // below evaluating to parent.height
            readonly property bool portrait: status === Image.Ready && implicitHeight > implicitWidth
            anchors.top: parent.top
            anchors.left: parent.left
            anchors.right: parent.right
            height: portrait ? width * (implicitHeight / Math.max(1, implicitWidth)) : parent.height

            onStatusChanged: {
                if (status === Image.Error)
                    tile.iconTryIndex += 1;
            }
        }

        // name overlay for the real-art case, bottom strip over the image
        // so long names stay readable against arbitrary art
        Rectangle {
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.bottom: parent.bottom
            height: nameOverlay.implicitHeight + 6
            color: Qt.rgba(0, 0, 0, 0.6)

            Text {
                id: nameOverlay
                anchors.centerIn: parent
                width: parent.width - 8
                horizontalAlignment: Text.AlignHCenter
                elide: Text.ElideRight
                maximumLineCount: 1
                text: tile.entry.name
                color: "white"

                font {
                    family: Theme.fontFamily
                    pointSize: Theme.pointSize - 3
                    bold: Theme.fontBold
                }
            }
        }
    }

    // visually rounds off the art Image's square corners without an actual
    // alpha mask (no GPU layer per tile - see the note on `art` above). A
    // Rectangle's own corner radius can't make this shape - rounding a
    // corner always keeps the *majority* of that corner box filled and
    // discards only the small sliver nearest the corner point, never the
    // reverse, so there's no way to get a Rectangle whose filled area
    // is just the sliver. assets/corner-cover.png is that sliver shape,
    // pre-rendered once (a quarter-circle cutout, Theme.tooltipBg baked
    // in - see the generating script's comment if it ever needs
    // regenerating for a different radius/color) and reused at all 4
    // corners via 90°-increment rotation, since the shape has that
    // rotational symmetry between corners
    Item {
        anchors.fill: parent
        visible: !tile.iconFailed

        Image {
            width: 6
            height: 6
            anchors.top: parent.top
            anchors.left: parent.left
            source: "assets/corner-cover.png"
        }
        Image {
            width: 6
            height: 6
            anchors.top: parent.top
            anchors.right: parent.right
            rotation: 90
            source: "assets/corner-cover.png"
        }
        Image {
            width: 6
            height: 6
            anchors.bottom: parent.bottom
            anchors.right: parent.right
            rotation: 180
            source: "assets/corner-cover.png"
        }
        Image {
            width: 6
            height: 6
            anchors.bottom: parent.bottom
            anchors.left: parent.left
            rotation: 270
            source: "assets/corner-cover.png"
        }
    }

    // glyph+name fallback, same layout AppTile/PinnedTile/BookmarkTile use
    ColumnLayout {
        visible: tile.iconFailed
        anchors.centerIn: parent
        width: parent.width - 8
        spacing: 4

        Text {
            Layout.alignment: Qt.AlignHCenter
            text: tile.glyph
            color: Theme.textColor
            font {
                family: Theme.fontFamily
                pixelSize: 28
            }
        }

        Text {
            Layout.fillWidth: true
            Layout.alignment: Qt.AlignHCenter
            horizontalAlignment: Text.AlignHCenter
            elide: Text.ElideRight
            maximumLineCount: 2
            wrapMode: Text.WrapAtWordBoundaryOrAnywhere
            text: tile.entry.name
            color: Theme.textColor
            style: Theme.style
            styleColor: Theme.styleColor

            font {
                family: Theme.fontFamily
                pointSize: Theme.pointSize - 2
                bold: Theme.fontBold
            }
        }
    }

    // selection/hover ring - a separate top-most child (rather than this
    // Rectangle's own border) so it's never hidden underneath the art
    // Image (anchors.fill: parent, same bounds, paints over its parent's
    // border otherwise). Same bright accent as the shell-mode search box
    // border elsewhere in the launcher, not the very faint menuItemHoverBg
    // - that one reads fine as a big fill but disappears as a thin line
    Rectangle {
        anchors.fill: parent
        visible: tile.selected || hover.hovered
        radius: 6
        color: "transparent"
        border.color: "#34C0EF"
        border.width: tile.selected ? 3 : 2
    }
}

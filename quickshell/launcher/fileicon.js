.pragma library

// Nerd Font (Material Design Icons subset) glyphs for pinned-file tiles.
// Rendered as plain Text in Theme.fontFamily, same trick used for the bar's
// volume/network glyphs - sidesteps Quickshell.iconPath() entirely, which
// only resolves against the (mostly empty) hicolor theme.

const FOLDER = String.fromCodePoint(0xf024b);
const GENERIC = String.fromCodePoint(0xf0224);

const EXTENSION_ICONS = {
    // images
    jpg: 0xf021f,
    jpeg: 0xf021f,
    png: 0xf021f,
    gif: 0xf021f,
    bmp: 0xf021f,
    webp: 0xf021f,
    svg: 0xf021f,
    tif: 0xf021f,
    tiff: 0xf021f,
    // audio
    mp3: 0xf0223,
    wav: 0xf0223,
    flac: 0xf0223,
    ogg: 0xf0223,
    m4a: 0xf0223,
    opus: 0xf0223,
    // video
    mp4: 0xf022b,
    mkv: 0xf022b,
    webm: 0xf022b,
    avi: 0xf022b,
    mov: 0xf022b,
    // documents
    pdf: 0xf0226,
    doc: 0xf0219,
    docx: 0xf0219,
    odt: 0xf0219,
    txt: 0xf0219,
    md: 0xf0219,
    // archives
    zip: 0xf05c4,
    tar: 0xf05c4,
    gz: 0xf05c4,
    "7z": 0xf05c4,
    rar: 0xf05c4,
    xz: 0xf05c4,
    bz2: 0xf05c4
};

function iconFor(path) {
    if (path.endsWith("/"))
        return FOLDER;

    const dot = path.lastIndexOf(".");
    const slash = path.lastIndexOf("/");
    if (dot <= slash)
        return GENERIC; // no extension (or a dotfile with no extension)

    const ext = path.slice(dot + 1).toLowerCase();
    const code = EXTENSION_ICONS[ext];
    return code !== undefined ? String.fromCodePoint(code) : GENERIC;
}

function baseName(path) {
    const trimmed = path.endsWith("/") ? path.slice(0, -1) : path;
    const slash = trimmed.lastIndexOf("/");
    return slash === -1 ? trimmed : trimmed.slice(slash + 1);
}

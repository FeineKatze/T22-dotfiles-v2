.pragma library

// Minimal parser for Valve's KeyValues / VDF text format - used for Steam's
// libraryfolders.vdf and per-game appmanifest_<id>.acf files. Handles
// quoted keys/values, nested {} blocks, and // line comments. Not a
// general-purpose implementation: a repeated key at the same level
// overwrites rather than merging into an array, which Steam's own files
// never do for the fields we care about.

function tokenize(text) {
    const tokens = [];
    const len = text.length;
    let i = 0;

    while (i < len) {
        const c = text[i];

        if (c === " " || c === "\t" || c === "\r" || c === "\n") {
            i++;
            continue;
        }
        if (c === "/" && text[i + 1] === "/") {
            while (i < len && text[i] !== "\n")
                i++;
            continue;
        }
        if (c === "{" || c === "}") {
            tokens.push(c);
            i++;
            continue;
        }
        if (c === "\"") {
            let j = i + 1;
            let out = "";
            while (j < len && text[j] !== "\"") {
                if (text[j] === "\\" && j + 1 < len) {
                    out += text[j + 1];
                    j += 2;
                } else {
                    out += text[j];
                    j++;
                }
            }
            tokens.push(out);
            i = j + 1;
            continue;
        }
        // bare/unquoted token - Steam always quotes its own keys/values,
        // this is just defensive leniency
        let j = i;
        while (j < len && !/\s/.test(text[j]) && text[j] !== "{" && text[j] !== "}")
            j++;
        tokens.push(text.slice(i, j));
        i = j;
    }
    return tokens;
}

function parseObject(tokens, pos) {
    const obj = {};
    while (pos.i < tokens.length) {
        const key = tokens[pos.i];
        if (key === "}") {
            pos.i++;
            return obj;
        }
        pos.i++;
        const next = tokens[pos.i];
        if (next === "{") {
            pos.i++;
            obj[key] = parseObject(tokens, pos);
        } else {
            obj[key] = next;
            pos.i++;
        }
    }
    return obj;
}

// returns a plain JS object of the file's top-level key(s) - eg.
// parse(acfText).AppState.name, or parse(libraryfoldersText).libraryfolders
function parse(text) {
    const pos = {
        i: 0
    };
    return parseObject(tokenize(text), pos);
}

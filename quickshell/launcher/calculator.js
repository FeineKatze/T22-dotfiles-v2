.pragma library

// Tokenizes and evaluates basic math expressions: + - * / ^ (power), %
// (modulo), sqrt(), parentheses, unary minus. Returns null for anything
// that isn't a valid, fully-consumed expression (including plain text,
// which is how this stays out of the way of normal app search queries).

function tokenize(input) {
    const tokens = [];
    let i = 0;

    while (i < input.length) {
        const c = input[i];

        if (/\s/.test(c)) {
            i++;
            continue;
        }

        // accepts both "0.5" and the leading-zero-less ".5"
        const numMatch = /^(\d+(\.\d+)?|\.\d+)/.exec(input.slice(i));
        if (numMatch) {
            tokens.push({
                type: "num",
                value: parseFloat(numMatch[0])
            });
            i += numMatch[0].length;
            continue;
        }

        if (/[a-zA-Z]/.test(c)) {
            const wordMatch = /^[a-zA-Z]+/.exec(input.slice(i));
            const word = wordMatch[0];
            if (word !== "sqrt")
                return null; // unknown identifier - not a calculator expression
            tokens.push({
                type: "sqrt"
            });
            i += word.length;
            continue;
        }

        if ("+-*/^%()".includes(c)) {
            tokens.push({
                type: c
            });
            i++;
            continue;
        }

        return null; // unrecognized character
    }

    return tokens;
}

function parse(tokens) {
    let pos = 0;

    function peek() {
        return tokens[pos];
    }
    function advance() {
        return tokens[pos++];
    }

    function parseExpression() {
        let left = parseTerm();
        if (left === null)
            return null;
        while (peek() && (peek().type === "+" || peek().type === "-")) {
            const op = advance().type;
            const right = parseTerm();
            if (right === null)
                return null;
            left = op === "+" ? left + right : left - right;
        }
        return left;
    }

    function parseTerm() {
        let left = parseFactor();
        if (left === null)
            return null;
        while (peek() && (peek().type === "*" || peek().type === "/" || peek().type === "%")) {
            const op = advance().type;
            const right = parseFactor();
            if (right === null)
                return null;
            if (op === "*")
                left = left * right;
            else if (op === "/")
                left = left / right;
            else
                left = left % right;
        }
        return left;
    }

    // '^' is right-associative and binds tighter than unary minus on its
    // right side is handled via parseUnary recursing back into parseFactor
    function parseFactor() {
        const base = parseUnary();
        if (base === null)
            return null;
        if (peek() && peek().type === "^") {
            advance();
            const exponent = parseFactor();
            if (exponent === null)
                return null;
            return Math.pow(base, exponent);
        }
        return base;
    }

    function parseUnary() {
        if (peek() && peek().type === "-") {
            advance();
            const value = parseUnary();
            if (value === null)
                return null;
            return -value;
        }
        return parsePrimary();
    }

    function parsePrimary() {
        const tok = peek();
        if (!tok)
            return null;

        if (tok.type === "num") {
            advance();
            return tok.value;
        }

        if (tok.type === "(") {
            advance();
            const value = parseExpression();
            if (value === null)
                return null;
            if (!peek() || peek().type !== ")")
                return null;
            advance();
            return value;
        }

        if (tok.type === "sqrt") {
            advance();
            if (!peek() || peek().type !== "(")
                return null;
            advance();
            const value = parseExpression();
            if (value === null)
                return null;
            if (!peek() || peek().type !== ")")
                return null;
            advance();
            return Math.sqrt(value);
        }

        return null;
    }

    const result = parseExpression();
    if (result === null)
        return null;
    if (pos !== tokens.length)
        return null; // leftover tokens - not a fully valid expression

    return result;
}

function formatNumber(n) {
    if (!isFinite(n))
        return "Error";
    if (Number.isInteger(n))
        return n.toString();

    let s = n.toFixed(10);
    s = s.replace(/0+$/, "").replace(/\.$/, "");
    return s;
}

// "1:30 + 2:00 - 0:45" style duration arithmetic - a chain of H:MM (or
// HH:MM) terms joined only by + and - (no *, /, ^, %). Handled separately
// from the general tokenizer/parser above since it's a different value type
// (a duration, not a plain number) that can only ever be added/subtracted.
const TIME_TERM = "\\d{1,2}:\\d{2}";
const TIME_EXPR_RE = new RegExp("^\\s*" + TIME_TERM + "\\s*(?:[+-]\\s*" + TIME_TERM + "\\s*)+$");

function parseTimeTerm(token) {
    const [h, m] = token.split(":").map(Number);
    return h * 60 + m;
}

// "Xd HH:MM" - the day part only appears once the total reaches 24h in
// either direction; negative totals get a single leading "-" rather than
// negative-looking hours/minutes
function formatTimeMath(totalMinutes) {
    const sign = totalMinutes < 0 ? "-" : "";
    const abs = Math.abs(totalMinutes);
    const days = Math.floor(abs / 1440);
    const rem = abs % 1440;
    const hh = String(Math.floor(rem / 60)).padStart(2, "0");
    const mm = String(rem % 60).padStart(2, "0");
    return sign + (days > 0 ? days + "d " : "") + hh + ":" + mm;
}

function evaluateTimeMath(input) {
    if (!TIME_EXPR_RE.test(input))
        return null;

    const termRe = new RegExp("([+-]?)\\s*(" + TIME_TERM + ")", "g");
    let total = 0;
    let m;
    while ((m = termRe.exec(input)) !== null)
        total += (m[1] === "-" ? -1 : 1) * parseTimeTerm(m[2]);

    return formatTimeMath(total);
}

function evaluate(input) {
    const trimmed = input.trim();
    if (trimmed.length === 0)
        return null;

    const timeResult = evaluateTimeMath(trimmed);
    if (timeResult !== null)
        return timeResult;

    // require an operator/function so a bare number (eg. while searching
    // for an app whose name starts with a digit) doesn't show a result
    if (!/[+\-*/^%]|sqrt/.test(trimmed))
        return null;

    const tokens = tokenize(trimmed);
    if (!tokens || tokens.length === 0)
        return null;

    const result = parse(tokens);
    if (result === null)
        return null;

    return formatNumber(result);
}

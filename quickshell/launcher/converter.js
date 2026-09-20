.pragma library

// Inline unit/currency conversion for the launcher search bar. Query shape
// is always: <number> <unit> (to|in) <unit> - eg "10 km to mi" or
// "20 usd to eur". <number> also accepts simple fractions ("3/8") and mixed
// numbers ("1 3/8"), eg "3/8 in to cm" or "1 3/8 in". Runs after the
// calculator (which bails out on any unrecognized word), so there's no
// overlap between the two.

const LENGTH_ALIASES = {
    mm: "mm",
    millimeter: "mm",
    millimeters: "mm",
    millimetre: "mm",
    millimetres: "mm",
    cm: "cm",
    centimeter: "cm",
    centimeters: "cm",
    centimetre: "cm",
    centimetres: "cm",
    m: "m",
    meter: "m",
    meters: "m",
    metre: "m",
    metres: "m",
    km: "km",
    kilometer: "km",
    kilometers: "km",
    kilometre: "km",
    kilometres: "km",
    "in": "in",
    inch: "in",
    inches: "in",
    ft: "ft",
    foot: "ft",
    feet: "ft",
    yd: "yd",
    yard: "yd",
    yards: "yd",
    mi: "mi",
    mile: "mi",
    miles: "mi",
    nm: "nm",
    nmi: "nm"
};
const LENGTH_FACTORS = {
    // meters per unit
    mm: 0.001,
    cm: 0.01,
    m: 1,
    km: 1000,
    "in": 0.0254,
    ft: 0.3048,
    yd: 0.9144,
    mi: 1609.344,
    nm: 1852
};
// bare-query defaults (no explicit "to X") only kick in for non-metric units -
// metric-to-metric ("10 cm" alone) has no obviously-better default
const LENGTH_METRIC = new Set(["mm", "cm", "m", "km"]);
function pickLengthTarget(meters) {
    if (meters < 1)
        return "cm";
    if (meters < 1000)
        return "m";
    return "km";
}

// accepts both word form (sqft, sqm) and exponent form (ft^2, m^2, ft2, m2)
const AREA_ALIASES = {
    mm2: "mm2",
    "mm^2": "mm2",
    sqmm: "mm2",
    cm2: "cm2",
    "cm^2": "cm2",
    sqcm: "cm2",
    m2: "m2",
    "m^2": "m2",
    sqm: "m2",
    sqmeter: "m2",
    sqmeters: "m2",
    sqmetre: "m2",
    sqmetres: "m2",
    km2: "km2",
    "km^2": "km2",
    sqkm: "km2",
    in2: "in2",
    "in^2": "in2",
    sqin: "in2",
    sqinch: "in2",
    sqinches: "in2",
    ft2: "ft2",
    "ft^2": "ft2",
    sqft: "ft2",
    sqfoot: "ft2",
    sqfeet: "ft2",
    yd2: "yd2",
    "yd^2": "yd2",
    sqyd: "yd2",
    sqyard: "yd2",
    sqyards: "yd2",
    mi2: "mi2",
    "mi^2": "mi2",
    sqmi: "mi2",
    sqmile: "mi2",
    sqmiles: "mi2",
    acre: "acre",
    acres: "acre",
    hectare: "hectare",
    hectares: "hectare",
    ha: "hectare"
};
const AREA_FACTORS = {
    // square meters per unit - the linear factors above, squared
    mm2: 0.001 ** 2,
    cm2: 0.01 ** 2,
    m2: 1,
    km2: 1000 ** 2,
    in2: 0.0254 ** 2,
    ft2: 0.3048 ** 2,
    yd2: 0.9144 ** 2,
    mi2: 1609.344 ** 2,
    acre: 4046.8564224,
    hectare: 10000
};
const AREA_METRIC = new Set(["mm2", "cm2", "m2", "km2", "hectare"]);
function pickAreaTarget(sqm) {
    if (sqm < 10000)
        return "m2";
    if (sqm < 1000000)
        return "hectare";
    return "km2";
}

const WEIGHT_ALIASES = {
    mg: "mg",
    milligram: "mg",
    milligrams: "mg",
    g: "g",
    gram: "g",
    grams: "g",
    kg: "kg",
    kilogram: "kg",
    kilograms: "kg",
    kilo: "kg",
    kilos: "kg",
    oz: "oz",
    ounce: "oz",
    ounces: "oz",
    lb: "lb",
    lbs: "lb",
    pound: "lb",
    pounds: "lb"
};
const WEIGHT_FACTORS = {
    // grams per unit
    mg: 0.001,
    g: 1,
    kg: 1000,
    oz: 28.349523125,
    lb: 453.59237
};
const WEIGHT_METRIC = new Set(["mg", "g", "kg"]);
function pickWeightTarget(grams) {
    if (grams < 1000)
        return "g";
    return "kg";
}

const DATA_ALIASES = {
    b: "b",
    byte: "b",
    bytes: "b",
    kb: "kb",
    mb: "mb",
    gb: "gb",
    tb: "tb",
    kib: "kib",
    mib: "mib",
    gib: "gib",
    tib: "tib"
};
const DATA_FACTORS = {
    // bytes per unit
    b: 1,
    kb: 1000,
    mb: 1000 ** 2,
    gb: 1000 ** 3,
    tb: 1000 ** 4,
    kib: 1024,
    mib: 1024 ** 2,
    gib: 1024 ** 3,
    tib: 1024 ** 4
};

// bit-rate spellings (bps/kbps/...) are decimal bits/sec, the ISP convention;
// byte-rate needs an explicit "/s" (mb/s, mib/s) so it can't be confused with
// the plain data-storage units above (mb, mib, ...)
const DATA_RATE_ALIASES = {
    bps: "bps",
    kbps: "kbps",
    mbps: "mbps",
    gbps: "gbps",
    tbps: "tbps",
    "b/s": "b/s",
    "kb/s": "kb/s",
    "mb/s": "mb/s",
    "gb/s": "gb/s",
    "tb/s": "tb/s",
    "kib/s": "kib/s",
    "mib/s": "mib/s",
    "gib/s": "gib/s",
    "tib/s": "tib/s"
};
const DATA_RATE_FACTORS = {
    // bits/sec per unit
    bps: 1,
    kbps: 1000,
    mbps: 1000 ** 2,
    gbps: 1000 ** 3,
    tbps: 1000 ** 4,
    "b/s": 8,
    "kb/s": 8 * 1000,
    "mb/s": 8 * 1000 ** 2,
    "gb/s": 8 * 1000 ** 3,
    "tb/s": 8 * 1000 ** 4,
    "kib/s": 8 * 1024,
    "mib/s": 8 * 1024 ** 2,
    "gib/s": 8 * 1024 ** 3,
    "tib/s": 8 * 1024 ** 4
};

const SPEED_ALIASES = {
    "m/s": "m/s",
    ms: "m/s",
    mps: "m/s",
    "km/h": "km/h",
    kmh: "km/h",
    kph: "km/h",
    mph: "mph",
    kn: "kn",
    kt: "kn",
    kts: "kn",
    knot: "kn",
    knots: "kn"
};
const SPEED_FACTORS = {
    // meters/sec per unit
    "m/s": 1,
    "km/h": 1000 / 3600,
    mph: 0.44704,
    kn: 0.514444
};
const SPEED_METRIC = new Set(["m/s", "km/h"]);

// temperature isn't a simple multiply-by-factor conversion, handled separately
const TEMP_ALIASES = {
    c: "c",
    "°c": "c",
    celsius: "c",
    f: "f",
    "°f": "f",
    fahrenheit: "f",
    k: "k",
    "°k": "k",
    kelvin: "k"
};

// linear (factor-based) categories - add new ones here, nothing else needs
// updating. metricUnits/pickTarget are optional - only categories that have
// both participate in bare-query ("<num> <unit>", no "to X") defaulting; data
// and data-rate are left out since eg. typing "5 gb" bare is already the
// final unit someone wants, no imperial/metric mismatch to auto-fix
const LINEAR_CATEGORIES = [
    {
        aliases: LENGTH_ALIASES,
        factors: LENGTH_FACTORS,
        metricUnits: LENGTH_METRIC,
        pickTarget: pickLengthTarget
    },
    {
        aliases: AREA_ALIASES,
        factors: AREA_FACTORS,
        metricUnits: AREA_METRIC,
        pickTarget: pickAreaTarget
    },
    {
        aliases: WEIGHT_ALIASES,
        factors: WEIGHT_FACTORS,
        metricUnits: WEIGHT_METRIC,
        pickTarget: pickWeightTarget
    },
    {
        aliases: DATA_ALIASES,
        factors: DATA_FACTORS
    },
    {
        aliases: DATA_RATE_ALIASES,
        factors: DATA_RATE_FACTORS
    },
    {
        aliases: SPEED_ALIASES,
        factors: SPEED_FACTORS,
        metricUnits: SPEED_METRIC,
        pickTarget: () => "km/h"
    }
];

// frankfurter.app only recognizes ISO-4217 codes (eg JPY, not "yen") - this
// maps a handful of common everyday names onto their code so typing the
// name people actually use still works. Deliberately skips names that are
// ambiguous between multiple currencies (peso, krone, dollar besides USD).
const CURRENCY_NAME_ALIASES = {
    dollar: "USD",
    dollars: "USD",
    usd: "USD",
    euro: "EUR",
    euros: "EUR",
    pound: "GBP",
    pounds: "GBP",
    sterling: "GBP",
    yen: "JPY",
    yuan: "CNY",
    renminbi: "CNY",
    won: "KRW",
    franc: "CHF",
    francs: "CHF",
    rupee: "INR",
    rupees: "INR",
    real: "BRL",
    reais: "BRL",
    baht: "THB",
    rand: "ZAR",
    ringgit: "MYR",
    rupiah: "IDR",
    shekel: "ILS",
    shekels: "ILS",
    koruna: "CZK",
    zloty: "PLN",
    leu: "RON",
    lira: "TRY",
    forint: "HUF"
};

// fixed UTC offsets (hours) for common timezone abbreviations - these are
// genuinely fixed (each abbreviation already implies standard vs. daylight,
// eg pst vs pdt), unlike IANA zone names which shift with DST. "cst" is
// treated as US Central, not China Standard Time, to match pst/est/mst above.
const TZ_OFFSETS = {
    utc: 0,
    gmt: 0,
    bst: 1,
    cet: 1,
    cest: 2,
    eet: 2,
    eest: 3,
    msk: 3,
    ist: 5.5,
    pkt: 5,
    jst: 9,
    kst: 9,
    aest: 10,
    aedt: 11,
    nzst: 12,
    nzdt: 13,
    est: -5,
    edt: -4,
    cst: -6,
    cdt: -5,
    mst: -7,
    mdt: -6,
    pst: -8,
    pdt: -7,
    akst: -9,
    akdt: -8,
    hst: -10
};

function lastSundayUtc(year, monthIndex) {
    const lastDay = new Date(Date.UTC(year, monthIndex + 1, 0)).getUTCDate();
    const d = new Date(Date.UTC(year, monthIndex, lastDay));
    return lastDay - d.getUTCDay();
}

// EU DST: starts last Sunday of March 01:00 UTC, ends last Sunday of
// October 01:00 UTC - same rule observed by Germany, hence CET/CEST
function isGermanDst(now) {
    const year = now.getUTCFullYear();
    const dstStart = new Date(Date.UTC(year, 2, lastSundayUtc(year, 2), 1, 0, 0));
    const dstEnd = new Date(Date.UTC(year, 9, lastSundayUtc(year, 9), 1, 0, 0));
    return now >= dstStart && now < dstEnd;
}

function parseTimezoneQuery(input) {
    const m = /^\s*([01]?\d|2[0-3]):([0-5]\d)\s+([a-zA-Z]+)\s*$/.exec(input);
    if (!m)
        return null;
    return {
        hour: parseInt(m[1], 10),
        minute: parseInt(m[2], 10),
        code: m[3].toLowerCase()
    };
}

function formatTime(totalMinutes) {
    const m = ((totalMinutes % 1440) + 1440) % 1440;
    const hh = Math.floor(m / 60).toString().padStart(2, "0");
    const mm = (m % 60).toString().padStart(2, "0");
    return hh + ":" + mm;
}

// "<HH:MM> <tz code>" -> always converts to current German time (CET/CEST
// depending on today's DST state) - null if the query isn't that shape or
// the code isn't recognized
function evaluateTimezone(input) {
    const q = parseTimezoneQuery(input);
    if (!q)
        return null;

    const fromOffset = TZ_OFFSETS[q.code];
    if (fromOffset === undefined)
        return null;

    const germanOffset = isGermanDst(new Date()) ? 2 : 1;
    const germanLabel = germanOffset === 2 ? "CEST" : "CET";

    const utcMinutes = q.hour * 60 + q.minute - fromOffset * 60;
    const germanMinutes = utcMinutes + germanOffset * 60;

    return formatTime(germanMinutes) + " " + germanLabel;
}

// accepts plain decimals ("3.5"), leading-zero-less decimals (".5"), simple
// fractions ("3/8"), and mixed numbers ("1 3/8") as the value in any query
// below, eg "3/8 in to cm", ".5 in", or "1 3/8 in"
const NUMBER_PATTERN = "(?:-?\\d+\\/\\d+|-?(?:\\d+(?:\\.\\d+)?|\\.\\d+)(?:\\s+\\d+\\/\\d+)?)";

function parseNumberToken(token) {
    const mixed = /^(-?\d+)\s+(\d+)\/(\d+)$/.exec(token);
    if (mixed) {
        const whole = parseInt(mixed[1], 10);
        const frac = parseInt(mixed[2], 10) / parseInt(mixed[3], 10);
        return whole < 0 ? whole - frac : whole + frac;
    }
    const frac = /^(-?\d+)\/(\d+)$/.exec(token);
    if (frac)
        return parseInt(frac[1], 10) / parseInt(frac[2], 10);
    return parseFloat(token);
}

function parseQuery(input) {
    const m = new RegExp("^\\s*(" + NUMBER_PATTERN + ")\\s*([a-zA-Z°/^0-9]+)\\s+(?:to|in)\\s+([a-zA-Z°/^0-9]+)\\s*$", "i").exec(input);
    if (!m)
        return null;
    return {
        value: parseNumberToken(m[1]),
        from: m[2].toLowerCase(),
        to: m[3].toLowerCase()
    };
}

// no explicit "to X" target, eg "20 jpy" - used to auto-convert bare currency
// amounts to DEFAULT_CURRENCY without having to type "to eur" every time
function parseBareQuery(input) {
    const m = new RegExp("^\\s*(" + NUMBER_PATTERN + ")\\s*([a-zA-Z°/^0-9]+)\\s*$", "i").exec(input);
    if (!m)
        return null;
    return {
        value: parseNumberToken(m[1]),
        from: m[2].toLowerCase()
    };
}

function formatResult(n) {
    if (!isFinite(n))
        return "Error";
    let s = n.toFixed(2);
    if (s.includes(".")) {
        s = s.replace(/0+$/, "").replace(/\.$/, "");
    }
    return s;
}

// unit<->unit conversion (length, weight, temperature, data, speed) - null
// if the query isn't a recognized "<num> <unit> to <unit>" shape, or the
// two units aren't in the same category
function evaluateUnit(input) {
    const q = parseQuery(input);
    if (!q)
        return null;

    if (q.from in TEMP_ALIASES && q.to in TEMP_ALIASES) {
        const from = TEMP_ALIASES[q.from];
        const to = TEMP_ALIASES[q.to];

        let celsius;
        if (from === "c")
            celsius = q.value;
        else if (from === "f")
            celsius = (q.value - 32) * 5 / 9;
        else
            celsius = q.value - 273.15;

        let result;
        if (to === "c")
            result = celsius;
        else if (to === "f")
            result = celsius * 9 / 5 + 32;
        else
            result = celsius + 273.15;

        return formatResult(result) + " °" + to.toUpperCase();
    }

    for (const category of LINEAR_CATEGORIES) {
        if (q.from in category.aliases && q.to in category.aliases) {
            const from = category.aliases[q.from];
            const to = category.aliases[q.to];
            const base = q.value * category.factors[from];
            const result = base / category.factors[to];
            return formatResult(result) + " " + to;
        }
    }

    return null;
}

// bare "<num> <unit>" (no explicit "to X") - auto-converts non-metric units
// to a metric target, scaled by magnitude (see pickLengthTarget etc. above so
// eg. "1 in" -> cm but "40 in" -> m. Metric-to-metric bare queries ("10 cm")
// return null - already a sensible unit, no better default to offer.
function evaluateUnitDefault(input) {
    const bare = parseBareQuery(input);
    if (!bare)
        return null;

    if (bare.from in TEMP_ALIASES) {
        const from = TEMP_ALIASES[bare.from];
        if (from === "c")
            return null;
        const celsius = from === "f" ? (bare.value - 32) * 5 / 9 : bare.value - 273.15;
        return formatResult(celsius) + " °C";
    }

    for (const category of LINEAR_CATEGORIES) {
        if (!category.pickTarget || !(bare.from in category.aliases))
            continue;

        const from = category.aliases[bare.from];
        if (category.metricUnits.has(from))
            return null;

        const base = bare.value * category.factors[from];
        const target = category.pickTarget(base);
        if (target === from)
            return null;

        return formatResult(base / category.factors[target]) + " " + target;
    }

    return null;
}

// base (radix) conversion - "0x" / "0b" / "0o" prefixed literals, or a plain
// decimal integer. Bare "0xFF" (no "to X") auto-converts to decimal, since a
// prefixed literal has an obvious canonical target; a bare plain decimal has
// no obvious target base, so that case is left to explicit "<num> to 0x".
const BASE_TARGET_ALIASES = {
    "0x": "0x",
    hex: "0x",
    hexadecimal: "0x",
    "0b": "0b",
    bin: "0b",
    binary: "0b",
    "0o": "0o",
    oct: "0o",
    octal: "0o",
    dec: "dec",
    decimal: "dec"
};

function parseBaseLiteral(token) {
    if (/^0x[0-9a-fA-F]+$/.test(token))
        return parseInt(token.slice(2), 16);
    if (/^0b[01]+$/.test(token))
        return parseInt(token.slice(2), 2);
    if (/^0o[0-7]+$/.test(token))
        return parseInt(token.slice(2), 8);
    if (/^-?\d+$/.test(token))
        return parseInt(token, 10);
    return NaN;
}

function formatBase(value, target) {
    const neg = value < 0;
    const abs = Math.abs(value);
    if (target === "dec")
        return (neg ? "-" : "") + abs.toString(10);
    const radix = target === "0x" ? 16 : target === "0b" ? 2 : 8;
    const body = target === "0x" ? abs.toString(16).toUpperCase() : abs.toString(radix);
    return (neg ? "-" : "") + target + body;
}

// "<num or 0x/0b/0o literal> to <0x|0b|0o|hex|bin|oct|dec>" - explicit target
// form, works from any recognized source base to any target base
function evaluateBaseTo(input) {
    const m = /^\s*(0[xX][0-9a-fA-F]+|0[bB][01]+|0[oO][0-7]+|-?\d+)\s+(?:to|in)\s+([a-zA-Z0]+)\s*$/.exec(input);
    if (!m)
        return null;

    const value = parseBaseLiteral(m[1]);
    if (!Number.isFinite(value))
        return null;

    const target = BASE_TARGET_ALIASES[m[2].toLowerCase()];
    if (!target)
        return null;

    return formatBase(value, target);
}

// bare "0xFF" / "0b1010" / "0o17" (no explicit "to X") - auto-converts
// straight to decimal, since that's the obviously useful default
function evaluateBaseDefault(input) {
    const m = /^\s*(0[xX][0-9a-fA-F]+|0[bB][01]+|0[oO][0-7]+)\s*$/.exec(input);
    if (!m)
        return null;

    const value = parseBaseLiteral(m[1]);
    if (!Number.isFinite(value))
        return null;

    return String(value);
}

// currency shown for bare "<amount> <currency>" queries that don't name a
// target, eg typing "20 jpy" alone auto-converts to this
const DEFAULT_CURRENCY = "EUR";

// currency conversion using a cached { base, rates } table (rates[code] =
// amount of `code` equal to one unit of `base`) - null if the query isn't
// a recognized shape, rates aren't loaded yet, or either code is unknown
function evaluateCurrency(input, rates) {
    if (!rates || !rates.base || !rates.rates)
        return null;

    const resolveCode = token => (CURRENCY_NAME_ALIASES[token] ?? token.toUpperCase());
    const rateOf = code => code === rates.base ? 1 : rates.rates[code];

    const convert = (value, from, to) => {
        const fromRate = rateOf(from);
        const toRate = rateOf(to);
        if (fromRate === undefined || toRate === undefined)
            return null;
        const inBase = value / fromRate;
        return formatResult(inBase * toRate) + " " + to;
    };

    const q = parseQuery(input);
    if (q)
        return convert(q.value, resolveCode(q.from), resolveCode(q.to));

    const bare = parseBareQuery(input);
    if (bare) {
        const from = resolveCode(bare.from);
        if (from === DEFAULT_CURRENCY || rateOf(from) === undefined)
            return null; // not a known currency code, or already the default - nothing useful to show
        return convert(bare.value, from, DEFAULT_CURRENCY);
    }

    return null;
}

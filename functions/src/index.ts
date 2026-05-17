import * as admin from "firebase-admin";
import * as functions from "firebase-functions/v1";

const DATABASE_URL = "https://chessiq-89b45-default-rtdb.firebaseio.com";

admin.initializeApp({
    databaseURL: DATABASE_URL,
});

const db = admin.database();

// ---------------------------------------------------------------------------
// Constants
// ---------------------------------------------------------------------------

const HANDLE_MIN = 3;
const HANDLE_MAX = 20;
// Letters, digits, spaces, underscores, hyphens only
const HANDLE_RE = /^[a-zA-Z0-9_\- ]+$/;
const HANDLE_MODERATED_PREFIX = "ACADEMY_HANDLE_MODERATED:";
const ACADEMY_MAX_SCORE_PER_NODE = 15000;
const ACADEMY_MAX_TRACKED_NODES = 80;
const ACADEMY_MAX_TOTAL_SCORE =
    ACADEMY_MAX_SCORE_PER_NODE * ACADEMY_MAX_TRACKED_NODES;
const ACADEMY_MAX_EXAM_SCORE = 10000;
const ACADEMY_MAX_EXAM_TOTAL_COUNT = 50;
const ACADEMY_MAX_EXAM_DURATION_MS = 60 * 60 * 1000;
const ACADEMY_NODE_MIN_ELO = 450;
const ACADEMY_NODE_MAX_ELO = 3999;
const PROMO_CODE_MIN = 3;
const PROMO_CODE_MAX = 32;
const PROMO_UNLOCK_KEYS = [
    "themePackOwned",
    "sakuraBoardOwned",
    "tropicalBoardOwned",
    "piecePackOwned",
    "tuttiFruttiOwned",
    "spectralOwned",
    "monochromePiecesOwned",
    "pixelArrowThemeOwned",
    "heavyArrowThemeOwned",
    "sacrificeModeOwned",
    "adFreeOwned",
    "academyTuitionPassOwned",
] as const;
const ECONOMY_DEFAULT_COINS = 120;
const ECONOMY_MAX_COINS = 1000000;
const ECONOMY_MIGRATION_MAX_COINS = 1000000;
const ECONOMY_STORE_REWARD_COINS = 120;
const ECONOMY_STORE_REWARD_COOLDOWNS_MS = [
    5 * 60 * 1000,
    15 * 60 * 1000,
    30 * 60 * 1000,
] as const;
const ECONOMY_MAX_TRACKED_CLAIM_KEYS = 60;
const ECONOMY_MAX_TRACKED_FINGERPRINTS = 200;
type EconomyRewardSpec = {
    amount: number;
    minIntervalMs?: number;
    dailyMax?: number;
    requiresClaimKey?: boolean;
    requiresFingerprint?: boolean;
};

const ECONOMY_REWARD_SPECS: Record<string, EconomyRewardSpec> = {
    analysisInterstitial: {
        amount: 10,
        minIntervalMs: 3 * 60 * 1000,
        dailyMax: 10,
    },
    academyInterstitial: {
        amount: 10,
        minIntervalMs: 3 * 60 * 1000,
        dailyMax: 10,
    },
    academyExamBonus: {
        amount: 50,
        minIntervalMs: 15 * 60 * 1000,
        dailyMax: 6,
        requiresClaimKey: true,
    },
    academyDailyPuzzle: {
        amount: 40,
        requiresClaimKey: true,
    },
    academyRewardedAd: {
        amount: 10,
        minIntervalMs: 3 * 60 * 1000,
        dailyMax: 10,
    },
    academyDailyChallenge: {
        amount: 200,
        dailyMax: 1,
        requiresClaimKey: true,
    },
    purchaseCoinPackS: {
        amount: 1500,
        requiresFingerprint: true,
    },
    purchaseCoinPackL: {
        amount: 5000,
        requiresFingerprint: true,
    },
};

// ---------------------------------------------------------------------------
// Helpers
// ---------------------------------------------------------------------------

function sanitizeHandleKey(handle: string): string {
    return encodeURIComponent(
        handle
            .trim()
            .toLowerCase()
            .replace(/[^a-z0-9_\- ]/g, "_")
            .replace(/ /g, "_"),
    );
}

function sanitizeCountryKey(country: string): string {
    return encodeURIComponent(
        (country.trim() || "Unknown").replace(/[.#$[\]/]/g, "_"),
    );
}

function normalizePromoCodeKey(code: string): string {
    return encodeURIComponent(
        code
            .trim()
            .toUpperCase()
            .replace(/\s+/g, " ")
            .replace(/[^A-Z0-9 _\-]/g, "_")
            .replace(/ /g, "_"),
    );
}

function validatePromoCodeInput(rawCode: unknown): string {
    if (typeof rawCode !== "string") {
        throw new functions.https.HttpsError(
            "invalid-argument",
            "Promo code must be a string.",
        );
    }

    const code = rawCode.trim().replace(/\s+/g, " ");
    if (code.length < PROMO_CODE_MIN || code.length > PROMO_CODE_MAX) {
        throw new functions.https.HttpsError(
            "invalid-argument",
            `Promo code must be ${PROMO_CODE_MIN}-${PROMO_CODE_MAX} characters.`,
        );
    }
    if (!/^[A-Za-z0-9][A-Za-z0-9 _\-]*$/.test(code)) {
        throw new functions.https.HttpsError(
            "invalid-argument",
            "Promo code may only contain letters, numbers, spaces, underscores, and hyphens.",
        );
    }

    return code.toUpperCase();
}

function isPromoUnlockKey(value: string): value is PromoUnlockKey {
    return PROMO_UNLOCK_KEYS.includes(value as PromoUnlockKey);
}

function validateHandle(handle: unknown): string {
    if (typeof handle !== "string") {
        throw new functions.https.HttpsError(
            "invalid-argument",
            "Handle must be a string.",
        );
    }
    const h = handle.trim();
    if (h.length < HANDLE_MIN || h.length > HANDLE_MAX) {
        throw new functions.https.HttpsError(
            "invalid-argument",
            `Handle must be ${HANDLE_MIN}–${HANDLE_MAX} characters.`,
        );
    }
    if (!HANDLE_RE.test(h)) {
        throw new functions.https.HttpsError(
            "invalid-argument",
            "Handle may only contain letters, numbers, spaces, underscores, and hyphens.",
        );
    }
    return h;
}

type PublicAcademyProfile = {
    handle: string;
    country: string;
    score: number;
    title: string;
    moderated: boolean;
    updatedAt: string;
};

type AcademyOwnerRecord = {
    handle: string;
    handleKey: string;
    country: string;
    countryKey: string;
    score: number;
    title: string;
    updatedAt: string;
};

type LegacyOwnedEntry = {
    handleKey: string;
    country: string;
    countryKey: string;
    score: number;
};

type AcademyScoreEvidenceEntry = {
    nodeKey: string;
    score: number;
    leaderboardScore: number;
    correctCount: number;
    totalCount: number;
    elapsedMs: number;
    timeLimitMs: number;
    completedAtMs: number;
};

type AcademyHandleModerationRecord = {
    active: boolean;
    displayHandle?: string;
    playerMessage?: string;
    reasonCode?: string;
    updatedAt?: string;
};

type PromoUnlockKey = typeof PROMO_UNLOCK_KEYS[number];

type PromoReward = {
    coinAmount: number;
    unlockKey: PromoUnlockKey | null;
};

type PromoClaimIdentity = {
    academyHandle?: string;
    academyTitle?: string;
    academyCountry?: string;
};

type PromoClaimRecord = {
    claimedAt: string;
} & PromoClaimIdentity;

type EconomyRewardKey = keyof typeof ECONOMY_REWARD_SPECS;

type EconomyRewardTracker = {
    lastClaimAtMs?: number;
    countToday?: number;
    lastDayKey?: string;
    claimKeys?: Record<string, string>;
};

type EconomyState = {
    coins: number;
    createdAt: string;
    updatedAt: string;
    storeRewardLastClaimAtMs: number | null;
    storeRewardCountToday: number;
    storeRewardDayKey: string;
    rewardTrackers?: Record<string, EconomyRewardTracker>;
    deliveredFingerprints?: string[];
    migratedFromClient?: boolean;
};

type EconomyClientPayload = {
    coins: number;
    storeReward: {
        lastClaimAtMs: number | null;
        watchCountToday: number;
        dayKey: string;
    };
};

type StoredPromoCode = {
    code: string;
    isActive: boolean;
    reward: PromoReward;
    expiresAt: string | null;
    maxUses: number | null;
    usedCount: number;
    claimedBy: Record<string, PromoClaimRecord>;
};

type PromoCodesRoot = Record<string, unknown>;

function buildPublicProfile(params: {
    handle: string;
    country: string;
    score: number;
    title: string;
}): PublicAcademyProfile {
    return {
        handle: params.handle,
        country: params.country,
        score: params.score,
        title: params.title,
        moderated: false,
        updatedAt: new Date().toISOString(),
    };
}

function buildOwnerRecord(params: {
    handle: string;
    handleKey: string;
    country: string;
    countryKey: string;
    score: number;
    title: string;
    updatedAt: string;
}): AcademyOwnerRecord {
    return {
        handle: params.handle,
        handleKey: params.handleKey,
        country: params.country,
        countryKey: params.countryKey,
        score: params.score,
        title: params.title,
        updatedAt: params.updatedAt,
    };
}

function hasInlineModerationFlag(value: unknown): boolean {
    if (!value || typeof value !== "object") {
        return false;
    }

    const record = value as Record<string, unknown>;
    return record.moderated === true;
}

function parseActiveHandleModeration(
    value: unknown,
): AcademyHandleModerationRecord | null {
    if (value === true) {
        return { active: true };
    }

    if (!value || typeof value !== "object") {
        return null;
    }

    const record = value as Record<string, unknown>;
    if (record.active === false) {
        return null;
    }

    const displayHandle =
        typeof record.displayHandle === "string" && record.displayHandle.trim().length > 0
            ? record.displayHandle.trim().substring(0, HANDLE_MAX)
            : undefined;
    const playerMessage =
        typeof record.playerMessage === "string" && record.playerMessage.trim().length > 0
            ? record.playerMessage.trim().substring(0, 240)
            : undefined;
    const reasonCode =
        typeof record.reasonCode === "string" && record.reasonCode.trim().length > 0
            ? record.reasonCode.trim().substring(0, 80)
            : undefined;
    const updatedAt =
        typeof record.updatedAt === "string" && record.updatedAt.trim().length > 0
            ? record.updatedAt.trim().substring(0, 80)
            : undefined;

    return {
        active: true,
        displayHandle,
        playerMessage,
        reasonCode,
        updatedAt,
    };
}

async function loadActiveHandleModeration(
    handleKey: string,
): Promise<AcademyHandleModerationRecord | null> {
    const snap = await db.ref(`academy_handle_moderation/${handleKey}`).once("value");
    return parseActiveHandleModeration(snap.val());
}

async function activateHandleModeration(handleKey: string): Promise<void> {
    await db.ref(`academy_handle_moderation/${handleKey}`).transaction((currentValue) => {
        if (currentValue === true) {
            return currentValue;
        }
        if (!currentValue || typeof currentValue !== "object") {
            return true;
        }

        const record = currentValue as Record<string, unknown>;
        if (record.active === true) {
            return currentValue;
        }

        return {
            ...record,
            active: true,
            updatedAt: new Date().toISOString(),
        };
    });
}

function calculateAcademyExamScore(params: {
    correctCount: number;
    totalCount: number;
    elapsedMs: number;
    timeLimitMs: number;
}): number {
    if (params.totalCount <= 0) {
        return 0;
    }

    const boundedElapsedMs = Math.min(
        Math.max(0, params.elapsedMs),
        params.timeLimitMs,
    );
    const remainingMs = Math.max(0, params.timeLimitMs - boundedElapsedMs);
    const accuracyRatio = Math.min(
        1,
        Math.max(0, params.correctCount / params.totalCount),
    );
    const speedRatio = params.timeLimitMs <= 0
        ? 0
        : remainingMs / params.timeLimitMs;
    return Math.round((accuracyRatio * 8000) + (speedRatio * 2000));
}

function calculateAcademyLeaderboardScore(
    examScore: number,
    nodeElo: number,
): number {
    const normalizedElo = Math.min(
        ACADEMY_NODE_MAX_ELO,
        Math.max(ACADEMY_NODE_MIN_ELO, nodeElo),
    );
    const weight =
        0.5 +
        ((normalizedElo - ACADEMY_NODE_MIN_ELO) /
            (ACADEMY_NODE_MAX_ELO - ACADEMY_NODE_MIN_ELO));
    return Math.round(examScore * weight);
}

function readPromoPositiveInteger(
    value: unknown,
    fieldName: string,
    max: number,
): number {
    if (typeof value !== "number" || !Number.isFinite(value) || !Number.isInteger(value)) {
        throw new Error(`Promo field ${fieldName} must be an integer.`);
    }
    if (value < 0 || value > max) {
        throw new Error(`Promo field ${fieldName} is out of range.`);
    }
    return value;
}

function parseStoredPromoCode(value: unknown): StoredPromoCode {
    if (!value || typeof value !== "object") {
        throw new Error("Promo code record is missing.");
    }

    const record = value as Record<string, unknown>;
    const code = typeof record.code === "string"
        ? validatePromoCodeInput(record.code)
        : "";
    if (code.length === 0) {
        throw new Error("Promo code record must include a valid code.");
    }

    const isActive = record.isActive !== false;
    const rewardValue = record.reward;
    if (!rewardValue || typeof rewardValue !== "object") {
        throw new Error("Promo code reward configuration is missing.");
    }

    const rewardRecord = rewardValue as Record<string, unknown>;
    const coinAmountRaw = rewardRecord.coinAmount;
    const coinAmount = coinAmountRaw == null
        ? 0
        : readPromoPositiveInteger(coinAmountRaw, "reward.coinAmount", 1000000);

    const rawUnlockKey = rewardRecord.unlockKey;
    const unlockKey = rawUnlockKey == null
        ? null
        : typeof rawUnlockKey === "string" && isPromoUnlockKey(rawUnlockKey)
            ? rawUnlockKey
            : null;
    if (rawUnlockKey != null && unlockKey == null) {
        throw new Error("Promo code unlock reward is not allowlisted.");
    }
    if (coinAmount <= 0 && unlockKey == null) {
        throw new Error("Promo code reward must grant coins or one unlock.");
    }

    const rawExpiresAt = record.expiresAt;
    let expiresAt: string | null = null;
    if (rawExpiresAt != null) {
        if (typeof rawExpiresAt !== "string") {
            throw new Error("Promo code expiry must be a string.");
        }
        const parsedExpiresAt = Date.parse(rawExpiresAt);
        if (Number.isNaN(parsedExpiresAt)) {
            throw new Error("Promo code expiry is not a valid ISO date.");
        }
        expiresAt = new Date(parsedExpiresAt).toISOString();
    }

    const maxUsesRaw = record.maxUses;
    const maxUses = maxUsesRaw == null
        ? null
        : readPromoPositiveInteger(maxUsesRaw, "maxUses", 1000000);
    if (maxUses === 0) {
        throw new Error("Promo code maxUses must be at least 1 when provided.");
    }

    const usedCountRaw = record.usedCount;
    const usedCount = usedCountRaw == null
        ? 0
        : readPromoPositiveInteger(usedCountRaw, "usedCount", 1000000);
    if (maxUses != null && usedCount > maxUses) {
        throw new Error("Promo code usedCount exceeds maxUses.");
    }

    const claimedByRaw = record.claimedBy;
    const claimedBy: Record<string, PromoClaimRecord> = {};
    if (claimedByRaw != null) {
        if (!claimedByRaw || typeof claimedByRaw !== "object") {
            throw new Error("Promo code claimedBy must be an object.");
        }

        for (const [uid, claimValue] of Object.entries(claimedByRaw)) {
            if (!claimValue || typeof claimValue !== "object") {
                throw new Error("Promo code claim entries must be objects.");
            }
            const claimRecord = claimValue as Record<string, unknown>;
            const claimedAt = typeof claimRecord.claimedAt === "string"
                ? claimRecord.claimedAt
                : "";
            if (!claimedAt || Number.isNaN(Date.parse(claimedAt))) {
                throw new Error("Promo code claim entries must include a valid claimedAt.");
            }

            const academyHandle =
                typeof claimRecord.academyHandle === "string" &&
                    claimRecord.academyHandle.trim().length > 0
                    ? claimRecord.academyHandle.trim().substring(0, HANDLE_MAX)
                    : undefined;
            const academyTitle =
                typeof claimRecord.academyTitle === "string" &&
                    claimRecord.academyTitle.trim().length > 0
                    ? claimRecord.academyTitle.trim().substring(0, 40)
                    : undefined;
            const academyCountry =
                typeof claimRecord.academyCountry === "string" &&
                    claimRecord.academyCountry.trim().length > 0
                    ? claimRecord.academyCountry.trim().substring(0, 40)
                    : undefined;

            claimedBy[uid] = {
                claimedAt,
                ...(academyHandle ? { academyHandle } : {}),
                ...(academyTitle ? { academyTitle } : {}),
                ...(academyCountry ? { academyCountry } : {}),
            };
        }
    }

    return {
        code,
        isActive,
        reward: {
            coinAmount,
            unlockKey,
        },
        expiresAt,
        maxUses,
        usedCount,
        claimedBy,
    };
}

function findPromoCodeEntry(params: {
    rootValue: unknown;
    requestedCode: string;
    preferredKey: string;
}): { key: string; value: unknown } | null {
    if (!params.rootValue || typeof params.rootValue !== "object") {
        return null;
    }

    const promoCodes = params.rootValue as PromoCodesRoot;
    if (Object.prototype.hasOwnProperty.call(promoCodes, params.preferredKey)) {
        return {
            key: params.preferredKey,
            value: promoCodes[params.preferredKey],
        };
    }

    for (const [entryKey, entryValue] of Object.entries(promoCodes)) {
        if (!entryValue || typeof entryValue !== "object") {
            continue;
        }

        const rawCode = (entryValue as Record<string, unknown>).code;
        if (typeof rawCode !== "string") {
            continue;
        }

        try {
            if (validatePromoCodeInput(rawCode) === params.requestedCode) {
                return {
                    key: entryKey,
                    value: entryValue,
                };
            }
        } catch {
            continue;
        }
    }

    return null;
}

function clampEconomyCoins(value: number): number {
    return Math.min(ECONOMY_MAX_COINS, Math.max(0, Math.trunc(value)));
}

function utcDayKeyFromMs(value: number): string {
    const date = new Date(value);
    const yyyy = date.getUTCFullYear().toString().padStart(4, "0");
    const mm = (date.getUTCMonth() + 1).toString().padStart(2, "0");
    const dd = date.getUTCDate().toString().padStart(2, "0");
    return `${yyyy}-${mm}-${dd}`;
}

function millisecondsUntilNextUtcMidnight(nowMs: number): number {
    const now = new Date(nowMs);
    const nextMidnight = Date.UTC(
        now.getUTCFullYear(),
        now.getUTCMonth(),
        now.getUTCDate() + 1,
        0,
        0,
        0,
        0,
    );
    return Math.max(0, nextMidnight - nowMs);
}

function readBoundedInteger(
    value: unknown,
    fallback: number,
    min: number,
    max: number,
): number {
    if (typeof value !== "number" || !Number.isFinite(value)) {
        return fallback;
    }

    const normalized = Math.trunc(value);
    if (normalized < min || normalized > max) {
        return fallback;
    }
    return normalized;
}

function pruneStringRecord(
    source: Record<string, string>,
    maxEntries: number,
): Record<string, string> {
    const entries = Object.entries(source)
        .filter(([key, value]) => key.trim().length > 0 && value.trim().length > 0)
        .sort((a, b) => a[1].localeCompare(b[1]));
    if (entries.length <= maxEntries) {
        return Object.fromEntries(entries);
    }
    return Object.fromEntries(entries.slice(entries.length - maxEntries));
}

function buildDefaultEconomyState(params?: {
    migrationCoins?: number | null;
    nowIso?: string;
}): EconomyState {
    const nowIso = params?.nowIso ?? new Date().toISOString();
    const migrationCoins = params?.migrationCoins ?? null;
    return {
        coins: clampEconomyCoins(migrationCoins ?? ECONOMY_DEFAULT_COINS),
        createdAt: nowIso,
        updatedAt: nowIso,
        storeRewardLastClaimAtMs: null,
        storeRewardCountToday: 0,
        storeRewardDayKey: "",
        rewardTrackers: {},
        deliveredFingerprints: [],
        migratedFromClient: migrationCoins != null,
    };
}

function isEconomyRewardKey(value: string): value is EconomyRewardKey {
    return Object.prototype.hasOwnProperty.call(ECONOMY_REWARD_SPECS, value);
}

function normalizeEconomyRewardTracker(value: unknown): EconomyRewardTracker {
    if (!value || typeof value !== "object") {
        return {
            countToday: 0,
            lastDayKey: "",
        };
    }

    const record = value as Record<string, unknown>;
    const claimKeysRaw = record.claimKeys;
    let claimKeys: Record<string, string> | undefined;
    if (claimKeysRaw && typeof claimKeysRaw === "object") {
        const next: Record<string, string> = {};
        for (const [claimKey, storedAt] of Object.entries(claimKeysRaw)) {
            if (typeof storedAt !== "string") {
                continue;
            }
            const trimmedKey = claimKey.trim().substring(0, 120);
            const trimmedValue = storedAt.trim().substring(0, 80);
            if (trimmedKey.length === 0 || trimmedValue.length === 0) {
                continue;
            }
            next[trimmedKey] = trimmedValue;
        }
        if (Object.keys(next).length > 0) {
            claimKeys = pruneStringRecord(next, ECONOMY_MAX_TRACKED_CLAIM_KEYS);
        }
    }

    const lastClaimAtMs = readBoundedInteger(
        record.lastClaimAtMs,
        -1,
        0,
        Number.MAX_SAFE_INTEGER,
    );
    return {
        ...(lastClaimAtMs >= 0 ? { lastClaimAtMs } : {}),
        countToday: readBoundedInteger(record.countToday, 0, 0, 1000),
        lastDayKey: typeof record.lastDayKey === "string"
            ? record.lastDayKey.trim().substring(0, 32)
            : "",
        ...(claimKeys != null ? { claimKeys } : {}),
    };
}

function normalizeEconomyState(
    value: unknown,
    migrationCoins?: number | null,
): EconomyState {
    const fallback = buildDefaultEconomyState({ migrationCoins });
    if (!value || typeof value !== "object") {
        return fallback;
    }

    const record = value as Record<string, unknown>;
    const rewardTrackers: Record<string, EconomyRewardTracker> = {};
    const rewardTrackersRaw = record.rewardTrackers;
    if (rewardTrackersRaw && typeof rewardTrackersRaw === "object") {
        for (const [key, trackerValue] of Object.entries(rewardTrackersRaw)) {
            if (!isEconomyRewardKey(key)) {
                continue;
            }
            rewardTrackers[key] = normalizeEconomyRewardTracker(trackerValue);
        }
    }

    const deliveredFingerprintsRaw = Array.isArray(record.deliveredFingerprints)
        ? record.deliveredFingerprints
        : [];
    const deliveredFingerprints = Array.from(
        new Set(
            deliveredFingerprintsRaw
                .filter((entry): entry is string => typeof entry === "string")
                .map((entry) => entry.trim())
                .filter((entry) => entry.length > 0)
                .slice(-ECONOMY_MAX_TRACKED_FINGERPRINTS),
        ),
    );

    return {
        coins: clampEconomyCoins(
            readBoundedInteger(
                record.coins,
                fallback.coins,
                0,
                ECONOMY_MAX_COINS,
            ),
        ),
        createdAt: typeof record.createdAt === "string" && record.createdAt.trim().length > 0
            ? record.createdAt.trim().substring(0, 80)
            : fallback.createdAt,
        updatedAt: typeof record.updatedAt === "string" && record.updatedAt.trim().length > 0
            ? record.updatedAt.trim().substring(0, 80)
            : fallback.updatedAt,
        storeRewardLastClaimAtMs: (() => {
            const normalized = readBoundedInteger(
                record.storeRewardLastClaimAtMs,
                -1,
                0,
                Number.MAX_SAFE_INTEGER,
            );
            return normalized >= 0 ? normalized : null;
        })(),
        storeRewardCountToday: readBoundedInteger(
            record.storeRewardCountToday,
            0,
            0,
            ECONOMY_STORE_REWARD_COOLDOWNS_MS.length,
        ),
        storeRewardDayKey: typeof record.storeRewardDayKey === "string"
            ? record.storeRewardDayKey.trim().substring(0, 32)
            : "",
        rewardTrackers,
        deliveredFingerprints,
        migratedFromClient: record.migratedFromClient === true,
    };
}

function buildEconomyClientPayload(state: EconomyState): EconomyClientPayload {
    return {
        coins: state.coins,
        storeReward: {
            lastClaimAtMs: state.storeRewardLastClaimAtMs,
            watchCountToday: state.storeRewardCountToday,
            dayKey: state.storeRewardDayKey,
        },
    };
}

function readOptionalMigrationCoins(value: unknown): number | null {
    if (value == null) {
        return null;
    }
    if (typeof value !== "number" || !Number.isFinite(value) || !Number.isInteger(value)) {
        throw new functions.https.HttpsError(
            "invalid-argument",
            "Migration coins must be an integer.",
        );
    }
    if (value < 0 || value > ECONOMY_MIGRATION_MAX_COINS) {
        throw new functions.https.HttpsError(
            "invalid-argument",
            "Migration coins are out of range.",
        );
    }
    return value;
}

function readRequiredEconomyAmount(value: unknown): number {
    if (typeof value !== "number" || !Number.isFinite(value) || !Number.isInteger(value)) {
        throw new functions.https.HttpsError(
            "invalid-argument",
            "Economy amount must be an integer.",
        );
    }
    if (value <= 0 || value > ECONOMY_MAX_COINS) {
        throw new functions.https.HttpsError(
            "invalid-argument",
            "Economy amount is out of range.",
        );
    }
    return value;
}

function readEconomyRewardKey(value: unknown): EconomyRewardKey {
    if (typeof value !== "string") {
        throw new functions.https.HttpsError(
            "invalid-argument",
            "Reward key must be a string.",
        );
    }

    const rewardKey = value.trim();
    if (!isEconomyRewardKey(rewardKey)) {
        throw new functions.https.HttpsError(
            "invalid-argument",
            "Reward key is not allowlisted.",
        );
    }
    return rewardKey;
}

function readOptionalEconomyString(
    value: unknown,
    fieldName: string,
    maxLength: number,
): string | null {
    if (value == null) {
        return null;
    }
    if (typeof value !== "string") {
        throw new functions.https.HttpsError(
            "invalid-argument",
            `${fieldName} must be a string.`,
        );
    }
    const trimmed = value.trim();
    if (trimmed.length == 0) {
        return null;
    }
    return trimmed.substring(0, maxLength);
}

async function loadOrCreateEconomyState(
    uid: string,
    migrationCoins?: number | null,
): Promise<EconomyState> {
    const ref = db.ref(`economy_profiles/${uid}`);
    const existingSnap = await ref.once("value");
    if (existingSnap.exists()) {
        return normalizeEconomyState(existingSnap.val());
    }

    const initialState = buildDefaultEconomyState({ migrationCoins });
    const transactionResult = await ref.transaction((currentValue) => {
        if (currentValue != null) {
            return currentValue;
        }
        return initialState;
    });

    return normalizeEconomyState(transactionResult.snapshot.val(), migrationCoins);
}

function parseAcademyNodeKey(nodeKey: string): { startElo: number; endElo: number } | null {
    const match = /^(\d+)_(\d+)$/.exec(nodeKey.trim());
    if (!match) {
        return null;
    }

    const startElo = Number(match[1]);
    const endElo = Number(match[2]);
    if (!Number.isInteger(startElo) || !Number.isInteger(endElo)) {
        return null;
    }
    if (startElo < ACADEMY_NODE_MIN_ELO || startElo > ACADEMY_NODE_MAX_ELO) {
        return null;
    }
    if (endElo <= startElo) {
        return null;
    }
    return { startElo, endElo };
}

function readIntegerField(
    value: unknown,
    fieldName: string,
    min: number,
    max: number,
): number {
    if (typeof value !== "number" || !Number.isFinite(value) || !Number.isInteger(value)) {
        throw new functions.https.HttpsError(
            "invalid-argument",
            `Score evidence field ${fieldName} must be an integer.`,
        );
    }
    if (value < min || value > max) {
        throw new functions.https.HttpsError(
            "invalid-argument",
            `Score evidence field ${fieldName} is out of range.`,
        );
    }
    return value;
}

function validateAcademyScoreEvidence(
    rawEvidence: unknown,
): { totalScore: number; examCount: number } | null {
    if (rawEvidence === null || rawEvidence === undefined) {
        return null;
    }
    if (!Array.isArray(rawEvidence)) {
        throw new functions.https.HttpsError(
            "invalid-argument",
            "Score evidence must be an array.",
        );
    }
    if (rawEvidence.length === 0) {
        return null;
    }
    if (rawEvidence.length > ACADEMY_MAX_TRACKED_NODES) {
        throw new functions.https.HttpsError(
            "invalid-argument",
            "Score evidence contains too many node results.",
        );
    }

    const seenNodeKeys = new Set<string>();
    let totalScore = 0;

    for (const rawEntry of rawEvidence) {
        if (!rawEntry || typeof rawEntry !== "object") {
            throw new functions.https.HttpsError(
                "invalid-argument",
                "Each score evidence entry must be an object.",
            );
        }

        const entry = rawEntry as Record<string, unknown>;
        const nodeKey = typeof entry.nodeKey === "string"
            ? entry.nodeKey.trim()
            : "";
        const nodeInfo = parseAcademyNodeKey(nodeKey);
        if (!nodeInfo) {
            throw new functions.https.HttpsError(
                "invalid-argument",
                "Score evidence contains an invalid node key.",
            );
        }
        if (seenNodeKeys.has(nodeKey)) {
            throw new functions.https.HttpsError(
                "invalid-argument",
                "Score evidence contains duplicate node results.",
            );
        }
        seenNodeKeys.add(nodeKey);

        const correctCount = readIntegerField(
            entry.correctCount,
            "correctCount",
            0,
            ACADEMY_MAX_EXAM_TOTAL_COUNT,
        );
        const totalCount = readIntegerField(
            entry.totalCount,
            "totalCount",
            1,
            ACADEMY_MAX_EXAM_TOTAL_COUNT,
        );
        if (correctCount > totalCount) {
            throw new functions.https.HttpsError(
                "invalid-argument",
                "Score evidence has correctCount above totalCount.",
            );
        }

        const timeLimitMs = readIntegerField(
            entry.timeLimitMs,
            "timeLimitMs",
            1,
            ACADEMY_MAX_EXAM_DURATION_MS,
        );
        const elapsedMs = readIntegerField(
            entry.elapsedMs,
            "elapsedMs",
            0,
            timeLimitMs,
        );
        readIntegerField(
            entry.completedAtMs,
            "completedAtMs",
            0,
            Number.MAX_SAFE_INTEGER,
        );

        const examScore = readIntegerField(
            entry.score,
            "score",
            0,
            ACADEMY_MAX_EXAM_SCORE,
        );
        const expectedExamScore = calculateAcademyExamScore({
            correctCount,
            totalCount,
            elapsedMs,
            timeLimitMs,
        });
        if (examScore !== expectedExamScore) {
            throw new functions.https.HttpsError(
                "invalid-argument",
                "Score evidence exam score does not match ChessIQ exam rules.",
            );
        }

        const leaderboardScore = readIntegerField(
            entry.leaderboardScore,
            "leaderboardScore",
            0,
            ACADEMY_MAX_SCORE_PER_NODE,
        );
        const expectedLeaderboardScore = calculateAcademyLeaderboardScore(
            examScore,
            nodeInfo.startElo,
        );
        if (leaderboardScore !== expectedLeaderboardScore) {
            throw new functions.https.HttpsError(
                "invalid-argument",
                "Score evidence leaderboard score does not match ChessIQ weighting rules.",
            );
        }

        totalScore += leaderboardScore;
        if (totalScore > ACADEMY_MAX_TOTAL_SCORE) {
            throw new functions.https.HttpsError(
                "invalid-argument",
                "Score evidence total exceeds the Academy leaderboard range.",
            );
        }
    }

    return {
        totalScore,
        examCount: rawEvidence.length,
    };
}

function academyLeaderboardTitleForExamCount(examCount: number): string {
    return `${examCount} exams counted`;
}

async function auditRejectedAcademyScoreAttempt(params: {
    uid: string;
    handleKey: string;
    requestedScore: number;
    currentScore: number;
    allowedScore: number;
    reasonCode: string;
    examCount?: number | null;
    detail?: string | null;
}) {
    try {
        await db.ref(`academy_scoreboard_security_audit/${params.uid}`).push({
            createdAt: new Date().toISOString(),
            handleKey: params.handleKey,
            requestedScore: params.requestedScore,
            currentScore: params.currentScore,
            allowedScore: params.allowedScore,
            reasonCode: params.reasonCode,
            examCount: params.examCount ?? null,
            detail: params.detail ?? null,
        });
    } catch (error) {
        console.warn("[submitAcademyScore] Failed to write security audit", {
            uid: params.uid,
            reasonCode: params.reasonCode,
            error,
        });
    }
}

function buildModeratedHandleError(
    record: AcademyHandleModerationRecord,
): string {
    const playerMessage =
        record.playerMessage ??
        "This nickname was removed from ChessIQ leaderboards for violating the nickname rules. Choose a new nickname to continue.";
    return `${HANDLE_MODERATED_PREFIX} ${playerMessage}`;
}

async function removePublicAcademyProfile(handleKey: string): Promise<void> {
    const globalSnap = await db.ref(`academy_scoreboard/global/${handleKey}`).once("value");
    const entry = globalSnap.val() as Record<string, unknown> | null;
    const registrySnap = await db.ref(`handle_registry/${handleKey}`).once("value");
    const ownerUid = typeof registrySnap.val() === "string"
        ? registrySnap.val() as string
        : null;
    const ownerSnap = ownerUid
        ? await db.ref(`academy_profile_owner/${ownerUid}`).once("value")
        : null;
    const ownerRecord = ownerSnap?.val() as AcademyOwnerRecord | null;

    const countryKeys = new Set<string>();
    if (entry) {
        const country =
            typeof entry.country === "string" && entry.country.trim().length > 0
                ? entry.country
                : "Unknown";
        countryKeys.add(sanitizeCountryKey(country));
    }
    if (ownerRecord && ownerRecord.handleKey === handleKey) {
        countryKeys.add(ownerRecord.countryKey);
    }
    if (countryKeys.size === 0 && ownerUid === null) {
        return;
    }

    const updates: Record<string, unknown> = {
        [`academy_scoreboard/global/${handleKey}`]: null,
        [`handle_registry/${handleKey}`]: null,
    };
    for (const countryKey of countryKeys) {
        updates[`academy_scoreboard/by_country/${countryKey}/${handleKey}`] = null;
    }
    if (ownerUid !== null && ownerRecord && ownerRecord.handleKey === handleKey) {
        updates[`academy_profile_owner/${ownerUid}`] = null;
    }

    await db.ref().update(updates);
}

async function loadLegacyOwnedEntries(uid: string): Promise<LegacyOwnedEntry[]> {
    const snap = await db
        .ref("academy_scoreboard/global")
        .orderByChild("uid")
        .equalTo(uid)
        .once("value");

    const entries: LegacyOwnedEntry[] = [];
    snap.forEach((entrySnap) => {
        const handleKey = entrySnap.key;
        const entry = entrySnap.val() as Record<string, unknown> | null;
        if (!handleKey || !entry) {
            return false;
        }

        const country =
            typeof entry.country === "string" && entry.country.trim().length > 0
                ? entry.country
                : "Unknown";
        const score = typeof entry.score === "number" ? entry.score : 0;

        entries.push({
            handleKey,
            country,
            countryKey: sanitizeCountryKey(country),
            score,
        });
        return false;
    });

    return entries;
}

function addProfileRemovalUpdates(params: {
    updates: Record<string, unknown>;
    handleKey: string;
    countryKey: string;
    registryOwnerUid: string | null;
    uid: string;
}) {
    params.updates[`academy_scoreboard/global/${params.handleKey}`] = null;
    params.updates[
        `academy_scoreboard/by_country/${params.countryKey}/${params.handleKey}`
    ] = null;
    if (params.registryOwnerUid === null || params.registryOwnerUid === params.uid) {
        params.updates[`handle_registry/${params.handleKey}`] = null;
    }
}

async function submitAcademyScoreImpl(
    data: any,
    context: functions.https.CallableContext,
    enforceModeration: boolean,
) {
    if (!context.auth) {
        throw new functions.https.HttpsError(
            "unauthenticated",
            "Must be signed in.",
        );
    }
    const uid = context.auth.uid;

    const handle = validateHandle(data?.handle);
    const country =
        typeof data?.country === "string" && data.country.trim()
            ? data.country.trim().substring(0, 40)
            : "Unknown";
    if (typeof data?.score !== "number" || !Number.isFinite(data.score)) {
        throw new functions.https.HttpsError(
            "invalid-argument",
            "Score must be a finite number.",
        );
    }
    const score = Math.max(0, Math.floor(data.score));
    const submittedTitle =
        typeof data?.title === "string" ? data.title.substring(0, 40) : "";
    const scoreEvidence = validateAcademyScoreEvidence(data?.scoreEvidence);
    const title = scoreEvidence
        ? academyLeaderboardTitleForExamCount(scoreEvidence.examCount)
        : submittedTitle;

    const handleKey = sanitizeHandleKey(handle);
    const countryKey = sanitizeCountryKey(country);
    const ownerRef = db.ref(`academy_profile_owner/${uid}`);

    if (enforceModeration) {
        const moderationRecord = await loadActiveHandleModeration(handleKey);
        if (moderationRecord) {
            throw new functions.https.HttpsError(
                "failed-precondition",
                buildModeratedHandleError(moderationRecord),
            );
        }
    }

    const registryRef = db.ref(`handle_registry/${handleKey}`);
    const globalRef = db.ref(`academy_scoreboard/global/${handleKey}`);

    const registrySnap = await registryRef.once("value");
    const ownerUid: string | null = registrySnap.val();

    if (ownerUid !== null && ownerUid !== uid) {
        throw new functions.https.HttpsError(
            "already-exists",
            "This nickname is already taken by another player.",
        );
    }

    const ownerSnap = await ownerRef.once("value");
    const ownerRecord = ownerSnap.val() as AcademyOwnerRecord | null;
    const legacyOwnedEntries = ownerRecord ? [] : await loadLegacyOwnedEntries(uid);

    let maxExistingScore = 0;
    let previousHandleKey: string | null = null;
    let previousCountryKey: string | null = null;

    if (ownerRecord) {
        maxExistingScore = Math.max(0, ownerRecord.score);
        previousHandleKey = ownerRecord.handleKey;
        previousCountryKey = ownerRecord.countryKey;
    } else if (ownerUid === uid) {
        const existingSnap = await globalRef.once("value");
        const existing = existingSnap.val() as Record<string, unknown> | null;
        if (existing) {
            maxExistingScore =
                typeof existing.score === "number" ? existing.score : 0;
            previousHandleKey = handleKey;
            previousCountryKey = sanitizeCountryKey(
                typeof existing.country === "string" ? existing.country : "Unknown",
            );
        }
    }

    for (const legacyEntry of legacyOwnedEntries) {
        if (legacyEntry.score > maxExistingScore) {
            maxExistingScore = legacyEntry.score;
        }
        if (legacyEntry.handleKey === handleKey) {
            previousHandleKey = legacyEntry.handleKey;
            previousCountryKey = legacyEntry.countryKey;
        }
    }

    if (score > ACADEMY_MAX_TOTAL_SCORE) {
        await auditRejectedAcademyScoreAttempt({
            uid,
            handleKey,
            requestedScore: score,
            currentScore: maxExistingScore,
            allowedScore: ACADEMY_MAX_TOTAL_SCORE,
            reasonCode: "score_out_of_range",
            examCount: scoreEvidence?.examCount,
        });
        throw new functions.https.HttpsError(
            "invalid-argument",
            "Score is outside the Academy leaderboard range.",
        );
    }

    if (score < maxExistingScore) {
        throw new functions.https.HttpsError(
            "failed-precondition",
            "Score cannot decrease.",
        );
    }

    if (score > maxExistingScore && !scoreEvidence) {
        await auditRejectedAcademyScoreAttempt({
            uid,
            handleKey,
            requestedScore: score,
            currentScore: maxExistingScore,
            allowedScore: maxExistingScore,
            reasonCode: "missing_score_evidence",
            detail: "Positive leaderboard score updates now require validated exam evidence.",
        });
        throw new functions.https.HttpsError(
            "failed-precondition",
            "This ChessIQ version cannot sync Academy score increases yet. Update the app and try again.",
        );
    }

    if (scoreEvidence && score !== scoreEvidence.totalScore) {
        await auditRejectedAcademyScoreAttempt({
            uid,
            handleKey,
            requestedScore: score,
            currentScore: maxExistingScore,
            allowedScore: scoreEvidence.totalScore,
            reasonCode: "score_mismatch_with_evidence",
            examCount: scoreEvidence.examCount,
            detail: "Submitted score did not match the validated evidence total.",
        });
        throw new functions.https.HttpsError(
            "invalid-argument",
            "Submitted score does not match the Academy exam evidence.",
        );
    }

    const payload = buildPublicProfile({ handle, country, score, title });
    const ownerPayload = buildOwnerRecord({
        handle,
        handleKey,
        country,
        countryKey,
        score,
        title,
        updatedAt: payload.updatedAt,
    });

    const updates: Record<string, unknown> = {
        [`handle_registry/${handleKey}`]: uid,
        [`academy_scoreboard/global/${handleKey}`]: payload,
        [`academy_scoreboard/by_country/${countryKey}/${handleKey}`]: payload,
        [`academy_profile_owner/${uid}`]: ownerPayload,
    };

    if (ownerRecord && previousHandleKey && previousHandleKey !== handleKey) {
        const registryOwnerSnap = await db
            .ref(`handle_registry/${previousHandleKey}`)
            .once("value");
        addProfileRemovalUpdates({
            updates,
            handleKey: previousHandleKey,
            countryKey: previousCountryKey ?? sanitizeCountryKey(ownerRecord.country),
            registryOwnerUid: registryOwnerSnap.val() as string | null,
            uid,
        });
    } else if (
        previousHandleKey === handleKey &&
        previousCountryKey &&
        previousCountryKey !== countryKey
    ) {
        updates[`academy_scoreboard/by_country/${previousCountryKey}/${handleKey}`] = null;
    }

    for (const legacyEntry of legacyOwnedEntries) {
        const registryOwnerSnap = await db
            .ref(`handle_registry/${legacyEntry.handleKey}`)
            .once("value");
        if (
            legacyEntry.handleKey === handleKey &&
            legacyEntry.countryKey === countryKey
        ) {
            continue;
        }
        addProfileRemovalUpdates({
            updates,
            handleKey: legacyEntry.handleKey,
            countryKey: legacyEntry.countryKey,
            registryOwnerUid: registryOwnerSnap.val() as string | null,
            uid,
        });
    }

    await db.ref().update(updates);

    return { success: true };
}

async function checkHandleAvailabilityImpl(
    data: any,
    context: functions.https.CallableContext,
    enforceModeration: boolean,
) {
    const handle = validateHandle(data?.handle);
    const callerUid = context.auth?.uid ?? null;

    const handleKey = sanitizeHandleKey(handle);
    if (enforceModeration) {
        const moderationRecord = await loadActiveHandleModeration(handleKey);
        if (moderationRecord) {
            return { available: false, moderated: true };
        }
    }

    const snap = await db.ref(`handle_registry/${handleKey}`).once("value");
    const ownerUid: string | null = snap.val();

    if (ownerUid === null) return { available: true };
    if (callerUid && ownerUid === callerUid) return { available: true };
    return { available: false };
}

async function redeemPromoCodeImpl(
    data: any,
    context: functions.https.CallableContext,
) {
    if (!context.auth) {
        throw new functions.https.HttpsError(
            "unauthenticated",
            "Must be signed in.",
        );
    }

    const uid = context.auth.uid;
    const requestedCode = validatePromoCodeInput(data?.code);
    const codeKey = normalizePromoCodeKey(requestedCode);
    const promoCodesRef = db.ref("promo_codes");
    const claimedAt = new Date().toISOString();
    const ownerSnap = await db.ref(`academy_profile_owner/${uid}`).once("value");
    const ownerRecord = ownerSnap.val() as AcademyOwnerRecord | null;
    const claimIdentity: PromoClaimIdentity = {
        ...(ownerRecord != null && ownerRecord.handle.trim().length > 0
            ? { academyHandle: ownerRecord.handle.trim().substring(0, HANDLE_MAX) }
            : {}),
        ...(ownerRecord != null && ownerRecord.title.trim().length > 0
            ? { academyTitle: ownerRecord.title.trim().substring(0, 40) }
            : {}),
        ...(ownerRecord != null && ownerRecord.country.trim().length > 0
            ? { academyCountry: ownerRecord.country.trim().substring(0, 40) }
            : {}),
    };

    const preflightSnapshot = await promoCodesRef.once("value");
    const preflightRootValue = preflightSnapshot.val();
    const preflightEntry = findPromoCodeEntry({
        rootValue: preflightRootValue,
        requestedCode,
        preferredKey: codeKey,
    });
    if (preflightEntry == null) {
        throw new functions.https.HttpsError(
            "not-found",
            "Incorrect promo code.",
        );
    }

    let transactionFailureCode: string = "not-found";
    let transactionFailureMessage = "Incorrect promo code.";

    const transactionResult = await promoCodesRef.transaction((currentValue) => {
        const baseRootValue = currentValue ?? preflightRootValue;
        const promoEntry = findPromoCodeEntry({
            rootValue: baseRootValue,
            requestedCode,
            preferredKey: codeKey,
        });

        if (promoEntry == null) {
            transactionFailureCode = "not-found";
            transactionFailureMessage = "Incorrect promo code.";
            return;
        }

        try {
            const storedPromo = parseStoredPromoCode(promoEntry.value);

            if (!storedPromo.isActive) {
                transactionFailureCode = "inactive";
                transactionFailureMessage = "This promo code is inactive.";
                return;
            }

            if (storedPromo.expiresAt != null && Date.parse(storedPromo.expiresAt) <= Date.now()) {
                transactionFailureCode = "expired";
                transactionFailureMessage = "This promo code has expired.";
                return;
            }

            if (Object.prototype.hasOwnProperty.call(storedPromo.claimedBy, uid)) {
                transactionFailureCode = "already-claimed";
                transactionFailureMessage = "Promo code already used on this account.";
                return;
            }

            if (storedPromo.maxUses != null && storedPromo.usedCount >= storedPromo.maxUses) {
                transactionFailureCode = "exhausted";
                transactionFailureMessage = "This promo code has no uses left.";
                return;
            }

            const currentPromoCodes = baseRootValue as PromoCodesRoot;
            const updatedPromoCode = {
                ...(promoEntry.value as Record<string, unknown>),
                code: storedPromo.code,
                usedCount: storedPromo.usedCount + 1,
                updatedAt: claimedAt,
                claimedBy: {
                    ...storedPromo.claimedBy,
                    [uid]: {
                        claimedAt,
                        ...claimIdentity,
                    },
                },
            };

            const nextPromoCodes: PromoCodesRoot = {
                ...currentPromoCodes,
                [codeKey]: updatedPromoCode,
            };
            if (promoEntry.key !== codeKey) {
                delete nextPromoCodes[promoEntry.key];
            }

            return {
                ...nextPromoCodes,
            };
        } catch (error) {
            transactionFailureCode = "invalid-config";
            transactionFailureMessage = error instanceof Error
                ? error.message
                : "This promo code is not set up correctly yet.";
            return;
        }
    });

    if (!transactionResult.committed) {
        switch (transactionFailureCode) {
            case "already-claimed":
                throw new functions.https.HttpsError(
                    "already-exists",
                    transactionFailureMessage,
                );
            case "inactive":
            case "expired":
            case "exhausted":
            case "invalid-config":
                throw new functions.https.HttpsError(
                    "failed-precondition",
                    transactionFailureMessage,
                );
            case "not-found":
            default:
                throw new functions.https.HttpsError(
                    "not-found",
                    transactionFailureMessage,
                );
        }
    }

    const committedPromoEntry = findPromoCodeEntry({
        rootValue: transactionResult.snapshot.val(),
        requestedCode,
        preferredKey: codeKey,
    });
    if (committedPromoEntry == null) {
        throw new functions.https.HttpsError(
            "internal",
            "Promo code redemption could not be verified after commit.",
        );
    }

    const storedPromo = parseStoredPromoCode(committedPromoEntry.value);
    const claimRecord = {
        claimedAt,
        code: storedPromo.code,
        ...claimIdentity,
        reward: {
            coinAmount: storedPromo.reward.coinAmount,
            unlockKey: storedPromo.reward.unlockKey,
        },
    };

    try {
        await db.ref(`promo_code_claims/${uid}/${codeKey}`).set(claimRecord);
    } catch (error) {
        console.warn("[redeemPromoCode] Failed to write claim ledger", {
            uid,
            codeKey,
            error,
        });
    }

    let economy: EconomyClientPayload | null = null;
    if (storedPromo.reward.coinAmount > 0) {
        const economyRef = db.ref(`economy_profiles/${uid}`);
        const economyResult = await economyRef.transaction((currentValue) => {
            const currentState = normalizeEconomyState(currentValue);
            return {
                ...currentState,
                coins: clampEconomyCoins(currentState.coins + storedPromo.reward.coinAmount),
                updatedAt: claimedAt,
            };
        });
        economy = buildEconomyClientPayload(
            normalizeEconomyState(economyResult.snapshot.val()),
        );
    }

    return {
        success: true,
        code: storedPromo.code,
        reward: claimRecord.reward,
        claimedAt,
        economy,
    };
}

async function getEconomyStateImpl(
    data: any,
    context: functions.https.CallableContext,
) {
    if (!context.auth) {
        throw new functions.https.HttpsError(
            "unauthenticated",
            "Must be signed in.",
        );
    }

    const migrationCoins = readOptionalMigrationCoins(data?.migrationCoins);
    const state = await loadOrCreateEconomyState(context.auth.uid, migrationCoins);
    return {
        success: true,
        state: buildEconomyClientPayload(state),
    };
}

async function claimStoreRewardAdImpl(
    context: functions.https.CallableContext,
) {
    if (!context.auth) {
        throw new functions.https.HttpsError(
            "unauthenticated",
            "Must be signed in.",
        );
    }

    const uid = context.auth.uid;
    const ref = db.ref(`economy_profiles/${uid}`);
    let blockedReason = "cooldown";
    let remainingMs = 0;
    let responseState: EconomyState | null = null;

    const transactionResult = await ref.transaction((currentValue) => {
        const state = normalizeEconomyState(currentValue);
        const nowMs = Date.now();
        const todayKey = utcDayKeyFromMs(nowMs);

        let countToday = state.storeRewardCountToday;
        if (state.storeRewardDayKey !== todayKey) {
            countToday = 0;
        }

        if (countToday >= ECONOMY_STORE_REWARD_COOLDOWNS_MS.length) {
            blockedReason = "daily-lock";
            remainingMs = millisecondsUntilNextUtcMidnight(nowMs);
            responseState = {
                ...state,
                storeRewardCountToday: countToday,
                storeRewardDayKey: todayKey,
            };
            return;
        }

        const lastClaimAtMs = state.storeRewardLastClaimAtMs;
        if (lastClaimAtMs != null) {
            const cooldownMs = ECONOMY_STORE_REWARD_COOLDOWNS_MS[
                Math.min(countToday, ECONOMY_STORE_REWARD_COOLDOWNS_MS.length - 1)
            ];
            const nextEligibleAtMs = lastClaimAtMs + cooldownMs;
            if (nextEligibleAtMs > nowMs) {
                blockedReason = "cooldown";
                remainingMs = nextEligibleAtMs - nowMs;
                responseState = {
                    ...state,
                    storeRewardCountToday: countToday,
                    storeRewardDayKey: todayKey,
                };
                return;
            }
        }

        const nextState: EconomyState = {
            ...state,
            coins: clampEconomyCoins(state.coins + ECONOMY_STORE_REWARD_COINS),
            storeRewardLastClaimAtMs: nowMs,
            storeRewardCountToday: countToday + 1,
            storeRewardDayKey: todayKey,
            updatedAt: new Date(nowMs).toISOString(),
        };
        responseState = nextState;
        return nextState;
    });

    const state = responseState ?? normalizeEconomyState(transactionResult.snapshot.val());
    return {
        success: transactionResult.committed,
        reason: transactionResult.committed ? null : blockedReason,
        remainingMs,
        state: buildEconomyClientPayload(state),
    };
}

async function spendEconomyCoinsImpl(
    data: any,
    context: functions.https.CallableContext,
) {
    if (!context.auth) {
        throw new functions.https.HttpsError(
            "unauthenticated",
            "Must be signed in.",
        );
    }

    const amount = readRequiredEconomyAmount(data?.amount);
    const ref = db.ref(`economy_profiles/${context.auth.uid}`);
    let responseState: EconomyState | null = null;

    const transactionResult = await ref.transaction((currentValue) => {
        const state = normalizeEconomyState(currentValue);
        if (state.coins < amount) {
            responseState = state;
            return;
        }

        const nextState: EconomyState = {
            ...state,
            coins: clampEconomyCoins(state.coins - amount),
            updatedAt: new Date().toISOString(),
        };
        responseState = nextState;
        return nextState;
    });

    const state = responseState ?? normalizeEconomyState(transactionResult.snapshot.val());
    return {
        success: transactionResult.committed,
        reason: transactionResult.committed ? null : "insufficient-funds",
        state: buildEconomyClientPayload(state),
    };
}

async function grantEconomyRewardImpl(
    data: any,
    context: functions.https.CallableContext,
) {
    if (!context.auth) {
        throw new functions.https.HttpsError(
            "unauthenticated",
            "Must be signed in.",
        );
    }

    const rewardKey = readEconomyRewardKey(data?.rewardKey);
    const rewardSpec = ECONOMY_REWARD_SPECS[rewardKey];
    const claimKey = readOptionalEconomyString(data?.claimKey, "claimKey", 120);
    const fingerprint = readOptionalEconomyString(
        data?.fingerprint,
        "fingerprint",
        1024,
    );

    if (rewardSpec.requiresClaimKey && claimKey == null) {
        throw new functions.https.HttpsError(
            "invalid-argument",
            `Reward ${rewardKey} requires a claim key.`,
        );
    }
    if (rewardSpec.requiresFingerprint && fingerprint == null) {
        throw new functions.https.HttpsError(
            "invalid-argument",
            `Reward ${rewardKey} requires a delivery fingerprint.`,
        );
    }

    const ref = db.ref(`economy_profiles/${context.auth.uid}`);
    let blockedReason = "rate-limited";
    let remainingMs = 0;
    let responseState: EconomyState | null = null;

    const transactionResult = await ref.transaction((currentValue) => {
        const state = normalizeEconomyState(currentValue);
        const nowMs = Date.now();
        const todayKey = utcDayKeyFromMs(nowMs);
        const nextRewardTrackers = {
            ...(state.rewardTrackers ?? {}),
        };
        const tracker = normalizeEconomyRewardTracker(nextRewardTrackers[rewardKey]);

        if (tracker.lastDayKey !== todayKey) {
            tracker.countToday = 0;
            tracker.lastDayKey = todayKey;
        }

        if (rewardSpec.dailyMax != null &&
            (tracker.countToday ?? 0) >= rewardSpec.dailyMax) {
            blockedReason = "daily-limit";
            responseState = state;
            return;
        }

        if (rewardSpec.minIntervalMs != null && tracker.lastClaimAtMs != null) {
            const nextEligibleAtMs = tracker.lastClaimAtMs + rewardSpec.minIntervalMs;
            if (nextEligibleAtMs > nowMs) {
                blockedReason = "rate-limited";
                remainingMs = nextEligibleAtMs - nowMs;
                responseState = state;
                return;
            }
        }

        if (claimKey != null) {
            const trackedClaims = {
                ...(tracker.claimKeys ?? {}),
            };
            if (Object.prototype.hasOwnProperty.call(trackedClaims, claimKey)) {
                blockedReason = "duplicate-claim";
                responseState = state;
                return;
            }
            trackedClaims[claimKey] = new Date(nowMs).toISOString();
            tracker.claimKeys = pruneStringRecord(
                trackedClaims,
                ECONOMY_MAX_TRACKED_CLAIM_KEYS,
            );
        }

        if (fingerprint != null) {
            const fingerprints = Array.from(
                new Set([...(state.deliveredFingerprints ?? []), fingerprint]),
            );
            if (fingerprints.length === (state.deliveredFingerprints ?? []).length) {
                blockedReason = "duplicate-delivery";
                responseState = state;
                return;
            }
            state.deliveredFingerprints = fingerprints.slice(
                -ECONOMY_MAX_TRACKED_FINGERPRINTS,
            );
        }

        tracker.lastClaimAtMs = nowMs;
        tracker.lastDayKey = todayKey;
        tracker.countToday = (tracker.countToday ?? 0) + 1;
        nextRewardTrackers[rewardKey] = tracker;

        const nextState: EconomyState = {
            ...state,
            coins: clampEconomyCoins(state.coins + rewardSpec.amount),
            rewardTrackers: nextRewardTrackers,
            deliveredFingerprints: state.deliveredFingerprints ?? [],
            updatedAt: new Date(nowMs).toISOString(),
        };
        responseState = nextState;
        return nextState;
    });

    const state = responseState ?? normalizeEconomyState(transactionResult.snapshot.val());
    return {
        success: transactionResult.committed,
        reason: transactionResult.committed ? null : blockedReason,
        remainingMs,
        state: buildEconomyClientPayload(state),
    };
}

// ---------------------------------------------------------------------------
// submitAcademyScore
//
// Called by the app whenever the player's score changes.  Enforces:
//   • Valid authenticated identity (uid required).
//   • Handle format rules.
//   • Score cannot decrease for an existing entry.
//   • Score must remain inside the Academy range.
//   • When score evidence is provided, totals must match validated exam data.
//   • Handle can only be owned by one uid (first-write wins).
//
// On success writes atomically to:
//   handle_registry/{handleKey}  = uid
//   academy_scoreboard/global/{handleKey}  = payload
//   academy_scoreboard/by_country/{countryKey}/{handleKey}  = payload
// And removes the old country bucket entry when the country changed.
// ---------------------------------------------------------------------------

export const submitAcademyScore = functions.https.onCall(
    async (data, context) => submitAcademyScoreImpl(data, context, false),
);

export const submitAcademyScoreV2 = functions.https.onCall(
    async (data, context) => submitAcademyScoreImpl(data, context, true),
);

// ---------------------------------------------------------------------------
// checkHandleAvailability
//
// Returns { available: true } when the handle is unclaimed or owned by the
// calling uid.  Does NOT reveal which uid owns a taken handle.
// ---------------------------------------------------------------------------

export const checkHandleAvailability = functions.https.onCall(
    async (data, context) => checkHandleAvailabilityImpl(data, context, false),
);

export const checkHandleAvailabilityV2 = functions.https.onCall(
    async (data, context) => checkHandleAvailabilityImpl(data, context, true),
);

// ---------------------------------------------------------------------------
// redeemPromoCode
//
// Redeems a server-managed promo code for the authenticated user.
// Promo definitions live in RTDB under `promo_codes/{codeKey}` and writes are
// blocked to clients by security rules. The function enforces:
//   • Authenticated identity is present.
//   • Code exists and is active.
//   • Code has not expired.
//   • Caller has not redeemed the code before.
//   • Global maxUses has not been exhausted.
//   • Reward configuration only grants allowlisted store unlock keys.
//
// On success the function increments `usedCount`, records the uid under
// `promo_codes/{codeKey}/claimedBy/{uid}`, and writes a best-effort audit copy
// to `promo_code_claims/{uid}/{codeKey}`.
// ---------------------------------------------------------------------------

export const redeemPromoCode = functions.https.onCall(
    async (data, context) => redeemPromoCodeImpl(data, context),
);

export const getEconomyState = functions.https.onCall(
    async (data, context) => getEconomyStateImpl(data, context),
);

export const claimStoreRewardAd = functions.https.onCall(
    async (_data, context) => claimStoreRewardAdImpl(context),
);

export const spendEconomyCoins = functions.https.onCall(
    async (data, context) => spendEconomyCoinsImpl(data, context),
);

export const grantEconomyReward = functions.https.onCall(
    async (data, context) => grantEconomyRewardImpl(data, context),
);

// ---------------------------------------------------------------------------
// deleteAcademyProfile
//
// Deletes the caller's Academy leaderboard profile from the public scoreboard,
// clears handle ownership, removes the private owner record, and optionally
// deletes the anonymous Firebase Auth user so a fresh identity is created on
// the next app launch.
// ---------------------------------------------------------------------------

export const deleteAcademyProfile = functions.https.onCall(
    async (data, context) => {
        if (!context.auth) {
            throw new functions.https.HttpsError(
                "unauthenticated",
                "Must be signed in.",
            );
        }

        const uid = context.auth.uid;
        const deleteAnonymousAuth = data?.deleteAnonymousAuth !== false;

        const ownerRef = db.ref(`academy_profile_owner/${uid}`);
        const ownerSnap = await ownerRef.once("value");
        const ownerRecord = ownerSnap.val() as AcademyOwnerRecord | null;
        const legacyOwnedEntries = ownerRecord ? [] : await loadLegacyOwnedEntries(uid);

        const updates: Record<string, unknown> = {
            [`academy_profile_owner/${uid}`]: null,
        };

        let deletedProfiles = 0;

        if (ownerRecord) {
            const registryOwnerSnap = await db
                .ref(`handle_registry/${ownerRecord.handleKey}`)
                .once("value");
            addProfileRemovalUpdates({
                updates,
                handleKey: ownerRecord.handleKey,
                countryKey: ownerRecord.countryKey,
                registryOwnerUid: registryOwnerSnap.val() as string | null,
                uid,
            });
            deletedProfiles += 1;
        }

        for (const legacyEntry of legacyOwnedEntries) {
            const registryOwnerSnap = await db
                .ref(`handle_registry/${legacyEntry.handleKey}`)
                .once("value");
            addProfileRemovalUpdates({
                updates,
                handleKey: legacyEntry.handleKey,
                countryKey: legacyEntry.countryKey,
                registryOwnerUid: registryOwnerSnap.val() as string | null,
                uid,
            });
            deletedProfiles += 1;
        }

        await db.ref().update(updates);

        let authDeleted = false;
        if (deleteAnonymousAuth) {
            try {
                await admin.auth().deleteUser(uid);
                authDeleted = true;
            } catch (error) {
                console.error("deleteAcademyProfile auth delete failed", error);
            }
        }

        return {
            success: true,
            deletedProfiles,
            authDeleted,
        };
    },
);

export const applyAcademyHandleModeration = functions.database
    .ref("academy_handle_moderation/{handleKey}")
    .onWrite(async (change, context) => {
        const moderationRecord = parseActiveHandleModeration(change.after.val());
        if (!moderationRecord) {
            return null;
        }

        await removePublicAcademyProfile(context.params.handleKey as string);
        return null;
    });

export const hideModeratedAcademyLeaderboardEntry = functions.database
    .ref("academy_scoreboard/global/{handleKey}")
    .onWrite(async (change, context) => {
        if (!change.after.exists()) {
            return null;
        }

        const handleKey = context.params.handleKey as string;
        const moderationRecord = await loadActiveHandleModeration(
            handleKey,
        );
        if (!moderationRecord) {
            if (!hasInlineModerationFlag(change.after.val())) {
                return null;
            }
            await activateHandleModeration(handleKey);
        }

        await removePublicAcademyProfile(handleKey);
        return null;
    });

// ---------------------------------------------------------------------------
// getServerDate
//
// Returns the current UTC calendar date as { date: "YYYYMMDD" }.
// Called by the Flutter app on startup so that daily-challenge selection is
// based on server time rather than the device clock (prevents date-
// manipulation cheating). Auth is optional - anonymous calls are fine.
// ---------------------------------------------------------------------------

export const getServerDate = functions.https.onCall(async () => {
    const now = new Date();
    const yyyy = now.getUTCFullYear().toString().padStart(4, "0");
    const mm = (now.getUTCMonth() + 1).toString().padStart(2, "0");
    const dd = now.getUTCDate().toString().padStart(2, "0");
    return { date: `${yyyy}${mm}${dd}` };
});

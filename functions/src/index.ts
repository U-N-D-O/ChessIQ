import * as admin from "firebase-admin";
import * as functions from "firebase-functions/v1";

admin.initializeApp();

const db = admin.database();

// ---------------------------------------------------------------------------
// Constants
// ---------------------------------------------------------------------------

const HANDLE_MIN = 3;
const HANDLE_MAX = 20;
// Letters, digits, spaces, underscores, hyphens only
const HANDLE_RE = /^[a-zA-Z0-9_\- ]+$/;
const HANDLE_MODERATED_PREFIX = "ACADEMY_HANDLE_MODERATED:";

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

type AcademyHandleModerationRecord = {
    active: boolean;
    displayHandle?: string;
    playerMessage?: string;
    reasonCode?: string;
    updatedAt?: string;
};

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
    if (!entry) {
        return;
    }

    const country =
        typeof entry.country === "string" && entry.country.trim().length > 0
            ? entry.country
            : "Unknown";

    await db.ref().update({
        [`academy_scoreboard/global/${handleKey}`]: null,
        [`academy_scoreboard/by_country/${sanitizeCountryKey(country)}/${handleKey}`]: null,
    });
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
    const score =
        typeof data?.score === "number" ? Math.max(0, Math.floor(data.score)) : 0;
    const title =
        typeof data?.title === "string" ? data.title.substring(0, 40) : "";

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

    if (score < maxExistingScore) {
        throw new functions.https.HttpsError(
            "failed-precondition",
            "Score cannot decrease.",
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

// ---------------------------------------------------------------------------
// submitAcademyScore
//
// Called by the app whenever the player's score changes.  Enforces:
//   • Valid authenticated identity (uid required).
//   • Handle format rules.
//   • Score cannot decrease for an existing entry.
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

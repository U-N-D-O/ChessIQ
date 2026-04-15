import * as admin from "firebase-admin";
import * as functions from "firebase-functions";

admin.initializeApp();

const db = admin.database();

// ---------------------------------------------------------------------------
// Constants
// ---------------------------------------------------------------------------

const HANDLE_MIN = 3;
const HANDLE_MAX = 20;
// Letters, digits, spaces, underscores, hyphens only
const HANDLE_RE = /^[a-zA-Z0-9_\- ]+$/;

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
    async (data, context) => {
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

        const registryRef = db.ref(`handle_registry/${handleKey}`);
        const globalRef = db.ref(`academy_scoreboard/global/${handleKey}`);

        // ── Ownership check ────────────────────────────────────────────────────
        const registrySnap = await registryRef.once("value");
        const ownerUid: string | null = registrySnap.val();

        if (ownerUid !== null && ownerUid !== uid) {
            throw new functions.https.HttpsError(
                "already-exists",
                "This nickname is already taken by another player.",
            );
        }

        // ── Score must not decrease ────────────────────────────────────────────
        let oldCountry: string | null = null;
        if (ownerUid === uid) {
            const existingSnap = await globalRef.once("value");
            const existing = existingSnap.val() as Record<string, unknown> | null;
            if (existing) {
                const existingScore =
                    typeof existing.score === "number" ? existing.score : 0;
                if (score < existingScore) {
                    throw new functions.https.HttpsError(
                        "failed-precondition",
                        "Score cannot decrease.",
                    );
                }
                if (typeof existing.country === "string") {
                    oldCountry = existing.country;
                }
            }
        }

        const payload = {
            handle,
            country,
            score,
            title,
            uid,
            updatedAt: new Date().toISOString(),
        };

        // ── Atomic multi-path write ────────────────────────────────────────────
        const updates: Record<string, unknown> = {
            [`handle_registry/${handleKey}`]: uid,
            [`academy_scoreboard/global/${handleKey}`]: payload,
            [`academy_scoreboard/by_country/${countryKey}/${handleKey}`]: payload,
        };

        // Remove old country bucket if country changed.
        if (oldCountry && oldCountry !== country) {
            const oldKey = sanitizeCountryKey(oldCountry);
            updates[`academy_scoreboard/by_country/${oldKey}/${handleKey}`] = null;
        }

        await db.ref().update(updates);

        return { success: true };
    },
);

// ---------------------------------------------------------------------------
// checkHandleAvailability
//
// Returns { available: true } when the handle is unclaimed or owned by the
// calling uid.  Does NOT reveal which uid owns a taken handle.
// ---------------------------------------------------------------------------

export const checkHandleAvailability = functions.https.onCall(
    async (data, context) => {
        const handle = validateHandle(data?.handle);
        const callerUid = context.auth?.uid ?? null;

        const handleKey = sanitizeHandleKey(handle);
        const snap = await db.ref(`handle_registry/${handleKey}`).once("value");
        const ownerUid: string | null = snap.val();

        if (ownerUid === null) return { available: true };
        if (callerUid && ownerUid === callerUid) return { available: true };
        return { available: false };
    },
);

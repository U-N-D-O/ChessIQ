export type AvatarPurchaseReceipt = {
    amount: number;
    avatarId: string;
};

export type AvatarPurchaseReceipts = Record<string, AvatarPurchaseReceipt>;

export function normalizeAvatarPurchaseReceipts(value: unknown): AvatarPurchaseReceipts {
    if (!value || typeof value !== "object") return {};
    const receipts: AvatarPurchaseReceipts = {};
    for (const [key, raw] of Object.entries(value)) {
        if (!/^[A-Za-z0-9_-]{16,80}$/.test(key) || !raw || typeof raw !== "object") continue;
        const receipt = raw as AvatarPurchaseReceipt;
        if (Number.isInteger(receipt.amount) && receipt.amount >= 0 &&
            typeof receipt.avatarId === "string") {
            receipts[key] = { amount: receipt.amount, avatarId: receipt.avatarId };
        }
    }
    return receipts;
}

export function applyAvatarPurchase(
    coins: number,
    receipts: AvatarPurchaseReceipts,
    requestId: string,
    receipt: AvatarPurchaseReceipt,
) {
    const existing = receipts[requestId];
    if (existing) {
        if (existing.amount !== receipt.amount || existing.avatarId !== receipt.avatarId) {
            throw new Error("Purchase receipt does not match the original roll.");
        }
        return { success: true, coins, receipts };
    }
    if (coins < receipt.amount) return { success: false, coins, receipts };
    return {
        success: true,
        coins: coins - receipt.amount,
        receipts: { ...receipts, [requestId]: receipt },
    };
}

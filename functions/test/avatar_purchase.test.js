const assert = require('node:assert/strict');
const { test, after } = require('node:test');
const { applyAvatarPurchase, normalizeAvatarPurchaseReceipts } = require('../lib/avatar_purchase');
const endpoints = require('../lib/index');
const admin = require('firebase-admin');
const database = admin.database();
const originalRef = database.ref;

after(async () => {
    database.ref = originalRef;
    await Promise.all(admin.apps.map(app => app.delete()));
});

test('retrying a paid roll does not debit twice; altered receipts are rejected', () => {
    const receipt = { amount: 200, avatarId: 'normal-celicianmara' };
    const paid = applyAvatarPurchase(500, {}, 'purchase_12345678', receipt);
    assert.equal(paid.coins, 300);
    const retry = applyAvatarPurchase(paid.coins,
        normalizeAvatarPurchaseReceipts(paid.receipts), 'purchase_12345678', receipt);
    assert.equal(retry.success, true);
    assert.equal(retry.coins, 300);
    assert.equal(Object.keys(retry.receipts).length, 1);
    assert.throws(() => applyAvatarPurchase(retry.coins, retry.receipts,
        'purchase_12345678', { ...receipt, amount: 100 }));
});

test('an unaffordable roll does not create a receipt', () => {
    const result = applyAvatarPurchase(120, {}, 'purchase_12345678',
        { amount: 200, avatarId: 'normal-celicianmara' });
    assert.equal(result.success, false);
    assert.equal(result.coins, 120);
    assert.deepEqual(result.receipts, {});
});

// Exercise the real callable handlers, replacing only database transport.
// RTDB can call the transaction callback with null before its server value.
function mockEconomy(initialCoins) {
    let stored = { coins: initialCoins };
    database.ref = path => {
        assert.equal(path, 'economy_profiles/test-player');
        return {
            get: async () => ({ val: () => structuredClone(stored) }),
            transaction: async update => {
                const speculative = update(null);
                if (speculative === undefined) {
                    return { committed: false, snapshot: { val: () => null } };
                }
                const committed = update(structuredClone(stored));
                if (committed !== undefined) stored = committed;
                return {
                    committed: committed !== undefined,
                    snapshot: { val: () => structuredClone(stored) },
                };
            },
        };
    };
    return () => stored;
}

test('cold-cache transactions read real balances and preserve roll receipts', async () => {
    const state = mockEconomy(800);
    const context = { auth: { uid: 'test-player' } };
    const input = { amount: 200, requestId: 'purchase_12345678', avatarId: 'normal-celicianmara' };
    const first = await endpoints.purchaseAvatarRoll.run(input, context);
    assert.equal(first.success, true);
    assert.equal(first.state.coins, 600);
    const otherSpend = await endpoints.spendEconomyCoins.run({ amount: 250 }, context);
    assert.equal(otherSpend.success, true);
    assert.equal(otherSpend.state.coins, 350);
    const retry = await endpoints.purchaseAvatarRoll.run(input, context);
    assert.equal(retry.success, true);
    assert.equal(retry.requestId, input.requestId);
    assert.equal(retry.state.coins, 350);
    assert.equal(Object.keys(state().avatarPurchaseReceipts).length, 1);
});

test('purchase endpoint requires authentication and validates its request', async () => {
    await assert.rejects(endpoints.purchaseAvatarRoll.run({}, {}),
        error => error.code === 'unauthenticated');
    await assert.rejects(endpoints.purchaseAvatarRoll.run({ amount: -1 },
        { auth: { uid: 'test-player' } }), error => error.code === 'invalid-argument');
});

function mockMatch({ conflict = false } = {}) {
    const now = Date.now();
    let stored = {
        matchId: 'test-match-123', inviteCode: 'ABCDEF', status: 'active',
        hostUid: 'white-player', guestUid: 'black-player',
        whiteUid: 'white-player', blackUid: 'black-player',
        whiteAvatarId: 'white-avatar', blackAvatarId: 'black-avatar',
        timeControl: { initialSeconds: 0, incrementSeconds: 0 },
        clocks: { whiteMsRemaining: 0, blackMsRemaining: 0 },
        nextPly: 0, whiteToMove: true, moves: {},
        createdAtMs: now, updatedAtMs: now, startedAtMs: now,
        expiresAtMs: now + 86400000,
    };
    database.ref = path => {
        if (!path) return { update: async () => {} };
        if (path.startsWith('push_device_tokens/')) {
            return { once: async () => ({ exists: () => false }) };
        }
        assert.equal(path, 'friend_matches/test-match-123');
        return {
            once: async () => ({ val: () => structuredClone(stored) }),
            transaction: async update => {
                update(null);
                if (conflict) stored = { ...stored, nextPly: 1, whiteToMove: false };
                const next = update(structuredClone(stored));
                if (next !== undefined) stored = next;
                return {
                    committed: next !== undefined,
                    snapshot: { val: () => structuredClone(stored) },
                };
            },
        };
    };
    return () => stored;
}

test('both seats exchange moves and avatar changes without losing the other avatar', async () => {
    const state = mockMatch();
    const matchId = 'test-match-123';
    const white = { auth: { uid: 'white-player' } };
    const black = { auth: { uid: 'black-player' } };
    await endpoints.refreshFriendMatchState.run({ matchId, avatarId: 'new-white-avatar' }, white);
    await endpoints.refreshFriendMatchState.run({ matchId, avatarId: 'new-black-avatar' }, black);
    const first = await endpoints.submitFriendMatchMove.run({ matchId, moveUci: 'e2e4', expectedPly: 0 }, white);
    const second = await endpoints.submitFriendMatchMove.run({ matchId, moveUci: 'e7e5', expectedPly: 1 }, black);
    assert.equal(first.acceptedMove, true);
    assert.equal(second.acceptedMove, true);
    assert.equal(second.snapshot.nextPly, 2);
    assert.equal(second.snapshot.whiteAvatarId, 'new-white-avatar');
    assert.equal(second.snapshot.blackAvatarId, 'new-black-avatar');
    assert.equal(state().moves['0002'].uci, 'e7e5');
    assert.equal(second.snapshot.fen.split(' ')[1], 'w');
});

test('a transaction conflict does not report a speculative move as accepted', async () => {
    mockMatch({ conflict: true });
    const result = await endpoints.submitFriendMatchMove.run({
        matchId: 'test-match-123', moveUci: 'e2e4', expectedPly: 0,
    }, { auth: { uid: 'white-player' } });
    assert.equal(result.acceptedMove, false);
    assert.equal(result.reason, 'stale-client');
});

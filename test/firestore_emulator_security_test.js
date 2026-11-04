/**
 * Firestore Security Rules Emulator Test Suite
 * Project: spentee-41ec7
 * 
 * Verifies all 8 security requirements against the live Firebase Firestore Emulator
 * evaluating the actual 'firestore.rules' file.
 */

const http = require('http');

const PROJECT_ID = 'spentee-41ec7';
const HOST_PORT = (process.env.FIRESTORE_EMULATOR_HOST || '127.0.0.1:8080').split(':');
const HOSTNAME = HOST_PORT[0];
const PORT = parseInt(HOST_PORT[1], 10);

function createMockJwt(uid) {
  const header = Buffer.from(JSON.stringify({ alg: "none", typ: "JWT" })).toString('base64url');
  const payload = Buffer.from(JSON.stringify({
    user_id: uid,
    sub: uid,
    aud: PROJECT_ID,
    iss: `https://securetoken.google.com/${PROJECT_ID}`
  })).toString('base64url');
  return `${header}.${payload}.`;
}

function firestoreRequest({ method, path, token, body }) {
  return new Promise((resolve, reject) => {
    const data = body ? JSON.stringify(body) : null;
    const headers = { 'Content-Type': 'application/json' };
    if (token) headers['Authorization'] = `Bearer ${token}`;
    if (data) headers['Content-Length'] = Buffer.byteLength(data);

    const req = http.request({
      hostname: HOSTNAME,
      port: PORT,
      path: `/v1/projects/${PROJECT_ID}/databases/(default)/documents/${path}`,
      method,
      headers
    }, (res) => {
      let resBody = '';
      res.on('data', chunk => resBody += chunk);
      res.on('end', () => {
        let parsed = null;
        try { parsed = JSON.parse(resBody); } catch (_) {}
        resolve({ statusCode: res.statusCode, body: parsed || resBody });
      });
    });

    req.on('error', reject);
    if (data) req.write(data);
    req.end();
  });
}

const tests = [];
function addTest(name, fn) {
  tests.push({ name, fn });
}

const OWNER_UID = 'user_spentee_owner';
const ATTACKER_UID = 'user_unauthorized_attacker';
const OWNER_TOKEN = createMockJwt(OWNER_UID);
const ATTACKER_TOKEN = createMockJwt(ATTACKER_UID);

// Test 1: Owner can create valid transactions
addTest('1. Owner can create valid transactions', async () => {
  const res = await firestoreRequest({
    method: 'PATCH',
    path: `users/${OWNER_UID}/transactions/tx_valid_01`,
    token: OWNER_TOKEN,
    body: {
      fields: {
        title: { stringValue: 'Grocery shopping at supermarket' },
        amount: { doubleValue: 74.50 },
        category: { stringValue: 'Food & Dining' },
        type: { stringValue: 'expense' },
        createdAt: { stringValue: '2026-11-04T12:00:00Z' }
      }
    }
  });
  if (res.statusCode !== 200) {
    throw new Error(`Expected 200, got ${res.statusCode}: ${JSON.stringify(res.body)}`);
  }
});

// Test 2: Owner cannot create transactions with negative amounts
addTest('2. Owner cannot create transactions with negative amounts', async () => {
  const res = await firestoreRequest({
    method: 'PATCH',
    path: `users/${OWNER_UID}/transactions/tx_negative_02`,
    token: OWNER_TOKEN,
    body: {
      fields: {
        title: { stringValue: 'Invalid Negative Transaction' },
        amount: { doubleValue: -25.00 }
      }
    }
  });
  if (res.statusCode !== 403) {
    throw new Error(`Expected 403 PERMISSION_DENIED, got ${res.statusCode}: ${JSON.stringify(res.body)}`);
  }
});

// Test 3: Owner cannot write invalid field types or lengths > 100
addTest('3. Owner cannot write invalid field types or lengths (>100 chars)', async () => {
  // Title exceeds 100 characters limit
  const longTitle = 'A'.repeat(105);
  const res = await firestoreRequest({
    method: 'PATCH',
    path: `users/${OWNER_UID}/transactions/tx_invalid_03`,
    token: OWNER_TOKEN,
    body: {
      fields: {
        title: { stringValue: longTitle },
        amount: { doubleValue: 10.0 }
      }
    }
  });
  if (res.statusCode !== 403) {
    throw new Error(`Expected 403 PERMISSION_DENIED for >100 char title, got ${res.statusCode}: ${JSON.stringify(res.body)}`);
  }
});

// Test 4: Another authenticated user cannot access the first user's data
addTest('4. Another authenticated user cannot access the first user\'s data', async () => {
  // Attacker tries to read owner's transaction
  const readRes = await firestoreRequest({
    method: 'GET',
    path: `users/${OWNER_UID}/transactions/tx_valid_01`,
    token: ATTACKER_TOKEN
  });
  if (readRes.statusCode !== 403) {
    throw new Error(`Expected 403 PERMISSION_DENIED on read, got ${readRes.statusCode}`);
  }

  // Attacker tries to overwrite owner's transaction
  const writeRes = await firestoreRequest({
    method: 'PATCH',
    path: `users/${OWNER_UID}/transactions/tx_valid_01`,
    token: ATTACKER_TOKEN,
    body: {
      fields: {
        title: { stringValue: 'Hacked by Attacker' },
        amount: { doubleValue: 1.00 }
      }
    }
  });
  if (writeRes.statusCode !== 403) {
    throw new Error(`Expected 403 PERMISSION_DENIED on write, got ${writeRes.statusCode}`);
  }
});

// Test 5: Unauthenticated users cannot access private data
addTest('5. Unauthenticated users cannot access private data', async () => {
  // Unauthenticated read attempt
  const readRes = await firestoreRequest({
    method: 'GET',
    path: `users/${OWNER_UID}/transactions/tx_valid_01`,
    token: null
  });
  if (readRes.statusCode !== 403) {
    throw new Error(`Expected 403 PERMISSION_DENIED on unauth read, got ${readRes.statusCode}`);
  }

  // Unauthenticated write attempt
  const writeRes = await firestoreRequest({
    method: 'PATCH',
    path: `users/${OWNER_UID}/transactions/tx_unauth_05`,
    token: null,
    body: {
      fields: {
        title: { stringValue: 'Unauthenticated write' },
        amount: { doubleValue: 20.00 }
      }
    }
  });
  if (writeRes.statusCode !== 403) {
    throw new Error(`Expected 403 PERMISSION_DENIED on unauth write, got ${writeRes.statusCode}`);
  }
});

// Test 6: Valid updates and soft deletions work
addTest('6. Valid updates and soft deletions work', async () => {
  // Soft deletion: update document with deletedAt timestamp and isDeleted flag
  const updateRes = await firestoreRequest({
    method: 'PATCH',
    path: `users/${OWNER_UID}/transactions/tx_valid_01`,
    token: OWNER_TOKEN,
    body: {
      fields: {
        title: { stringValue: 'Grocery shopping at supermarket' },
        amount: { doubleValue: 74.50 },
        isDeleted: { booleanValue: true },
        deletedAt: { stringValue: '2026-11-04T12:30:00Z' }
      }
    }
  });
  if (updateRes.statusCode !== 200) {
    throw new Error(`Expected 200 for soft delete update, got ${updateRes.statusCode}`);
  }

  // Owner reads the updated transaction document
  const readRes = await firestoreRequest({
    method: 'GET',
    path: `users/${OWNER_UID}/transactions/tx_valid_01`,
    token: OWNER_TOKEN
  });
  if (readRes.statusCode !== 200) {
    throw new Error(`Expected 200 for owner read, got ${readRes.statusCode}`);
  }
});

// Test 7: Account deletion remains permitted (subcollections and user root doc)
addTest('7. Account deletion remains permitted', async () => {
  // 1. Setup user root document first
  const createRootRes = await firestoreRequest({
    method: 'PATCH',
    path: `users/${OWNER_UID}`,
    token: OWNER_TOKEN,
    body: {
      fields: {
        email: { stringValue: 'owner@spentee.app' },
        displayName: { stringValue: 'Spentee User' }
      }
    }
  });
  if (createRootRes.statusCode !== 200) {
    throw new Error(`Failed to create root doc: ${createRootRes.statusCode}`);
  }

  // 2. Owner hard deletes subcollection transaction document
  const deleteTxRes = await firestoreRequest({
    method: 'DELETE',
    path: `users/${OWNER_UID}/transactions/tx_valid_01`,
    token: OWNER_TOKEN
  });
  if (deleteTxRes.statusCode !== 200) {
    throw new Error(`Expected 200 on deleting subcollection doc, got ${deleteTxRes.statusCode}`);
  }

  // 3. Owner hard deletes root user document
  const deleteRootRes = await firestoreRequest({
    method: 'DELETE',
    path: `users/${OWNER_UID}`,
    token: OWNER_TOKEN
  });
  if (deleteRootRes.statusCode !== 200) {
    throw new Error(`Expected 200 on deleting user root doc, got ${deleteRootRes.statusCode}`);
  }
});

// Test 8: Unknown subcollections are denied (verifying recursive wildcard was removed)
addTest('8. Unknown subcollections are denied', async () => {
  // Attempt to write to arbitrary/unknown subcollection under users/{userId}
  const writeRes = await firestoreRequest({
    method: 'PATCH',
    path: `users/${OWNER_UID}/arbitrary_unapproved_collection/doc_01`,
    token: OWNER_TOKEN,
    body: {
      fields: {
        someField: { stringValue: 'malicious or untracked payload' }
      }
    }
  });
  if (writeRes.statusCode !== 403) {
    throw new Error(`Expected 403 PERMISSION_DENIED on unknown subcollection write, got ${writeRes.statusCode}`);
  }

  // Attempt to read from arbitrary subcollection
  const readRes = await firestoreRequest({
    method: 'GET',
    path: `users/${OWNER_UID}/arbitrary_unapproved_collection/doc_01`,
    token: OWNER_TOKEN
  });
  if (readRes.statusCode !== 403) {
    throw new Error(`Expected 403 PERMISSION_DENIED on unknown subcollection read, got ${readRes.statusCode}`);
  }
});

async function main() {
  console.log('===============================================================');
  console.log(' FIRESTORE SECURITY RULES EMULATOR SUITE');
  console.log(` Project: ${PROJECT_ID}`);
  console.log(` Target Endpoint: http://${HOSTNAME}:${PORT}`);
  console.log(' Rules File: firestore.rules (loaded by cloud-firestore-emulator)');
  console.log('===============================================================\n');

  let passed = 0;
  let failed = 0;

  for (const t of tests) {
    try {
      await t.fn();
      console.log(` [PASS] ${t.name}`);
      passed++;
    } catch (err) {
      console.error(` [FAIL] ${t.name}`);
      console.error(`        Error: ${err.message}`);
      failed++;
    }
  }

  console.log('\n===============================================================');
  console.log(` SUMMARY: Total: ${tests.length} | Passed: ${passed} | Failed: ${failed}`);
  console.log('===============================================================');

  if (failed > 0) {
    process.exit(1);
  }
}

main().catch((err) => {
  console.error('Fatal test error:', err);
  process.exit(1);
});


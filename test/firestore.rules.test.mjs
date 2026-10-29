import assert from 'node:assert/strict';
import { readFileSync } from 'node:fs';
import { fileURLToPath } from 'node:url';
import path from 'node:path';
import test from 'node:test';
import {
  assertFails,
  assertSucceeds,
  initializeTestEnvironment,
} from '@firebase/rules-unit-testing';
import {
  collection,
  deleteDoc,
  doc,
  getDoc,
  getDocs,
  serverTimestamp,
  setDoc,
  Timestamp,
  updateDoc,
  writeBatch,
} from 'firebase/firestore';

const here = path.dirname(fileURLToPath(import.meta.url));
const root = path.resolve(here, '..');
const projectId = 'demo-cms-rules';
let env;

const adminUser = {
  name: 'Branch Admin',
  email: 'admin@example.test',
  phone: '03001234567',
  isAdmin: true,
  permissions: { view: true, add: true, edit: true, delete: true },
  active: true,
  createdBy: 'admin',
  createdAt: Timestamp.fromDate(new Date('2025-01-01T00:00:00Z')),
};

function staffData(uid, permissions = {}) {
  return {
    name: 'Branch Staff',
    email: `${uid}@example.test`,
    phone: '03007654321',
    isAdmin: false,
    permissions: { view: false, add: false, edit: false, delete: false, ...permissions },
    active: true,
    createdBy: 'admin',
    createdAt: Timestamp.fromDate(new Date('2025-01-01T00:00:00Z')),
  };
}

function activity(action, targetId, uid, name, details = null) {
  return {
    action,
    targetId,
    performedBy: uid,
    performedByName: name,
    timestamp: serverTimestamp(),
    details,
  };
}

function customerData(actorUid, overrides = {}) {
  return {
    accountNumber: '12345678901234',
    name: 'Test Customer',
    accountTitle: 'Test Trading',
    phone: '03001112223',
    cnic: '3520212345671',
    accountType: 'Current',
    ibnNo: 'AB12CD34EF56GH78IJ90KL12',
    status: 'Active',
    dateOpened: null,
    address: null,
    notes: null,
    searchKeywords: ['test'],
    accountTitleSearchWords: ['test', 'trading'],
    phoneLast4: '2223',
    cnicLast4: '5671',
    accountNumberLast4: '1234',
    createdBy: actorUid,
    createdAt: serverTimestamp(),
    updatedBy: actorUid,
    updatedAt: serverTimestamp(),
    lastActivityId: 'create-event',
    deleteActivityId: 'delete-event',
    ...overrides,
  };
}

async function seed(pathName, value) {
  await env.withSecurityRulesDisabled(async (context) => {
    await setDoc(doc(context.firestore(), pathName), value);
  });
}

async function seedAdmin() {
  await seed('users/admin', adminUser);
}

async function seedStaff(uid, permissions = {}) {
  await seed(`users/${uid}`, staffData(uid, permissions));
}

test.before(async () => {
  env = await initializeTestEnvironment({
    projectId,
    firestore: {
      host: '127.0.0.1',
      port: 8080,
      rules: readFileSync(path.join(root, 'firestore.rules'), 'utf8'),
    },
  });
});

test.beforeEach(async () => {
  await env.clearFirestore();
});

test.after(async () => {
  await env?.cleanup();
});

test('bootstrap flag cannot be claimed without creating the caller Admin doc atomically', async () => {
  await seed('system/bootstrap', { adminExists: false });
  const attacker = env.authenticatedContext('attacker', { email: 'attacker@example.test' }).firestore();
  await assertFails(setDoc(doc(attacker, 'system/bootstrap'), { adminExists: true }));
});

test('first Admin can create its user doc and close bootstrap in one batch', async () => {
  await seed('system/bootstrap', { adminExists: false });
  const db = env.authenticatedContext('first-admin', { email: 'admin@example.test' }).firestore();
  const batch = writeBatch(db);
  batch.set(doc(db, 'users/first-admin'), {
    ...adminUser,
    createdBy: 'first-admin',
  });
  batch.set(doc(db, 'phoneIndex/03001234567'), { email: 'admin@example.test', uid: 'first-admin' });
  batch.set(doc(db, 'system/bootstrap'), { adminExists: true });
  await assertSucceeds(batch.commit());
});

test('phone index blocks collection listing while exact lookup remains available for phone login', async () => {
  await seed('phoneIndex/03001234567', { email: 'admin@example.test', uid: 'admin' });
  const db = env.unauthenticatedContext().firestore();
  await assertFails(getDocs(collection(db, 'phoneIndex')));
  const result = await assertSucceeds(getDoc(doc(db, 'phoneIndex/03001234567')));
  assert.equal(result.data().email, 'admin@example.test');
});

test('customer creation and customer_created event must commit together', async () => {
  await seedAdmin();
  await seedStaff('adder', { add: true });
  const db = env.authenticatedContext('adder').firestore();
  const customer = customerData('adder', { lastActivityId: 'event-1' });
  const batch = writeBatch(db);
  batch.set(doc(db, 'customers/12345678901234'), customer);
  batch.set(doc(db, 'activityLog/event-1'), activity('customer_created', '12345678901234', 'adder', 'Branch Staff'));
  await assertSucceeds(batch.commit());
});

test('customer create without a matching event is denied', async () => {
  await seedAdmin();
  await seedStaff('adder', { add: true });
  const db = env.authenticatedContext('adder').firestore();
  await assertFails(setDoc(doc(db, 'customers/12345678901234'), customerData('adder')));
});

test('customer update and customer_updated event must commit together', async () => {
  await seedAdmin();
  await seedStaff('editor', { edit: true });
  await seed('customers/12345678901234', customerData('adder', {
    createdAt: Timestamp.fromDate(new Date('2025-01-01T00:00:00Z')),
    updatedAt: Timestamp.fromDate(new Date('2025-01-01T00:00:00Z')),
  }));
  const db = env.authenticatedContext('editor').firestore();
  const batch = writeBatch(db);
  batch.update(doc(db, 'customers/12345678901234'), {
    name: 'Updated Customer',
    updatedBy: 'editor',
    updatedAt: serverTimestamp(),
    lastActivityId: 'event-update',
  });
  batch.set(doc(db, 'activityLog/event-update'), activity('customer_updated', '12345678901234', 'editor', 'Branch Staff'));
  await assertSucceeds(batch.commit());
});

test('customer update without a matching event is denied', async () => {
  await seedAdmin();
  await seedStaff('editor', { edit: true });
  await seed('customers/12345678901234', customerData('adder', {
    createdAt: Timestamp.fromDate(new Date('2025-01-01T00:00:00Z')),
    updatedAt: Timestamp.fromDate(new Date('2025-01-01T00:00:00Z')),
  }));
  const db = env.authenticatedContext('editor').firestore();
  await assertFails(updateDoc(doc(db, 'customers/12345678901234'), {
    name: 'Unlogged Update',
    updatedBy: 'editor',
    updatedAt: serverTimestamp(),
    lastActivityId: 'missing-event',
  }));
});

test('customer deletion and customer_deleted event must commit together', async () => {
  await seedAdmin();
  await seedStaff('deleter', { delete: true });
  await seed('customers/12345678901234', customerData('adder', {
    createdAt: Timestamp.fromDate(new Date('2025-01-01T00:00:00Z')),
    updatedAt: Timestamp.fromDate(new Date('2025-01-01T00:00:00Z')),
    deleteActivityId: 'delete-event',
  }));
  const db = env.authenticatedContext('deleter').firestore();
  const batch = writeBatch(db);
  batch.delete(doc(db, 'customers/12345678901234'));
  batch.set(doc(db, 'activityLog/delete-event'), activity('customer_deleted', '12345678901234', 'deleter', 'Branch Staff'));
  await assertSucceeds(batch.commit());
});

test('staff creation and staff_created event must commit together', async () => {
  await seedAdmin();
  const db = env.authenticatedContext('admin', { email: adminUser.email }).firestore();
  const batch = writeBatch(db);
  batch.set(doc(db, 'users/new-staff'), {
    ...staffData('new-staff'),
    lastActivityId: 'staff-create-event',
  });
  batch.set(doc(db, 'phoneIndex/03007654321'), { email: 'new-staff@example.test', uid: 'new-staff' });
  batch.set(doc(db, 'activityLog/staff-create-event'), activity('staff_created', 'new-staff', 'admin', adminUser.name));
  await assertSucceeds(batch.commit());
});

test('staff creation without a matching event is denied', async () => {
  await seedAdmin();
  const db = env.authenticatedContext('admin', { email: adminUser.email }).firestore();
  await assertFails(setDoc(doc(db, 'users/new-staff'), staffData('new-staff')));
});

test('staff permission change and event must commit together', async () => {
  await seedAdmin();
  await seedStaff('target-staff');
  const db = env.authenticatedContext('admin', { email: adminUser.email }).firestore();
  const batch = writeBatch(db);
  batch.update(doc(db, 'users/target-staff'), {
    permissions: { view: true, add: false, edit: false, delete: false },
    lastActivityId: 'staff-permission-event',
  });
  batch.set(doc(db, 'activityLog/staff-permission-event'), activity('staff_permissions_changed', 'target-staff', 'admin', adminUser.name));
  await assertSucceeds(batch.commit());
});

test('staff active-state change and staff_removed event must commit together', async () => {
  await seedAdmin();
  await seedStaff('target-staff');
  const db = env.authenticatedContext('admin', { email: adminUser.email }).firestore();
  const batch = writeBatch(db);
  batch.update(doc(db, 'users/target-staff'), {
    active: false,
    lastActivityId: 'staff-active-event',
  });
  batch.set(doc(db, 'activityLog/staff-active-event'), activity('staff_removed', 'target-staff', 'admin', adminUser.name, 'deactivated'));
  await assertSucceeds(batch.commit());
});

test('staff permission changes without a matching event are denied', async () => {
  await seedAdmin();
  await seedStaff('target-staff');
  const db = env.authenticatedContext('admin', { email: adminUser.email }).firestore();
  await assertFails(updateDoc(doc(db, 'users/target-staff'), {
    permissions: { view: true, add: false, edit: false, delete: false },
    lastActivityId: 'missing-event',
  }));
});

test('inactive staff cannot write customer data or activity events', async () => {
  await seedAdmin();
  await seedStaff('inactive-adder', { add: true });
  await seed('users/inactive-adder', { ...staffData('inactive-adder', { add: true }), active: false });
  const db = env.authenticatedContext('inactive-adder').firestore();
  const batch = writeBatch(db);
  batch.set(doc(db, 'customers/12345678901234'), customerData('inactive-adder', { lastActivityId: 'inactive-event' }));
  batch.set(doc(db, 'activityLog/inactive-event'), activity('customer_created', '12345678901234', 'inactive-adder', 'Branch Staff'));
  await assertFails(batch.commit());
});

test('activity log records cannot be updated or deleted', async () => {
  await seedAdmin();
  await seed('activityLog/old-event', activity('export', 'pdf:0_records', 'admin', adminUser.name));
  const db = env.authenticatedContext('admin', { email: adminUser.email }).firestore();
  await assertFails(updateDoc(doc(db, 'activityLog/old-event'), { details: 'changed' }));
  await assertFails(deleteDoc(doc(db, 'activityLog/old-event')));
});

test('customer deletion without a matching event is denied', async () => {
  await seedAdmin();
  await seedStaff('deleter', { delete: true });
  await seed('customers/12345678901234', customerData('adder', {
    createdAt: Timestamp.fromDate(new Date('2025-01-01T00:00:00Z')),
    updatedAt: Timestamp.fromDate(new Date('2025-01-01T00:00:00Z')),
    deleteActivityId: 'delete-event',
  }));
  const db = env.authenticatedContext('deleter').firestore();
  await assertFails(deleteDoc(doc(db, 'customers/12345678901234')));
});

test('staff active-state changes without a matching event are denied', async () => {
  await seedAdmin();
  await seedStaff('target-staff');
  const db = env.authenticatedContext('admin', { email: adminUser.email }).firestore();
  await assertFails(updateDoc(doc(db, 'users/target-staff'), {
    active: false,
    lastActivityId: 'missing-event',
  }));
});

test('customer identifier formats are validated by rules', async () => {
  await seedAdmin();
  await seedStaff('adder', { add: true });
  const db = env.authenticatedContext('adder').firestore();
  const batch = writeBatch(db);
  batch.set(doc(db, 'customers/12345678901234'), customerData('adder', {
    phone: '0300-1112223',
    lastActivityId: 'bad-customer-event',
  }));
  batch.set(doc(db, 'activityLog/bad-customer-event'), activity('customer_created', '12345678901234', 'adder', 'Branch Staff'));
  await assertFails(batch.commit());
});

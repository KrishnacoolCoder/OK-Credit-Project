const {onCall, HttpsError} = require("firebase-functions/v2/https");
const admin = require("firebase-admin");

admin.initializeApp();
const db = admin.firestore();

/**
 * Requires the caller to be signed in and to hold the "admin" custom claim.
 * Returns their shopId (which, for an admin, is their own uid).
 */
function requireAdmin(request) {
  const claims = request.auth && request.auth.token;
  if (!claims || claims.role !== "admin") {
    throw new HttpsError("permission-denied", "Only the shop owner can do this.");
  }
  return claims.shopId;
}

/**
 * Called once by a newly phone-verified owner, right after they finish the
 * shop-setup form. Makes them the admin of their own shop (shopId = their
 * own uid) and writes the shop's profile doc. Idempotent: if they already
 * have a shopId claim, this just returns it unchanged.
 */
exports.claimShop = onCall(async (request) => {
  const uid = request.auth && request.auth.uid;
  if (!uid) throw new HttpsError("unauthenticated", "Sign in first.");

  const user = await admin.auth().getUser(uid);
  const existing = user.customClaims || {};
  if (existing.shopId) {
    return {shopId: existing.shopId, role: existing.role};
  }

  const name = ((request.data && request.data.name) || "Owner").toString().trim().slice(0, 80);

  await admin.auth().setCustomUserClaims(uid, {shopId: uid, role: "admin", canEdit: true});
  await db.collection("shops").doc(uid).set({
    profile: {ownerName: name},
    ownerUid: uid,
    createdAt: admin.firestore.FieldValue.serverTimestamp(),
  }, {merge: true});

  return {shopId: uid, role: "admin"};
});

/**
 * Creates a real, separate Firebase Auth account for a staff member. This has
 * to run server-side with the Admin SDK: the owner's own device can't create
 * a second signed-in account on the client SDK without logging itself out.
 * Stamps the new account with custom claims tying it to the owner's shop.
 */
exports.createStaffAccount = onCall(async (request) => {
  const shopId = requireAdmin(request);
  const data = request.data || {};
  const name = (data.name || "").toString().trim();
  const email = (data.email || "").toString().trim();
  const password = (data.password || "").toString();
  const canEdit = data.canEdit !== false;

  if (!name || !email || password.length < 6) {
    throw new HttpsError(
        "invalid-argument",
        "Name, email, and a password of at least 6 characters are required.",
    );
  }

  let newUser;
  try {
    newUser = await admin.auth().createUser({email, password, displayName: name});
  } catch (e) {
    if (e.code === "auth/email-already-exists") {
      throw new HttpsError("already-exists", "That email is already registered.");
    }
    throw new HttpsError("internal", e.message || "Could not create the account.");
  }

  await admin.auth().setCustomUserClaims(newUser.uid, {shopId, role: "staff", canEdit});
  await db.collection("shops").doc(shopId).collection("staff").doc(newUser.uid).set({
    name,
    email,
    canEdit,
    createdAt: admin.firestore.FieldValue.serverTimestamp(),
  });

  return {uid: newUser.uid};
});

/**
 * Lets an admin rename a staff member or flip their edit access.
 */
exports.updateStaffAccess = onCall(async (request) => {
  const shopId = requireAdmin(request);
  const data = request.data || {};
  const uid = (data.uid || "").toString();
  if (!uid) throw new HttpsError("invalid-argument", "Missing staff uid.");

  const staffRef = db.collection("shops").doc(shopId).collection("staff").doc(uid);
  const staffDoc = await staffRef.get();
  if (!staffDoc.exists) {
    throw new HttpsError("not-found", "That staff member isn't part of your shop.");
  }

  const update = {};
  if (data.name) update.name = data.name.toString().trim();
  if (data.canEdit !== undefined) {
    update.canEdit = !!data.canEdit;
    await admin.auth().setCustomUserClaims(uid, {shopId, role: "staff", canEdit: !!data.canEdit});
  }
  if (Object.keys(update).length) await staffRef.update(update);

  return {ok: true};
});

/**
 * Removes a staff member entirely: deletes their Firebase Auth account (so
 * they can no longer sign in at all, from any device) and their profile doc.
 */
exports.removeStaffAccount = onCall(async (request) => {
  const shopId = requireAdmin(request);
  const data = request.data || {};
  const uid = (data.uid || "").toString();
  if (!uid) throw new HttpsError("invalid-argument", "Missing staff uid.");

  const staffRef = db.collection("shops").doc(shopId).collection("staff").doc(uid);
  const staffDoc = await staffRef.get();
  if (!staffDoc.exists) {
    throw new HttpsError("not-found", "That staff member isn't part of your shop.");
  }

  await admin.auth().deleteUser(uid).catch(() => {});
  await staffRef.delete();

  return {ok: true};
});

/**
 * Lets an admin reset a staff member's password directly (they don't need
 * the old one — this mirrors what the local, offline version used to do).
 */
exports.resetStaffPassword = onCall(async (request) => {
  const shopId = requireAdmin(request);
  const data = request.data || {};
  const uid = (data.uid || "").toString();
  const password = (data.password || "").toString();

  if (!uid || password.length < 6) {
    throw new HttpsError("invalid-argument", "A staff uid and a password of at least 6 characters are required.");
  }

  const staffDoc = await db.collection("shops").doc(shopId).collection("staff").doc(uid).get();
  if (!staffDoc.exists) {
    throw new HttpsError("not-found", "That staff member isn't part of your shop.");
  }

  await admin.auth().updateUser(uid, {password});
  return {ok: true};
});

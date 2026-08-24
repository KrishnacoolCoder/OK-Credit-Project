import 'dart:async';
import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart' as fb;
import 'package:firebase_core/firebase_core.dart' as firebase_core;
import 'package:google_sign_in/google_sign_in.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../domain/entities/app_user.dart';

/// Thrown when an invite code doesn't exist, was already used, or belongs to
/// a different shop than expected.
class InvalidInviteException implements Exception {
  final String message;
  InvalidInviteException(this.message);
  @override
  String toString() => message;
}

class AuthService {
  static const _everClaimedKey = 'sangam_shop_claimed_v2';
  static const _codeChars = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789';

  fb.FirebaseAuth get _auth => fb.FirebaseAuth.instance;
  FirebaseFirestore get _db => FirebaseFirestore.instance;

  // ── Google Sign-In ──────────────────────────────────────

  /// Initiates the Google Sign-In flow and authenticates with Firebase.
  /// Returns the [AppUser] if sign-in succeeds and the user already belongs to a shop.
  /// Returns null for brand-new users who need to set up a shop.
  Future<AppUser?> signInWithGoogle() async {
    if (firebase_core.Firebase.apps.isEmpty) {
      // Offline mode — simulate sign in
      final p = await SharedPreferences.getInstance();
      await p.setBool(_everClaimedKey, true);
      await p.setString('offline_email', 'offline@example.com');
      await p.setString('offline_ownerName', 'Offline User');
      return getSessionUser();
    }

    // Trigger the authentication flow
    final GoogleSignInAccount? googleUser = await GoogleSignIn().signIn();

    if (googleUser == null) {
      throw Exception('Sign in aborted by user');
    }

    // Obtain the auth details from the request
    final GoogleSignInAuthentication googleAuth = await googleUser.authentication;

    // Create a new credential
    final fb.OAuthCredential credential = fb.GoogleAuthProvider.credential(
      accessToken: googleAuth.accessToken,
      idToken: googleAuth.idToken,
    );

    // Sign in to Firebase
    await _auth.signInWithCredential(credential);

    final p = await SharedPreferences.getInstance();
    await p.setBool(_everClaimedKey, true);

    return getSessionUser();
  }

  // ── Owner shop creation ─────

  Future<AppUser> createShop({
    required String shopName,
    required String ownerName,
    required String location,
  }) async {
    if (firebase_core.Firebase.apps.isEmpty) {
      final p = await SharedPreferences.getInstance();
      await p.setBool(_everClaimedKey, true);
      await p.setString('offline_ownerName', ownerName.trim());
      return (await getSessionUser())!;
    }

    final user = _auth.currentUser;
    if (user == null) throw StateError('Not signed in — complete Google sign-in first');

    await _db.collection('shops').doc(user.uid).set({
      'profile': {
        'ownerName': ownerName.trim(),
        'name': shopName.trim(),
        'location': location.trim(),
      },
      'ownerUid': user.uid,
      'email': user.email,
      'createdAt': FieldValue.serverTimestamp(),
    });

    final p = await SharedPreferences.getInstance();
    await p.setBool(_everClaimedKey, true);

    final appUser = await getSessionUser();
    if (appUser == null) throw StateError('Shop creation did not take effect');
    return appUser;
  }

  // ── Staff (Google + invite code) ───────────────────────────

  Future<AppUser> redeemInviteCode({required String inviteCode}) async {
    if (firebase_core.Firebase.apps.isEmpty) {
      throw InvalidInviteException('Cannot add staff in offline mode. Please configure Firebase.');
    }

    final user = _auth.currentUser;
    if (user == null) throw StateError('Not signed in — complete Google sign-in first');

    final code = inviteCode.trim().toUpperCase();
    final inviteRef = _db.collection('invites').doc(code);
    final inviteSnap = await inviteRef.get();

    if (!inviteSnap.exists) {
      throw InvalidInviteException('That invite code wasn\'t found — check it and try again');
    }
    final invite = inviteSnap.data()!;
    if (invite['used'] == true) {
      throw InvalidInviteException('That invite code has already been used');
    }
    final shopId = invite['shopId'] as String;
    final canEdit = invite['canEdit'] as bool? ?? true;
    final staffName = invite['name'] as String? ?? user.displayName ?? 'Staff';
    final uid = user.uid;

    try {
      final batch = _db.batch();
      batch.update(inviteRef, {'used': true, 'claimedBy': uid});
      batch.set(_db.collection('shops').doc(shopId).collection('staff').doc(uid), {
        'name': staffName,
        'email': user.email,
        'canEdit': canEdit,
        'inviteCode': code,
        'createdAt': FieldValue.serverTimestamp(),
      });
      batch.set(_db.collection('staffIndex').doc(uid), {'shopId': shopId});
      await batch.commit();
    } catch (_) {
      throw InvalidInviteException('That invite code was just used by someone else — ask the owner for a new one');
    }

    final p = await SharedPreferences.getInstance();
    await p.setBool(_everClaimedKey, true);

    final appUser = await getSessionUser();
    if (appUser == null) throw StateError('Staff sign-up did not take effect');
    return appUser;
  }

  // ── Session ──────────────────────────────────────

  Future<AppUser?> getSessionUser() async {
    if (firebase_core.Firebase.apps.isEmpty) {
      final p = await SharedPreferences.getInstance();
      if (p.getBool(_everClaimedKey) == true) {
        return AppUser(
          id: 'offline_owner',
          name: p.getString('offline_ownerName') ?? 'Owner',
          username: p.getString('offline_email') ?? 'offline@local',
          role: UserRole.admin,
          canEdit: true,
          shopId: 'offline_shop',
        );
      }
      return null;
    }
    final user = _auth.currentUser;
    if (user == null) return null;

    final ownShop = await _db.collection('shops').doc(user.uid).get();
    if (ownShop.exists) {
      final name = (ownShop.data()?['profile']?['ownerName'] as String?) ?? user.displayName ?? 'Owner';
      return AppUser(
        id: user.uid,
        name: name,
        username: user.email ?? user.uid,
        role: UserRole.admin,
        canEdit: true,
        shopId: user.uid,
      );
    }

    final index = await _db.collection('staffIndex').doc(user.uid).get();
    final shopId = index.data()?['shopId'] as String?;
    if (shopId == null) return null;

    final staffDoc = await _db.collection('shops').doc(shopId).collection('staff').doc(user.uid).get();
    if (!staffDoc.exists) return null;

    final d = staffDoc.data()!;
    return AppUser(
      id: user.uid,
      name: (d['name'] as String?) ?? user.displayName ?? 'Staff',
      username: user.email ?? user.uid,
      role: UserRole.staff,
      canEdit: d['canEdit'] as bool? ?? true,
      shopId: shopId,
    );
  }

  Future<bool> hasAdmin() async {
    if (firebase_core.Firebase.apps.isNotEmpty && _auth.currentUser != null) return true;
    final p = await SharedPreferences.getInstance();
    return p.getBool(_everClaimedKey) ?? false;
  }

  Future<String> getUserType() async {
    if (firebase_core.Firebase.apps.isEmpty) {
      final p = await SharedPreferences.getInstance();
      return p.getBool(_everClaimedKey) == true ? 'owner' : 'new';
    }
    final user = _auth.currentUser;
    if (user == null) return 'new';

    final ownShop = await _db.collection('shops').doc(user.uid).get();
    if (ownShop.exists) return 'owner';

    final index = await _db.collection('staffIndex').doc(user.uid).get();
    if (index.exists && index.data()?['shopId'] != null) return 'staff';

    return 'new';
  }

  Future<void> setSession(String id) async {}
  Future<void> clearSession() async {
    if (firebase_core.Firebase.apps.isNotEmpty) {
      await GoogleSignIn().signOut();
      await _auth.signOut();
    }
  }

  // ── Team management ──────────────────────────────────

  Future<List<AppUser>> getUsers() async {
    final me = await getSessionUser();
    if (me == null) return [];
    if (firebase_core.Firebase.apps.isEmpty) return [me];

    final shopId = me.effectiveShopId;

    final owner = me.isAdmin ? me : await _ownerOf(shopId);
    final staffSnap = await _db.collection('shops').doc(shopId).collection('staff').get();
    final staff = staffSnap.docs.map((doc) {
      final d = doc.data();
      return AppUser(
        id: doc.id,
        name: d['name'] as String? ?? 'Staff',
        username: d['email'] as String? ?? '',
        role: UserRole.staff,
        canEdit: d['canEdit'] as bool? ?? true,
        shopId: shopId,
      );
    });
    return [owner, ...staff];
  }

  Future<AppUser> _ownerOf(String shopId) async {
    final doc = await _db.collection('shops').doc(shopId).get();
    final name = (doc.data()?['profile']?['ownerName'] as String?) ?? 'Owner';
    return AppUser(id: shopId, name: name, username: '', role: UserRole.admin, canEdit: true, shopId: shopId);
  }

  Future<String> createInvite({required String name, bool canEdit = true}) async {
    final me = await getSessionUser();
    if (me == null || !me.isAdmin) {
      throw StateError('Only the shop owner can create staff invites');
    }
    final code = _randomCode();
    await _db.collection('invites').doc(code).set({
      'shopId': me.id,
      'name': name.trim(),
      'canEdit': canEdit,
      'used': false,
      'createdAt': FieldValue.serverTimestamp(),
    });
    return code;
  }

  String _randomCode() {
    final rnd = Random.secure();
    return List.generate(6, (_) => _codeChars[rnd.nextInt(_codeChars.length)]).join();
  }

  Future<void> updateStaff(String id, {String? name, bool? canEdit}) async {
    final me = await getSessionUser();
    if (me == null || !me.isAdmin) throw StateError('Only the shop owner can manage staff');
    final update = <String, dynamic>{};
    if (name != null) update['name'] = name.trim();
    if (canEdit != null) update['canEdit'] = canEdit;
    if (update.isEmpty) return;
    await _db.collection('shops').doc(me.id).collection('staff').doc(id).update(update);
  }

  Future<void> removeUser(String id) async {
    final me = await getSessionUser();
    if (me == null || !me.isAdmin) throw StateError('Only the shop owner can remove staff');
    await _db.collection('shops').doc(me.id).collection('staff').doc(id).delete();
  }
}

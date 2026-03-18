import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../models/user_profile.dart';
import '../../models/workout_plan.dart';

class FirebaseService {
  static final _auth = FirebaseAuth.instance;
  static final _db = FirebaseFirestore.instance;

  static User? get currentUser => _auth.currentUser;
  static String? get uid => _auth.currentUser?.uid;

  // ── Auth ──────────────────────────────────────────────────────────────────
  static Future<User?> signInWithGoogle() async {
    final provider = GoogleAuthProvider();
    final result = await _auth.signInWithPopup(provider);
    return result.user;
  }

  static Future<void> signOut() async {
    await _auth.signOut();
  }

  // ── Perfil de usuario ─────────────────────────────────────────────────────
  static Future<UserProfile?> loadProfile() async {
    if (uid == null) return null;
    final doc = await _db.collection('users').doc(uid).get();
    if (!doc.exists) return null;
    return UserProfile.fromMap(doc.data()!);
  }

  static Future<void> saveProfile(UserProfile profile) async {
    if (uid == null) return;
    await _db.collection('users').doc(uid).set(profile.toMap(), SetOptions(merge: true));
  }

  static Future<void> updateProfilePartial(Map<String, dynamic> data) async {
    if (uid == null) return;
    await _db.collection('users').doc(uid).update(data);
  }

  // ── Plan de entrenamiento ─────────────────────────────────────────────────
  static Future<WorkoutPlan?> loadActivePlan() async {
    if (uid == null) return null;
    final doc = await _db.collection('users').doc(uid).collection('plans').doc('active').get();
    if (!doc.exists) return null;
    return WorkoutPlan.fromMap(doc.data()!);
  }

  static Future<void> saveActivePlan(WorkoutPlan plan) async {
    if (uid == null) return;
    await _db
        .collection('users')
        .doc(uid)
        .collection('plans')
        .doc('active')
        .set(plan.toMap());
  }

  static Future<void> deleteActivePlan() async {
    if (uid == null) return;
    await _db.collection('users').doc(uid).collection('plans').doc('active').delete();
  }

  // ── Sesiones de entrenamiento ─────────────────────────────────────────────
  static Future<void> saveSession(Map<String, dynamic> sessionData) async {
    if (uid == null) return;
    await _db
        .collection('users')
        .doc(uid)
        .collection('sessions')
        .add({
          ...sessionData,
          'timestamp': FieldValue.serverTimestamp(),
        });
  }

  static Future<List<Map<String, dynamic>>> loadRecentSessions({int limit = 10}) async {
    if (uid == null) return [];
    final snap = await _db
        .collection('users')
        .doc(uid)
        .collection('sessions')
        .orderBy('timestamp', descending: true)
        .limit(limit)
        .get();

    return snap.docs.map((d) => d.data()).toList();
  }

  // ── Datos AR semanales ────────────────────────────────────────────────────
  static Future<void> saveWeeklyMesh(AnthropometricData mesh) async {
    if (uid == null) return;
    await _db
        .collection('users')
        .doc(uid)
        .collection('weekly_mesh')
        .add({
          ...mesh.toMap(),
          'timestamp': FieldValue.serverTimestamp(),
        });
  }

  static Future<List<Map<String, dynamic>>> loadWeeklyMeshHistory({int limit = 12}) async {
    if (uid == null) return [];
    final snap = await _db
        .collection('users')
        .doc(uid)
        .collection('weekly_mesh')
        .orderBy('timestamp', descending: true)
        .limit(limit)
        .get();

    return snap.docs.map((d) => d.data()).toList();
  }
}

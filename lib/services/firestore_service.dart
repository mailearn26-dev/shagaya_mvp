import 'package:cloud_firestore/cloud_firestore.dart';

class FirestoreService {
  final _db = FirebaseFirestore.instance;

  DocumentReference<Map<String, dynamic>> userDoc(String uid) =>
      _db.collection('users').doc(uid);

  CollectionReference<Map<String, dynamic>> productsCol() =>
      _db.collection('products');

  CollectionReference<Map<String, dynamic>> requestsCol() =>
      _db.collection('requests');

  Future<void> ensureUserDoc({
    required String uid,
    required String email,
    required String role,
  }) async {
    await userDoc(uid).set({
      'uid': uid,
      'email': email,
      'role': role,
      'createdAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }
}

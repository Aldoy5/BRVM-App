import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../../core/models/operation.dart';

/// Repository pour la persistance des opérations et données utilisateur dans Firestore
/// Chaque utilisateur dispose de son sous-ensemble isolé : `users/{uid}/operations`
/// La persistance hors-ligne Firestore assure la disponibilité totale sans connexion.
class OperationsRepository {
  final FirebaseFirestore? _customFirestore;
  final String? _userId;

  OperationsRepository({FirebaseFirestore? firestore, String? userId})
      : _customFirestore = firestore,
        _userId = userId;

  FirebaseFirestore? get _firestore {
    if (_customFirestore != null) return _customFirestore;
    try {
      return FirebaseFirestore.instance;
    } catch (_) {
      return null;
    }
  }

  DocumentReference<Map<String, dynamic>>? get _userDocRef {
    final db = _firestore;
    if (db == null || _userId == null) return null;
    return db.collection('users').doc(_userId);
  }

  CollectionReference<Map<String, dynamic>>? get _userOpsRef {
    return _userDocRef?.collection('operations');
  }

  /// Écoute le flux d'opérations de l'utilisateur en temps réel
  Stream<List<Operation>> watchOperations() {
    final ref = _userOpsRef;
    if (ref == null) {
      return Stream.value([]);
    }

    return ref.orderBy('date', descending: true).snapshots().map((snapshot) {
      return snapshot.docs.map((doc) {
        final data = doc.data();
        return _mapDocToOperation(doc.id, data);
      }).toList();
    }).handleError((error) {
      debugPrint('[OperationsRepository] Erreur d\'écoute Firestore : $error');
      return <Operation>[];
    });
  }

  /// Enregistre ou met à jour une opération
  Future<void> saveOperation(Operation operation) async {
    final ref = _userOpsRef;
    if (ref == null) return;

    await ref.doc(operation.id).set({
      'type': operation.type.name,
      'date': Timestamp.fromDate(operation.date),
      'stockCode': operation.stockCode,
      'stockName': operation.stockName,
      'quantity': operation.quantity,
      'unitPrice': operation.unitPrice,
      'fees': operation.fees,
      'cashAmount': operation.cashAmount,
      'notes': operation.notes,
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  /// Supprime une opération existante
  Future<void> deleteOperation(String operationId) async {
    final ref = _userOpsRef;
    if (ref == null) return;
    await ref.doc(operationId).delete();
  }

  /// Récupère le solde SGI déclaré de l'utilisateur depuis Firestore
  Future<int?> getSgiDeclaredBalance() async {
    final docRef = _userDocRef;
    if (docRef == null) return null;
    try {
      final snap = await docRef.get();
      if (snap.exists && snap.data() != null) {
        final val = snap.data()!['sgiDeclaredBalance'];
        if (val is num) return val.toInt();
      }
    } catch (e) {
      debugPrint('[OperationsRepository] Erreur lecture solde SGI : $e');
    }
    return null;
  }

  /// Enregistre le solde SGI déclaré de l'utilisateur dans Firestore
  Future<void> saveSgiDeclaredBalance(int balance) async {
    final docRef = _userDocRef;
    if (docRef == null) return;
    try {
      await docRef.set({
        'sgiDeclaredBalance': balance,
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    } catch (e) {
      debugPrint('[OperationsRepository] Erreur sauvegarde solde SGI : $e');
    }
  }

  Operation _mapDocToOperation(String id, Map<String, dynamic> data) {
    final typeStr = data['type'] as String? ?? 'achat';
    final opType = OperationType.values.firstWhere(
      (e) => e.name == typeStr,
      orElse: () => OperationType.achat,
    );

    final rawDate = data['date'];
    final DateTime opDate;
    if (rawDate is Timestamp) {
      opDate = rawDate.toDate();
    } else if (rawDate is String) {
      opDate = DateTime.tryParse(rawDate) ?? DateTime.now();
    } else {
      opDate = DateTime.now();
    }

    return Operation(
      id: id,
      type: opType,
      date: opDate,
      stockCode: data['stockCode'] as String?,
      stockName: data['stockName'] as String?,
      quantity: (data['quantity'] as num?)?.toInt(),
      unitPrice: (data['unitPrice'] as num?)?.toInt(),
      fees: (data['fees'] as num?)?.toInt() ?? 0,
      cashAmount: (data['cashAmount'] as num?)?.toInt(),
      notes: data['notes'] as String?,
    );
  }
}

import '../models/billing_record_model.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class DatabaseHelper {
  final CollectionReference collection = FirebaseFirestore.instance.collection(BillingRecordModel.CollectionName);

  // insert a new billing record
  Future<DocumentReference> addBillingRecord(BillingRecordModel billingRecord) async {
    return await collection.add(billingRecord.toJson());
  }
  // update an existing billing record
  Future<void> updateBillingRecord(String id, BillingRecordModel billingRecord) async {
    return await collection.doc(id).update(billingRecord.toJson());
  }
  // delete a billing record
  Future<void> deleteBillingRecord(String id) async {
    return await collection.doc(id).delete();
  }
  // load all billing records
  Stream<QuerySnapshot> getStreamBillingRecords() {
    return collection.snapshots();
  }  
}

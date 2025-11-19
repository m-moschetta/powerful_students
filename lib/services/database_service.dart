import 'package:cloud_firestore/cloud_firestore.dart';

class DatabaseService {
  final String? uid;
  DatabaseService({this.uid});

  // Collection reference
  final CollectionReference studentsCollection =
      FirebaseFirestore.instance.collection('students');

  // Update student data
  Future updateStudentData(String name, String grade) async {
    return await studentsCollection.doc(uid).set({
      'name': name,
      'grade': grade,
    });
  }

  // Get student stream
  Stream<QuerySnapshot> get students {
    return studentsCollection.snapshots();
  }
}

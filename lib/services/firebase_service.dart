import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:srscs/models/user_model.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'dart:io';
import 'package:intl/intl.dart';

class FirebaseService {
  FirebaseAuth get auth => FirebaseAuth.instance;
  FirebaseFirestore get firestore => FirebaseFirestore.instance;

  // Verify NID
  Future<Map<String, String>?> verifyNID(String nid, String dateOfBirth) async {
    final user = await FirebaseFirestore.instance
        .collection('NIDRecords')
        .doc(nid)
        .get();
    if (user.exists) {
      final data = user.data()!;
      final String dob = DateFormat('dd/MM/yyyy')
          .format(DateFormat('dd/MM/yyyy').parse(dateOfBirth));
      if (data['dob'] == dob) {
        return {
          'firstName': data['firstName'],
          'lastName': data['lastName'],
          'address': data['address'],
        };
      } else {
        return null;
      }
    }
    return null;
  }

  Future<void> registerEntry(
    String nidNumber,
    String firstName,
    String lastName,
    String email,
    String phoneNumber,
    String uid,
    String address,
    String dob,
  ) async {
    try {
      await firestore.collection('ApplicationUsers').doc(uid).set({
        'firstName': firstName,
        'lastName': lastName,
        'email': email,
        'phoneNumber': phoneNumber,
        'imageUrl': '',
        'isActive': true,
        'nidNumber': nidNumber,
        'address': address,
        'dob': DateFormat('dd/MM/yyyy').parse(dob),
      });
    } catch (e) {
      rethrow;
    }
  }

  // Get User by UID
  Future<UserModel> getUserData(String uid) async {
    DocumentSnapshot snapshot =
        await firestore.collection('ApplicationUsers').doc(uid).get();
    if (snapshot.exists) {
      return UserModel.fromDocumentSnapshot(snapshot);
    } else {
      throw 'User not found';
    }
  }

  // Update User Profile
  Future<void> updateUserProfile(UserModel user) async {
    try {
      await firestore.collection('ApplicationUsers').doc(user.uid).update({
        'firstName': user.firstName,
        'lastName': user.lastName,
        'imageUrl': user.imageUrl,
        'phoneNumber': user.phoneNumber,
      });
    } catch (e) {
      rethrow;
    }
  }

  //Upload image to Firebase Storage
  Future<String> uploadImageToFirebase(File imageFile, String userId) async {
    final storageRef = FirebaseStorage.instance.ref().child(
          'user_avatars/$userId/${DateTime.now().millisecondsSinceEpoch}.jpg',
        );
    final uploadTask = await storageRef.putFile(imageFile);
    final downloadUrl = await uploadTask.ref.getDownloadURL();
    return downloadUrl;
  }

//   Future<void> insertNIDDataToFirestore() async {
//     // Reference to your collection
//     final CollectionReference nidCollection =
//         FirebaseFirestore.instance.collection('NIDRecords');

//     // Your data (truncated for example, include full data in your implementation)
//     final List<Map<String, dynamic>> nidData = [
//       {
//         "firstName": "Lamia",
//         "lastName": "Akter",
//         "image":
//             "https://firebasestorage.googleapis.com/v0/b/demo-app.appspot.com/o/nid%2F7171052719122.jpg?alt=media",
//         "fatherName": "Asif Hossain",
//         "motherName": "Sadia Miah",
//         "dob": "1999-05-08",
//         "NIDnumber": "7171052719122",
//         "address": "H.No. 739, Sahota Circle, Khulna, Bangladesh",
//         "bloodGroup": "A+"
//       },
//       {
//         "firstName": "Nayeem",
//         "lastName": "Karim",
//         "image":
//             "https://firebasestorage.googleapis.com/v0/b/demo-app.appspot.com/o/nid%2F3137019168746.jpg?alt=media",
//         "fatherName": "Shakib Begum",
//         "motherName": "Tanjila Chowdhury",
//         "dob": "1992-06-16",
//         "NIDnumber": "3137019168746",
//         "address": "595, Das Nagar, Rajshahi, Bangladesh",
//         "bloodGroup": "O-"
//       },
//       {
//         "firstName": "Sadia",
//         "lastName": "Islam",
//         "image":
//             "https://firebasestorage.googleapis.com/v0/b/demo-app.appspot.com/o/nid%2F793714445370.jpg?alt=media",
//         "fatherName": "Asif Sikder",
//         "motherName": "Afsana Begum",
//         "dob": "1983-07-10",
//         "NIDnumber": "793714445370",
//         "address": "26, Ganguly Nagar, Chattogram, Bangladesh",
//         "bloodGroup": "B+"
//       },
//       {
//         "firstName": "Taslima",
//         "lastName": "Hossain",
//         "image":
//             "https://firebasestorage.googleapis.com/v0/b/demo-app.appspot.com/o/nid%2F4637394395932.jpg?alt=media",
//         "fatherName": "Mehedi Begum",
//         "motherName": "Afsana Islam",
//         "dob": "1969-07-02",
//         "NIDnumber": "4637394395932",
//         "address": "02/677, Kade Nagar, Comilla, Bangladesh",
//         "bloodGroup": "B-"
//       },
//       {
//         "firstName": "Tanjila",
//         "lastName": "Miah",
//         "image":
//             "https://firebasestorage.googleapis.com/v0/b/demo-app.appspot.com/o/nid%2F2854118467710.jpg?alt=media",
//         "fatherName": "Abdul Karim",
//         "motherName": "Mou Akter",
//         "dob": "1983-04-05",
//         "NIDnumber": "2854118467710",
//         "address": "15/079, Singhal Nagar, Rangpur, Bangladesh",
//         "bloodGroup": "A-"
//       },
//       {
//         "firstName": "Mou",
//         "lastName": "Begum",
//         "image":
//             "https://firebasestorage.googleapis.com/v0/b/demo-app.appspot.com/o/nid%2F7966653496389.jpg?alt=media",
//         "fatherName": "Shakib Akter",
//         "motherName": "Tanjila Sikder",
//         "dob": "1965-10-24",
//         "NIDnumber": "7966653496389",
//         "address": "24/84, Kara Road, Khulna, Bangladesh",
//         "bloodGroup": "AB-"
//       },
//       {
//         "firstName": "Tanvir",
//         "lastName": "Begum",
//         "image":
//             "https://firebasestorage.googleapis.com/v0/b/demo-app.appspot.com/o/nid%2F4466601143637.jpg?alt=media",
//         "fatherName": "Abdul Chowdhury",
//         "motherName": "Tanjila Chowdhury",
//         "dob": "1966-09-05",
//         "NIDnumber": "4466601143637",
//         "address": "86/05, Date Ganj, Cox's Bazar, Bangladesh",
//         "bloodGroup": "A-"
//       },
//       {
//         "firstName": "Rina",
//         "lastName": "Hossain",
//         "image":
//             "https://firebasestorage.googleapis.com/v0/b/demo-app.appspot.com/o/nid%2F9870774816146.jpg?alt=media",
//         "fatherName": "Rafi Islam",
//         "motherName": "Taslima Karim",
//         "dob": "1982-06-30",
//         "NIDnumber": "9870774816146",
//         "address": "H.No. 11, Sathe Marg, Rangpur, Bangladesh",
//         "bloodGroup": "O+"
//       },
//       {
//         "firstName": "Asif",
//         "lastName": "Islam",
//         "image":
//             "https://firebasestorage.googleapis.com/v0/b/demo-app.appspot.com/o/nid%2F2871126304644.jpg?alt=media",
//         "fatherName": "Rafi Sikder",
//         "motherName": "Afsana Rahman",
//         "dob": "2006-08-22",
//         "NIDnumber": "2871126304644",
//         "address": "470, Jayaraman Path, Chattogram, Bangladesh",
//         "bloodGroup": "O+"
//       },
//       {
//         "firstName": "Afsana",
//         "lastName": "Sikder",
//         "image":
//             "https://firebasestorage.googleapis.com/v0/b/demo-app.appspot.com/o/nid%2F233334635276.jpg?alt=media",
//         "fatherName": "Asif Begum",
//         "motherName": "Sumaiya Karim",
//         "dob": "1986-03-08",
//         "NIDnumber": "233334635276",
//         "address": "H.No. 73, Kibe Ganj, Rajshahi, Bangladesh",
//         "bloodGroup": "AB+"
//       },
//       {
//         "firstName": "Sumaiya",
//         "lastName": "Miah",
//         "image":
//             "https://firebasestorage.googleapis.com/v0/b/demo-app.appspot.com/o/nid%2F8113597779261.jpg?alt=media",
//         "fatherName": "Mehedi Miah",
//         "motherName": "Tanjila Begum",
//         "dob": "1997-10-18",
//         "NIDnumber": "8113597779261",
//         "address": "H.No. 60, Rama Chowk, Chattogram, Bangladesh",
//         "bloodGroup": "A+"
//       },
//       {
//         "firstName": "Tanjila",
//         "lastName": "Chowdhury",
//         "image":
//             "https://firebasestorage.googleapis.com/v0/b/demo-app.appspot.com/o/nid%2F2699004280848.jpg?alt=media",
//         "fatherName": "Mehedi Karim",
//         "motherName": "Afsana Hossain",
//         "dob": "1975-01-31",
//         "NIDnumber": "2699004280848",
//         "address": "57/46, Reddy Circle, Khulna, Bangladesh",
//         "bloodGroup": "O-"
//       },
//       {
//         "firstName": "Jannat",
//         "lastName": "Hossain",
//         "image":
//             "https://firebasestorage.googleapis.com/v0/b/demo-app.appspot.com/o/nid%2F668715069994.jpg?alt=media",
//         "fatherName": "Asif Akter",
//         "motherName": "Nusrat Hasan",
//         "dob": "1973-04-24",
//         "NIDnumber": "668715069994",
//         "address": "001, Halder Marg, Chattogram, Bangladesh",
//         "bloodGroup": "AB-"
//       },
//       {
//         "firstName": "Shakib",
//         "lastName": "Hasan",
//         "image":
//             "https://firebasestorage.googleapis.com/v0/b/demo-app.appspot.com/o/nid%2F1503242543275.jpg?alt=media",
//         "fatherName": "Shakib Akter",
//         "motherName": "Rina Miah",
//         "dob": "1993-08-30",
//         "NIDnumber": "1503242543275",
//         "address": "594, Kannan Marg, Rangpur, Bangladesh",
//         "bloodGroup": "B-"
//       },
//       {
//         "firstName": "Tanjila",
//         "lastName": "Chowdhury",
//         "image":
//             "https://firebasestorage.googleapis.com/v0/b/demo-app.appspot.com/o/nid%2F3155439992083.jpg?alt=media",
//         "fatherName": "Nayeem Hasan",
//         "motherName": "Tanjila Rahman",
//         "dob": "2003-10-26",
//         "NIDnumber": "3155439992083",
//         "address": "H.No. 403, Tella Marg, Rangpur, Bangladesh",
//         "bloodGroup": "A+"
//       },
//       {
//         "firstName": "Abdul",
//         "lastName": "Islam",
//         "image":
//             "https://firebasestorage.googleapis.com/v0/b/demo-app.appspot.com/o/nid%2F2657087069713.jpg?alt=media",
//         "fatherName": "Rafi Islam",
//         "motherName": "Nusrat Sikder",
//         "dob": "1968-05-19",
//         "NIDnumber": "2657087069713",
//         "address": "82, Dutta Nagar, Mymensingh, Bangladesh",
//         "bloodGroup": "O-"
//       },
//       {
//         "firstName": "Hasib",
//         "lastName": "Karim",
//         "image":
//             "https://firebasestorage.googleapis.com/v0/b/demo-app.appspot.com/o/nid%2F4427168569127.jpg?alt=media",
//         "fatherName": "Tanvir Rahman",
//         "motherName": "Sumaiya Chowdhury",
//         "dob": "2005-04-05",
//         "NIDnumber": "4427168569127",
//         "address": "H.No. 03, Sampath Circle, Mymensingh, Bangladesh",
//         "bloodGroup": "O+"
//       },
//       {
//         "firstName": "Tanvir",
//         "lastName": "Begum",
//         "image":
//             "https://firebasestorage.googleapis.com/v0/b/demo-app.appspot.com/o/nid%2F3877502741975.jpg?alt=media",
//         "fatherName": "Mehedi Begum",
//         "motherName": "Rina Hasan",
//         "dob": "1967-01-22",
//         "NIDnumber": "3877502741975",
//         "address": "H.No. 53, Kamdar, Rangpur, Bangladesh",
//         "bloodGroup": "O-"
//       },
//       {
//         "firstName": "Mehedi",
//         "lastName": "Karim",
//         "image":
//             "https://firebasestorage.googleapis.com/v0/b/demo-app.appspot.com/o/nid%2F8819801154433.jpg?alt=media",
//         "fatherName": "Sajid Islam",
//         "motherName": "Nusrat Hossain",
//         "dob": "1993-12-06",
//         "NIDnumber": "8819801154433",
//         "address": "116, Dhaliwal Nagar, Dhaka, Bangladesh",
//         "bloodGroup": "O+"
//       },
//       {
//         "firstName": "Sumaiya",
//         "lastName": "Hasan",
//         "image":
//             "https://firebasestorage.googleapis.com/v0/b/demo-app.appspot.com/o/nid%2F9992297529658.jpg?alt=media",
//         "fatherName": "Sajid Karim",
//         "motherName": "Taslima Karim",
//         "dob": "1987-01-28",
//         "NIDnumber": "9992297529658",
//         "address": "018, Dey Street, Rajshahi, Bangladesh",
//         "bloodGroup": "AB-"
//       },
//       {
//         "firstName": "Afsana",
//         "lastName": "Islam",
//         "image":
//             "https://firebasestorage.googleapis.com/v0/b/demo-app.appspot.com/o/nid%2F6232972124293.jpg?alt=media",
//         "fatherName": "Fahim Miah",
//         "motherName": "Afsana Akter",
//         "dob": "1981-02-16",
//         "NIDnumber": "6232972124293",
//         "address": "H.No. 31, Dua Circle, Mymensingh, Bangladesh",
//         "bloodGroup": "A+"
//       },
//       {
//         "firstName": "Jannat",
//         "lastName": "Begum",
//         "image":
//             "https://firebasestorage.googleapis.com/v0/b/demo-app.appspot.com/o/nid%2F1841748525225.jpg?alt=media",
//         "fatherName": "Shakib Begum",
//         "motherName": "Jannat Begum",
//         "dob": "1975-06-05",
//         "NIDnumber": "1841748525225",
//         "address": "85/061, D\u2019Alia Ganj, Cox's Bazar, Bangladesh",
//         "bloodGroup": "A+"
//       },
//       {
//         "firstName": "Tanvir",
//         "lastName": "Hossain",
//         "image":
//             "https://firebasestorage.googleapis.com/v0/b/demo-app.appspot.com/o/nid%2F7378286255007.jpg?alt=media",
//         "fatherName": "Abdul Miah",
//         "motherName": "Mou Chowdhury",
//         "dob": "2005-04-03",
//         "NIDnumber": "7378286255007",
//         "address": "H.No. 33, Bhakta, Cox's Bazar, Bangladesh",
//         "bloodGroup": "AB-"
//       },
//       {
//         "firstName": "Jannat",
//         "lastName": "Begum",
//         "image":
//             "https://firebasestorage.googleapis.com/v0/b/demo-app.appspot.com/o/nid%2F6078625658818.jpg?alt=media",
//         "fatherName": "Abdul Sikder",
//         "motherName": "Lamia Akter",
//         "dob": "1989-08-28",
//         "NIDnumber": "6078625658818",
//         "address": "59/503, Arora Road, Sylhet, Bangladesh",
//         "bloodGroup": "O-"
//       },
//       {
//         "firstName": "Fahim",
//         "lastName": "Sikder",
//         "image":
//             "https://firebasestorage.googleapis.com/v0/b/demo-app.appspot.com/o/nid%2F3350148929607.jpg?alt=media",
//         "fatherName": "Sajid Hossain",
//         "motherName": "Afsana Hasan",
//         "dob": "1994-04-17",
//         "NIDnumber": "3350148929607",
//         "address": "H.No. 234, Upadhyay Chowk, Rajshahi, Bangladesh",
//         "bloodGroup": "B+"
//       },
//       {
//         "firstName": "Taslima",
//         "lastName": "Begum",
//         "image":
//             "https://firebasestorage.googleapis.com/v0/b/demo-app.appspot.com/o/nid%2F8018678557868.jpg?alt=media",
//         "fatherName": "Sajid Rahman",
//         "motherName": "Sadia Sikder",
//         "dob": "1987-05-07",
//         "NIDnumber": "8018678557868",
//         "address": "83, Majumdar Chowk, Rajshahi, Bangladesh",
//         "bloodGroup": "AB-"
//       },
//       {
//         "firstName": "Sajid",
//         "lastName": "Sikder",
//         "image":
//             "https://firebasestorage.googleapis.com/v0/b/demo-app.appspot.com/o/nid%2F9093438860528.jpg?alt=media",
//         "fatherName": "Abdul Hossain",
//         "motherName": "Jannat Karim",
//         "dob": "1991-10-07",
//         "NIDnumber": "9093438860528",
//         "address": "11/85, Manne Road, Dhaka, Bangladesh",
//         "bloodGroup": "O-"
//       },
//       {
//         "firstName": "Fahim",
//         "lastName": "Rahman",
//         "image":
//             "https://firebasestorage.googleapis.com/v0/b/demo-app.appspot.com/o/nid%2F6635534888536.jpg?alt=media",
//         "fatherName": "Asif Sikder",
//         "motherName": "Mou Hossain",
//         "dob": "1999-08-16",
//         "NIDnumber": "6635534888536",
//         "address": "H.No. 347, Doshi Zila, Barisal, Bangladesh",
//         "bloodGroup": "A+"
//       },
//       {
//         "firstName": "Mehedi",
//         "lastName": "Sikder",
//         "image":
//             "https://firebasestorage.googleapis.com/v0/b/demo-app.appspot.com/o/nid%2F955181578528.jpg?alt=media",
//         "fatherName": "Nayeem Islam",
//         "motherName": "Lamia Akter",
//         "dob": "1991-06-30",
//         "NIDnumber": "955181578528",
//         "address": "890, Lad Path, Rajshahi, Bangladesh",
//         "bloodGroup": "AB-"
//       },
//       {
//         "firstName": "Abdul",
//         "lastName": "Miah",
//         "image":
//             "https://firebasestorage.googleapis.com/v0/b/demo-app.appspot.com/o/nid%2F5173788277211.jpg?alt=media",
//         "fatherName": "Asif Chowdhury",
//         "motherName": "Rina Miah",
//         "dob": "1995-04-14",
//         "NIDnumber": "5173788277211",
//         "address": "33, Baral Path, Barisal, Bangladesh",
//         "bloodGroup": "O-"
//       },
//       {
//         "firstName": "Nayeem",
//         "lastName": "Chowdhury",
//         "image":
//             "https://firebasestorage.googleapis.com/v0/b/demo-app.appspot.com/o/nid%2F6525659055451.jpg?alt=media",
//         "fatherName": "Hasib Sikder",
//         "motherName": "Sumaiya Sikder",
//         "dob": "2000-03-23",
//         "NIDnumber": "6525659055451",
//         "address": "98/15, Hayer Chowk, Khulna, Bangladesh",
//         "bloodGroup": "AB-"
//       },
//       {
//         "firstName": "Mehedi",
//         "lastName": "Sikder",
//         "image":
//             "https://firebasestorage.googleapis.com/v0/b/demo-app.appspot.com/o/nid%2F521558559336.jpg?alt=media",
//         "fatherName": "Mehedi Sikder",
//         "motherName": "Sadia Akter",
//         "dob": "1984-10-12",
//         "NIDnumber": "521558559336",
//         "address": "H.No. 193, Butala Ganj, Sylhet, Bangladesh",
//         "bloodGroup": "AB-"
//       },
//       {
//         "firstName": "Rafi",
//         "lastName": "Miah",
//         "image":
//             "https://firebasestorage.googleapis.com/v0/b/demo-app.appspot.com/o/nid%2F533634177076.jpg?alt=media",
//         "fatherName": "Fahim Hossain",
//         "motherName": "Lamia Karim",
//         "dob": "1985-03-22",
//         "NIDnumber": "533634177076",
//         "address": "H.No. 97, Rao Nagar, Rajshahi, Bangladesh",
//         "bloodGroup": "O+"
//       },
//       {
//         "firstName": "Afsana",
//         "lastName": "Hasan",
//         "image":
//             "https://firebasestorage.googleapis.com/v0/b/demo-app.appspot.com/o/nid%2F9584511202270.jpg?alt=media",
//         "fatherName": "Asif Hasan",
//         "motherName": "Afsana Hasan",
//         "dob": "2006-08-23",
//         "NIDnumber": "9584511202270",
//         "address": "H.No. 580, Rout Marg, Dhaka, Bangladesh",
//         "bloodGroup": "A+"
//       },
//       {
//         "firstName": "Fahim",
//         "lastName": "Miah",
//         "image":
//             "https://firebasestorage.googleapis.com/v0/b/demo-app.appspot.com/o/nid%2F9068677478805.jpg?alt=media",
//         "fatherName": "Shakib Islam",
//         "motherName": "Tanjila Begum",
//         "dob": "1998-04-26",
//         "NIDnumber": "9068677478805",
//         "address": "H.No. 233, Brar Circle, Rangpur, Bangladesh",
//         "bloodGroup": "AB-"
//       },
//       {
//         "firstName": "Mou",
//         "lastName": "Sikder",
//         "image":
//             "https://firebasestorage.googleapis.com/v0/b/demo-app.appspot.com/o/nid%2F3475483579317.jpg?alt=media",
//         "fatherName": "Nayeem Karim",
//         "motherName": "Taslima Hasan",
//         "dob": "1970-11-06",
//         "NIDnumber": "3475483579317",
//         "address": "89, Butala Chowk, Rangpur, Bangladesh",
//         "bloodGroup": "B+"
//       },
//       {
//         "firstName": "Nayeem",
//         "lastName": "Begum",
//         "image":
//             "https://firebasestorage.googleapis.com/v0/b/demo-app.appspot.com/o/nid%2F5330688588932.jpg?alt=media",
//         "fatherName": "Mehedi Hossain",
//         "motherName": "Taslima Chowdhury",
//         "dob": "1988-09-07",
//         "NIDnumber": "5330688588932",
//         "address": "H.No. 248, Choudhury Street, Sylhet, Bangladesh",
//         "bloodGroup": "A+"
//       },
//       {
//         "firstName": "Asif",
//         "lastName": "Rahman",
//         "image":
//             "https://firebasestorage.googleapis.com/v0/b/demo-app.appspot.com/o/nid%2F862045710947.jpg?alt=media",
//         "fatherName": "Nayeem Islam",
//         "motherName": "Sadia Sikder",
//         "dob": "1987-04-25",
//         "NIDnumber": "862045710947",
//         "address": "646, Walia Zila, Rangpur, Bangladesh",
//         "bloodGroup": "AB-"
//       },
//       {
//         "firstName": "Hasib",
//         "lastName": "Begum",
//         "image":
//             "https://firebasestorage.googleapis.com/v0/b/demo-app.appspot.com/o/nid%2F3794736488875.jpg?alt=media",
//         "fatherName": "Fahim Islam",
//         "motherName": "Afsana Akter",
//         "dob": "1982-09-16",
//         "NIDnumber": "3794736488875",
//         "address": "64/307, Subramanian, Barisal, Bangladesh",
//         "bloodGroup": "B+"
//       },
//       {
//         "firstName": "Sadia",
//         "lastName": "Rahman",
//         "image":
//             "https://firebasestorage.googleapis.com/v0/b/demo-app.appspot.com/o/nid%2F3891752621136.jpg?alt=media",
//         "fatherName": "Hasib Hasan",
//         "motherName": "Sumaiya Islam",
//         "dob": "1965-04-16",
//         "NIDnumber": "3891752621136",
//         "address": "H.No. 31, Ray Circle, Barisal, Bangladesh",
//         "bloodGroup": "O-"
//       },
//       {
//         "firstName": "Hasib",
//         "lastName": "Sikder",
//         "image":
//             "https://firebasestorage.googleapis.com/v0/b/demo-app.appspot.com/o/nid%2F1634291061172.jpg?alt=media",
//         "fatherName": "Mehedi Begum",
//         "motherName": "Mou Miah",
//         "dob": "1979-05-07",
//         "NIDnumber": "1634291061172",
//         "address": "H.No. 409, Bhatnagar Path, Comilla, Bangladesh",
//         "bloodGroup": "O+"
//       },
//       {
//         "firstName": "Rina",
//         "lastName": "Karim",
//         "image":
//             "https://firebasestorage.googleapis.com/v0/b/demo-app.appspot.com/o/nid%2F2003271904272.jpg?alt=media",
//         "fatherName": "Shakib Islam",
//         "motherName": "Sumaiya Karim",
//         "dob": "1992-11-09",
//         "NIDnumber": "2003271904272",
//         "address": "24/35, Goyal Path, Rangpur, Bangladesh",
//         "bloodGroup": "B+"
//       },
//       {
//         "firstName": "Jannat",
//         "lastName": "Sikder",
//         "image":
//             "https://firebasestorage.googleapis.com/v0/b/demo-app.appspot.com/o/nid%2F4381333714628.jpg?alt=media",
//         "fatherName": "Asif Hossain",
//         "motherName": "Rina Chowdhury",
//         "dob": "1970-06-08",
//         "NIDnumber": "4381333714628",
//         "address": "73/43, Kata Zila, Mymensingh, Bangladesh",
//         "bloodGroup": "AB+"
//       },
//       {
//         "firstName": "Rina",
//         "lastName": "Hossain",
//         "image":
//             "https://firebasestorage.googleapis.com/v0/b/demo-app.appspot.com/o/nid%2F9696948117701.jpg?alt=media",
//         "fatherName": "Mehedi Sikder",
//         "motherName": "Tanjila Hossain",
//         "dob": "1997-10-13",
//         "NIDnumber": "9696948117701",
//         "address": "H.No. 49, Majumdar Nagar, Sylhet, Bangladesh",
//         "bloodGroup": "O-"
//       },
//       {
//         "firstName": "Abdul",
//         "lastName": "Akter",
//         "image":
//             "https://firebasestorage.googleapis.com/v0/b/demo-app.appspot.com/o/nid%2F3183063438355.jpg?alt=media",
//         "fatherName": "Shakib Rahman",
//         "motherName": "Sumaiya Rahman",
//         "dob": "1995-10-15",
//         "NIDnumber": "3183063438355",
//         "address": "74/909, Vaidya Chowk, Khulna, Bangladesh",
//         "bloodGroup": "O-"
//       },
//       {
//         "firstName": "Tanjila",
//         "lastName": "Sikder",
//         "image":
//             "https://firebasestorage.googleapis.com/v0/b/demo-app.appspot.com/o/nid%2F1449030202599.jpg?alt=media",
//         "fatherName": "Tanvir Akter",
//         "motherName": "Sumaiya Rahman",
//         "dob": "1995-11-08",
//         "NIDnumber": "1449030202599",
//         "address": "H.No. 948, Apte Road, Barisal, Bangladesh",
//         "bloodGroup": "AB-"
//       },
//       {
//         "firstName": "Shakib",
//         "lastName": "Akter",
//         "image":
//             "https://firebasestorage.googleapis.com/v0/b/demo-app.appspot.com/o/nid%2F6590093303864.jpg?alt=media",
//         "fatherName": "Asif Hossain",
//         "motherName": "Sumaiya Hossain",
//         "dob": "1989-06-27",
//         "NIDnumber": "6590093303864",
//         "address": "72, Karpe Path, Comilla, Bangladesh",
//         "bloodGroup": "O+"
//       },
//       {
//         "firstName": "Afsana",
//         "lastName": "Hasan",
//         "image":
//             "https://firebasestorage.googleapis.com/v0/b/demo-app.appspot.com/o/nid%2F2850498472099.jpg?alt=media",
//         "fatherName": "Nayeem Rahman",
//         "motherName": "Nusrat Hasan",
//         "dob": "1972-10-13",
//         "NIDnumber": "2850498472099",
//         "address": "H.No. 36, Krish Marg, Barisal, Bangladesh",
//         "bloodGroup": "A+"
//       },
//       {
//         "firstName": "Mehedi",
//         "lastName": "Miah",
//         "image":
//             "https://firebasestorage.googleapis.com/v0/b/demo-app.appspot.com/o/nid%2F2576629698066.jpg?alt=media",
//         "fatherName": "Abdul Miah",
//         "motherName": "Rina Islam",
//         "dob": "2005-01-18",
//         "NIDnumber": "2576629698066",
//         "address": "92/903, Karnik Street, Chattogram, Bangladesh",
//         "bloodGroup": "B+"
//       },
//       {
//         "firstName": "Tanvir",
//         "lastName": "Akter",
//         "image":
//             "https://firebasestorage.googleapis.com/v0/b/demo-app.appspot.com/o/nid%2F4986000397791.jpg?alt=media",
//         "fatherName": "Hasib Hossain",
//         "motherName": "Lamia Islam",
//         "dob": "2006-10-30",
//         "NIDnumber": "4986000397791",
//         "address": "683, Sengupta Street, Mymensingh, Bangladesh",
//         "bloodGroup": "AB+"
//       }
//     ];

//     // Batch write for better performance
//     final WriteBatch batch = firestore.batch();

//     try {
//       // Process each record
//       for (final record in nidData) {
//         // Format the date from yyyy-mm-dd to dd/mm/yyyy
//         final originalDate = record['dob'];
//         final formattedDate = _formatDate(originalDate);

//         // Create document reference with NID number as document ID
//         final docRef = nidCollection.doc(record['NIDnumber']);

//         // Prepare data with formatted date
//         final data = {
//           ...record,
//           'dob': formattedDate,
//           'createdAt': FieldValue.serverTimestamp(),
//         };

//         // Add to batch
//         batch.set(docRef, data);
//       }

//       // Commit the batch
//       await batch.commit();
//       print('Successfully inserted ${nidData.length} records');
//     } catch (e) {
//       print('Error inserting data: $e');
//       // Consider rethrowing or handling the error appropriately
//       throw e;
//     }
//   }

// // Helper function to format date from yyyy-mm-dd to dd/mm/yyyy
//   String _formatDate(String originalDate) {
//     try {
//       final parsedDate = DateTime.parse(originalDate);
//       return DateFormat('dd/MM/yyyy').format(parsedDate);
//     } catch (e) {
//       print('Error parsing date $originalDate: $e');
//       return originalDate; // Return original if parsing fails
//     }
//   }
}

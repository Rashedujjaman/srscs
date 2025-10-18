import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Map<String, dynamic>? _userData;
  List<Map<String, dynamic>> _recentComplaints = [];

  @override
  void initState() {
    super.initState();
    _loadUserData();
    _loadComplaints();
  }

  Future<void> _loadUserData() async {
    final uid = _auth.currentUser?.uid;
    if (uid != null) {
      final doc = await _firestore.collection('citizens').doc(uid).get();
      if (doc.exists) {
        setState(() {
          _userData = doc.data();
        });
      } else {
        print('No document found for UID: $uid');
      }
    }
  }

  Future<void> _loadComplaints() async {
    final uid = _auth.currentUser?.uid;
    if (uid != null) {
      final query = await _firestore
          .collection('complaints')
          .where('userId', isEqualTo: uid)
          .orderBy('date', descending: true)
          .limit(5)
          .get();

      setState(() {
        _recentComplaints = query.docs.map((doc) => doc.data()).toList();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final name = _userData?['fullName'] ?? 'Loading...';
    final dob = _userData?['dob'];
    final formattedDob =
        dob is Timestamp ? DateFormat('dd MMM yyyy').format(dob.toDate()) : '';

    return Scaffold(
      appBar: AppBar(
        title: const Text("Profile"),
        backgroundColor: const Color.fromARGB(255, 246, 246, 247),
      ),
      body: _userData == null
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // Profile Image + Name
                  Stack(
                    alignment: Alignment.bottomRight,
                    children: [
                      CircleAvatar(
                        radius: 50,
                        backgroundColor: Colors.deepPurple[100],
                        child: const Icon(Icons.person, size: 50),
                      ),
                      IconButton(
                        icon: const Icon(Icons.edit, color: Colors.deepPurple),
                        onPressed: () {
                          // TODO: Edit profile picture
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Text(
                    name,
                    style: const TextStyle(
                        fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 20),

                  // Personal Info
                  _buildInfoRow("NID Number", _userData?['nid']),
                  _buildInfoRow("Address", _userData?['address']),
                  _buildInfoRow("Blood Group", _userData?['bloodType']),
                  _buildInfoRow("Phone Number", _userData?['phone']),
                  _buildInfoRow("Email", _userData?['email']),
                  _buildInfoRow("Date of Birth", formattedDob),

                  const SizedBox(height: 30),

                  // Contact Section
                  const Divider(),
                  const SizedBox(height: 10),
                  const Text("Contact With Us",
                      style:
                          TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 10),
                  ListTile(
                    leading: const Icon(Icons.phone),
                    title: const Text("Call Us"),
                    onTap: () {
                      // TODO: Call logic
                    },
                  ),
                  ListTile(
                    leading: const Icon(Icons.chat),
                    title: const Text("Chat with Admin"),
                    onTap: () {
                      // TODO: Chat logic
                    },
                  ),

                  const SizedBox(height: 30),

                  // Recent Complaints
                  const Divider(),
                  const SizedBox(height: 10),
                  const Text("Recent Complaints",
                      style:
                          TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 10),
                  ..._recentComplaints.map((c) => ListTile(
                        title: Text(c['title'] ?? 'Complaint'),
                        subtitle: Text("Date: ${c['date'] ?? ''}"),
                        trailing: Chip(label: Text(c['status'] ?? '')),
                      )),

                  const SizedBox(height: 30),

                  // Logout & Update Buttons
                  const Divider(),
                  const SizedBox(height: 10),
                  const Text("Account Settings",
                      style:
                          TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 10),
                  ElevatedButton.icon(
                    icon: const Icon(Icons.logout),
                    label: const Text("Logout"),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.redAccent,
                    ),
                    onPressed: () async {
                      await FirebaseAuth.instance.signOut();
                      Get.offAllNamed('/login'); // Define this route
                    },
                  ),
                  const SizedBox(height: 10),
                  ElevatedButton.icon(
                    icon: const Icon(Icons.edit),
                    label: const Text("Update Info"),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.deepPurple,
                    ),
                    onPressed: () {
                      Get.toNamed('/update'); // Create this route & screen
                    },
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildInfoRow(String label, String? value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(flex: 3, child: Text(label)),
          Expanded(
            flex: 5,
            child: Text(value ?? '',
                style: const TextStyle(fontWeight: FontWeight.w500)),
          ),
        ],
      ),
    );
  }
}

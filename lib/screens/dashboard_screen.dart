import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:srscs/models/user_model.dart';
import 'package:srscs/services/firebase_service.dart';
import 'package:srscs/services/user_provider.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  late String uid;
  late UserModel user;

  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    uid = Provider.of<UserProvider>(context, listen: false).userId;
    _fetchUserData();
  }

  Future<UserModel> _fetchUserData() async {
    setState(() {
      _isLoading = true;
    });
    user = await FirebaseService().getUserData(uid);
    setState(() {
      _isLoading = false;
    });
    return user;
  }

  @override
  Widget build(BuildContext context) {
    return _isLoading
        ? const Center(child: CircularProgressIndicator())
        : Scaffold(
            appBar: AppBar(
              title: ClipOval(
                child: user.imageUrl == '' || user.imageUrl == null
                    ? const CircleAvatar(
                        radius: 20,
                        backgroundImage: NetworkImage(
                            'https://cdn-icons-png.flaticon.com/256/6522/6522516.png'),
                      )
                    : CircleAvatar(
                        radius: 20,
                        backgroundImage: NetworkImage(
                          user.imageUrl ?? '',
                        ),
                      ),
              ),
              actions: [
                IconButton(
                  icon: const Icon(Icons.notifications),
                  tooltip: 'Notifications',
                  onPressed: () {
                    // Handle notification button press
                  },
                ),
              ],
            ),
            body: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.start,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Text(
                    'Welcome to SRSCS ${user.lastName}',
                    style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 20),
                  Container(
                    width: double.infinity,
                    height: 600,
                    padding: EdgeInsets.all(16.0),
                    decoration: BoxDecoration(
                      color: Colors.red[100],
                      borderRadius: BorderRadius.all(Radius.circular(10)),
                    ),
                    child: Text(
                      'Recent Complaints',
                      textAlign: TextAlign.start,
                      style:
                          TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
            ),
            floatingActionButton: Padding(
              padding: const EdgeInsets.all(0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  //  Add Complaint Button
                  FloatingActionButton(
                    heroTag: 'add_complaint',
                    tooltip: 'Add Complaint',
                    onPressed: () {
                      // Navigator.push(
                      //   context,
                      //   MaterialPageRoute(
                      //   ),
                      // );
                    },
                    backgroundColor: Colors.grey[200],
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(50),
                    ),
                    child: const Icon(Icons.add),
                  ),
                  const SizedBox(height: 100),
                  // Live chat Button
                  FloatingActionButton(
                    heroTag: 'live_chat',
                    tooltip: 'Live Chat',
                    onPressed: () {
                      // Navigator.push(
                      //   context,
                      //   MaterialPageRoute(
                      //   ),
                      // );
                    },
                    backgroundColor: Colors.grey[200],
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(50),
                    ),
                    child: const Text(
                      'Live Chat',
                    ),
                  ),
                ],
              ),
            ),
          );
  }
}

// * หน้าโปรไฟล์ผู้ใช้
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'item_detail_screen.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'inbox_page.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  final User? user = FirebaseAuth.instance.currentUser;

  // ฟังก์ชันแสดง Popup ยืนยันการออกจากระบบ
  Future<void> _showLogoutConfirmation(BuildContext context) async {
    return showDialog<void>(
      context: context,
      barrierDismissible: true, // แตะที่ว่างเพื่อปิดได้
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: const Text(
            'ออกจากระบบ',
            style: TextStyle(
              fontFamily: 'Line Seed Sans TH',
              fontWeight: FontWeight.bold,
            ),
          ),
          content: const Text(
            'คุณแน่ใจหรือไม่ว่าต้องการออกจากระบบ?',
            style: TextStyle(fontFamily: 'Line Seed Sans TH'),
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15),
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('ยกเลิก', style: TextStyle(color: Colors.grey)),
              onPressed: () {
                Navigator.of(dialogContext).pop(); // ปิด Dialog
              },
            ),
            TextButton(
              child: const Text(
                'ยืนยัน',
                style: TextStyle(
                  color: Colors.red,
                  fontWeight: FontWeight.bold,
                ),
              ),
              onPressed: () async {
                Navigator.of(dialogContext).pop();

                try {
                  await GoogleSignIn().signOut();
                  await FirebaseAuth.instance.signOut();
                } catch (e) {
                  debugPrint('Error signing out: $e');
                }
              },
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    // ใช้รูปจาก Google Account (ถ้ามี)
    ImageProvider? imageProvider;
    if (user?.photoURL != null) {
      imageProvider = NetworkImage(user!.photoURL!);
    }

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Stack(
          children: [
            // Top Logout Icon
            Positioned(
              right: 20,
              top: 20,
              child: IconButton(
                icon: const Icon(Icons.logout, size: 30, color: Color(0xFF1E1E1E)),
                onPressed: () async {
                  _showLogoutConfirmation(context);
                },
              ),
            ),
            // Main Content
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 28),
              child: Column(
                children: [
                  const SizedBox(height: 40),
                  _buildProfileHeader(imageProvider),
                  const SizedBox(height: 24),
                  Expanded(
                    child: ListView(
                      physics: const BouncingScrollPhysics(),
                      children: [
                        _buildLevelSection(),
                        const SizedBox(height: 20),
                        _buildInboxSection(),
                        const SizedBox(height: 20),
                        // _buildLostItemsSection(),
                        const SizedBox(height: 100)
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileHeader(ImageProvider? imageProvider) {
    return Column(
      children: [
        CircleAvatar(
          radius: 80,
          backgroundColor: Colors.grey.shade300,
          backgroundImage: imageProvider,
          child: imageProvider == null
              ? const Icon(Icons.person, size: 80, color: Colors.white)
              : null,
        ),
        const SizedBox(height: 20),
        Text(
          user?.displayName ?? 'ผู้ใช้งานทั่วไป',
          style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        Text(
          user?.email ?? '-',
          style: const TextStyle(fontSize: 13, color: Colors.black),
        ),
      ],
    );
  }

  Widget _buildLevelSection() {
    return StreamBuilder<DocumentSnapshot>(
      stream: user != null
          ? FirebaseFirestore.instance.collection('users').doc(user!.uid).snapshots()
          : null,
      builder: (context, snapshot) {
        int points = 0;

        if (snapshot.hasData && snapshot.data != null && snapshot.data!.exists) {
          final data = snapshot.data!.data() as Map<String, dynamic>;
          points = data['points'] ?? 0;
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('ระดับ', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 14),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 13),
              decoration: BoxDecoration(
                border: Border.all(color: const Color(0xFF006C68)),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('แต้มสะสม (ปัจจุบัน)', style: const TextStyle(color: Color(0xFF005451), fontSize: 20, fontWeight: FontWeight.bold)),
                    ],
                  ),
                  Text('$points แต้ม', style: const TextStyle(color: Color(0xFF005451), fontSize: 20, fontWeight: FontWeight.bold)),
                ],
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildInboxSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('กล่องจดหมาย', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
        const SizedBox(height: 14),
        SizedBox(
          width: double.infinity,
          height: 39,
          child: ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF005451),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            onPressed: () {
              Navigator.push(
                context, 
                MaterialPageRoute(builder: (context) => const InboxPage()),
              );
            },
            child: const Text('เปิด', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        ),
      ],
    );
  }

  /*
  Widget _buildLostItemsSection() { ... }
  */
  
  String _getTimeAgo(Timestamp? timestamp) {
    if (timestamp == null) return '-';
    final dt = timestamp.toDate();
    final diff = DateTime.now().difference(dt);
    if (diff.inMinutes < 60) return '${diff.inMinutes} mins ago';
    if (diff.inHours < 24) return '${diff.inHours} hours ago';
    return '${diff.inDays} days ago';
  }

  Widget _buildLostItemCard(Map<String, dynamic> data) {
    final title = data['title'] ?? 'ไม่ระบุชื่อ';
    final description = data['description'] ?? '';
    final timestamp = data['date'] as Timestamp?;
    final String status = data['status'] ?? 'lost';
    final bool isLost = status == 'lost';
    final List<dynamic> images = data['images'] ?? [];

    Widget imageWidget;
    if (images.isNotEmpty && images.first.toString().startsWith('http')) {
      imageWidget = Image.network(
        images.first,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) {
          return Container(
            color: Colors.grey[200],
            child: const Icon(Icons.broken_image, color: Colors.grey),
          );
        },
      );
    } else {
      imageWidget = Image.asset(
        'assets/No_Image_Available.png',
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) {
          return Container(
            color: Colors.grey[200],
            child: const Icon(Icons.image_not_supported, color: Colors.grey),
          );
        },
      );
    }

    return InkWell(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => ItemDetailScreen(data: data)),
        );
      },
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Thumbnail
          Container(
            width: 90,
            height: 90,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8),
              color: Colors.grey[200],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: imageWidget,
            ),
          ),
          const SizedBox(width: 12),
          // Details
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isLost ? 'ตามหา: $title' : 'พบ: $title',
                  style: const TextStyle(
                    fontFamily: 'Line Seed Sans TH',
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  description,
                  style: const TextStyle(
                    fontFamily: 'Line Seed Sans TH',
                    fontSize: 12,
                    color: Color(0xFF757575),
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      _getTimeAgo(timestamp),
                      style: const TextStyle(
                          fontSize: 10, color: Color(0xFFB3B3B3)),
                    ),
                    Text(
                      'รายละเอียด >',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: isLost
                            ? const Color(0xFF006C68)
                            : Colors.orange.shade800,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
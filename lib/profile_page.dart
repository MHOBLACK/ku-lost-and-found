// * หน้าโปรไฟล์ผู้ใช้
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'item_detail_screen.dart';
import 'package:image_picker/image_picker.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'inbox_page.dart'; // <-- เพิ่มบรรทัดนี้
// import 'package:camera/camera.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  File? _imageFile;
  final ImagePicker _picker = ImagePicker();
  final User? user = FirebaseAuth.instance.currentUser;

  // ฟังก์ชันเลือกภาพ (จากโค้ดของคุณ)
  Future<void> _pickImage(ImageSource source) async {
    try {
      final XFile? pickedFile = await _picker.pickImage(
        source: source,
        imageQuality: 80,
        maxWidth: 1024,
      );
      if (pickedFile != null) {
        setState(() {
          _imageFile = File(pickedFile.path);
        });
      }
    } catch (e) {
      debugPrint('Error picking image: $e');
    }
  }

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

  // แสดง BottomSheet เลือกแหล่งรูปภาพ
  void _showImageSourceActionSheet() {
    showModalBottomSheet(
      context: context,
      builder: (_) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.photo_library),
              title: const Text('เลือกจาก Gallery'),
              onTap: () {
                Navigator.pop(context);
                _pickImage(ImageSource.gallery);
              },
            ),
            ListTile(
              leading: const Icon(Icons.camera_alt),
              title: const Text('ถ่ายภาพ'),
              onTap: () {
                Navigator.pop(context);
                _pickImage(ImageSource.camera);
              },
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // ตรวจสอบว่าจะใช้รูปจากไหน: รูปที่เลือกใหม่ -> รูปจาก Google -> หรือไอคอนว่าง
    ImageProvider? imageProvider;
    if (_imageFile != null) {
      imageProvider = FileImage(_imageFile!);
    } else if (user?.photoURL != null) {
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
        GestureDetector(
          onTap: _showImageSourceActionSheet,
          child: Stack(
            children: [
              CircleAvatar(
                radius: 80,
                backgroundColor: Colors.grey.shade300,
                backgroundImage: imageProvider,
                child: imageProvider == null
                    ? const Icon(Icons.person, size: 80, color: Colors.white)
                    : null,
              ),
              Positioned(
                bottom: 0,
                right: 0,
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: const BoxDecoration(
                    color: Color(0xFF006C68),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.camera_alt,
                    color: Colors.white,
                    size: 24,
                  ),
                ),
              ),
            ],
          ),
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
        // int level = 1;
        int points = 0;

        if (snapshot.hasData && snapshot.data != null && snapshot.data!.exists) {
          final data = snapshot.data!.data() as Map<String, dynamic>;
          // level = data['level'] ?? 1;
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

  Widget _buildLostItemsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('รายการแจ้งของฉัน',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
        const SizedBox(height: 19),
        if (user != null)
          StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance.collection('items').where('uid', isEqualTo: user!.uid).snapshots(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              if (snapshot.hasError) {
                return Center(child: Text('เกิดข้อผิดพลาด: ${snapshot.error}'));
              }
              if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                return const Center(
                    child: Padding(
                  padding: EdgeInsets.all(20.0),
                  child: Text('คุณยังไม่มีรายการแจ้งของ'),
                ));
              }

              final docs = snapshot.data!.docs;

              // Sort documents by date on the client-side (newest first)
              docs.sort((a, b) {
                final dataA = a.data() as Map<String, dynamic>;
                final dataB = b.data() as Map<String, dynamic>;
                final Timestamp? dateA = dataA['date'];
                final Timestamp? dateB = dataB['date'];
                if (dateA == null || dateB == null) return 0;
                return dateB.compareTo(dateA); // descending
              });

              return ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: docs.length,
                separatorBuilder: (context, index) =>
                    const Divider(height: 24, color: Color(0xFFEEEEEE)),
                itemBuilder: (context, index) {
                  final data = docs[index].data() as Map<String, dynamic>;
                  data['id'] = docs[index].id;
                  return _buildLostItemCard(data);
                },
              );
            },
          ),
        const SizedBox(height: 19),
        OutlinedButton(
          style: OutlinedButton.styleFrom(
            minimumSize: const Size(double.infinity, 39),
            side: const BorderSide(color: Color(0xFF006C68)),
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
          onPressed: () {},
          child: const Text('แสดงรายการทั้งหมด', style: TextStyle(color: Color(0xFF006C68), fontWeight: FontWeight.bold)),
        ),
      ],
    );
  }

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
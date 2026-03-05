// * หน้าโปรไฟล์ผู้ใช้
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:image_picker/image_picker.dart';
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
                  await FirebaseAuth.instance.signOut();
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
                        _buildLostItemsSection(),
                        const SizedBox(height: 100), // Space for Bottom Nav
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
                children: const [
                  Text('เลเวล 1', style: TextStyle(color: Color(0xFF005451), fontSize: 20, fontWeight: FontWeight.bold)),
                  Text('นักหาของสมัครเล่น', style: TextStyle(color: Color(0xFFB3B3B3), fontSize: 12)),
                ],
              ),
              const Text('0 แต้ม', style: TextStyle(color: Color(0xFF005451), fontSize: 20, fontWeight: FontWeight.bold)),
            ],
          ),
        ),
      ],
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
            onPressed: () {},
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
        const Text('รายการแจ้งของหาย', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
        const SizedBox(height: 19),
        _buildLostItemCard(),
        const SizedBox(height: 10),
        _buildLostItemCard(),
        const SizedBox(height: 19),
        OutlinedButton(
          style: OutlinedButton.styleFrom(
            minimumSize: const Size(double.infinity, 39),
            side: const BorderSide(color: Color(0xFF006C68)),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
          onPressed: () {},
          child: const Text('แสดงรายการทั้งหมด', style: TextStyle(color: Color(0xFF006C68), fontWeight: FontWeight.bold)),
        ),
      ],
    );
  }

  Widget _buildLostItemCard() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 100,
          height: 80,
          decoration: BoxDecoration(
            color: Colors.grey[200],
            // image: const DecorationImage(image: AssetImage('assets/checker.png'), fit: BoxFit.cover),
          ),
          child: const Icon(Icons.image, color: Colors.grey),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Lorem ipsum dolor sit amet consectetur adipiscing elit. Quisque faucibus ex sapien vitae pellentesque...',
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(fontSize: 10, color: Color(0xFF757575), height: 1.5),
              ),
              const SizedBox(height: 10),
              Row(
                children: const [
                  Text('สถานะ: Status', style: TextStyle(fontSize: 12, color: Color(0xFFB3B3B3))),
                  SizedBox(width: 10),
                  Text('วันที่แจ้ง: dd/MM/yyyy', style: TextStyle(fontSize: 12, color: Color(0xFFB3B3B3))),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }
}
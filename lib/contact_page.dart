import 'dart:io';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;

class ContactPage extends StatefulWidget {
  final Map<String, dynamic>
  itemData; // รับข้อมูลโพสต์มาเพื่อจะได้รู้ว่าส่งหาใคร

  const ContactPage({super.key, required this.itemData});

  @override
  State<ContactPage> createState() => _ContactPageState();
}

class _ContactPageState extends State<ContactPage> {
  final TextEditingController _messageController = TextEditingController();
  final TextEditingController _contactInfoController = TextEditingController();
  final ImagePicker _picker = ImagePicker();
  List<File> _imageFiles = [];
  bool _isSubmitting = false;
  String _uploadStatus = '';

  // ฟังก์ชันเลือกรูป
  Future<void> _pickImages() async {
    final List<XFile> selectedImages = await _picker.pickMultiImage();
    if (selectedImages.isNotEmpty) {
      setState(() {
        _imageFiles.addAll(selectedImages.map((e) => File(e.path)));
      });
    }
  }

  // ฟังก์ชันอัปโหลดรูปไป Cloudinary
  Future<List<String>> _uploadImagesToCloud() async {
    List<String> uploadedUrls = [];
    String cloudName = "dq7hiqpfh"; // เปลี่ยนเป็นของตนเอง
    String uploadPreset = "ku-lost-and-found"; // เปลี่ยนเป็นของตนเอง

    for (int i = 0; i < _imageFiles.length; i++) {
      setState(
        () =>
            _uploadStatus =
                'กำลังอัปโหลดรูปที่ ${i + 1}/${_imageFiles.length}...',
      );
      try {
        var uri = Uri.parse(
          'https://api.cloudinary.com/v1_1/$cloudName/image/upload',
        );
        var request = http.MultipartRequest('POST', uri);
        request.fields['upload_preset'] = uploadPreset;
        request.files.add(
          await http.MultipartFile.fromPath('file', _imageFiles[i].path),
        );

        var response = await request.send();
        if (response.statusCode == 200) {
          var responseData = await response.stream.toBytes();
          var result = json.decode(String.fromCharCodes(responseData));
          uploadedUrls.add(result['secure_url']);
        }
      } catch (e) {
        debugPrint('Upload error: $e');
      }
    }
    return uploadedUrls;
  }

  // ฟังก์ชันส่งข้อความ
  Future<void> _sendMessage() async {
    if (_contactInfoController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('กรุณาระบุช่องทางการติดต่อของคุณ')),
      );
      return;
    }
    if (_messageController.text.trim().isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('กรุณากรอกคำอธิบาย')));
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      List<String> imageUrls = [];
      if (_imageFiles.isNotEmpty) {
        imageUrls = await _uploadImagesToCloud();
      }

      final currentUser = FirebaseAuth.instance.currentUser;

      // บันทึกข้อมูลลงใน Collection 'inbox' (กล่องจดหมาย)
      await FirebaseFirestore.instance.collection('inbox').add({
        'itemId': widget.itemData['id'], // ID ของของชิ้นนั้น
        'itemTitle': widget.itemData['title'], // ชื่อของ
        'receiverId': widget.itemData['uid'], // ส่งหาใคร (เจ้าของโพสต์)
        'receiverName': widget.itemData['displayName'] ?? 'เจ้าของโพสต์',
        'senderId': currentUser?.uid, // ใครเป็นคนส่ง
        'senderName': currentUser?.displayName ?? 'ไม่ระบุชื่อ',
        'contactInfo': _contactInfoController.text.trim(),
        'message': _messageController.text.trim(), // คำอธิบายที่พิมพ์
        'images': imageUrls, // รูปภาพหลักฐาน
        'timestamp': FieldValue.serverTimestamp(),
        'isRead': false, // สถานะการอ่าน
        'type':
            widget.itemData['status'] == 'lost'
                ? 'found_it'
                : 'mine', // ประเภทการติดต่อ
      });

      await FirebaseFirestore.instance
          .collection('items')
          .doc(widget.itemData['id'])
          .update({
            'progress': 'pending',
            'current_finder_id': currentUser?.uid,
          });

      if (mounted) {
        Navigator.pop(context); // ปิดหน้าต่าง
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('ส่งข้อความสำเร็จ!')));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('เกิดข้อผิดพลาด: $e')));
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
          _uploadStatus = '';
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final String status = widget.itemData['status'] ?? 'lost';
    final String title =
        status == 'found' ? 'ยืนยันความเป็นเจ้าของ' : 'แจ้งรายละเอียดการพบของ';

    return Scaffold(
      appBar: AppBar(
        title: Text(
          title,
          style: const TextStyle(fontFamily: 'Line Seed Sans TH'),
        ),
        backgroundColor: const Color(0xFF006C68),
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'ติดต่อเรื่อง: ${widget.itemData['title']}',
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),

            const Text(
              'ช่องทางการติดต่อของคุณ:',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _contactInfoController,
              decoration: const InputDecoration(
                hintText: 'เบอร์โทรศัพท์, Line ID, FB ฯลฯ',
                border: OutlineInputBorder(),
                prefixIcon: Icon(
                  Icons.contact_phone_outlined,
                  color: Color(0xFF006C68),
                ),
              ),
            ),
            const SizedBox(height: 20),

            const Text(
              'คำอธิบายเพิ่มเติม / จุดสังเกต:',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _messageController,
              maxLines: 4,
              decoration: const InputDecoration(
                hintText: 'พิมพ์รายละเอียดที่นี่...',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 20),

            // รูปภาพ
            const Text(
              'แนบรูปภาพหลักฐาน (ถ้ามี):',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            OutlinedButton.icon(
              onPressed: _pickImages,
              icon: const Icon(
                Icons.add_photo_alternate,
                color: Color(0xFF006C68),
              ),
              label: const Text(
                'เพิ่มรูปภาพ',
                style: TextStyle(color: Color(0xFF006C68)),
              ),
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: Color(0xFF006C68)),
              ),
            ),
            const SizedBox(height: 10),

            if (_imageFiles.isNotEmpty)
              SizedBox(
                height: 100,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: _imageFiles.length,
                  itemBuilder: (context, index) {
                    return Stack(
                      children: [
                        Container(
                          margin: const EdgeInsets.only(right: 10),
                          width: 100,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(8),
                            image: DecorationImage(
                              image: FileImage(_imageFiles[index]),
                              fit: BoxFit.cover,
                            ),
                          ),
                        ),
                        Positioned(
                          top: 0,
                          right: 10,
                          child: GestureDetector(
                            onTap:
                                () =>
                                    setState(() => _imageFiles.removeAt(index)),
                            child: Container(
                              color: Colors.black54,
                              child: const Icon(
                                Icons.close,
                                color: Colors.white,
                                size: 20,
                              ),
                            ),
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ),

            const SizedBox(height: 30),

            // ปุ่มส่ง
            if (_uploadStatus.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Text(
                  _uploadStatus,
                  style: const TextStyle(color: Colors.orange),
                ),
              ),

            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: _isSubmitting ? null : _sendMessage,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF006C68),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                child:
                    _isSubmitting
                        ? const CircularProgressIndicator(color: Colors.white)
                        : const Text(
                          'ส่งข้อมูล',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

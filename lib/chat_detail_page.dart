import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ChatDetailPage extends StatelessWidget {
  final String chatRoomId;

  const ChatDetailPage({super.key, required this.chatRoomId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('รายละเอียดแชท', style: TextStyle(fontFamily: 'Line Seed Sans TH')),
        backgroundColor: const Color(0xFF006C68),
        foregroundColor: Colors.white,
      ),
      body: FutureBuilder<DocumentSnapshot>(
        future: FirebaseFirestore.instance.collection('chats').doc(chatRoomId).get(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError || !snapshot.hasData || !snapshot.data!.exists) {
            return const Center(child: Text('ไม่พบข้อมูลแชท'));
          }

          final data = snapshot.data!.data() as Map<String, dynamic>;
          final String ownerId = data['ownerId'] ?? '';
          final String visitorId = data['visitorId'] ?? '';
          final String itemId = data['itemId'] ?? '';
          
          final currentUser = FirebaseAuth.instance.currentUser;
          final bool isOwner = currentUser != null && currentUser.uid == ownerId;

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildActionSection(context, isOwner, itemId, ownerId, visitorId),
                const SizedBox(height: 24),
                const Divider(),
                const SizedBox(height: 24),
                _buildLogSection(itemId, ownerId, visitorId),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildActionSection(BuildContext context, bool isOwner, String itemId, String ownerId, String visitorId) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'การจัดการ',
          style: TextStyle(
            fontFamily: 'Line Seed Sans TH',
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        if (isOwner)
          SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton.icon(
              onPressed: () => _markAsSolved(context, itemId),
              icon: const Icon(Icons.check_circle_outline),
              label: const Text('ปิดงาน / ทำเครื่องหมายว่าจบแล้ว'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF006C68),
                foregroundColor: Colors.white,
              ),
            ),
          )
        else
          SizedBox(
            width: double.infinity,
            height: 50,
            child: OutlinedButton.icon(
              onPressed: () => _askOwnerToSolve(context),
              icon: const Icon(Icons.notifications_active_outlined),
              label: const Text('แจ้งเจ้าของโพสต์ให้ปิดงาน'),
              style: OutlinedButton.styleFrom(
                foregroundColor: const Color(0xFF006C68),
                side: const BorderSide(color: Color(0xFF006C68)),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildLogSection(String itemId, String ownerId, String visitorId) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'ข้อมูลระบบ (Log)',
          style: TextStyle(
            fontFamily: 'Line Seed Sans TH',
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        _buildInfoTile('Chat ID', chatRoomId),
        _buildInfoTile('Item ID', itemId),
        _buildInfoTile('Owner UID', ownerId),
        _buildInfoTile('Visitor UID', visitorId),
        FutureBuilder<AggregateQuerySnapshot>(
          future: FirebaseFirestore.instance
              .collection('chats')
              .doc(chatRoomId)
              .collection('messages')
              .count()
              .get(),
          builder: (context, snapshot) {
             String count = '...';
             if (snapshot.hasData) {
               count = snapshot.data!.count.toString();
             }
             return _buildInfoTile('Message Count', count);
          },
        ),
      ],
    );
  }

  Widget _buildInfoTile(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: const TextStyle(
                fontFamily: 'Line Seed Sans TH',
                color: Colors.grey,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontFamily: 'Line Seed Sans TH',
                fontSize: 13,
                color: Color(0xFF333333),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _markAsSolved(BuildContext context, String itemId) async {
    try {
      // Mark item as solved in Firestore
      await FirebaseFirestore.instance.collection('items').doc(itemId).update({
        'status': 'solved',
      });
      if (context.mounted) {
         ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('ปิดงานเรียบร้อยแล้ว')));
         Navigator.pop(context);
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('เกิดข้อผิดพลาด: $e')));
      }
    }
  }

  Future<void> _askOwnerToSolve(BuildContext context) async {
    try {
      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser == null) return;
      
      final String msg = '🔔 ผู้ใช้ต้องการยืนยันว่าภารกิจเสร็จสิ้น (ได้รับของ/คืนของแล้ว) โปรดตรวจสอบและกด "ปิดงาน"';
      
      // Send a text message to the chat
      await FirebaseFirestore.instance
          .collection('chats')
          .doc(chatRoomId)
          .collection('messages')
          .add({
        'senderId': currentUser.uid,
        'text': msg,
        'timestamp': FieldValue.serverTimestamp(),
      });
       
      // Update last message
      await FirebaseFirestore.instance
        .collection('chats')
        .doc(chatRoomId)
        .set({
      'lastMessage': '🔔 แจ้งเตือนปิดงาน',
      'lastMessageTime': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      if (context.mounted) {
         ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('ส่งแจ้งเตือนให้เจ้าของโพสต์แล้ว')));
         Navigator.pop(context);
      }
    } catch (e) {
       if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('เกิดข้อผิดพลาด: $e')));
      }
    }
  }
}

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'message_detail_page.dart';

class InboxPage extends StatelessWidget {
  const InboxPage({super.key});

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'กล่องข้อความ',
          style: TextStyle(fontFamily: 'Line Seed Sans TH'),
        ),
        backgroundColor: const Color(0xFF006C68),
        foregroundColor: Colors.white,
      ),
      backgroundColor: Colors.white,
      body:
          user == null
              ? const Center(
                child: Text(
                  'กรุณาเข้าสู่ระบบ',
                  style: TextStyle(fontFamily: 'Line Seed Sans TH'),
                ),
              )
              : StreamBuilder<QuerySnapshot>(
                // ใช้ Filter.or เพื่อดึงทั้งข้อความที่เราเป็นคนส่ง และข้อความที่เราเป็นคนรับ
                stream:
                    FirebaseFirestore.instance
                        .collection('inbox')
                        .where(
                          Filter.or(
                            Filter('receiverId', isEqualTo: user.uid),
                            Filter('senderId', isEqualTo: user.uid),
                          ),
                        )
                        .orderBy('timestamp', descending: true)
                        .snapshots(),
                builder: (context, snapshot) {
                  if (snapshot.hasError) {
                    return Center(
                      child: Text(
                        'Error: ${snapshot.error}',
                        style: const TextStyle(fontFamily: 'Line Seed Sans TH'),
                      ),
                    );
                  }
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(
                      child: CircularProgressIndicator(
                        color: Color(0xFF006C68),
                      ),
                    );
                  }

                  final docs = snapshot.data?.docs ?? [];
                  if (docs.isEmpty) {
                    return const Center(
                      child: Text(
                        'ไม่มีข้อความที่เกี่ยวข้องกับคุณ',
                        style: TextStyle(
                          fontFamily: 'Line Seed Sans TH',
                          fontSize: 16,
                          color: Colors.grey,
                        ),
                      ),
                    );
                  }

                  return ListView.separated(
                    itemCount: docs.length,
                    separatorBuilder:
                        (context, index) =>
                            const Divider(height: 1, color: Color(0xFFEEEEEE)),
                    itemBuilder: (context, index) {
                      final data = docs[index].data() as Map<String, dynamic>;
                      final docId = docs[index].id;
                      final isRead = data['isRead'] ?? false;
                      final timestamp = data['timestamp'] as Timestamp?;

                      // เช็กว่าเป็นข้อความที่เราได้รับ (เราคือคนรับ) ใช่หรือไม่
                      final bool isReceived = data['receiverId'] == user.uid;

                      return ListTile(
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 8,
                        ),
                        // ไฮไลท์พื้นหลังถ้าเป็นข้อความเข้าและยังไม่ได้อ่าน
                        tileColor:
                            (isReceived && !isRead)
                                ? const Color(0xFFE0F2F1)
                                : Colors.white,
                        leading: CircleAvatar(
                          backgroundColor:
                              isReceived
                                  ? (isRead
                                      ? Colors.grey.shade300
                                      : const Color(0xFF006C68))
                                  : Colors
                                      .blue
                                      .shade50, // สีฟ้าอ่อนสำหรับข้อความที่เราส่งออก
                          child: Icon(
                            isReceived ? Icons.mail : Icons.send,
                            color:
                                isReceived
                                    ? (isRead
                                        ? Colors.grey.shade600
                                        : Colors.white)
                                    : Colors.blue.shade400,
                          ),
                        ),
                        title: Text(
                          'เรื่อง: ${data['itemTitle'] ?? ''}',
                          style: TextStyle(
                            fontFamily: 'Line Seed Sans TH',
                            fontWeight:
                                (isReceived && !isRead)
                                    ? FontWeight.bold
                                    : FontWeight.normal,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        subtitle: Text(
                          isReceived
                              ? 'จาก: ${data['senderName'] ?? 'ไม่ระบุชื่อ'}'
                              : 'สถานะ: คุณส่งข้อความนี้', // ถ้าเราเป็นคนส่ง
                          style: const TextStyle(
                            fontFamily: 'Line Seed Sans TH',
                            color: Color(0xFF757575),
                          ),
                        ),
                        trailing: Text(
                          _formatTime(timestamp),
                          style: const TextStyle(
                            fontSize: 12,
                            color: Colors.grey,
                            fontFamily: 'Line Seed Sans TH',
                          ),
                        ),
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder:
                                  (context) => MessageDetailPage(
                                    messageData: data,
                                    messageId: docId,
                                  ),
                            ),
                          );
                        },
                      );
                    },
                  );
                },
              ),
    );
  }

  String _formatTime(Timestamp? timestamp) {
    if (timestamp == null) return '';
    final dt = timestamp.toDate();
    return '${dt.day.toString().padLeft(2, '0')}/${dt.month.toString().padLeft(2, '0')}/${dt.year}';
  }
}

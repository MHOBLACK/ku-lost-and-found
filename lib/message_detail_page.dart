import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class MessageDetailPage extends StatefulWidget {
  final Map<String, dynamic> messageData;
  final String messageId;

  const MessageDetailPage({
    super.key,
    required this.messageData,
    required this.messageId,
  });

  @override
  State<MessageDetailPage> createState() => _MessageDetailPageState();
}

class _MessageDetailPageState extends State<MessageDetailPage> {
  @override
  void initState() {
    super.initState();
    final user = FirebaseAuth.instance.currentUser;

    // เปลี่ยนสถานะเป็น "อ่านแล้ว" ก็ต่อเมื่อ "เราคือผู้รับ" เท่านั้น
    if (widget.messageData['isRead'] == false &&
        widget.messageData['receiverId'] == user?.uid) {
      FirebaseFirestore.instance
          .collection('inbox')
          .doc(widget.messageId)
          .update({'isRead': true});
    }
  }

  // ฟังก์ชันแสดงหน้าต่างให้แต้ม
  Future<void> _showRatingDialog(
    BuildContext context,
    String itemId,
    String finderId,
  ) async {
    int rating = 5; // ค่าเริ่มต้น
    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: const Text(
                'ได้รับของแล้ว!',
                style: TextStyle(
                  fontFamily: 'Line Seed Sans TH',
                  fontWeight: FontWeight.bold,
                ),
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    'โปรดมอบแต้มตอบแทนให้ผู้ที่เจอของ (1-5 แต้ม)',
                    style: TextStyle(fontFamily: 'Line Seed Sans TH'),
                  ),
                  const SizedBox(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(5, (index) {
                      int starValue = index + 1;
                      return IconButton(
                        icon: Icon(
                          starValue <= rating ? Icons.star : Icons.star_border,
                          color: Colors.amber,
                          size: 36,
                        ),
                        onPressed: () {
                          setState(() => rating = starValue);
                        },
                      );
                    }),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(dialogContext),
                  child: const Text(
                    'ยกเลิก',
                    style: TextStyle(
                      color: Colors.grey,
                      fontFamily: 'Line Seed Sans TH',
                    ),
                  ),
                ),
                TextButton(
                  onPressed: () async {
                    Navigator.pop(dialogContext); // ปิด Dialog

                    if (finderId.isNotEmpty) {
                      await FirebaseFirestore.instance
                          .collection('users')
                          .doc(finderId)
                          .update({'points': FieldValue.increment(rating)});
                    }

                    await FirebaseFirestore.instance
                        .collection('items')
                        .doc(itemId)
                        .update({'progress': 'completed'});

                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('มอบแต้มและเสร็จสิ้นรายการเรียบร้อย!'),
                        ),
                      );
                    }
                  },
                  child: const Text(
                    'ยืนยันการให้แต้ม',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF006C68),
                      fontFamily: 'Line Seed Sans TH',
                    ),
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final data = widget.messageData;
    final List<dynamic> images = data['images'] ?? [];

    final String senderName = data['senderName'] ?? 'ไม่ระบุชื่อ';
    final String receiverName = data['receiverName'] ?? 'ไม่ระบุชื่อ';
    final String contactInfo = data['contactInfo'] ?? 'ไม่ได้ระบุ';

    final user = FirebaseAuth.instance.currentUser;
    final bool isReceived = data['receiverId'] == user?.uid;

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'รายละเอียดข้อความ',
          style: TextStyle(fontFamily: 'Line Seed Sans TH'),
        ),
        backgroundColor: const Color(0xFF006C68),
        foregroundColor: Colors.white,
      ),
      backgroundColor: Colors.white,
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'เรื่อง: ${data['itemTitle'] ?? ''}',
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                fontFamily: 'Line Seed Sans TH',
              ),
            ),
            const SizedBox(height: 15),

            // กล่องแสดงผู้รับ ผู้ส่ง และช่องทางการติดต่อ
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFFF5F5F5),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: const Color(0xFFEEEEEE)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment:
                        CrossAxisAlignment
                            .start, // ปรับให้อยู่ด้านบนเวลาข้อความขึ้นบรรทัดใหม่
                    children: [
                      const Padding(
                        padding: EdgeInsets.only(
                          top: 2.0,
                        ), // ดันไอคอนลงมานิดหน่อยให้ตรงกับบรรทัดแรก
                        child: Icon(Icons.person, size: 18, color: Colors.grey),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        // เพิ่ม Expanded ครอบ Text ไว้
                        child: Text(
                          'ผู้ส่ง: $senderName',
                          style: TextStyle(
                            fontSize: 14,
                            color:
                                isReceived
                                    ? const Color(0xFF006C68)
                                    : Colors.blue.shade700,
                            fontWeight: FontWeight.bold,
                            fontFamily: 'Line Seed Sans TH',
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    crossAxisAlignment:
                        CrossAxisAlignment
                            .start, // ปรับให้อยู่ด้านบนเวลาข้อความขึ้นบรรทัดใหม่
                    children: [
                      const Padding(
                        padding: EdgeInsets.only(top: 2.0),
                        child: Icon(
                          Icons.person_outline,
                          size: 18,
                          color: Colors.grey,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        // เพิ่ม Expanded ครอบ Text ไว้
                        child: Text(
                          'ผู้รับ: $receiverName',
                          style: const TextStyle(
                            fontSize: 14,
                            fontFamily: 'Line Seed Sans TH',
                          ),
                        ),
                      ),
                    ],
                  ),
                  const Divider(height: 20, color: Color(0xFFDDDDDD)),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Padding(
                        padding: EdgeInsets.only(top: 2.0),
                        child: Icon(
                          Icons.phone_in_talk,
                          size: 18,
                          color: Color(0xFF006C68),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'ช่องทางการติดต่อ: $contactInfo',
                          style: const TextStyle(
                            fontSize: 14,
                            color: Color(0xFF006C68),
                            fontWeight: FontWeight.bold,
                            fontFamily: 'Line Seed Sans TH',
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 25),
            const Text(
              'รายละเอียด / จุดสังเกต:',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                fontFamily: 'Line Seed Sans TH',
              ),
            ),
            const SizedBox(height: 10),
            Text(
              data['message'] ?? '-',
              style: const TextStyle(
                fontSize: 16,
                fontFamily: 'Line Seed Sans TH',
                color: Color(0xFF4A4A4A),
              ),
            ),
            const SizedBox(height: 30),

            // รูปภาพหลักฐาน
            if (images.isNotEmpty) ...[
              const Divider(height: 40, thickness: 1, color: Color(0xFFEEEEEE)),
              const Text(
                'รูปภาพหลักฐาน:',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  fontFamily: 'Line Seed Sans TH',
                ),
              ),
              const SizedBox(height: 15),
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: images.length,
                itemBuilder: (context, index) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 15),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(10),
                      child: Image.network(
                        images[index].toString(),
                        fit: BoxFit.cover,
                      ),
                    ),
                  );
                },
              ),
            ],

            // ใช้ StreamBuilder คอยฟังการเปลี่ยนแปลงของโพสต์หลัก
            StreamBuilder<DocumentSnapshot>(
              stream:
                  FirebaseFirestore.instance
                      .collection('items')
                      .doc(data['itemId'])
                      .snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData || !snapshot.data!.exists)
                  return const SizedBox.shrink();

                final itemData = snapshot.data!.data() as Map<String, dynamic>;
                final String progress = itemData['progress'] ?? '';
                final String finderId = itemData['finderId'] ?? '';
                final bool hasReplied = data['hasReplied'] ?? false;

                // ถ้าเป็นข้อความแจ้งพบของหาย และเราคือผู้รับ (เจ้าของ)
                if (isReceived && data['type'] == 'found_it') {
                  // 1. ยังไม่ได้ตอบ และสถานะโพสต์ขึ้น Pending -> โชว์ปุ่มยืนยัน ใช่/ไม่ใช่
                  if (!hasReplied && progress == 'pending') {
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 30),
                        const Divider(height: 1, color: Color(0xFFEEEEEE)),
                        const SizedBox(height: 20),
                        const Text(
                          'การยืนยันของหาย',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            fontFamily: 'Line Seed Sans TH',
                          ),
                        ),
                        const SizedBox(height: 15),
                        Row(
                          children: [
                            Expanded(
                              child: ElevatedButton(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFF006C68),
                                ),
                                onPressed: () async {
                                  // ยืนยันว่าคนนี้เจอจริง
                                  await FirebaseFirestore.instance
                                      .collection('items')
                                      .doc(data['itemId'])
                                      .update({
                                        'progress': 'founded',
                                        'finderId': data['senderId'],
                                      });
                                  await FirebaseFirestore.instance
                                      .collection('inbox')
                                      .doc(widget.messageId)
                                      .update({'hasReplied': true});
                                  setState(() {
                                    data['hasReplied'] = true;
                                  }); // อัปเดต UI ทันที
                                  if (context.mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text(
                                          'ยืนยันสิ่งของเรียบร้อยแล้ว',
                                        ),
                                      ),
                                    );
                                  }
                                },
                                child: const Text(
                                  'ใช่ นี่คือของฉัน',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontFamily: 'Line Seed Sans TH',
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: OutlinedButton(
                                style: OutlinedButton.styleFrom(
                                  side: const BorderSide(color: Colors.red),
                                ),
                                onPressed: () async {
                                  // ปฏิเสธ ปล่อยโพสต์ว่าง
                                  await FirebaseFirestore.instance
                                      .collection('items')
                                      .doc(data['itemId'])
                                      .update({
                                        'progress': '',
                                        'current_finder_id':
                                            FieldValue.delete(),
                                      });
                                  await FirebaseFirestore.instance
                                      .collection('inbox')
                                      .doc(widget.messageId)
                                      .update({'hasReplied': true});
                                  setState(() {
                                    data['hasReplied'] = true;
                                  }); // อัปเดต UI ทันที
                                  if (context.mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text(
                                          'ปฏิเสธสิ่งของเรียบร้อยแล้ว',
                                        ),
                                      ),
                                    );
                                  }
                                },
                                child: const Text(
                                  'ไม่ใช่ ของฉัน',
                                  style: TextStyle(
                                    color: Colors.red,
                                    fontFamily: 'Line Seed Sans TH',
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    );
                  }
                  // 2. สถานะยืนยันแล้ว และข้อความนี้มาจากคนเจอตัวจริง -> โชว์ปุ่มรับของ
                  else if (progress == 'founded' &&
                      finderId == data['senderId']) {
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 30),
                        const Divider(height: 1, color: Color(0xFFEEEEEE)),
                        const SizedBox(height: 20),
                        SizedBox(
                          width: double.infinity,
                          height: 45,
                          child: ElevatedButton(
                            onPressed:
                                () => _showRatingDialog(
                                  context,
                                  data['itemId'],
                                  finderId,
                                ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.green,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                              elevation: 0,
                            ),
                            child: const Text(
                              'ฉันได้รับของคืนแล้ว',
                              style: TextStyle(
                                fontFamily: 'Line Seed Sans TH',
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ),
                      ],
                    );
                  }
                  // 3. รับของเรียบร้อย -> ขึ้นข้อความติ๊กถูก
                  else if (progress == 'completed' &&
                      finderId == data['senderId']) {
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 30),
                        const Divider(height: 1, color: Color(0xFFEEEEEE)),
                        const SizedBox(height: 20),
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.green.shade50,
                            border: Border.all(color: Colors.green.shade200),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Text(
                            '✅ รายการนี้เสร็จสิ้นและได้รับของคืนเรียบร้อยแล้ว',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: Colors.green,
                              fontWeight: FontWeight.bold,
                              fontFamily: 'Line Seed Sans TH',
                            ),
                          ),
                        ),
                      ],
                    );
                  }
                  // 4. ถ้าตอบกลับแล้ว แต่คนนี้ไม่ใช่คนเจอตัวจริง (เช่น ปฏิเสธไปแล้ว)
                  else if (hasReplied) {
                    return const Padding(
                      padding: EdgeInsets.only(top: 30),
                      child: Center(
                        child: Text(
                          'คุณได้ทำการตรวจสอบและตอบกลับข้อความนี้ไปแล้ว',
                          style: TextStyle(
                            color: Colors.grey,
                            fontFamily: 'Line Seed Sans TH',
                          ),
                        ),
                      ),
                    );
                  }
                }

                if (data['type'] == 'mine') {
                  // 1. เจ้าของโพสต์ (คนเจอของ) กดยืนยันว่าคนทักมาคือ "เจ้าของตัวจริง"
                  if (isReceived && !hasReplied && progress == 'pending') {
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 30),
                        const Divider(height: 1, color: Color(0xFFEEEEEE)),
                        const SizedBox(height: 20),
                        const Text(
                          'การยืนยันเจ้าของสิ่งของ',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            fontFamily: 'Line Seed Sans TH',
                          ),
                        ),
                        const SizedBox(height: 15),
                        Row(
                          children: [
                            Expanded(
                              child: ElevatedButton(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFF006C68),
                                ),
                                onPressed: () async {
                                  await FirebaseFirestore.instance
                                      .collection('items')
                                      .doc(data['itemId'])
                                      .update({
                                        'progress': 'founded',
                                        'confirmed_owner_id':
                                            data['senderId'], // ยืนยัน UID ของเจ้าของตัวจริง
                                      });
                                  await FirebaseFirestore.instance
                                      .collection('inbox')
                                      .doc(widget.messageId)
                                      .update({'hasReplied': true});
                                  setState(() {
                                    data['hasReplied'] = true;
                                  });
                                  if (context.mounted)
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text(
                                          'ยืนยันเจ้าของเรียบร้อยแล้ว',
                                        ),
                                      ),
                                    );
                                },
                                child: const Text(
                                  'ใช่ นี่คือเจ้าของ',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontFamily: 'Line Seed Sans TH',
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: OutlinedButton(
                                style: OutlinedButton.styleFrom(
                                  side: const BorderSide(color: Colors.red),
                                ),
                                onPressed: () async {
                                  await FirebaseFirestore.instance
                                      .collection('items')
                                      .doc(data['itemId'])
                                      .update({
                                        'progress': '',
                                        'current_contact_id':
                                            FieldValue.delete(),
                                      });
                                  await FirebaseFirestore.instance
                                      .collection('inbox')
                                      .doc(widget.messageId)
                                      .update({'hasReplied': true});
                                  setState(() {
                                    data['hasReplied'] = true;
                                  });
                                  if (context.mounted)
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text('ปฏิเสธเรียบร้อยแล้ว'),
                                      ),
                                    );
                                },
                                child: const Text(
                                  'ไม่ใช่ เจ้าของ',
                                  style: TextStyle(
                                    color: Colors.red,
                                    fontFamily: 'Line Seed Sans TH',
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    );
                  }
                  // 2. คนทัก (เจ้าของตัวจริง) กดยืนยันรับของ และมอบแต้มให้คนโพสต์ (คนเจอของ)
                  else if (!isReceived &&
                      progress == 'founded' &&
                      itemData['confirmed_owner_id'] == user?.uid) {
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 30),
                        const Divider(height: 1, color: Color(0xFFEEEEEE)),
                        const SizedBox(height: 20),
                        SizedBox(
                          width: double.infinity,
                          height: 45,
                          child: ElevatedButton(
                            // ส่ง data['receiverId'] ไปรับแต้ม (เพราะคนรับข้อความคือคนโพสต์/คนเจอของ)
                            onPressed:
                                () => _showRatingDialog(
                                  context,
                                  data['itemId'],
                                  data['receiverId'],
                                ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.green,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                              elevation: 0,
                            ),
                            child: const Text(
                              'ฉันได้รับของคืนแล้ว',
                              style: TextStyle(
                                fontFamily: 'Line Seed Sans TH',
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ),
                      ],
                    );
                  }
                  // 3. แสดงสถานะเมื่อกดรับของเสร็จสิ้น
                  else if (progress == 'completed' &&
                      itemData['confirmed_owner_id'] == data['senderId']) {
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 30),
                        const Divider(height: 1, color: Color(0xFFEEEEEE)),
                        const SizedBox(height: 20),
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.green.shade50,
                            border: Border.all(color: Colors.green.shade200),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Text(
                            '✅ รายการนี้เสร็จสิ้นและได้รับของคืนเรียบร้อยแล้ว',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: Colors.green,
                              fontWeight: FontWeight.bold,
                              fontFamily: 'Line Seed Sans TH',
                            ),
                          ),
                        ),
                      ],
                    );
                  }
                  // 4. แสดงข้อความสำหรับคนโพสต์ เมื่อกดยืนยันหรือปฏิเสธไปแล้ว
                  else if (isReceived && hasReplied) {
                    return const Padding(
                      padding: EdgeInsets.only(top: 30),
                      child: Center(
                        child: Text(
                          'คุณได้ทำการตรวจสอบและตอบกลับข้อความนี้ไปแล้ว',
                          style: TextStyle(
                            color: Colors.grey,
                            fontFamily: 'Line Seed Sans TH',
                          ),
                        ),
                      ),
                    );
                  }
                }

                return const SizedBox.shrink();
              },
            ),
          ],
        ),
      ),
    );
  }
}

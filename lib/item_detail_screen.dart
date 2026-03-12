import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'edit_item_page.dart';
import 'contact_page.dart';
import 'chat_screen.dart';

class ItemDetailScreen extends StatelessWidget {
  final Map<String, dynamic> data;

  const ItemDetailScreen({super.key, required this.data});

  @override
  Widget build(BuildContext context) {
    final String? docId = data['id'];

    if (docId == null) {
      return _buildContent(context, data);
    }

    return StreamBuilder<DocumentSnapshot>(
      stream:
          FirebaseFirestore.instance.collection('items').doc(docId).snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            backgroundColor: Colors.white,
            body: Center(
              child: CircularProgressIndicator(color: Color(0xFF006C68)),
            ),
          );
        }

        if (snapshot.hasError || !snapshot.hasData || !snapshot.data!.exists) {
          return Scaffold(
            appBar: AppBar(
              backgroundColor: Colors.white,
              elevation: 0,
              leading: IconButton(
                icon: const Icon(Icons.arrow_back, color: Colors.black),
                onPressed: () => Navigator.pop(context),
              ),
            ),
            body: const Center(
              child: Text(
                'ไม่พบข้อมูล หรือโพสต์ถูกลบไปแล้ว',
                style: TextStyle(fontFamily: 'Line Seed Sans TH'),
              ),
            ),
          );
        }

        final Map<String, dynamic> freshData = Map<String, dynamic>.from(
          snapshot.data!.data() as Map<String, dynamic>,
        );
        freshData['id'] = docId;

        return _buildContent(context, freshData);
      },
    );
  }

  Widget _buildContent(BuildContext context, Map<String, dynamic> currentData) {
    final String own_name = currentData['displayName'] ?? 'ไม่ระบุชื่อ';
    final String status = currentData['status'] ?? 'lost';
    final String title = currentData['title'] ?? '';
    final String description = currentData['description'] ?? '';
    final Timestamp? created_date = currentData['created_date'];
    final GeoPoint? location = currentData['location'];
    final String locationDetail = currentData['location_detail'] ?? '';
    final List<dynamic> images =
        currentData['images'] ??
        (currentData['imageUrl'] != null ? [currentData['imageUrl']] : []);

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Stack(
          children: [
            Positioned(
              top: 10,
              left: 10,
              child: IconButton(
                icon: const Icon(Icons.arrow_back, color: Colors.black),
                onPressed: () => Navigator.pop(context),
              ),
            ),
            Positioned(
              top: 71,
              left: 0,
              right: 0,
              child: Center(
                child: Image.asset(
                  'assets/images/Logo.png',
                  width: 114,
                  height: 82,
                ),
              ),
            ),
            Positioned(
              top: 181,
              left: 0,
              right: 0,
              bottom: 0,
              child: SingleChildScrollView(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Column(
                    children: [
                      _buildHeaderInfo(
                        own_name,
                        title,
                        description,
                        created_date,
                        location,
                        status,
                        locationDetail,
                      ),
                      const SizedBox(height: 20),
                      _buildImageSection(images),
                      const SizedBox(height: 20),
                      _buildMapSection(location),
                      const SizedBox(height: 20),
                      _buildActionButtons(context, currentData),
                      if (FirebaseAuth.instance.currentUser?.uid == currentData['uid'])
                        _buildOwnerChatList(context, currentData),
                      const SizedBox(height: 30),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeaderInfo(
    String own_name,
    String title,
    String description,
    Timestamp? created_date,
    GeoPoint? location,
    String status,
    String locationDetail,
  ) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFEEEEEE)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontFamily: 'Line Seed Sans TH',
              fontWeight: FontWeight.bold,
              fontSize: 18,
              color: Color(0xFF1E1E1E),
            ),
          ),
          if (description.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(
              description,
              style: const TextStyle(
                fontFamily: 'Line Seed Sans TH',
                fontSize: 14,
                color: Color(0xFF757575),
              ),
            ),
          ],
          const Divider(height: 24, color: Color(0xFFEEEEEE)),
          _buildInfoRow(
            status == 'found'
                ? "วันที่และเวลา (แจ้งพบ)"
                : "วันที่และเวลา (แจ้งหาย)",
            _formatDate(created_date),
            Icons.calendar_today_outlined,
          ),
          if (locationDetail.isNotEmpty) ...[
            const SizedBox(height: 12),
            _buildInfoRow(
              "รายละเอียดสถานที่",
              locationDetail,
              Icons.info_outline,
            ),
          ],
          const SizedBox(height: 12),
          _buildInfoRow(
            "พิกัด",
            _formatLocation(location),
            Icons.location_on_outlined,
          ),
          const SizedBox(height: 12),
          _buildInfoRow("ผู้แจ้ง", own_name, Icons.person_4_outlined),
        ],
      ),
    );
  }

  Widget _buildImageSection(List<dynamic> images) {
    if (images.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          "รูปภาพ",
          style: TextStyle(
            fontFamily: 'Line Seed Sans TH',
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
        const SizedBox(height: 10),
        SizedBox(
          height: 200,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: images.length,
            separatorBuilder: (context, index) => const SizedBox(width: 10),
            itemBuilder: (context, index) {
              return Container(
                width: 300,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(10),
                  image: DecorationImage(
                    image:
                        images[index].toString().startsWith('http')
                            ? NetworkImage(images[index])
                            : AssetImage(images[index]) as ImageProvider,
                    fit: BoxFit.cover,
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildMapSection(GeoPoint? location) {
    if (location == null) return const SizedBox.shrink();

    final latLng = LatLng(location.latitude, location.longitude);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          "ตำแหน่งบนแผนที่",
          style: TextStyle(
            fontFamily: 'Line Seed Sans TH',
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
        const SizedBox(height: 10),
        Container(
          height: 250,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: Colors.grey.shade300),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: FlutterMap(
              options: MapOptions(initialCenter: latLng, initialZoom: 15.0),
              children: [
                TileLayer(
                  urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                  userAgentPackageName: 'com.example.ku_lost_and_found',
                ),
                MarkerLayer(
                  markers: [
                    Marker(
                      point: latLng,
                      width: 80,
                      height: 80,
                      child: const Icon(
                        Icons.location_on,
                        color: Colors.red,
                        size: 40,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  String _formatDate(Timestamp? timestamp) {
    if (timestamp == null) return '-';
    final dt = timestamp.toDate();
    return '${dt.day.toString().padLeft(2, '0')}/${dt.month.toString().padLeft(2, '0')}/${dt.year} เวลา ${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')} น.';
  }

  String _formatLocation(GeoPoint? point) {
    if (point == null) return '-';
    return '${point.latitude.toStringAsFixed(5)}, ${point.longitude.toStringAsFixed(5)}';
  }

  Widget _buildInfoRow(String label, String value, IconData icon) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 18, color: const Color(0xFF006C68)),
        const SizedBox(width: 8),
        Expanded(
          child: RichText(
            text: TextSpan(
              style: const TextStyle(
                fontFamily: 'Line Seed Sans TH',
                fontSize: 14,
                color: Color(0xFF1E1E1E),
              ),
              children: [
                TextSpan(
                  text: '$label: ',
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
                TextSpan(
                  text: value,
                  style: const TextStyle(color: Color(0xFF666666)),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildActionButtons(
    BuildContext context,
    Map<String, dynamic> currentData,
  ) {
    final user = FirebaseAuth.instance.currentUser;
    final isOwner = user != null && currentData['uid'] == user.uid;
    final String status = currentData['status'] ?? 'lost';
    final String progress = currentData['progress'] ?? '';

    return Column(
      children: [
        if (isOwner) ...[
          if (progress == 'pending') ...[
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.orange.shade50,
                border: Border.all(color: Colors.orange.shade200),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Text(
                'มีผู้แจ้งพบของแล้ว กรุณาตรวจสอบหลักฐานและยืนยันใน "กล่องข้อความ"',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.orange,
                  fontWeight: FontWeight.bold,
                  fontFamily: 'Line Seed Sans TH',
                ),
              ),
            ),
          ] else if (progress == 'founded') ...[
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.green.shade50,
                border: Border.all(color: Colors.green.shade200),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Text(
                '✅ ยืนยันพบของแล้ว\nกรุณากดรับของและมอบแต้มให้ผู้พบที่ "กล่องจดหมาย"',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.green,
                  fontWeight: FontWeight.bold,
                  fontFamily: 'Line Seed Sans TH',
                ),
              ),
            ),
          ] else if (progress == 'completed') ...[
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
          ] else ...[
            SizedBox(
              width: double.infinity,
              height: 45,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => EditItemPage(data: currentData),
                    ),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF006C68),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  elevation: 0,
                ),
                child: const Text(
                  'แก้ไขโพสต์',
                  style: TextStyle(
                    fontFamily: 'Line Seed Sans TH',
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              height: 45,
              child: ElevatedButton(
                onPressed: () async {
                  final bool? confirm = await showDialog<bool>(
                    context: context,
                    builder: (context) {
                      return AlertDialog(
                        title: const Text(
                          'ยืนยันการลบ',
                          style: TextStyle(
                            fontFamily: 'Line Seed Sans TH',
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        content: const Text(
                          'คุณแน่ใจหรือไม่ว่าต้องการลบโพสต์นี้?\nการกระทำนี้ไม่สามารถย้อนกลับได้',
                          style: TextStyle(fontFamily: 'Line Seed Sans TH'),
                        ),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(context, false),
                            child: const Text(
                              'ยกเลิก',
                              style: TextStyle(
                                fontFamily: 'Line Seed Sans TH',
                                color: Colors.grey,
                              ),
                            ),
                          ),
                          TextButton(
                            onPressed: () => Navigator.pop(context, true),
                            style: TextButton.styleFrom(
                              foregroundColor: Colors.red,
                            ),
                            child: const Text(
                              'ลบโพสต์',
                              style: TextStyle(
                                fontFamily: 'Line Seed Sans TH',
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      );
                    },
                  );

                  if (confirm == true && currentData['id'] != null) {
                    await FirebaseFirestore.instance
                        .collection('items')
                        .doc(currentData['id'])
                        .delete();
                    if (context.mounted) Navigator.pop(context);
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red.shade600,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  elevation: 0,
                ),
                child: const Text(
                  'ลบโพสต์',
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
        ],

        if (!isOwner) ...[
          if (progress == '') ...[
            SizedBox(
              width: double.infinity,
              height: 45,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => ContactPage(itemData: currentData),
                    ),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF005451),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  elevation: 0,
                ),
                child: Text(
                  status == 'found' ? 'นี่คือของของฉัน' : 'ฉันเจอของชิ้นนี้',
                  style: const TextStyle(
                    fontFamily: 'Line Seed Sans TH',
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              height: 45,
              child: OutlinedButton(
                onPressed: () async {
                  final itemId = currentData['id'];
                  final ownerId = currentData['uid'];
                  final visitorId = user!.uid;
                  if (itemId == null) return;

                  final String chatRoomId = '${itemId}_$visitorId';
                  final chatDocRef = FirebaseFirestore.instance.collection('chats').doc(chatRoomId);
                  final chatDoc = await chatDocRef.get();

                  if (!chatDoc.exists) {
                    await chatDocRef.set({
                      'itemId': itemId,
                      'ownerId': ownerId,
                      'visitorId': visitorId,
                      'participants': [ownerId, visitorId],
                      'itemTitle': currentData['title'] ?? 'ไม่ระบุชื่อ',
                      'itemImage': (currentData['images'] != null && (currentData['images'] as List).isNotEmpty)
                          ? currentData['images'][0]
                          : (currentData['imageUrl'] ?? ''),
                      'lastMessage': '',
                      'lastMessageTime': FieldValue.serverTimestamp(),
                    });
                  }

                  if (context.mounted) {
                    Navigator.push(context, MaterialPageRoute(builder: (_) => ChatScreen(
                      chatRoomId: chatRoomId,
                      otherUserId: ownerId,
                      itemName: currentData['title'] ?? 'Chat',
                    )));
                  }
                },
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: Color(0xFF006C68)),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
                child: Text(
                  status == 'found' ? 'แชทกับผู้ที่พบของชิ้นนี้' : 'แชทกับผู้ตามหา',
                  style: const TextStyle(
                    fontFamily: 'Line Seed Sans TH',
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                    color: Color(0xFF006C68),
                  ),
                ),
              ),
            ),
          ] else ...[
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                border: Border.all(color: Colors.grey.shade300),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Text(
                'รายการนี้มีผู้แจ้งดำเนินการแล้ว',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.grey,
                  fontWeight: FontWeight.bold,
                  fontFamily: 'Line Seed Sans TH',
                ),
              ),
            ),
          ],
        ],
      ],
    );
  }

  Widget _buildOwnerChatList(BuildContext context, Map<String, dynamic> currentData) {
    if (currentData['id'] == null) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 20),
        const Text(
          "รายการแชทที่เกี่ยวข้อง",
          style: TextStyle(
            fontFamily: 'Line Seed Sans TH',
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
        const SizedBox(height: 10),
        StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance
              .collection('chats')
              .where('itemId', isEqualTo: currentData['id'])
              .snapshots(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
              return Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(color: Colors.grey[100], borderRadius: BorderRadius.circular(8)),
                child: const Text('ยังไม่มีการติดต่อเข้ามา', style: TextStyle(color: Colors.grey, fontFamily: 'Line Seed Sans TH'), textAlign: TextAlign.center),
              );
            }

            return ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: snapshot.data!.docs.length,
              separatorBuilder: (context, index) => const Divider(height: 1),
              itemBuilder: (context, index) {
                final chatDoc = snapshot.data!.docs[index];
                final chatData = chatDoc.data() as Map<String, dynamic>;
                final String visitorId = chatData['visitorId'] ?? '';
                final String lastMessage = chatData['lastMessage'] ?? '-';

                return ListTile(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 0, vertical: 4),
                  leading: CircleAvatar(backgroundColor: const Color(0xFF006C68).withOpacity(0.1), child: const Icon(Icons.person, color: Color(0xFF006C68))),
                  title: const Text('ผู้ติดต่อ', style: TextStyle(fontFamily: 'Line Seed Sans TH', fontWeight: FontWeight.bold, fontSize: 14)),
                  subtitle: Text(lastMessage, style: const TextStyle(fontFamily: 'Line Seed Sans TH', fontSize: 12, color: Colors.grey), maxLines: 1, overflow: TextOverflow.ellipsis),
                  trailing: const Icon(Icons.arrow_forward_ios, size: 14, color: Colors.grey),
                  onTap: () {
                    Navigator.push(context, MaterialPageRoute(builder: (_) => ChatScreen(
                      chatRoomId: chatDoc.id,
                      otherUserId: visitorId,
                      itemName: currentData['title'] ?? 'Chat',
                    )));
                  },
                );
              },
            );
          },
        ),
      ],
    );
  }
}

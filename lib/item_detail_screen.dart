import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'chat_screen.dart';

class ItemDetailScreen extends StatelessWidget {
  final Map<String, dynamic> data;

  const ItemDetailScreen({super.key, required this.data});

  @override
  Widget build(BuildContext context) {
    // Extract data
    final String type = data['type'] ?? 'lost';
    final String title = data['title'] ?? '';
    final String description = data['description'] ?? '';
    final Timestamp? date = data['date'];
    final GeoPoint? location = data['location'];
    final String locationDetail = data['location_detail'] ?? '';
    // Support multiple images, fall back to single imageUrl, or empty list
    final List<dynamic> images = data['images'] ?? (data['imageUrl'] != null ? [data['imageUrl']] : []);

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Stack(
          children: [
            // Back Button
            Positioned(
              top: 10,
              left: 10,
              child: IconButton(
                icon: const Icon(Icons.arrow_back, color: Colors.black),
                onPressed: () => Navigator.pop(context),
              ),
            ),

            // Logo 1 - Centered at the top
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

            // Main Scrollable Content
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
                      _buildHeaderInfo(title, description, date, location, type, locationDetail),
                      const SizedBox(height: 20),
                      _buildImageSection(images),
                      const SizedBox(height: 20),
                      _buildMapSection(location),
                      const SizedBox(height: 20),
                      _buildActionButtons(context),
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

  // 1. Name, Date, Location Info
  Widget _buildHeaderInfo(
    String title, 
    String description, 
    Timestamp? date, 
    GeoPoint? location, 
    String type,
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
          // Name (Title) & Description
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

          // Date
          _buildInfoRow(
            type == 'found' ? "วันที่พบ" : "วันที่หาย",
            _formatDate(date),
            Icons.calendar_today_outlined,
          ),

          // Location Part 2: Detail Text
          if (locationDetail.isNotEmpty) ...[
            const SizedBox(height: 12),
            _buildInfoRow(
              "รายละเอียดสถานที่",
              locationDetail,
              Icons.info_outline,
            ),
          ],
          const SizedBox(height: 12),

          // Location Part 1: Lat Long
          _buildInfoRow(
            "พิกัด",
            _formatLocation(location),
            Icons.location_on_outlined,
          ),
        ],
      ),
    );
  }

  // 2. Images Section
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
                    // Assuming images are URLs. If they are assets in testing, allow check.
                    image: images[index].toString().startsWith('http') 
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

  // 3. Map Section
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
              options: MapOptions(
                initialCenter: latLng,
                initialZoom: 15.0,
              ),
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

  // Shared Widget for Label: Value rows
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

  // Frame 42 (Part 2) - Action Buttons
  Widget _buildActionButtons(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    final isOwner = user != null && data['uid'] == user.uid;
    final String type = data['type'] ?? 'lost';

    return Column(
      children: [
        // Dark Teal Button (Filled)
        SizedBox(
          width: double.infinity,
          height: 45,
          child: ElevatedButton(
            onPressed: () async {
              if (isOwner) {
                // Confirmation Dialog
                final bool? confirm = await showDialog<bool>(
                  context: context,
                  builder: (context) {
                    return AlertDialog(
                      title: const Text('ยืนยันการลบ', style: TextStyle(fontFamily: 'Line Seed Sans TH', fontWeight: FontWeight.bold)),
                      content: const Text('คุณแน่ใจหรือไม่ว่าต้องการลบโพสต์นี้?\nการกระทำนี้ไม่สามารถย้อนกลับได้', style: TextStyle(fontFamily: 'Line Seed Sans TH')),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(context, false),
                          child: const Text('ยกเลิก', style: TextStyle(fontFamily: 'Line Seed Sans TH', color: Colors.grey)),
                        ),
                        TextButton(
                          onPressed: () => Navigator.pop(context, true),
                          style: TextButton.styleFrom(foregroundColor: Colors.red),
                          child: const Text('ลบโพสต์', style: TextStyle(fontFamily: 'Line Seed Sans TH', fontWeight: FontWeight.bold)),
                        ),
                      ],
                    );
                  },
                );

                if (confirm == true && data['id'] != null) {
                  await FirebaseFirestore.instance
                      .collection('items')
                      .doc(data['id'])
                      .delete();
                  if (context.mounted) {
                    Navigator.pop(context);
                  }
                }
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: isOwner ? Colors.red : const Color(0xFF005451),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              elevation: 0,
            ),
            child: Text(
              isOwner ? 'ลบโพสต์' : (type == 'found' ? 'นี่คือของของฉัน' : 'ฉันเจอของชิ้นนี้'),
              style: const TextStyle(
                fontFamily: 'Line Seed Sans TH',
                fontWeight: FontWeight.bold,
                fontSize: 14,
                color: Colors.white,
              ),
            ),
          ),
        ),
        if (!isOwner) ...[
          const SizedBox(height: 12),
          // Light Teal Button (Outlined)
          SizedBox(
            width: double.infinity,
            height: 45,
            child: OutlinedButton(
            onPressed: () async {
              if (user == null) return;

              // Generate a unique Chat Room ID: ItemID_VisitorID
              // (This separates chats per item per user)
              final String itemId = data['id'] ?? 'unknown_item';
              final String ownerId = data['uid'];
              final String visitorId = user.uid;
              final String chatRoomId = '${itemId}_$visitorId';

              // Initialize Chat Room Metadata if it doesn't exist
              final chatDocRef = FirebaseFirestore.instance.collection('chats').doc(chatRoomId);
              final chatDoc = await chatDocRef.get();

              if (!chatDoc.exists) {
                await chatDocRef.set({
                  'itemId': itemId,
                  'ownerId': ownerId,
                  'visitorId': visitorId,
                  'participants': [ownerId, visitorId],
                  'itemTitle': data['title'] ?? 'ไม่ระบุชื่อ',
                  'itemImage': (data['images'] != null && (data['images'] as List).isNotEmpty)
                      ? data['images'][0]
                      : (data['imageUrl'] ?? ''),
                  'lastMessage': '',
                  'lastMessageTime': FieldValue.serverTimestamp(),
                });
              }

              if (context.mounted) {
                Navigator.push(context, MaterialPageRoute(builder: (_) => ChatScreen(
                  chatRoomId: chatRoomId,
                  otherUserId: ownerId,
                  itemName: data['title'] ?? 'Chat',
                )));
              }
            },
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: Color(0xFF006C68)),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: Text(
                type == 'found' ? 'แชทกับผู้ที่พบของชิ้นนี้' : 'แชทกับผู้ตามหา',
                style: const TextStyle(
                  fontFamily: 'Line Seed Sans TH',
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                  color: Color(0xFF006C68),
                ),
              ),
            ),
          ),
        ],
      ],
    );
  }
}
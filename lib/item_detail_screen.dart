import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'edit_item_page.dart'; // เพิ่มบรรทัดนี้

class ItemDetailScreen extends StatelessWidget {
  final Map<String, dynamic> data;

  const ItemDetailScreen({super.key, required this.data});

  @override
  Widget build(BuildContext context) {
    final String? docId = data['id'];

    // ถ้าไม่มี ID (กัน Error) ให้แสดงข้อมูลเดิมไปก่อน
    if (docId == null) {
      return _buildContent(context, data);
    }

    // ใช้ StreamBuilder คอยฟังการเปลี่ยนแปลงของ Document นี้
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

        // สร้าง Map ตัวใหม่จากข้อมูลล่าสุด (Real-time) และแนบ ID กลับเข้าไป
        final Map<String, dynamic> freshData = Map<String, dynamic>.from(
          snapshot.data!.data() as Map<String, dynamic>,
        );
        freshData['id'] = docId;

        // โยนข้อมูลล่าสุดไปสร้างหน้าจอ
        return _buildContent(context, freshData);
      },
    );
  }

  Widget _buildContent(BuildContext context, Map<String, dynamic> currentData) {
    final String own_name = currentData['displayName'];
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
            status == 'found' ? "วันที่และเวลา (แจ้งพบ)" : "วันที่และเวลา (แจ้งหาย)",
            _formatDate(created_date),
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
          const SizedBox(height: 12),

          _buildInfoRow(
            "ผู้แจ้ง",
            own_name,
            Icons.person_4_outlined,
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

  Widget _buildActionButtons(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    final isOwner = user != null && data['uid'] == user.uid;
    final String status = data['status'] ?? 'lost';

    return Column(
      children: [
        if (isOwner) ...[
          SizedBox(
            width: double.infinity,
            height: 45,
            child: ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => EditItemPage(data: data),
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
        ],

        // ปุ่มลบโพสต์ หรือ ปุ่มแสดงตัวเป็นเจ้าของ/คนเจอ
        SizedBox(
          width: double.infinity,
          height: 45,
          child: ElevatedButton(
            onPressed: () async {
              if (isOwner) {
                // Confirmation Dialog สำหรับการลบ
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
              backgroundColor:
                  isOwner ? Colors.red.shade600 : const Color(0xFF005451),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              elevation: 0,
            ),
            child: Text((status == 'found'
                      ? 'นี่คือของของฉัน'
                      : 'ฉันเจอของชิ้นนี้'),
              style: const TextStyle(
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
}
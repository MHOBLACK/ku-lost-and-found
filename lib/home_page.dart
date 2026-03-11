// * หน้าหลักของแอปพลิเคชัน
import 'package:flutter/material.dart';
import 'add_item_page.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'item_detail_screen.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFFFFF),
      body: SafeArea(
        child: Stack(
          children: [
            // Logo 1
            Positioned(
              top: 27,
              left: 0,
              right: 0,
              child: Center(
                child: SizedBox(
                  width: 110,
                  height: 80,
                  child: Image.asset('assets/images/Logo.png'),
                ),
              ),
            ),

            Positioned.fill(
              top: 134,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: double.infinity,
                      height: 105,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(10),
                        image: const DecorationImage(
                          image: AssetImage('assets/images/Grand-Opening.png'),
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),
                    
                    const SizedBox(height: 15),

                    // Quick Menu Row
                    Row(
                      children: [
                        _buildQuickActionButton(context, 'แจ้งของหาย', Icons.search_rounded, const Color(0xFF006C68), 'lost'),
                        const SizedBox(width: 12),
                        _buildQuickActionButton(context, 'แจ้งพบของ', Icons.check_circle_outline, Colors.orange.shade700, 'found'),
                      ],
                    ),
                    
                    const SizedBox(height: 15), 

                    Expanded(
                      child: StreamBuilder<QuerySnapshot>(
                        stream:
                            FirebaseFirestore.instance
                                .collection('items')
                                .orderBy(
                                  'created_date',
                                  descending: true,
                                ) // เรียงจากล่าสุดไปเก่าสุด
                                .snapshots(),
                        builder: (context, snapshot) {
                          if (snapshot.hasError) {
                            return const Center(
                              child: Text(
                                'เกิดข้อผิดพลาดในการโหลดข้อมูล',
                                style: TextStyle(
                                  fontFamily: 'Line Seed Sans TH',
                                ),
                              ),
                            );
                          }
                          if (snapshot.connectionState ==
                              ConnectionState.waiting) {
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
                                'ยังไม่มีรายการใหม่ในขณะนี้',
                                style: TextStyle(
                                  fontFamily: 'Line Seed Sans TH',
                                ),
                              ),
                            );
                          }

                          return ListView.separated(
                            padding: EdgeInsets.zero,
                            itemCount: docs.length,
                            separatorBuilder:
                                (context, index) => const Divider(
                                  height: 15,
                                  color: Color(0xFFEEEEEE),
                                ),
                            itemBuilder: (context, index) {
                              final Map<String, dynamic> data =
                                  Map<String, dynamic>.from(
                                    docs[index].data() as Map<String, dynamic>,
                                  );
                              data['id'] = docs[index].id;

                              // ส่งข้อมูลแต่ละรายการไปแสดงใน Widget
                              return NewsItemTile(itemData: data);
                            },
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickActionButton(BuildContext context, String label, IconData icon, Color color, String type) {
    return Expanded(
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.white,
          foregroundColor: color,
          side: BorderSide(color: color),
          padding: const EdgeInsets.symmetric(vertical: 12),
          elevation: 0,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => AddItemPage(itemType: type)),
          );
        },
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 20, color: color),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                fontFamily: 'Line Seed Sans TH',
                fontWeight: FontWeight.bold,
                fontSize: 14,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class NewsItemTile extends StatelessWidget {
  final Map<String, dynamic> itemData; // รับข้อมูลมาจาก StreamBuilder

  const NewsItemTile({super.key, required this.itemData});

  @override
  Widget build(BuildContext context) {
    final bool isLost = itemData['status'] == 'lost';
    final String title = itemData['title'] ?? 'ไม่ระบุชื่อ';
    final String description = itemData['description'] ?? '';
    final Timestamp? timestamp = itemData['created_date'];

    // จัดการรูปภาพ
    final List<dynamic> images = itemData['images'] ?? [];
    Widget imageWidget;
    if (images.isNotEmpty && images.first.toString().startsWith('http')) {
      imageWidget = Image.network(
        images.first.toString(),
        fit: BoxFit.cover,
        errorBuilder:
            (context, error, stackTrace) => Container(
              color: Colors.grey[200],
              child: const Icon(Icons.broken_image, color: Colors.grey),
            ),
      );
    } else {
      imageWidget = Image.asset(
        'assets/images/No_Image_Available.png',
        fit: BoxFit.cover,
        errorBuilder:
            (context, error, stackTrace) => Container(
              color: Colors.grey[200],
              child: const Icon(Icons.image_not_supported, color: Colors.grey),
            ),
      );
    }

    // แปลงวันที่
    String dateStr = '';
    if (timestamp != null) {
      final dt = timestamp.toDate();
      dateStr =
          '${dt.day.toString().padLeft(2, '0')}/${dt.month.toString().padLeft(2, '0')}/${dt.year}';
    }

    return InkWell(
      onTap: () {
        // กดแล้วให้ไปยังหน้ารายละเอียด
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ItemDetailScreen(data: itemData),
          ),
        );
      },
      child: Container(
        height: 110,
        padding: const EdgeInsets.symmetric(vertical: 10),
        color: Colors.white,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Thumbnail Image
            Container(
              width: 100,
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

            // Content
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ป้ายกำกับ (ตามหา/พบของ) + ชื่อสิ่งของ
                  Text(
                    '${isLost ? '[ของหาย]' : '[พบของ]'} $title',
                    style: TextStyle(
                      fontFamily: 'Line Seed Sans TH',
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color:
                          isLost
                              ? Colors.red.shade700
                              : const Color(0xFF006C68),
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  // รายละเอียด
                  SizedBox(
                    height: 40,
                    child: Text(
                      description,
                      style: const TextStyle(
                        fontFamily: 'Line Seed Sans TH',
                        fontSize: 12,
                        fontWeight: FontWeight.w400,
                        color: Color(0xFF757575),
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),

                  const Spacer(),

                  // วันที่ และ ปุ่มอ่านเพิ่มเติม
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        dateStr,
                        style: const TextStyle(
                          fontFamily: 'Line Seed Sans TH',
                          fontSize: 12,
                          color: Color(0xFFB3B3B3),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
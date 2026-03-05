import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'add_item_page.dart';

class ItemsListScreen extends StatefulWidget {
  const ItemsListScreen({super.key});

  @override
  State<ItemsListScreen> createState() => _ItemsListScreenState();
}

class _ItemsListScreenState extends State<ItemsListScreen> with TickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  // This function handles the "Two Button" overlay when FAB is clicked
  void _showPostOptions(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Container(
          padding: const EdgeInsets.all(24),
          height: 200,
          child: Column(
            children: [
              const Text(
                'สร้างโพสต์ใหม่',
                style: TextStyle(
                  fontFamily: 'Line Seed Sans TH',
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                ),
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: _buildPostButton(
                      context,
                      "ตามหาของหาย",
                      Icons.search_rounded,
                      const Color(0xFF006C68),
                      () {
                        Navigator.pop(context); // Close the sheet
                        // Navigate to the Add Item Page (Form)
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => const AddItemPage(itemType: 'lost')),
                        );
                      },
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _buildPostButton(
                      context,
                      "แจ้งพบของ",
                      Icons.check_circle_outline,
                      Colors.orange.shade700,
                      () {
                        Navigator.pop(context);
                        // You can link this to a different page if needed
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => const AddItemPage(itemType: 'found')),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildPostButton(BuildContext context, String label, IconData icon, Color color, VoidCallback onTap) {
    return ElevatedButton(
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.white,
        side: BorderSide(color: color),
        padding: const EdgeInsets.symmetric(vertical: 16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
      onPressed: onTap,
      child: Column(
        children: [
          Icon(icon, color: color),
          const SizedBox(height: 8),
          Text(
            label,
            style: TextStyle(color: color, fontFamily: 'Line Seed Sans TH', fontSize: 12),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: Image.asset('assets/images/Logo.png', height: 40), // Keeping branding consistent
        centerTitle: true,
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: const Color(0xFF006C68),
          labelColor: const Color(0xFF006C68),
          unselectedLabelColor: Colors.grey,
          labelStyle: const TextStyle(fontFamily: 'Line Seed Sans TH', fontWeight: FontWeight.bold),
          tabs: const [
            Tab(text: 'ของหาย (Looking for)'),
            Tab(text: 'ใจดีพบ (Found)'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildItemList(isLost: true),
          _buildItemList(isLost: false),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showPostOptions(context),
        backgroundColor: const Color(0xFF006C68),
        child: const Icon(Icons.add, color: Colors.white, size: 30),
      ),
    );
  }

  Widget _buildItemList({required bool isLost}) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('items')
          .where('type', isEqualTo: isLost ? 'lost' : 'found')
          .orderBy('date', descending: true)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Center(child: Text('เกิดข้อผิดพลาด: ${snapshot.error}'));
        }
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        final docs = snapshot.data!.docs;

        if (docs.isEmpty) {
          return Center(child: Text(isLost ? 'ยังไม่มีรายการของหาย' : 'ยังไม่มีรายการพบของ'));
        }

        return ListView.separated(
          padding: const EdgeInsets.all(16),
          itemCount: docs.length,
          separatorBuilder: (context, index) => const Divider(height: 24, color: Color(0xFFEEEEEE)),
          itemBuilder: (context, index) {
            final data = docs[index].data() as Map<String, dynamic>;
            final title = data['title'] ?? 'ไม่ระบุชื่อ';
            final description = data['description'] ?? '';
            final timestamp = data['date'] as Timestamp?;

        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Thumbnail
            Container(
              width: 90,
              height: 90,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(8),
                image: const DecorationImage(
                  image: AssetImage('assets/Checker.png'),
                  fit: BoxFit.cover,
                ),
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
                        style: const TextStyle(fontSize: 10, color: Color(0xFFB3B3B3)),
                      ),
                      Text(
                        'รายละเอียด >',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: isLost ? const Color(0xFF006C68) : Colors.orange.shade800,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        );
      },
    );
      },
    );
  }

  String _getTimeAgo(Timestamp? timestamp) {
    if (timestamp == null) return '';
    final dt = timestamp.toDate();
    final diff = DateTime.now().difference(dt);
    if (diff.inMinutes < 60) return '${diff.inMinutes} mins ago';
    if (diff.inHours < 24) return '${diff.inHours} hours ago';
    return '${diff.inDays} days ago';
  }
}
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'add_item_page.dart';
import 'item_detail_screen.dart';

class ItemsListScreen extends StatefulWidget {
  const ItemsListScreen({super.key});

  @override
  State<ItemsListScreen> createState() => _ItemsListScreenState();
}

class _ItemsListScreenState extends State<ItemsListScreen> with TickerProviderStateMixin {
  late TabController _tabController;
  bool _showAllPosts = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  void _showPostOptions(BuildContext context) {
    final parentContext = context;
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (sheetContext) {
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
                      sheetContext,
                      "ตามหาของหาย",
                      Icons.search_rounded,
                      const Color(0xFF006C68),
                      () {
                        Navigator.pop(sheetContext);
                        Navigator.push(
                          parentContext,
                          MaterialPageRoute(builder: (context) => AddItemPage(itemType: 'lost')),
                        );
                      },
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _buildPostButton(
                      sheetContext,
                      "แจ้งพบของ",
                      Icons.warning_amber_rounded,
                      Colors.orange.shade700,
                      () {
                        Navigator.pop(sheetContext);
                        Navigator.push(
                          parentContext,
                          MaterialPageRoute(builder: (context) => AddItemPage(itemType: 'found')),
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

  void _showFilterOptions() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Container(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'ตัวกรองการแสดงผล',
                style: TextStyle(
                  fontFamily: 'Line Seed Sans TH',
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                ),
              ),
              const SizedBox(height: 20),
              ListTile(
                leading: const Icon(Icons.public, color: Color(0xFF006C68)),
                title: const Text('โพสต์ทั้งหมด', style: TextStyle(fontFamily: 'Line Seed Sans TH')),
                trailing: _showAllPosts ? const Icon(Icons.check, color: Color(0xFF006C68)) : null,
                onTap: () {
                  setState(() {
                    _showAllPosts = true;
                  });
                  Navigator.pop(context);
                },
              ),
              ListTile(
                leading: const Icon(Icons.person, color: Color(0xFF006C68)),
                title: const Text('โพสต์ของฉัน', style: TextStyle(fontFamily: 'Line Seed Sans TH')),
                trailing: !_showAllPosts ? const Icon(Icons.check, color: Color(0xFF006C68)) : null,
                onTap: () {
                  setState(() {
                    _showAllPosts = false;
                  });
                  Navigator.pop(context);
                },
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.filter_list, color: Color(0xFF006C68)),
          onPressed: _showFilterOptions,
        ),
        title: Image.asset('assets/images/Logo.png', height: 40),
        centerTitle: true,
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: const Color(0xFF006C68),
          labelColor: const Color(0xFF006C68),
          unselectedLabelColor: Colors.grey,
          labelStyle: const TextStyle(fontFamily: 'Line Seed Sans TH', fontWeight: FontWeight.bold),
          tabs: const [
            Tab(text: 'แจ้งของหาย (Lost)', icon: Icon(Icons.search_rounded)),
            Tab(text: 'แจ้งพบของ (Found)', icon: Icon(Icons.warning_amber_rounded)),
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
    final String? userId = FirebaseAuth.instance.currentUser?.uid;
    Query query = FirebaseFirestore.instance
        .collection('items')
        .where('status', isEqualTo: isLost ? 'lost' : 'found');

    if (!_showAllPosts) {
      query = query.where('uid', isEqualTo: userId);
    }

    return StreamBuilder<QuerySnapshot>(
      stream: query
          .orderBy('created_date', descending: false)
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
            final Map<String, dynamic> data = Map<String, dynamic>.from(
              docs[index].data() as Map<String, dynamic>,
            );
            data['id'] = docs[index].id;

            final title = data['title'] ?? 'ไม่ระบุชื่อ';
            final description = data['description'] ?? '';
            final timestamp = data['created_date'] as Timestamp?;

            final List<dynamic> images = data['images'] ?? [];
            Widget imageWidget;

            if (images.isNotEmpty &&
                images.first.toString().startsWith('http')) {
              imageWidget = Image.network(
                images.first.toString(),
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  return Container(
                    color: Colors.grey[200],
                    child: const Icon(Icons.broken_image, color: Colors.grey),
                  );
                },
              );
            } else {
              imageWidget = Image.asset(
                'assets/images/No_Image_Available.png',
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  return Container(
                    color: Colors.grey[200],
                    child: const Icon(
                      Icons.image_not_supported,
                      color: Colors.grey,
                    ),
                  );
                },
              );
            }

        return InkWell(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => ItemDetailScreen(data: data)),
            );
          },
          child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Thumbnail
            Container(
              width: 90,
              height: 90,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(8),
                color: Colors.grey[200],
              ),
              child: ClipRect(
                child: imageWidget,
              ),
            ),
            const SizedBox(width: 12),
            // Details
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    isLost ? '$title' : '$title',
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
        ),
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
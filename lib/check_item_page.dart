// * หน้าค้นหาของหาย
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'item_detail_screen.dart';

class CheckItemPage extends StatefulWidget {
  const CheckItemPage({super.key});

  @override
  State<CheckItemPage> createState() => _CheckItemPageState();
}

class _CheckItemPageState extends State<CheckItemPage> {
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();
  bool _isSearching = false;
  String _searchQuery = "";
  String _submittedQuery = "";

  @override
  void dispose() {
    _searchController.dispose();
    _searchFocusNode.dispose();
    super.dispose();
  }

  void _deactivateSearch() {
    setState(() {
      _isSearching = false;
      _searchQuery = "";
      _submittedQuery = "";
      _searchController.clear();
    });
    FocusScope.of(context).unfocus();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: _isSearching
          ? AppBar(
              backgroundColor: Colors.white,
              elevation: 0,
              leading: IconButton(
                icon: const Icon(Icons.arrow_back, color: Color(0xFF006C68)),
                onPressed: _deactivateSearch,
              ),
              title: _buildTextField(),
            )
          : null,
      body: _isSearching ? _buildResultsList() : _buildCenteredView(),
    );
  }

  Widget _buildCenteredView() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Image.asset('assets/images/Logo.png', height: 80),
            const SizedBox(height: 40),
            _buildTextField(),
          ],
        ),
      ),
    );
  }

  Widget _buildTextField() {
    return TextField(
      controller: _searchController,
      focusNode: _searchFocusNode,
      textInputAction: TextInputAction.search,
      onChanged: (value) {
        setState(() {
          _searchQuery = value;
        });
      },
      onSubmitted: (value) {
        setState(() {
          _submittedQuery = value;
          _isSearching = true;
        });
      },
      decoration: InputDecoration(
        hintText: 'ค้นหาชื่อสิ่งของ...',
        hintStyle: const TextStyle(
            color: Color(0xFFB3B3B3), fontFamily: 'Line Seed Sans TH'),
        prefixIcon: const Icon(Icons.search, color: Color(0xFF006C68)),
        suffixIcon: _searchQuery.isNotEmpty
            ? IconButton(
                icon: const Icon(Icons.clear, color: Colors.grey),
                onPressed: () {
                  _searchController.clear();
                  setState(() {
                    _searchQuery = "";
                    _submittedQuery = "";
                  });
                },
              )
            : null,
        filled: true,
        fillColor: const Color(0xFFF5F5F5),
        contentPadding: const EdgeInsets.symmetric(vertical: 0, horizontal: 20),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(30),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(30),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(30),
          borderSide: const BorderSide(color: Color(0xFF006C68), width: 1.5),
        ),
      ),
    );
  }

  Widget _buildResultsList() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection('items').snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Center(child: Text('เกิดข้อผิดพลาด: ${snapshot.error}'));
        }
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        final docs = snapshot.data!.docs;
        final query = _submittedQuery.toLowerCase().trim();

        if (query.isEmpty) {
          return const Center(child: Text('พิมพ์เพื่อค้นหา'));
        }

        // Client-side Filter & Sort
        List<Map<String, dynamic>> results = docs.map((doc) {
          final data = doc.data() as Map<String, dynamic>;
          data['id'] = doc.id;
          return data;
        }).where((data) {
          final title = (data['title'] ?? '').toString().toLowerCase();
          return title.contains(query);
        }).toList();

        // Sort by "closest name" (Starts with > Contains > Alphabetical)
        results.sort((a, b) {
          String titleA = (a['title'] ?? '').toString().toLowerCase();
          String titleB = (b['title'] ?? '').toString().toLowerCase();

          bool startA = titleA.startsWith(query);
          bool startB = titleB.startsWith(query);

          if (startA && !startB) return -1;
          if (!startA && startB) return 1;

          return titleA.compareTo(titleB);
        });

        if (results.isEmpty) {
          return Center(
            child: Text(query.isEmpty ? 'พิมพ์เพื่อค้นหา' : 'ไม่พบรายการ'),
          );
        }

        return ListView.separated(
          padding: const EdgeInsets.all(16),
          itemCount: results.length,
          separatorBuilder: (context, index) =>
              const Divider(height: 24, color: Color(0xFFEEEEEE)),
          itemBuilder: (context, index) =>
              _buildListItem(context, results[index]),
        );
      },
    );
  }

  Widget _buildListItem(BuildContext context, Map<String, dynamic> data) {
    final title = data['title'] ?? 'ไม่ระบุชื่อ';
    final description = data['description'] ?? '';
    final timestamp = data['date'] as Timestamp?;
    final type = data['type'] ?? 'lost';
    final bool isLost = type == 'lost';

    Widget imageWidget;
    final List<dynamic> images = data['images'] ?? [];
    if (images.isNotEmpty && images.first.toString().startsWith('http')) {
      imageWidget = Image.network(
        images.first,
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
        'assets/Checker.png',
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) {
          return Container(
            color: Colors.grey[200],
            child: const Icon(Icons.image_not_supported, color: Colors.grey),
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
          Container(
            width: 90,
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
                      style: const TextStyle(
                          fontSize: 10, color: Color(0xFFB3B3B3)),
                    ),
                    Text(
                      'รายละเอียด >',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: isLost
                            ? const Color(0xFF006C68)
                            : Colors.orange.shade800,
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

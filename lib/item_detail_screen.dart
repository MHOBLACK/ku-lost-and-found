import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

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
                      _buildActionButtons(),
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
    return '${dt.day.toString().padLeft(2, '0')}/${dt.month.toString().padLeft(2, '0')}/${dt.year}';
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
  Widget _buildActionButtons() {
    return Column(
      children: [
        // Dark Teal Button (Filled)
        SizedBox(
          width: double.infinity,
          height: 45,
          child: ElevatedButton(
            onPressed: () {},
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF005451),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              elevation: 0,
            ),
            child: const Text(
              'นี่คือของของฉัน', // "This is mine"
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
        // Light Teal Button (Outlined)
        SizedBox(
          width: double.infinity,
          height: 45,
          child: OutlinedButton(
            onPressed: () {},
            style: OutlinedButton.styleFrom(
              side: const BorderSide(color: Color(0xFF006C68)),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: const Text(
              'แชทกับผู้ที่พบของชิ้นนี้', // "Chat with finder"
              style: TextStyle(
                fontFamily: 'Line Seed Sans TH',
                fontWeight: FontWeight.bold,
                fontSize: 14,
                color: Color(0xFF006C68),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
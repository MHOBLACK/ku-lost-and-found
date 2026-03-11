// * หน้าหลักของแอปพลิเคชัน
import 'package:flutter/material.dart';
import 'add_item_page.dart';

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
                    
                    const SizedBox(height: 15), // Gap

                    // Frame 11 - Scrollable List
                    Expanded(
                      child: ListView.separated(
                        padding: EdgeInsets.zero,
                        itemCount: 6,
                        separatorBuilder: (context, index) => const SizedBox(height: 5),
                        itemBuilder: (context, index) => const NewsItemTile(),
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
  const NewsItemTile({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 110,
      padding: const EdgeInsets.symmetric(vertical: 10),
      color: Colors.white,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Rectangle 11 (Image)
          Container(
            width: 100,
            height: 90,
            decoration: const BoxDecoration(
              image: DecorationImage(
                image: AssetImage('assets/images/Grand-Opening.png'),
                fit: BoxFit.cover,
              ),
            ),
          ),
          
          const SizedBox(width: 10), // Gap

          // Frame 42 (Content)
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Text Body
                const SizedBox(
                  height: 60,
                  child: Text(
                    'Lorem ipsum dolor sit amet consectetur adipiscing elit. Quisque faucibus ex sapien vitae pellentesque sem placerat...',
                    style: TextStyle(
                      fontFamily: 'Line Seed Sans TH',
                      fontSize: 12,
                      fontWeight: FontWeight.w400,
                      color: Color(0xFF757575),
                      height: 1.25,
                    ),
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                
                const Spacer(),

                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'dd/MM/yyyy',
                      style: TextStyle(
                        fontFamily: 'Line Seed Sans TH',
                        fontSize: 12,
                        color: Color(0xFFB3B3B3),
                      ),
                    ),
                    
                    // Small Default Button
                    SizedBox(
                      width: 80,
                      height: 20,
                      child: OutlinedButton(
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(color: Color(0xFF006C68)),
                          padding: EdgeInsets.zero,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(5),
                          ),
                        ),
                        onPressed: () {},
                        child: const Text(
                          'อ่านเพิ่มเติม',
                          style: TextStyle(
                            fontFamily: 'Line Seed Sans TH',
                            fontWeight: FontWeight.w700,
                            fontSize: 10,
                            color: Color(0xFF006C68),
                          ),
                        ),
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
}
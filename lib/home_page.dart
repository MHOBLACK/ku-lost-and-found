// * หน้าหลักของแอปพลิเคชัน
import 'package:flutter/material.dart';

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

            // Frame 68 (Main Container)
            Positioned.fill(
              top: 134,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Frame 46 - Status Image
                    Container(
                      width: double.infinity,
                      height: 105,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(10),
                        image: const DecorationImage(
                          image: AssetImage('assets/เปิดใช้งานแล้ว!.png'),
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),
                    
                    const SizedBox(height: 17), // Gap

                    // Frame 47 - Default Button
                    SizedBox(
                      width: double.infinity,
                      height: 30,
                      child: OutlinedButton(
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(color: Color(0xFF006C68)),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        onPressed: () {},
                        child: const Text(
                          'ข้อความ',
                          style: TextStyle(
                            fontFamily: 'Line Seed Sans TH',
                            fontWeight: FontWeight.w700,
                            fontSize: 12,
                            color: Color(0xFF006C68),
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 17), // Gap

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
                image: AssetImage('assets/Checker.png'),
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
                    maxLines: 4,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                
                const Spacer(),

                // Frame 43 (Footer: Date + Small Button)
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
                          'ข้อความ',
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
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'firebase_options.dart';

import 'login_page.dart';
import 'home_page.dart';
import 'items_list_page.dart';
import 'check_item_page.dart';
import 'profile_page.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  runApp(const MainApp());
}

class MainApp extends StatelessWidget {
  const MainApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'KU Lost & Found',
      theme: ThemeData(
        fontFamily: 'Line Seed Sans TH',
      ),
      home: StreamBuilder<User?>(
        stream: FirebaseAuth.instance.authStateChanges(),
        builder: (context, snapshot) {
          if (snapshot.hasData) {
            return const BottomNavBar();
          }
          return const LoginPage();
        },
      ),
    );
  }
}


// * แท็บด้านล่าง
class BottomNavBar extends StatefulWidget {
  const BottomNavBar({super.key});

  @override
  State<BottomNavBar> createState() => _BottomNavBarState();
}

class _BottomNavBarState extends State<BottomNavBar> {
  int _selectedIndex = 0;

  // สีหลัก (เขียวเข้ม)
  // final Color _primaryColor = const Color(0xFF006C68);

  // รายการหน้าต่างๆ
  final List<Widget> pageOptions = const [
    HomePage(),
    ItemsListScreen(), // เปลี่ยนจาก SearchPage เป็นหน้ารายการของหายที่มี Tab
    // AddItemPage(), // หน้านี้จะไม่ถูกแสดงจริง เพราะปุ่มตรงกลางเป็น FAB
    CheckItemPage(),
    ProfilePage(),
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(child: pageOptions[_selectedIndex]),

      // floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      // floatingActionButton: Transform.translate(
      //   // *หัวใจสำคัญ: ดันปุ่มลงมา 25 pixel เพื่อให้อยู่ระดับเดียวกับบาร์
      //   offset: const Offset(0, 25),
      //   child: SizedBox(
      //     height: 70, // กำหนดขนาดปุ่ม
      //     width: 70,
      //     child: FloatingActionButton(
      //       backgroundColor: _primaryColor,
      //       elevation: 4,
      //       onPressed: () => _onItemTapped(2),
      //       shape: const CircleBorder(),
      //       child: Column(
      //         mainAxisAlignment: MainAxisAlignment.center,
      //         children: const [
      //           Icon(Icons.add, size: 28, color: Colors.white),
      //           Text(
      //             "แจ้งหาย",
      //             style: TextStyle(fontSize: 14, color: Colors.white, height: 1),
      //           ),
      //         ],
      //       ),
      //     ),
      //   ),
      // ),

      // --- แถบเมนูด้านล่าง ---
      bottomNavigationBar: CustomBottomNavBar(
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
      ),
    );
  }
}

class CustomBottomNavBar extends StatelessWidget {
  final int currentIndex;
  final Function(int) onTap;

  const CustomBottomNavBar({
    super.key,
    required this.currentIndex,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      // Menu
      width: double.infinity, // Matches your width spec but responsive
      height: 86,  // Matches your height spec
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(
          top: BorderSide(color: Color(0xFFEEEEEE), width: 1),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          _buildTabItem(0, Icons.home_outlined, "หน้าแรก"),
          _buildTabItem(1, Icons.add_box_outlined, "สร้างโพสต์"),
          _buildTabItem(2, Icons.search_rounded, "ค้นหา"),
          _buildTabItem(3, Icons.person_outline, "โปรไฟล์"),
        ],
      ),
    );
  }

  Widget _buildTabItem(int index, IconData icon, String label) {
    bool isActive = currentIndex == index;
    final Color primaryColor = const Color(0xFF006C68);

    return Expanded(
      child: GestureDetector(
        onTap: () => onTap(index),
        behavior: HitTestBehavior.opaque,
        child: SizedBox(
          height: 86,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Icon - Matches 24x24 spec
              Icon(
                icon,
                size: 24,
                color: isActive ? primaryColor : Colors.grey,
              ),
              const SizedBox(height: 5), // Gap spec
              // Text - Matches Typography specs
              Text(
                label,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontFamily: 'Line Seed Sans TH',
                  fontSize: 10,
                  height: 1.0, // line-height: 10px / font-size: 10px
                  fontWeight: FontWeight.w400,
                  color: isActive ? primaryColor : Colors.grey,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

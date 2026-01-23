import 'package:flutter/material.dart';
import 'home_page.dart';
import 'search_page.dart';
import 'add_item_page.dart';
import 'check_item_page.dart';
import 'profile_page.dart';

void main() {
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
      home: const BottomNavBar(),
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
  final Color _primaryColor = const Color(0xFF006C68);

  // รายการหน้าต่างๆ
  final List<Widget> pageOptions = const [
    HomePage(),
    SearchPage(),
    AddItemPage(), // หน้านี้จะไม่ถูกแสดงจริง เพราะปุ่มตรงกลางเป็น FAB
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

      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      floatingActionButton: Transform.translate(
        // *หัวใจสำคัญ: ดันปุ่มลงมา 25 pixel เพื่อให้อยู่ระดับเดียวกับบาร์
        offset: const Offset(0, 25),
        child: SizedBox(
          height: 70, // กำหนดขนาดปุ่ม
          width: 70,
          child: FloatingActionButton(
            backgroundColor: _primaryColor,
            elevation: 4,
            onPressed: () => _onItemTapped(2),
            shape: const CircleBorder(),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: const [
                Icon(Icons.add, size: 28, color: Colors.white),
                Text(
                  "แจ้งหาย",
                  style: TextStyle(fontSize: 14, color: Colors.white, height: 1),
                ),
              ],
            ),
          ),
        ),
      ),

      // --- แถบเมนูด้านล่าง ---
      bottomNavigationBar: BottomNavigationBar(
        backgroundColor: Colors.white, // พื้นหลังบาร์สีขาว
        type: BottomNavigationBarType.fixed,

        currentIndex: _selectedIndex,
        onTap: _onItemTapped,

        selectedItemColor: _primaryColor, 
        unselectedItemColor: Colors.grey[600], 

        selectedFontSize: 12,
        unselectedFontSize: 12,

        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home), 
            label: 'หน้าหลัก'
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.grid_view),
            label: 'ค้นหาของหาย',
          ),

          // ปุ่มหลอกตรงกลาง (เว้นที่ให้ FAB)
          BottomNavigationBarItem(
            icon: Icon(Icons.add, color: Colors.transparent),
            label: '',
          ),

          BottomNavigationBarItem(
            icon: Icon(Icons.search),
            label: 'ตรวจสอบวัตถุ',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person_outline),
            label: 'บัญชีของฉัน',
          ),
        ],
      ),
    );
  }
}

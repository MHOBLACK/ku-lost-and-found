// * หน้าหลักของแอปพลิเคชัน
import 'package:flutter/material.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(

      ),
      body: Center(
        child: Column(
          children: [
            Image.asset(
              "assets/images/Logo.png",
              width: 110,
            ),

            _buildBanner(),

          ],
        ),
      )
    );
  }
}

Widget _buildBanner() {
  return SizedBox(
    height: 105,
    child: ListView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      children: [
        _buildBannerItem(""),
        _buildBannerItem(""),
        _buildBannerItem(""),
      ],
    ),
  );
}

Widget _buildBannerItem(String imgPath) {
  return Container(
    width: 365,
    margin: const EdgeInsets.only(right: 16),
    decoration: BoxDecoration(
      borderRadius: BorderRadius.circular(10)
    ),
    child: Column(
      children: [
        Expanded(
          child: ClipRRect(
            child: SizedBox(
              width: double.infinity,
              child: Image.asset(imgPath, fit: BoxFit.cover),
            ),
          ),
        ),
      ],
    )
  );
}
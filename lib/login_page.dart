import 'package:flutter/material.dart';

class LoginPage extends StatelessWidget {
  const LoginPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(

      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
              Image.asset('assets/images/Logo.png', width: 150, height: 150,),
              Text( 
                'ระบบแจ้ง ค้นหา ของหาย\nมหาวิทยาลัยเกษตรศาสตร์',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontFamily: 'Line Seed Sans TH',
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.black
                ),
              ),
              const SizedBox(height: 45),
              OutlinedButton(
                onPressed: () {},
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 50, vertical: 15),
                  textStyle: const TextStyle(fontFamily: 'Line Seed Sans TH', fontSize: 16, fontWeight: FontWeight.bold),
                  foregroundColor: Color.fromRGBO(0, 108, 104, 100),
                  side: const BorderSide(color: Color.fromRGBO(0, 108, 104, 100), width: 1),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                child: const Text('เข้าสู่ระบบด้วย @ku.th'),
              ),
            ],
          )
        )
      );
  }
}

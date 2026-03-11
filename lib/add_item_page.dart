// * หน้าเพิ่มของหาย
import 'dart:io';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

final user = FirebaseAuth.instance.currentUser;
class AddItemPage extends StatefulWidget {
  final String itemType; // 'lost' or 'found'
  AddItemPage({super.key, required this.itemType});

  @override
  State<AddItemPage> createState() => _AddItemPageState();
}

class _AddItemPageState extends State<AddItemPage> {
  final _formKey = GlobalKey<FormState>();

  // Common Controllers
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController _locationDetailController =
      TextEditingController();

  // Found Specific Controllers
  final TextEditingController _contactsDetailController = TextEditingController();
  final TextEditingController _dropoffPointController = TextEditingController();

  bool _isDroppedOff = false;
  bool _isSubmitting = false;

  // พิกัดเริ่มต้น (ม.เกษตร บางเขน)
  LatLng _selectedLocation = const LatLng(13.8476, 100.5696);

  final ImagePicker _picker = ImagePicker();
  List<File> _imageFiles = [];
  String _uploadStatus = '';

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _locationDetailController.dispose();
    _contactsDetailController.dispose();
    _dropoffPointController.dispose();
    super.dispose();
  }

  Future<void> _pickImages() async {
    final List<XFile> selectedImages = await _picker.pickMultiImage();
    if (selectedImages.isNotEmpty) {
      setState(() {
        _imageFiles.addAll(selectedImages.map((e) => File(e.path)));
      });
    }
  }

  Future<List<String>> _uploadImagesToCloud() async {
    List<String> uploadedUrls = [];

    String cloudName = "dq7hiqpfh";
    String uploadPreset = "ku-lost-and-found";

    for (int i = 0; i < _imageFiles.length; i++) {
      setState(() {
        _uploadStatus = 'กำลังอัปโหลดรูปที่ ${i + 1}/${_imageFiles.length}...';
      });

      try {
        var uri = Uri.parse(
          'https://api.cloudinary.com/v1_1/$cloudName/image/upload',
        );
        var request = http.MultipartRequest('POST', uri);
        request.fields['upload_preset'] = uploadPreset;
        request.files.add(
          await http.MultipartFile.fromPath('file', _imageFiles[i].path),
        );

        var response = await request.send();
        if (response.statusCode == 200) {
          var responseData = await response.stream.toBytes();
          var result = json.decode(String.fromCharCodes(responseData));
          uploadedUrls.add(result['secure_url']); // ได้ URL ของรูปมาแล้ว!
        }
      } catch (e) {
        debugPrint('Upload error: $e');
      }
    }
    return uploadedUrls;
  }

  Future<void> _submitData() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isSubmitting = true);

    try {

      List<String> imageUrls = [];

      if (_imageFiles.isNotEmpty) {
        imageUrls = await _uploadImagesToCloud();
      }
      
      if (widget.itemType == 'lost') {
        await _submitLostItem(imageUrls);
      } else if (widget.itemType == 'found') {
        await _submitFoundItem(imageUrls);
      }

      if (mounted) {
        Navigator.pop(context); // Close page on success
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
    } finally {
      if (mounted) setState(() {
          _isSubmitting = false;
          _uploadStatus = '';
        });
    }
  }

  Future<void> _submitLostItem(List<String> imageUrls) async {
    await FirebaseFirestore.instance.collection('items').add({
      'title': _nameController.text.trim(),
      'description': _descriptionController.text.trim(),
      'location_detail': _locationDetailController.text.trim(),
      'location': GeoPoint(
        _selectedLocation.latitude,
        _selectedLocation.longitude,
      ),
      'status': 'lost',
      'created_date': FieldValue.serverTimestamp(),
      'contacts': _contactsDetailController.text.trim(), // <--- เพิ่มบรรทัดนี้
      'uid': user?.uid,
      'displayName': user?.displayName,
      'images': imageUrls,
    });
  }

  Future<void> _submitFoundItem(List<String> imageUrls) async {
    final user = FirebaseAuth.instance.currentUser;
    await FirebaseFirestore.instance.collection('items').add({
      'title': _nameController.text.trim(),
      'description': _descriptionController.text.trim(),
      'location_detail': _locationDetailController.text.trim(),
      'location': GeoPoint(
        _selectedLocation.latitude,
        _selectedLocation.longitude,
      ),
      'status': 'found',
      'created_date': FieldValue.serverTimestamp(),
      'contacts': _contactsDetailController.text.trim(),
      'dropoff_point': _isDroppedOff ? _dropoffPointController.text.trim() : '',
      'uid': user?.uid,
      'displayName': user?.displayName,
      'images': imageUrls,
    });
  }

  Widget _buildCommonFields() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'รายละเอียดสิ่งของ',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 10),
        TextFormField(
          controller: _nameController,
          maxLength: 100,
          decoration: const InputDecoration(
            labelText: 'ชื่อสิ่งของ (เช่น กระเป๋าสตางค์, กุญแจรถ)',
            border: OutlineInputBorder(),
            prefixIcon: Icon(Icons.shopping_bag_outlined),
          ),
          validator:
              (value) =>
                  value == null || value.isEmpty
                      ? 'กรุณาระบุชื่อสิ่งของ'
                      : null,
        ),
        const SizedBox(height: 15),
        TextFormField(
          controller: _descriptionController,
          maxLength: 255,
          maxLines: 3,
          keyboardType: TextInputType.multiline,
          decoration: const InputDecoration(
            labelText: 'รายละเอียดเพิ่มเติม (สี, ยี่ห้อ, จุดสังเกต)',
            border: OutlineInputBorder(),
            prefixIcon: Icon(Icons.description_outlined),
            alignLabelWithHint: true,
          ),
        ),
        const SizedBox(height: 15),
        TextFormField(
          controller: _locationDetailController,
          maxLength: 255,
          decoration: const InputDecoration(
            labelText: 'รายละเอียดสถานที่ (เช่น ตึก SC45 ชั้น 8)',
            border: OutlineInputBorder(),
            prefixIcon: Icon(Icons.pin_drop_outlined),
          ),
        ),
        const SizedBox(height: 15),

        // --- ส่วนที่ย้ายมาใหม่: ช่องทางการติดต่อ ---
        TextFormField(
          controller: _contactsDetailController,
          maxLength: 255,
          decoration: const InputDecoration(
            labelText: 'ช่องทางการติดต่อ (เบอร์โทร, Line, FB ฯลฯ)',
            border: OutlineInputBorder(),
            prefixIcon: Icon(Icons.contact_phone_outlined),
          ),
          validator:
              (value) =>
                  value == null || value.isEmpty
                      ? 'กรุณาระบุช่องทางการติดต่อ'
                      : null,
        ),

        const SizedBox(height: 25),
      ],
    );
  }

  Widget _buildFoundSpecificFields() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // เปลี่ยนชื่อหัวข้อให้เหมาะกับข้อมูลที่เหลืออยู่
        const Text(
          'ข้อมูลการฝากของ (ถ้ามี)',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 10),
        CheckboxListTile(
          title: const Text('ฝากของไว้ที่จุดรับฝาก / ส่วนกลาง'),
          value: _isDroppedOff,
          activeColor: const Color(0xFF006C68),
          contentPadding: EdgeInsets.zero,
          controlAffinity: ListTileControlAffinity.leading,
          onChanged: (bool? value) {
            setState(() {
              _isDroppedOff = value ?? false;
              if (!_isDroppedOff) _dropoffPointController.clear();
            });
          },
        ),
        if (_isDroppedOff) ...[
          const SizedBox(height: 5),
          TextFormField(
            controller: _dropoffPointController,
            maxLength: 255,
            decoration: const InputDecoration(
              labelText: 'ระบุจุดที่ฝากของไว้ (เช่น ป้อมยามประตู 1)',
              border: OutlineInputBorder(),
              prefixIcon: Icon(Icons.storefront_outlined),
            ),
            validator:
                (value) =>
                    _isDroppedOff && (value == null || value.isEmpty)
                        ? 'กรุณาระบุจุดที่ฝากของไว้'
                        : null,
          ),
        ],
        const SizedBox(height: 25),
      ],
    );
  }

  Widget _buildImagePickerSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'รูปภาพประกอบ (ถ้ามี)',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 10),

        // ปุ่มกดเลือกรูป
        OutlinedButton.icon(
          onPressed: _pickImages,
          icon: const Icon(Icons.add_photo_alternate, color: Color(0xFF006C68)),
          label: const Text(
            'เพิ่มรูปภาพ',
            style: TextStyle(color: Color(0xFF006C68)),
          ),
          style: OutlinedButton.styleFrom(
            side: const BorderSide(color: Color(0xFF006C68)),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        ),
        const SizedBox(height: 10),

        // แสดงรูปตัวอย่างที่เลือกไว้
        if (_imageFiles.isNotEmpty)
          SizedBox(
            height: 100,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: _imageFiles.length,
              itemBuilder: (context, index) {
                return Stack(
                  children: [
                    Container(
                      margin: const EdgeInsets.only(right: 10),
                      width: 100,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(10),
                        image: DecorationImage(
                          image: FileImage(_imageFiles[index]),
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),
                    // ปุ่มกากบาทลบรูป
                    Positioned(
                      top: 0,
                      right: 10,
                      child: GestureDetector(
                        onTap:
                            () => setState(() => _imageFiles.removeAt(index)),
                        child: Container(
                          color: Colors.black54,
                          child: const Icon(
                            Icons.close,
                            color: Colors.white,
                            size: 20,
                          ),
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        const SizedBox(height: 25),
      ],
    );
  }

  Widget _buildMapSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'ระบุตำแหน่งที่หาย / พบ',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 5),
        const Text(
          'แตะบนแผนที่เพื่อปักหมุดตำแหน่ง',
          style: TextStyle(color: Colors.grey),
        ),
        const SizedBox(height: 10),
        Container(
          height: 300,
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey.shade400),
            borderRadius: BorderRadius.circular(10),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: FlutterMap(
              options: MapOptions(
                initialCenter: _selectedLocation,
                initialZoom: 15.0,
                onTap:
                    (tapPosition, point) =>
                        setState(() => _selectedLocation = point),
              ),
              children: [
                TileLayer(
                  urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                  userAgentPackageName: 'com.example.lostNFoundTest',
                ),
                MarkerLayer(
                  markers: [
                    Marker(
                      point: _selectedLocation,
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
        const SizedBox(height: 30),
      ],
    );
  }

  Widget _buildSubmitButton() {
    return SizedBox(
      width: double.infinity,
      height: 50,
      child: ElevatedButton(
        onPressed: _isSubmitting ? null : _submitData,
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF006C68),
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
        child:
            _isSubmitting
                ? const CircularProgressIndicator(color: Colors.white)
                : Text(
                  widget.itemType == 'lost'
                      ? 'ยืนยันการแจ้งหาย'
                      : 'ยืนยันการแจ้งพบ',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.itemType == 'lost' ? 'แจ้งของหาย' : 'แจ้งพบของ'),
        backgroundColor: const Color(0xFF006C68),
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildImagePickerSection(),
                _buildCommonFields(),
                if (widget.itemType == 'found') _buildFoundSpecificFields(),
                _buildMapSection(),
                _buildSubmitButton(),
                const SizedBox(height: 30),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

  // * --- New Widget to Preview Selected Images ---

  /*
  Widget _buildImagePreview() {
    if (_imageFiles.isEmpty) {
      return const SizedBox.shrink();
    }
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: _imageFiles.length,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: 8,
        mainAxisSpacing: 8,
      ),
      itemBuilder: (context, index) {
        return Stack(
          alignment: Alignment.topRight,
          children: [
            Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(8),
                image: DecorationImage(
                  image: FileImage(File(_imageFiles[index].path)),
                  fit: BoxFit.cover,
                ),
              ),
            ),
            IconButton(
              icon: const CircleAvatar(
                radius: 12,
                backgroundColor: Colors.black54,
                child: Icon(Icons.close, color: Colors.white, size: 14),
              ),
              onPressed: () {
                setState(() {
                  _imageFiles.removeAt(index);
                });
              },
            ),
          ],
        );
      },
    );
  }
  */

// * A simple HTTP client that injects Google auth headers into every request
/* 
class _GoogleAuthClient extends http.BaseClient {
  final Map<String, String> _headers;
  final http.Client _client = http.Client();

  _GoogleAuthClient(this._headers);

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) {
    request.headers.addAll(_headers);
    return _client.send(request);
  }
} 
*/
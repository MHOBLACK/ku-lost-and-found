import 'dart:io';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class EditItemPage extends StatefulWidget {
  final Map<String, dynamic> data;

  const EditItemPage({super.key, required this.data});

  @override
  State<EditItemPage> createState() => _EditItemPageState();
}

class _EditItemPageState extends State<EditItemPage> {
  final _formKey = GlobalKey<FormState>();

  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController _locationDetailController =
      TextEditingController();
  final TextEditingController _contactsDetailController =
      TextEditingController();
  final TextEditingController _dropoffPointController = TextEditingController();

  bool _isDroppedOff = false;
  bool _isSubmitting = false;
  late String _itemType;
  LatLng _selectedLocation = const LatLng(13.8476, 100.5696);

  final ImagePicker _picker = ImagePicker();
  List<String> _existingImages = []; // เก็บ URL รูปเดิมที่โหลดมาจาก DB
  List<File> _newImageFiles = []; // เก็บไฟล์รูปใหม่ที่เพิ่งเลือกจากเครื่อง
  String _uploadStatus = '';

  Future<void> _pickImages() async {
    final List<XFile> selectedImages = await _picker.pickMultiImage();
    if (selectedImages.isNotEmpty) {
      setState(() {
        _newImageFiles.addAll(selectedImages.map((e) => File(e.path)));
      });
    }
  }

  Future<List<String>> _uploadNewImagesToCloud() async {
    List<String> uploadedUrls = [];
    String cloudName = "dq7hiqpfh"; // ใช้ค่าเดียวกับหน้า Add
    String uploadPreset = "ku-lost-and-found";

    for (int i = 0; i < _newImageFiles.length; i++) {
      setState(() {
        _uploadStatus =
            'กำลังอัปโหลดรูปใหม่ ${i + 1}/${_newImageFiles.length}...';
      });

      try {
        var uri = Uri.parse(
          'https://api.cloudinary.com/v1_1/$cloudName/image/upload',
        );
        var request = http.MultipartRequest('POST', uri);
        request.fields['upload_preset'] = uploadPreset;
        request.files.add(
          await http.MultipartFile.fromPath('file', _newImageFiles[i].path),
        );

        var response = await request.send();
        if (response.statusCode == 200) {
          var responseData = await response.stream.toBytes();
          var result = json.decode(String.fromCharCodes(responseData));
          uploadedUrls.add(result['secure_url']);
        }
      } catch (e) {
        debugPrint('Upload error: $e');
      }
    }
    return uploadedUrls;
  }

  @override
  void initState() {
    super.initState();
    // โหลดข้อมูลเดิมมาใส่ในฟอร์ม
    _itemType = widget.data['status'] ?? 'lost';
    _nameController.text = widget.data['title'] ?? '';
    _descriptionController.text = widget.data['description'] ?? '';
    _locationDetailController.text = widget.data['location_detail'] ?? '';

    if (_itemType == 'found') {
      _contactsDetailController.text = widget.data['contacts'] ?? '';
      _dropoffPointController.text = widget.data['dropoff_point'] ?? '';
      _isDroppedOff = _dropoffPointController.text.isNotEmpty;
    }

    if (widget.data['location'] != null) {
      GeoPoint geo = widget.data['location'];
      _selectedLocation = LatLng(geo.latitude, geo.longitude);
    }

    if (widget.data['images'] != null && widget.data['images'] is List) {
      // แปลง List<dynamic> เป็น List<String> อย่างปลอดภัย
      _existingImages =
          (widget.data['images'] as List).map((e) => e.toString()).toList();
    } else if (widget.data['imageUrl'] != null) {
      // รองรับกรณีข้อมูลเก่ามีแค่รูปเดียว
      _existingImages = [widget.data['imageUrl'].toString()];
    } else {
      _existingImages = [];
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _locationDetailController.dispose();
    _contactsDetailController.dispose();
    _dropoffPointController.dispose();
    super.dispose();
  }

  Future<void> _updateData() async {
    if (!_formKey.currentState!.validate()) return;
    if (widget.data['id'] == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('ไม่พบ ID ของโพสต์นี้')));
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      List<String> finalImageUrls = List.from(_existingImages);

      if (_newImageFiles.isNotEmpty) {
        List<String> newlyUploadedUrls = await _uploadNewImagesToCloud();
        finalImageUrls.addAll(newlyUploadedUrls);
      }

      Map<String, dynamic> updateData = {
        'title': _nameController.text.trim(),
        'description': _descriptionController.text.trim(),
        'location_detail': _locationDetailController.text.trim(),
        'location': GeoPoint(
          _selectedLocation.latitude,
          _selectedLocation.longitude,
        ),
        'images': finalImageUrls,
      };

      if (_itemType == 'found') {
        updateData['contacts'] = _contactsDetailController.text.trim();
        updateData['dropoff_point'] =
            _isDroppedOff ? _dropoffPointController.text.trim() : '';
      }

      await FirebaseFirestore.instance
          .collection('items')
          .doc(widget.data['id'])
          .update(updateData);

      if (mounted) {
        Navigator.pop(context); // ปิดหน้าต่างแก้ไขเมื่อเสร็จสิ้น
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('อัปเดตข้อมูลสำเร็จ')));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    } finally {
      if (mounted)
        setState(() {
          _isSubmitting = false;
          _uploadStatus = '';
        });
    }
  }

  // ใช้ UI ของฟอร์มเหมือน AddItemPage
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
          maxLines: 3,
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
          decoration: const InputDecoration(
            labelText: 'รายละเอียดสถานที่ (เช่น ตึก SC45 ชั้น 8)',
            border: OutlineInputBorder(),
            prefixIcon: Icon(Icons.pin_drop_outlined),
          ),
        ),
        const SizedBox(height: 25),
      ],
    );
  }

  Widget _buildFoundSpecificFields() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'ข้อมูลการติดต่อผู้แจ้งพบ',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 10),
        TextFormField(
          controller: _contactsDetailController,
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

  Widget _buildImageEditSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'จัดการรูปภาพประกอบ',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 10),

        OutlinedButton.icon(
          onPressed: _pickImages,
          icon: const Icon(Icons.add_photo_alternate, color: Color(0xFF006C68)),
          label: const Text(
            'เพิ่มรูปภาพใหม่',
            style: TextStyle(color: Color(0xFF006C68)),
          ),
          style: OutlinedButton.styleFrom(
            side: const BorderSide(color: Color(0xFF006C68)),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        ),
        const SizedBox(height: 15),

        // แสดงรูปเดิมที่มาจาก Firestore
        if (_existingImages.isNotEmpty) ...[
          const Text(
            'รูปภาพเดิม:',
            style: TextStyle(color: Colors.grey, fontSize: 14),
          ),
          const SizedBox(height: 5),
          SizedBox(
            height: 100,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: _existingImages.length,
              itemBuilder: (context, index) {
                return Stack(
                  children: [
                    Container(
                      margin: const EdgeInsets.only(right: 10),
                      width: 100,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(10),
                        image: DecorationImage(
                          image: NetworkImage(
                            _existingImages[index],
                          ), // โหลดจาก URL
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),
                    Positioned(
                      top: 0,
                      right: 10,
                      child: GestureDetector(
                        onTap:
                            () =>
                                setState(() => _existingImages.removeAt(index)),
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
          const SizedBox(height: 10),
        ],

        // แสดงรูปใหม่ที่เพิ่งเลือกจากเครื่อง
        if (_newImageFiles.isNotEmpty) ...[
          const Text(
            'รูปภาพใหม่ (รออัปโหลด):',
            style: TextStyle(color: Colors.grey, fontSize: 14),
          ),
          const SizedBox(height: 5),
          SizedBox(
            height: 100,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: _newImageFiles.length,
              itemBuilder: (context, index) {
                return Stack(
                  children: [
                    Container(
                      margin: const EdgeInsets.only(right: 10),
                      width: 100,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(10),
                        image: DecorationImage(
                          image: FileImage(
                            _newImageFiles[index],
                          ), // โหลดจาก File
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),
                    Positioned(
                      top: 0,
                      right: 10,
                      child: GestureDetector(
                        onTap:
                            () =>
                                setState(() => _newImageFiles.removeAt(index)),
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
        ],
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
                      width: 39,
                      height: 39,
                      alignment: Alignment.topCenter,
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('แก้ไขข้อมูล'),
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
                _buildCommonFields(),
                if (_itemType == 'found') _buildFoundSpecificFields(),
                _buildImageEditSection(),
                _buildMapSection(),
                if (_uploadStatus.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: Text(
                      _uploadStatus,
                      style: const TextStyle(color: Colors.orange),
                    ),
                  ),
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    onPressed: _isSubmitting ? null : _updateData,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF006C68),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    child:
                        _isSubmitting
                            ? const CircularProgressIndicator(
                              color: Colors.white,
                            )
                            : const Text(
                              'บันทึกการแก้ไข',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                  ),
                ),
                const SizedBox(height: 30),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

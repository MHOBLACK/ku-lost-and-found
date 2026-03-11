// * หน้าเพิ่มของหาย
// import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
// import 'package:image_picker/image_picker.dart';
// import 'package:googleapis/drive/v3.dart' as drive;
// import 'package:http/http.dart' as http;
// import 'package:google_sign_in/google_sign_in.dart';
// import 'firebase_options.dart';

class AddItemPage extends StatefulWidget {
  final String itemType; // 'lost' or 'found'
  const AddItemPage({super.key, required this.itemType});

  @override
  State<AddItemPage> createState() => _AddItemPageState();
}

class _AddItemPageState extends State<AddItemPage> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController _locationDetailController = TextEditingController();
  bool _isSubmitting = false;

  // พิกัดเริ่มต้น (ม.เกษตร บางเขน)
  LatLng _selectedLocation = const LatLng(13.8476, 100.5696);

  // --- State for Image Uploading ---
  // final ImagePicker _picker = ImagePicker();
  // List<XFile> _imageFiles = [];
  // String _uploadStatus = '';

  // --- End State for Image Uploading ---

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _locationDetailController.dispose();
    super.dispose();
  }

  // --- New Method: Pick Images from Gallery ---
  // Future<void> _pickImages() async {
  //   final List<XFile> selectedImages = await _picker.pickMultiImage();
  //   if (selectedImages.isNotEmpty) {
  //     setState(() {
  //       _imageFiles.addAll(selectedImages);
  //     });
  //   }
  // }

  // --- New Method: Authenticate with Google ---
  // Future<http.Client?> _getAuthClient() async {
  //   final scopes = [drive.DriveApi.driveFileScope];
  //   
  //   try {
  //     final googleSignIn = GoogleSignIn(
  //       clientId: DefaultFirebaseOptions.googleDriveClientId,
  //       scopes: scopes,
  //     );
  //
  //     // Ensure the user is signed in
  //     final GoogleSignInAccount? account = await googleSignIn.signIn();
  //     if (account == null) {
  //       // User cancelled the sign-in flow
  //       return null;
  //     }
  //
  //     // Get the auth headers (this handles refreshing tokens if needed)
  //     final authHeaders = await account.authHeaders;
  //
  //     // Return a custom http client that injects these headers
  //     return _GoogleAuthClient(authHeaders);
  //
  //   } catch (e) {
  //     debugPrint('Error getting auth client: $e');
  //     ScaffoldMessenger.of(context).showSnackBar(
  //       SnackBar(content: Text('Google Authentication Failed: $e')),
  //     );
  //     return null;
  //   }
  // }

  // --- New Method: Upload Images to Google Drive and get URLs ---
  // Future<List<String>> _uploadImagesAndGetUrls(http.Client client) async {
  //   final driveApi = drive.DriveApi(client);
  //   List<String> uploadedUrls = [];
  //
  //   for (int i = 0; i < _imageFiles.length; i++) {
  //     final imageFile = _imageFiles[i];
  //     setState(() {
  //       _uploadStatus = 'Uploading image ${i + 1}/${_imageFiles.length}...';
  //     });
  //
  //     try {
  //       final fileToUpload = File(imageFile.path);
  //       var driveFile = drive.File();
  //       driveFile.name =
  //           'item_${DateTime.now().millisecondsSinceEpoch}_${imageFile.name}';
  //
  //       var media =
  //           drive.Media(fileToUpload.openRead(), fileToUpload.lengthSync());
  //
  //       // The create method returns a File object. By requesting the 'id' field,
  //       // we can be efficient and construct our own image URL.
  //       final uploadedFile = await driveApi.files
  //           .create(driveFile, uploadMedia: media, $fields: 'id');
  //
  //       if (uploadedFile.id != null) {
  //         var permissions = drive.Permission()..role = 'reader'..type = 'anyone';
  //         await driveApi.permissions.create(permissions, uploadedFile.id!);
  //         // Construct a URL that can be used directly by Image.network.
  //         // This avoids using webViewLink, which is not a direct image link.
  //         final imageUrl =
  //             'https://drive.google.com/uc?export=view&id=${uploadedFile.id}';
  //         uploadedUrls.add(imageUrl);
  //       }
  //
  //     } catch (e) {
  //       debugPrint('Error uploading file: $e');
  //     }
  //   }
  //   return uploadedUrls;
  // }

  Future<void> _submitData() async {
    if (!_formKey.currentState!.validate()) return;

    // setState(() {
    //   _isSubmitting = true;
    //   _uploadStatus = 'Starting submission...';
    // });
    setState(() => _isSubmitting = true);

    // List<String> imageUrls = [];

    // 1. Check if there are images to upload
    // if (_imageFiles.isNotEmpty) {
    //   // 2. Authenticate and get HTTP client
    //   setState(() {
    //     _uploadStatus = 'Please sign in with Google to upload images...';
    //   });
    //   http.Client? authClient = await _getAuthClient();
    //
    //   if (authClient != null) {
    //     // 3. Upload images and get URLs
    //     imageUrls = await _uploadImagesAndGetUrls(authClient);
    //     authClient.close();
    //   } else {
    //     setState(() {
    //       _isSubmitting = false;
    //       _uploadStatus = '';
    //     });
    //     return;
    //   }
    // }

    // 4. Save data to Firestore
    // setState(() {
    //   _uploadStatus = 'Saving post to database...';
    // });

    try {
      final user = FirebaseAuth.instance.currentUser;
      
      await FirebaseFirestore.instance.collection('items').add({
        'title': _nameController.text.trim(),
        'description': _descriptionController.text.trim(),
        'location_detail': _locationDetailController.text.trim(),
        'location': GeoPoint(_selectedLocation.latitude, _selectedLocation.longitude),
        'type': widget.itemType, // 'lost' or 'found'
        'date': FieldValue.serverTimestamp(),
        'uid': user?.uid,
        'email': user?.email,
        // 'images': imageUrls,
      });

      if (mounted) {
        Navigator.pop(context); // Close page on success
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
    } finally {
      // if (mounted) setState(() {
      //   _isSubmitting = false;
      //   _uploadStatus = '';
      // });
      if (mounted) setState(() => _isSubmitting = false);
    }
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
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'กรุณาระบุชื่อสิ่งของ';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 25),

                // --- New UI for Image Uploading ---
                // const Text(
                //   'รูปภาพประกอบ',
                //   style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                // ),
                // const SizedBox(height: 10),
                // _buildImagePreview(),
                // const SizedBox(height: 10),
                // OutlinedButton.icon(
                //   onPressed: _pickImages,
                //   icon: const Icon(Icons.add_photo_alternate_outlined),
                //   label: const Text('เพิ่มรูปภาพ'),
                //   style: OutlinedButton.styleFrom(
                //     foregroundColor: const Color(0xFF006C68),
                //     side: const BorderSide(color: Color(0xFF006C68)),
                //   ),
                // ),
                const SizedBox(height: 15),
                TextFormField(
                  controller: _descriptionController,
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
                  decoration: const InputDecoration(
                    labelText: 'รายละเอียดสถานที่ (เช่น ตึก SC45 ชั้น 8)',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.pin_drop_outlined),
                  ),
                ),
                const SizedBox(height: 25),
                const Text(
                  'ระบุตำแหน่งที่หาย',
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
                        onTap: (tapPosition, point) {
                          setState(() {
                            _selectedLocation = point;
                          });
                        },
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
                SizedBox(
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
                    child: _isSubmitting 
                      // ? Row(
                      //     mainAxisAlignment: MainAxisAlignment.center,
                      //     children: [const CircularProgressIndicator(color: Colors.white), const SizedBox(width: 15), Text(_uploadStatus)],
                      //   )
                      ? const CircularProgressIndicator(color: Colors.white)
                      : Text(
                          widget.itemType == 'lost' ? 'ยืนยันการแจ้งหาย' : 'ยืนยันการแจ้งพบ',
                          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
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

  // --- New Widget to Preview Selected Images ---
  // Widget _buildImagePreview() {
  //   if (_imageFiles.isEmpty) {
  //     return const SizedBox.shrink();
  //   }
  //   return GridView.builder(
  //     shrinkWrap: true,
  //     physics: const NeverScrollableScrollPhysics(),
  //     itemCount: _imageFiles.length,
  //     gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
  //       crossAxisCount: 3,
  //       crossAxisSpacing: 8,
  //       mainAxisSpacing: 8,
  //     ),
  //     itemBuilder: (context, index) {
  //       return Stack(
  //         alignment: Alignment.topRight,
  //         children: [
  //           Container(
  //             decoration: BoxDecoration(
  //               borderRadius: BorderRadius.circular(8),
  //               image: DecorationImage(
  //                 image: FileImage(File(_imageFiles[index].path)),
  //                 fit: BoxFit.cover,
  //               ),
  //             ),
  //           ),
  //           IconButton(
  //             icon: const CircleAvatar(
  //               radius: 12,
  //               backgroundColor: Colors.black54,
  //               child: Icon(Icons.close, color: Colors.white, size: 14),
  //             ),
  //             onPressed: () {
  //               setState(() {
  //                 _imageFiles.removeAt(index);
  //               });
  //             },
  //           ),
  //         ],
  //       );
  //     },
  //   );
  // }
}

// A simple HTTP client that injects Google auth headers into every request
// class _GoogleAuthClient extends http.BaseClient {
//   final Map<String, String> _headers;
//   final http.Client _client = http.Client();
//
//   _GoogleAuthClient(this._headers);
//
//   @override
//   Future<http.StreamedResponse> send(http.BaseRequest request) {
//     request.headers.addAll(_headers);
//     return _client.send(request);
//   }
// }
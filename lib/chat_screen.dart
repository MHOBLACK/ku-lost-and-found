import 'dart:io';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';
import 'chat_detail_page.dart';

class ChatScreen extends StatefulWidget {
  final String chatRoomId;
  final String otherUserId;
  final String itemName;

  const ChatScreen({
    super.key,
    required this.chatRoomId,
    required this.otherUserId,
    required this.itemName,
  });

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController _messageController = TextEditingController();
  final FirebaseAuth _auth = FirebaseAuth.instance;

  final ImagePicker _picker = ImagePicker();
  List<File> _imageFiles = [];
  LatLng? _selectedLocation;
  bool _isUploading = false;
  String _uploadStatus = '';
  Position?
  _currentUserPosition; // To store the viewer's location for the chat map
  late Stream<QuerySnapshot> _messagesStream;

  @override
  void initState() {
    super.initState();
    _fetchCurrentLocation();
    _messagesStream = FirebaseFirestore.instance
        .collection('chats')
        .doc(widget.chatRoomId)
        .collection('messages')
        .orderBy('timestamp', descending: true)
        .snapshots();
  }

  Future<void> _fetchCurrentLocation() async {
    try {
      Position pos = await _determinePosition();
      if (mounted) {
        setState(() {
          _currentUserPosition = pos;
        });
      }
    } catch (e) {
      debugPrint("Could not fetch current location: $e");
    }
  }

  Future<Position> _determinePosition() async {
    bool serviceEnabled;
    LocationPermission permission;

    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      return Future.error('Location services are disabled.');
    }

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        return Future.error('Location permissions are denied');
      }
    }

    if (permission == LocationPermission.deniedForever) {
      return Future.error(
        'Location permissions are permanently denied, we cannot request permissions.',
      );
    }

    return await Geolocator.getCurrentPosition();
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

  Future<void> _selectLocation() async {
    LatLng initialCenter = const LatLng(13.8476, 100.5696); // Default KU
    try {
      Position p = await _determinePosition();
      initialCenter = LatLng(p.latitude, p.longitude);
    } catch (_) {}

    LatLng tempLocation = initialCenter;

    await showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              contentPadding: EdgeInsets.zero,
              content: SizedBox(
                width: double.maxFinite,
                height: 400,
                child: FlutterMap(
                  options: MapOptions(
                    initialCenter: initialCenter,
                    initialZoom: 15.0,
                    onTap: (tapPosition, point) {
                      setDialogState(() {
                        tempLocation = point;
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
                        // User's current position (approximate)
                        Marker(
                          point: initialCenter,
                          width: 20,
                          height: 20,
                          child: Container(
                            decoration: BoxDecoration(
                              color: Colors.blue.withOpacity(0.5),
                              shape: BoxShape.circle,
                              border: Border.all(color: Colors.white, width: 2),
                            ),
                          ),
                        ),
                        // Selected Pin
                        Marker(
                          point: tempLocation,
                          width: 40,
                          height: 40,
                          child: const Icon(Icons.location_on, color: Colors.red, size: 40),
                          alignment: Alignment.bottomCenter,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('ยกเลิก'),
                ),
                TextButton(
                  onPressed: () {
                    setState(() {
                      _selectedLocation = tempLocation;
                    });
                    Navigator.pop(context);
                  },
                  child: const Text('ยืนยันตำแหน่งนี้'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _showAttachmentOptions() {
    showModalBottomSheet(
      context: context,
      builder: (BuildContext context) {
        return SafeArea(
          child: Wrap(
            children: <Widget>[
              ListTile(
                leading: const Icon(Icons.image),
                title: const Text('รูปภาพ'),
                onTap: () {
                  Navigator.pop(context);
                  _pickImages();
                },
              ),
              ListTile(
                leading: const Icon(Icons.location_on),
                title: const Text('ตำแหน่ง'),
                onTap: () {
                  Navigator.pop(context);
                  _selectLocation();
                },
              ),
            ],
          ),
        );
      },
    );
  }

  void _sendMessage() async {
    if (_messageController.text.trim().isEmpty &&
        _imageFiles.isEmpty &&
        _selectedLocation == null)
      return;

    final String message = _messageController.text.trim();
    _messageController.clear();

    // Dismiss keyboard
    FocusScope.of(context).unfocus();

    final currentUser = _auth.currentUser;
    if (currentUser == null) return;

    List<String> imageUrls = [];

    // 1. Upload Images
    if (_imageFiles.isNotEmpty) {
      setState(() => _isUploading = true);
      imageUrls = await _uploadImagesToCloud();
      setState(() {
        _isUploading = false;
        _uploadStatus = '';
      });
    }

    GeoPoint? locationData;
    if (_selectedLocation != null) {
      locationData = GeoPoint(
        _selectedLocation!.latitude,
        _selectedLocation!.longitude,
      );
    }

    // 2. Add message to the 'messages' subcollection
    await FirebaseFirestore.instance
        .collection('chats')
        .doc(widget.chatRoomId)
        .collection('messages')
        .add({
          'senderId': currentUser.uid,
          'text':
              message.isEmpty
                  ? (imageUrls.isNotEmpty ? 'ส่งรูปภาพ' : 'ส่งตำแหน่ง')
                  : message,
          'images': imageUrls,
          'location': locationData,
          'timestamp': FieldValue.serverTimestamp(),
        });

    // 3. Update the chat room summary (for inbox lists)
    await FirebaseFirestore.instance
        .collection('chats')
        .doc(widget.chatRoomId)
        .set({
          'lastMessage':
              message.isEmpty
                  ? (imageUrls.isNotEmpty ? 'ส่งรูปภาพ' : 'ส่งตำแหน่ง')
                  : message,
          'lastMessageTime': FieldValue.serverTimestamp(),
          'participants': FieldValue.arrayUnion([
            currentUser.uid,
            widget.otherUserId,
          ]),
        }, SetOptions(merge: true));

    // Clear attachments
    setState(() {
      _imageFiles.clear();
      _selectedLocation = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text(
          widget.itemName,
          style: const TextStyle(
            color: Colors.white,
            fontFamily: 'Line Seed Sans TH',
          ),
        ),
        backgroundColor: const Color(0xFF006C68),
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          IconButton(
            icon: const Icon(Icons.info_outline),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder:
                      (context) =>
                          ChatDetailPage(chatRoomId: widget.chatRoomId),
                ),
              );
            },
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: _messagesStream,
              builder: (context, snapshot) {
                if (snapshot.hasError)
                  return Center(child: Text('Error: ${snapshot.error}'));
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                final docs = snapshot.data!.docs;

                return ListView.builder(
                  reverse: true,
                  itemCount: docs.length,
                  padding: const EdgeInsets.all(10),
                  itemBuilder: (context, index) {
                    final data = docs[index].data() as Map<String, dynamic>;
                    final bool isMe =
                        data['senderId'] == _auth.currentUser?.uid;

                    List<dynamic> images = data['images'] ?? [];
                    GeoPoint? location = data['location'];

                    return Align(
                      alignment:
                          isMe ? Alignment.centerRight : Alignment.centerLeft,
                      child: Container(
                        margin: const EdgeInsets.symmetric(vertical: 4),
                        padding: const EdgeInsets.all(12),
                        constraints: BoxConstraints(
                          maxWidth: MediaQuery.of(context).size.width * 0.7,
                        ),
                        decoration: BoxDecoration(
                          color:
                              isMe ? const Color(0xFF006C68) : Colors.grey[200],
                          borderRadius: BorderRadius.only(
                            topLeft: const Radius.circular(12),
                            topRight: const Radius.circular(12),
                            bottomLeft:
                                isMe ? const Radius.circular(12) : Radius.zero,
                            bottomRight:
                                isMe ? Radius.zero : const Radius.circular(12),
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Location Map
                            if (location != null) _buildMapPreview(location),

                            // Images
                            if (images.isNotEmpty) _buildImageGrid(images),

                            // Text
                            if (data['text'] != null &&
                                data['text'].toString().isNotEmpty &&
                                data['text'] != 'ส่งรูปภาพ' &&
                                data['text'] != 'ส่งตำแหน่ง')
                              Text(
                                data['text'],
                                style: TextStyle(
                                  color: isMe ? Colors.white : Colors.black87,
                                  fontFamily: 'Line Seed Sans TH',
                                ),
                              ),
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
          _buildMessageInput(),
        ],
      ),
    );
  }

  Widget _buildMapPreview(GeoPoint pinLocation) {
    // Show "Where B is" (CurrentUser) and "Where A Pin" (pinLocation)
    // Only if we have the current user's location. Otherwise just show the pin.
    List<Marker> markers = [
      Marker(
        point: LatLng(pinLocation.latitude, pinLocation.longitude),
        width: 40,
        height: 40,
        child: const Icon(Icons.location_on, color: Colors.red, size: 40),
        alignment: Alignment.bottomCenter,
      ),
    ];

    if (_currentUserPosition != null) {
      markers.add(
        Marker(
          point: LatLng(
            _currentUserPosition!.latitude,
            _currentUserPosition!.longitude,
          ),
          width: 20,
          height: 20,
          child: Container(
            decoration: BoxDecoration(
              color: Colors.blue.withOpacity(0.8),
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white, width: 2),
            ),
          ),
        ),
      );
    }

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => FullScreenMapView(
              pinLocation: LatLng(pinLocation.latitude, pinLocation.longitude),
              userPosition: _currentUserPosition,
            ),
          ),
        );
      },
      child: Container(
        height: 150,
        width: double.infinity,
        margin: const EdgeInsets.only(bottom: 8),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.grey.shade400),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: FlutterMap(
            options: MapOptions(
              initialCenter: LatLng(pinLocation.latitude, pinLocation.longitude),
              initialZoom: 13.0,
              interactionOptions: const InteractionOptions(
                flags: InteractiveFlag.none,
              ), // Static map
            ),
            children: [
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.example.lostNFoundTest',
              ),
              MarkerLayer(markers: markers),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildImageGrid(List<dynamic> images) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Wrap(
        spacing: 4,
        runSpacing: 4,
        children:
            images.map((imgUrl) {
              return GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => FullScreenImageView(imageUrl: imgUrl.toString()),
                    ),
                  );
                },
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.network(
                    imgUrl.toString(),
                    width: 100,
                    height: 100,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => const Icon(Icons.broken_image),
                  ),
                ),
              );
            }).toList(),
      ),
    );
  }

  Widget _buildMessageInput() {
    return SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Attachment Previews
          if (_imageFiles.isNotEmpty || _selectedLocation != null)
            Container(
              height: 60,
              padding: const EdgeInsets.symmetric(horizontal: 10),
              color: Colors.grey[100],
              child: Row(
                children: [
                  ..._imageFiles.map(
                    (f) => Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: Image.file(
                        f,
                        width: 50,
                        height: 50,
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                  if (_selectedLocation != null)
                    const Chip(
                      avatar: Icon(Icons.location_on, size: 16),
                      label: Text("ตำแหน่งที่เลือก"),
                    ),
                  const Spacer(),
                  IconButton(
                    onPressed:
                        () => setState(() {
                          _imageFiles.clear();
                          _selectedLocation = null;
                        }),
                    icon: const Icon(Icons.close),
                  ),
                ],
              ),
            ),
          if (_isUploading)
            Container(
              color: Colors.black12,
              padding: const EdgeInsets.all(4),
              width: double.infinity,
              child: Text(
                _uploadStatus,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 12),
              ),
            ),

          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border(top: BorderSide(color: Colors.grey.shade200)),
            ),
            child: Row(
              children: [
                IconButton(
                  icon: const Icon(
                    Icons.add_circle_outline,
                    color: Color(0xFF006C68),
                  ),
                  onPressed: _showAttachmentOptions,
                ),
                Expanded(
                  child: TextField(
                    controller: _messageController,
                    decoration: InputDecoration(
                      hintText: 'พิมพ์ข้อความ...',
                      hintStyle: const TextStyle(
                        fontFamily: 'Line Seed Sans TH',
                        color: Colors.grey,
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(20),
                        borderSide: BorderSide.none,
                      ),
                      filled: true,
                      fillColor: Colors.grey[100],
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                CircleAvatar(
                  backgroundColor: const Color(0xFF006C68),
                  child: IconButton(
                    icon: const Icon(Icons.send, color: Colors.white, size: 20),
                    onPressed: _isUploading ? null : _sendMessage,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class FullScreenImageView extends StatelessWidget {
  final String imageUrl;
  const FullScreenImageView({super.key, required this.imageUrl});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Center(
        child: InteractiveViewer(
          child: Image.network(imageUrl),
        ),
      ),
    );
  }
}

class FullScreenMapView extends StatelessWidget {
  final LatLng pinLocation;
  final Position? userPosition;

  const FullScreenMapView({
    super.key,
    required this.pinLocation,
    this.userPosition,
  });

  @override
  Widget build(BuildContext context) {
    List<Marker> markers = [
      Marker(
        point: pinLocation,
        width: 40,
        height: 40,
        child: const Icon(Icons.location_on, color: Colors.red, size: 40),
        alignment: Alignment.bottomCenter,
      ),
    ];

    if (userPosition != null) {
      markers.add(
        Marker(
          point: LatLng(userPosition!.latitude, userPosition!.longitude),
          width: 20,
          height: 20,
          child: Container(
            decoration: BoxDecoration(
              color: Colors.blue.withOpacity(0.8),
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white, width: 2),
            ),
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'ตำแหน่งที่ตั้ง',
          style: TextStyle(fontFamily: 'Line Seed Sans TH'),
        ),
        backgroundColor: const Color(0xFF006C68),
        foregroundColor: Colors.white,
      ),
      body: FlutterMap(
        options: MapOptions(
          initialCenter: pinLocation,
          initialZoom: 15.0,
        ),
        children: [
          TileLayer(
            urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
            userAgentPackageName: 'com.example.lostNFoundTest',
          ),
          MarkerLayer(markers: markers),
        ],
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';

class ChatDetailPage extends StatelessWidget {
  final String chatRoomId;

  const ChatDetailPage({super.key, required this.chatRoomId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text(
          'รายละเอียดแชท',
          style: TextStyle(fontFamily: 'Line Seed Sans TH'),
        ),
        backgroundColor: const Color(0xFF006C68),
        foregroundColor: Colors.white,
      ),
      body: FutureBuilder<DocumentSnapshot>(
        future:
            FirebaseFirestore.instance
                .collection('chats')
                .doc(chatRoomId)
                .get(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError ||
              !snapshot.hasData ||
              !snapshot.data!.exists) {
            return const Center(child: Text('ไม่พบข้อมูลแชท'));
          }

          final data = snapshot.data!.data() as Map<String, dynamic>;
          final String ownerId = data['ownerId'] ?? '';
          final String visitorId = data['visitorId'] ?? '';
          final String itemId = data['itemId'] ?? '';

          final currentUser = FirebaseAuth.instance.currentUser;
          final bool isOwner =
              currentUser != null && currentUser.uid == ownerId;

          return StreamBuilder<DocumentSnapshot>(
            stream:
                FirebaseFirestore.instance
                    .collection('items')
                    .doc(itemId)
                    .snapshots(),
            builder: (context, itemSnapshot) {
              if (!itemSnapshot.hasData || !itemSnapshot.data!.exists) {
                return const Center(child: Text('ไม่พบข้อมูลสิ่งของ'));
              }

              final itemData =
                  itemSnapshot.data!.data() as Map<String, dynamic>;

              return SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildActionSection(
                      context,
                      isOwner,
                      itemId,
                      ownerId,
                      visitorId,
                      itemData,
                    ),
                    const SizedBox(height: 24),
                    const Divider(),
                    const SizedBox(height: 24),
                    _buildLogSection(itemId, ownerId, visitorId),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildActionSection(
    BuildContext context,
    bool isOwner,
    String itemId,
    String ownerId,
    String visitorId,
    Map<String, dynamic> itemData,
  ) {
    String progress = itemData['progress'] ?? '';
    bool isCompleted = progress == 'completed';
    bool isOngoing = progress == 'pending';

    // Phase 3: Completed
    if (isCompleted) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.green.shade50,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.green),
        ),
        child: Column(
          children: const [
            Icon(Icons.check_circle, color: Colors.green, size: 48),
            SizedBox(height: 8),
            Text(
              'ภารกิจเสร็จสิ้น',
              style: TextStyle(
                fontFamily: 'Line Seed Sans TH',
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.green,
              ),
            ),
            Text(
              'ปิดงานเรียบร้อยแล้ว',
              style: TextStyle(
                fontFamily: 'Line Seed Sans TH',
                color: Colors.green,
              ),
            ),
          ],
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'การจัดการ',
          style: TextStyle(
            fontFamily: 'Line Seed Sans TH',
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),

        // Phase 1: Appointment (Available to both if not completed)
        _buildAppointmentButton(context, itemId, itemData),

        const SizedBox(height: 12),

        // Phase 2: Completion (Only for Owner when Ongoing)
        if (isOngoing)
          if (isOwner)
            _buildCompletionButton(context, itemId, itemData, visitorId)
          else
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.orange.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.orange.shade200),
              ),
              child: const Center(
                child: Text(
                  "รอเจ้าของโพสต์ตรวจสอบและปิดงาน",
                  style: TextStyle(
                    fontFamily: 'Line Seed Sans TH',
                    color: Colors.orange,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
      ],
    );
  }

  Widget _buildAppointmentButton(
    BuildContext context,
    String itemId,
    Map<String, dynamic> itemData,
  ) {
    bool hasAppointment = itemData['appointment_time'] != null;
    String btnLabel =
        hasAppointment ? 'แก้ไขเวลานัดหมาย' : 'นัดหมายสถานที่และเวลา';
    IconData btnIcon =
        hasAppointment ? Icons.edit_calendar : Icons.calendar_today;

    return SizedBox(
      width: double.infinity,
      height: 50,
      child: OutlinedButton.icon(
        onPressed: () => _showAppointmentDialog(context, itemId, itemData),
        icon: Icon(btnIcon),
        label: Text(btnLabel),
        style: OutlinedButton.styleFrom(
          foregroundColor: const Color(0xFF006C68),
          side: const BorderSide(color: Color(0xFF006C68)),
        ),
      ),
    );
  }

  Widget _buildCompletionButton(
    BuildContext context,
    String itemId,
    Map<String, dynamic> itemData,
    String visitorId,
  ) {
    return SizedBox(
      width: double.infinity,
      height: 50,
      child: ElevatedButton.icon(
        onPressed:
            () => _confirmCompletion(context, itemId, itemData, visitorId),
        icon: const Icon(Icons.check_circle_outline),
        label: const Text('ยืนยันการรับ/ส่งของ & ปิดงาน'),
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF006C68),
          foregroundColor: Colors.white,
        ),
      ),
    );
  }

  Widget _buildLogSection(String itemId, String ownerId, String visitorId) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'ข้อมูลระบบ (Log)',
          style: TextStyle(
            fontFamily: 'Line Seed Sans TH',
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        _buildInfoTile('Chat ID', chatRoomId),
        _buildInfoTile('Item ID', itemId),
        _buildInfoTile('Owner UID', ownerId),
        _buildInfoTile('Visitor UID', visitorId),
        FutureBuilder<AggregateQuerySnapshot>(
          future:
              FirebaseFirestore.instance
                  .collection('chats')
                  .doc(chatRoomId)
                  .collection('messages')
                  .count()
                  .get(),
          builder: (context, snapshot) {
            String count = '...';
            if (snapshot.hasData) {
              count = snapshot.data!.count.toString();
            }
            return _buildInfoTile('Message Count', count);
          },
        ),
      ],
    );
  }

  Widget _buildInfoTile(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: const TextStyle(
                fontFamily: 'Line Seed Sans TH',
                color: Colors.grey,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontFamily: 'Line Seed Sans TH',
                fontSize: 13,
                color: Color(0xFF333333),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // --- Phase 1 Logic: Appointment ---
  Future<void> _showAppointmentDialog(
    BuildContext context,
    String itemId,
    Map<String, dynamic> itemData,
  ) async {
    DateTime selectedDate = DateTime.now();
    TimeOfDay selectedTime = TimeOfDay.now();
    TextEditingController locController = TextEditingController(
      text: itemData['appointment_location'] ?? '',
    );
    LatLng? selectedLatLng;

    if (itemData['appointment_time'] != null) {
      DateTime saved = (itemData['appointment_time'] as Timestamp).toDate();
      selectedDate = saved;
      selectedTime = TimeOfDay(hour: saved.hour, minute: saved.minute);
    }

    if (itemData['appointment_geo'] != null) {
      GeoPoint gp = itemData['appointment_geo'];
      selectedLatLng = LatLng(gp.latitude, gp.longitude);
    }

    await showDialog(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: const Text(
                'นัดหมาย',
                style: TextStyle(
                  fontFamily: 'Line Seed Sans TH',
                  fontWeight: FontWeight.bold,
                ),
              ),
              content: SizedBox(
                width: double.maxFinite,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Map Preview / Selector
                      GestureDetector(
                        onTap: () async {
                          LatLng? result = await _selectLocationOnMap(
                            context,
                            selectedLatLng,
                          );
                          if (result != null) {
                            setState(() {
                              selectedLatLng = result;
                            });
                          }
                        },
                        child: Container(
                          height: 150,
                          width: double.infinity,
                          margin: const EdgeInsets.only(bottom: 12),
                          decoration: BoxDecoration(
                            color: Colors.grey[200],
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Colors.grey.shade400),
                          ),
                          child:
                              selectedLatLng == null
                                  ? Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: const [
                                      Icon(
                                        Icons.map,
                                        color: Colors.grey,
                                        size: 40,
                                      ),
                                      Text(
                                        "แตะเพื่อเลือกตำแหน่งบนแผนที่",
                                        style: TextStyle(color: Colors.grey),
                                      ),
                                    ],
                                  )
                                  : ClipRRect(
                                    borderRadius: BorderRadius.circular(8),
                                    child: FlutterMap(
                                      options: MapOptions(
                                        initialCenter: selectedLatLng!,
                                        initialZoom: 15.0,
                                        interactionOptions:
                                            const InteractionOptions(
                                              flags: InteractiveFlag.none,
                                            ),
                                      ),
                                      children: [
                                        TileLayer(
                                          urlTemplate:
                                              'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                                          userAgentPackageName:
                                              'com.example.lostNFoundTest',
                                        ),
                                        MarkerLayer(
                                          markers: [
                                            Marker(
                                              point: selectedLatLng!,
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
                      ),
                      TextField(
                        controller: locController,
                        decoration: const InputDecoration(
                          labelText: 'สถานที่นัดพบ (รายละเอียด)',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.pin_drop),
                        ),
                      ),
                      const SizedBox(height: 16),
                      ListTile(
                        title: const Text('วันที่ & เวลา'),
                        subtitle: Text(
                          "${selectedDate.day}/${selectedDate.month}/${selectedDate.year} ${selectedTime.format(context)}",
                        ),
                        trailing: const Icon(Icons.calendar_month),
                        onTap: () async {
                          final d = await showDatePicker(
                            context: context,
                            initialDate: selectedDate,
                            firstDate: DateTime.now(),
                            lastDate: DateTime.now().add(
                              const Duration(days: 365),
                            ),
                          );
                          if (d != null) {
                            if (context.mounted) {
                              final t = await showTimePicker(
                                context: context,
                                initialTime: selectedTime,
                              );
                              if (t != null) {
                                setState(() {
                                  selectedDate = d;
                                  selectedTime = t;
                                });
                              }
                            }
                          }
                        },
                      ),
                    ],
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: const Text('ยกเลิก'),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF006C68),
                    foregroundColor: Colors.white,
                  ),
                  onPressed: () async {
                    Navigator.pop(ctx);
                    await _saveAppointment(
                      context,
                      itemId,
                      itemData['status'] ?? 'lost',
                      locController.text,
                      selectedDate,
                      selectedTime,
                      selectedLatLng,
                    );
                  },
                  child: const Text('บันทึก'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<LatLng?> _selectLocationOnMap(
    BuildContext context,
    LatLng? currentSelection,
  ) async {
    LatLng initialCenter = currentSelection ?? const LatLng(13.8476, 100.5696);

    if (currentSelection == null) {
      try {
        bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
        if (serviceEnabled) {
          LocationPermission permission = await Geolocator.checkPermission();
          if (permission == LocationPermission.denied) {
            permission = await Geolocator.requestPermission();
          }
          if (permission != LocationPermission.denied &&
              permission != LocationPermission.deniedForever) {
            Position p = await Geolocator.getCurrentPosition();
            initialCenter = LatLng(p.latitude, p.longitude);
          }
        }
      } catch (_) {}
    }

    LatLng tempLocation = initialCenter;

    return await showDialog<LatLng>(
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
                      urlTemplate:
                          'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                      userAgentPackageName: 'com.example.lostNFoundTest',
                    ),
                    MarkerLayer(
                      markers: [
                        Marker(
                          point: tempLocation,
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
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('ยกเลิก'),
                ),
                TextButton(
                  onPressed: () {
                    Navigator.pop(context, tempLocation);
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

  Future<void> _saveAppointment(
    BuildContext context,
    String itemId,
    String currentStatus,
    String location,
    DateTime date,
    TimeOfDay time,
    LatLng? latLng,
  ) async {
    try {
      final currentUser = FirebaseAuth.instance.currentUser;
      final dt = DateTime(
        date.year,
        date.month,
        date.day,
        time.hour,
        time.minute,
      );

      Map<String, dynamic> updateData = {
        'progress': 'pending',
        'appointment_location': location,
        'appointment_time': Timestamp.fromDate(dt),
      };

      if (latLng != null) {
        updateData['appointment_geo'] = GeoPoint(
          latLng.latitude,
          latLng.longitude,
        );
      }

      // 1. Update Item
      await FirebaseFirestore.instance
          .collection('items')
          .doc(itemId)
          .update(updateData);

      // 2. Send System Message
      String formattedDate =
          "${dt.day}/${dt.month}/${dt.year} เวลา ${time.format(context)}";
      String msg =
          "📅 มีการนัดหมาย/เปลี่ยนแปลงเวลา\nสถานที่: $location\nเวลา: $formattedDate";

      Map<String, dynamic> msgData = {
        'senderId': currentUser?.uid,
        'text': msg,
        'timestamp': FieldValue.serverTimestamp(),
        'isSystem': true, // Optional flag for styling
      };

      if (latLng != null) {
        msgData['location'] = GeoPoint(latLng.latitude, latLng.longitude);
      }

      await FirebaseFirestore.instance
          .collection('chats')
          .doc(chatRoomId)
          .collection('messages')
          .add(msgData);

      // 3. Update Chat Summary
      await FirebaseFirestore.instance.collection('chats').doc(chatRoomId).set({
        'lastMessage': ' มีการนัดหมาย',
        'lastMessageTime': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      if (context.mounted)
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('บันทึกการนัดหมายเรียบร้อย')),
        );
    } catch (e) {
      debugPrint('Error saving appointment: $e');
    }
  }

  // --- Phase 2 Logic: Completion & Points ---
  Future<void> _confirmCompletion(
    BuildContext context,
    String itemId,
    Map<String, dynamic> itemData,
    String visitorId,
  ) async {
    // Calculate Points
    String status = itemData['status'] ?? 'lost';
    String ownerId = itemData['uid'];

    String targetUserId;

    if (status.startsWith('lost')) {
      // Case: Lost Item. Owner lost it. Visitor found it. -> Visitor gets points.
      targetUserId = visitorId;
    } else {
      // Case: Found Item. Owner found it. Visitor lost it. -> Owner gets points (for being a good citizen).
      targetUserId = ownerId;
    }

    try {
      // 1. Update Progress
      await FirebaseFirestore.instance.collection('items').doc(itemId).update({
        'progress': 'completed',
      });

      // 2. Give Points (Assuming 'users' collection has 'points' field)
      if (targetUserId.isNotEmpty) {
        await FirebaseFirestore.instance
            .collection('users')
            .doc(targetUserId)
            .update({
              'points': FieldValue.increment(10), // Give 10 points
            })
            .catchError(
              (e) => debugPrint("Error giving points: $e"),
            ); // Handle if user doc doesn't exist
      }

      // 3. Send Message
      await FirebaseFirestore.instance
          .collection('chats')
          .doc(chatRoomId)
          .collection('messages')
          .add({
            'senderId': FirebaseAuth.instance.currentUser?.uid,
            'text': '✅ ภารกิจเสร็จสิ้น! ปิดงานเรียบร้อยแล้ว',
            'timestamp': FieldValue.serverTimestamp(),
          });

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('ปิดงานสำเร็จ! มอบคะแนนเรียบร้อย')),
        );
      }
    } catch (e) {
      if (context.mounted)
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error: $e')));
    }
  }
}

import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'theme_provider.dart';
import 'dart:html' as html;
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
import 'dart:typed_data';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:cloud_firestore/cloud_firestore.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  final user = FirebaseAuth.instance.currentUser;
  final _nameController = TextEditingController();
  bool _notificationsEnabled = true;
  String _selectedLanguage = 'English';
  bool _isDarkMode = false;
  String? userImageUrl;

  @override
  void initState() {
    super.initState();
    _nameController.text = user?.displayName ?? '';
    _loadProfileImage();
  }

  void _loadProfileImage() async {
    final doc = await FirebaseFirestore.instance.collection('users').doc(user!.uid).get();
    setState(() {
      userImageUrl = doc.data()?['profileImage'];
    });
  }

  void pickAndUploadImage() async {
    final uploadInput = html.FileUploadInputElement()..accept = 'image/*';
    uploadInput.click();

    uploadInput.onChange.listen((e) async {
      final file = uploadInput.files?.first;
      if (file == null) return;

      final reader = html.FileReader();
      reader.readAsDataUrl(file);

      reader.onLoadEnd.listen((event) async {
        final base64Image = reader.result.toString();
        final rawBase64 = reader.result.toString().split(',').last;


        // You can use this to display image temporarily
        setState(() => userImageUrl = base64Image);

        // Upload to Cloudinary
        final response = await http.post(
          Uri.parse('https://api.cloudinary.com/v1_1/dlq1nlfsk/image/upload'),
          body: {
            'file': base64Encode(base64Decode(rawBase64)), // OR just use rawBase64
            'upload_preset': 'unsigned_preset',
          },
        );

        if (response.statusCode == 200) {
          final imageUrl = jsonDecode(response.body)['secure_url'];
          print("✅ Upload success: $imageUrl");
          // You can now save this imageUrl to Firestore
        } else {
          print("❌ Upload failed: ${response.body}");
        }
      });
    });
  }

  void _updateDisplayName() async {
    try {
      await user?.updateDisplayName(_nameController.text.trim());
      await user?.reload();
      setState(() {});
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Name updated")),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Update failed: $e")),
      );
    }
  }

  void _signOut() async {
    await FirebaseAuth.instance.signOut();
    if (!mounted) return;
    Navigator.pushReplacementNamed(context, '/login');
  }

  @override
  Widget build(BuildContext context) {
    final metadata = user?.metadata;
    final themeProvider = Provider.of<ThemeProvider>(context);
    return Scaffold(
      backgroundColor: const Color(0xFFf2ede9),
      appBar: AppBar(
        title: const Text('Account'),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            GestureDetector(
              onTap: pickAndUploadImage,
              child: Stack(
                alignment: Alignment.bottomRight,
                children: [
                  CircleAvatar(
                    radius: 50,
                    backgroundImage:
                    userImageUrl != null ? NetworkImage(userImageUrl!) : null,
                    child: userImageUrl == null
                        ? Icon(Icons.person, size: 50, color: Colors.white)
                        : null,
                  ),
                  const CircleAvatar(
                    radius: 15,
                    backgroundColor: Colors.white,
                    child: Icon(Icons.edit, size: 18),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 10),
            Text(user?.email ?? '', style: const TextStyle(color: Colors.black54)),
            const SizedBox(height: 20),

            // Editable Name
            TextField(
              controller: _nameController,
              decoration: InputDecoration(
                labelText: "Display Name",
                border: const OutlineInputBorder(),
                suffixIcon: IconButton(
                  icon: const Icon(Icons.check),
                  onPressed: _updateDisplayName,
                  tooltip: "Save",
                ),
              ),
            ),
            const SizedBox(height: 30),

            // Account Info
            _infoRow("UID", user?.uid ?? '', copyable: true),
            _infoRow("Member Since", metadata?.creationTime?.toString().split('.')[0] ?? '-'),
            _infoRow("Last Login", metadata?.lastSignInTime?.toString().split('.')[0] ?? '-'),
            const SizedBox(height: 30),

            // App Settings
            const Align(
              alignment: Alignment.centerLeft,
              child: Text("App Settings", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            ),
            const SizedBox(height: 10),

            SwitchListTile(
              value: _notificationsEnabled,
              onChanged: (val) => setState(() => _notificationsEnabled = val),
              title: const Text("Enable Notifications"),
              secondary: const Icon(Icons.notifications_active),
            ),

            ListTile(
              title: const Text("Language"),
              leading: const Icon(Icons.language),
              trailing: DropdownButton<String>(
                value: _selectedLanguage,
                onChanged: (val) => setState(() => _selectedLanguage = val!),
                items: ['English', 'Malay', 'Chinese']
                    .map((lang) => DropdownMenuItem(value: lang, child: Text(lang)))
                    .toList(),
              ),
            ),

            SwitchListTile(
              title: const Text("Dark Mode"),
              value: themeProvider.themeMode == ThemeMode.dark,
              onChanged: (val) => themeProvider.toggleTheme(val),
            ),

            const SizedBox(height: 30),
            ElevatedButton.icon(
              onPressed: _signOut,
              icon: const Icon(Icons.logout),
              label: const Text("Logout"),
              style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
            ),
          ],
        ),
      ),
    );
  }

  Widget _infoRow(String label, String value, {bool copyable = false}) {
    return ListTile(
      title: Text(label),
      subtitle: Text(value),
      trailing: copyable
          ? IconButton(
        icon: const Icon(Icons.copy),
        tooltip: "Copy",
        onPressed: () {
          Clipboard.setData(ClipboardData(text: value));
          ScaffoldMessenger.of(context)
              .showSnackBar(SnackBar(content: Text('$label copied')));
        },
      )
          : null,
    );
  }
}

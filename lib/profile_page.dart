import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'theme_provider.dart';
import 'dart:html' as html;
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

  final _currentPasswordController = TextEditingController();
  final _newPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();


  @override
  void initState() {
    super.initState();
    _nameController.text = user?.displayName ?? '';
    _checkEmailVerification();
  }

  void pickImageOnly() async {
    final uploadInput = html.FileUploadInputElement()..accept = 'image/*';
    uploadInput.click();

    uploadInput.onChange.listen((e) async {
      final file = uploadInput.files?.first;
      if (file == null) return;

      final reader = html.FileReader();
      reader.readAsDataUrl(file);

      reader.onLoadEnd.listen((event) {
        final base64Image = reader.result.toString();
        setState(() => userImageUrl = base64Image); // Just preview it
      });
    });
  }


  void _updateDisplayName() async {

    if (!_emailVerified) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Verify your email to update your profile.")),
      );
      return;
    }

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

  bool _emailVerified = false;
  bool _emailStatusLoaded = false;
  bool _sendingVerification = false;

  void _checkEmailVerification() async {
    await user?.reload();
    final refreshedUser = FirebaseAuth.instance.currentUser;

    setState(() {
      _emailVerified = refreshedUser?.emailVerified ?? false;
      _emailStatusLoaded = true;
    });
  }


  Future<bool> _reauthenticate(String email, String password) async {
    try {
      final credential = EmailAuthProvider.credential(email: email, password: password);
      await FirebaseAuth.instance.currentUser!.reauthenticateWithCredential(credential);
      return true;
    } catch (e) {
      print(" Reauth failed: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Login failed: ${e.toString()}")),
      );
      return false;
    }
  }


  void _changePassword() async {

    if (!_requireVerifiedEmail()) return;

    final currentPassword = _currentPasswordController.text.trim();
    final newPassword = _newPasswordController.text.trim();
    final confirmPassword = _confirmPasswordController.text.trim();

    if (newPassword != confirmPassword) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("New passwords do not match")),
      );
      return;
    }

    final email = user!.email!;
    bool reauthed = await _reauthenticate(email, currentPassword);

    if (!reauthed) return;

    try {
      await user!.updatePassword(newPassword);

      await FirebaseFirestore.instance
          .collection('users')
          .doc(user!.uid)
          .update({'password': newPassword});

      _currentPasswordController.clear();
      _newPasswordController.clear();
      _confirmPasswordController.clear();

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Password updated successfully")),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Password update failed: ${e.toString()}")),
      );
    }
  }

  bool _requireVerifiedEmail() {
    if (!_emailVerified) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Action blocked. Please verify your email.")),
      );
      return false;
    }
    return true;
  }


  void _signOut() async {
    await FirebaseAuth.instance.signOut();
    if (!mounted) return;
    Navigator.pushReplacementNamed(context, '/login');
  }

  @override
  void dispose() {
    _nameController.dispose();
    _currentPasswordController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
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
              onTap: pickImageOnly,
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
            if (_emailStatusLoaded && !_emailVerified)
              Container(
                margin: const EdgeInsets.only(top: 10),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.orange.shade100,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.warning_amber, color: Colors.orange),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text("Your email is not verified. Please check your inbox."),
                    ),
                    TextButton(
                      onPressed: _sendingVerification
                          ? null
                          : () async {
                        setState(() => _sendingVerification = true);
                        try {
                          await user?.sendEmailVerification();
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text("Verification email sent.")),
                          );
                        } catch (e) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text("Failed to send email: $e")),
                          );
                        } finally {
                          setState(() => _sendingVerification = false);
                        }
                      },
                      child: _sendingVerification ? const Text("Sending...") : const Text("Resend"),
                    ),
                  ],
                ),
              ),
            TextButton.icon(
              onPressed: _checkEmailVerification,
              icon: Icon(Icons.refresh),
              label: Text("Refresh Status"),
            ),

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
            const Align(
              alignment: Alignment.centerLeft,
              child: Text("Change Password", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            ),
            const SizedBox(height: 10),

            TextField(
              controller: _currentPasswordController,
              obscureText: true,
              decoration: const InputDecoration(
                labelText: "Current Password",
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 10),

            TextField(
              controller: _newPasswordController,
              obscureText: true,
              decoration: const InputDecoration(
                labelText: "New Password",
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 10),

            TextField(
              controller: _confirmPasswordController,
              obscureText: true,
              decoration: const InputDecoration(
                labelText: "Confirm New Password",
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 10),

            ElevatedButton.icon(
              onPressed: _emailVerified ? _changePassword : null,
              icon: const Icon(Icons.lock_reset),
              label: const Text("Update Password"),
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

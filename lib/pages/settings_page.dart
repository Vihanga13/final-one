import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'dart:io';
import 'package:permission_handler/permission_handler.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  _SettingsPageState createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  final Color customGreen = const Color(0xFF86BF3E);
  final _formKey = GlobalKey<FormState>();

  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _heightController = TextEditingController();
  final _weightController = TextEditingController();

  String? _selectedGoal;
  final List<Map<String, dynamic>> _goals = [
    {
      'title': 'Diabetic Patient',
      'description': 'Manage blood sugar levels and maintain a healthy lifestyle',
      'icon': Icons.medical_services_outlined,
    },
    {
      'title': 'Cholesterol Patient',
      'description': 'Control cholesterol levels with proper diet and exercise',
      'icon': Icons.favorite_outline,
    },
    {
      'title': 'Loss Weight',
      'description': 'Achieve healthy weight loss through balanced nutrition',
      'icon': Icons.trending_down,
    },
    {
      'title': 'Gain Weight',
      'description': 'Build healthy mass with proper nutrition and exercise',
      'icon': Icons.trending_up,
    },
    {
      'title': 'Weight Balancing',
      'description': 'Maintain optimal weight and healthy lifestyle',
      'icon': Icons.balance_outlined,
    },
  ];

  DateTime? _selectedDate;
  String? _profileImageUrl;
  File? _newProfileImageFile;
  final ImagePicker _picker = ImagePicker();

  bool _isEditing = false;
  bool _isUploadingImage = false;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _heightController.dispose();
    _weightController.dispose();
    super.dispose();
  }

  Future<void> _loadUserData() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      final doc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
      if (doc.exists) {
        final data = doc.data()!;
        setState(() {
          _nameController.text = data['name'] ?? '';
          _phoneController.text = data['phoneNumber'] ?? '';
          _heightController.text = data['height_cm']?.toString() ?? '';
          _weightController.text = data['weight']?.toString() ?? '';
          _profileImageUrl = data['profileImage'];
          _selectedGoal = data['goal'];
          final birthday = data['birthday'];
          if (birthday != null) {
            if (birthday is Timestamp) {
              _selectedDate = birthday.toDate();
            } else if (birthday is String) {
              _selectedDate = DateTime.tryParse(birthday);
            }
          }
        });
      }
    }
  }

  Future<void> _showImageSourceDialog() async {
    showModalBottomSheet(
      context: context,
      builder: (context) => SafeArea(
        child: Wrap(
          children: [
            ListTile(
              leading: const Icon(Icons.camera_alt),
              title: const Text('Camera'),
              onTap: () async {
                Navigator.pop(context);
                await _pickProfileImage(ImageSource.camera);
              },
            ),
            ListTile(
              leading: const Icon(Icons.photo_library),
              title: const Text('Gallery'),
              onTap: () async {
                Navigator.pop(context);
                await _pickProfileImage(ImageSource.gallery);
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _pickProfileImage(ImageSource source) async {
    // Request permissions for camera and gallery
    if (source == ImageSource.camera) {
      final cameraStatus = await Permission.camera.request();
      if (!cameraStatus.isGranted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Camera permission denied.')),
        );
        return;
      }
    } else {
      final photosStatus = await Permission.photos.request();
      final storageStatus = await Permission.storage.request();
      if (!photosStatus.isGranted && !storageStatus.isGranted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Gallery permission denied.')),
        );
        return;
      }
    }
    final XFile? image = await _picker.pickImage(source: source);
    if (image != null) {
      setState(() {
        _newProfileImageFile = File(image.path);
      });
    }
  }

  void _removeProfileImage() {
    setState(() {
      _newProfileImageFile = null;
      _profileImageUrl = null;
    });
  }

  Future<String?> _uploadProfileImage(File imageFile) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return null;
    final ref = FirebaseStorage.instance.ref().child('profile_images/${user.uid}.jpg');
    try {
      setState(() {
        _isUploadingImage = true;
      });
      await ref.putFile(imageFile);
      return await ref.getDownloadURL();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error uploading image: $e'),
          backgroundColor: Colors.red,
        ),
      );
      return null;
    } finally {
      setState(() {
        _isUploadingImage = false;
      });
    }
  }

  Future<void> _saveUserData() async {
    final user = FirebaseAuth.instance.currentUser;
    String? imageUrl = _profileImageUrl;

    if (user != null && _newProfileImageFile != null) {
      imageUrl = await _uploadProfileImage(_newProfileImageFile!);
    }

    if (user != null) {
      try {
        await FirebaseFirestore.instance.collection('users').doc(user.uid).update({
          'name': _nameController.text,
          'phoneNumber': _phoneController.text,
          'height_cm': double.tryParse(_heightController.text) ?? 0.0,
          'weight': double.tryParse(_weightController.text) ?? 0.0,
          'birthday': _selectedDate,
          'profileImage': imageUrl,
          'goal': _selectedGoal,
        });

        setState(() {
          _profileImageUrl = imageUrl;
          _newProfileImageFile = null;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Changes saved successfully!'),
            backgroundColor: customGreen,
          ),
        );
        Navigator.pop(context);
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error saving changes: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? DateTime.now(),
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: customGreen,
              onPrimary: Colors.white,
              surface: Colors.white,
              onSurface: Colors.black,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          'Settings',
          style: TextStyle(color: Colors.black, fontSize: 20, fontWeight: FontWeight.bold),
        ),        leading: GestureDetector(
          onTap: () {
            Navigator.pushNamedAndRemoveUntil(
              context,
              '/profile',
              (route) => false,
            );
          },
          child: Container(
            width: 36,
            height: 36,
            margin: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
            ),
            child: const Center(
              child: Icon(Icons.arrow_back_ios_new, color: Colors.black, size: 20),
            ),
          ),
        ),
        actions: [
          if (!_isEditing)
            TextButton(
              onPressed: () {
                setState(() {
                  _isEditing = true;
                });
              },
              child: Text(
                'Edit',
                style: TextStyle(color: customGreen, fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ),
          // Remove the Save button from AppBar
        ],
      ),
      body: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Profile Picture
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                color: Colors.white,
                child: Column(
                  children: [
                    Stack(
                      alignment: Alignment.bottomRight,
                      children: [
                        Stack(
                          alignment: Alignment.center,
                          children: [
                            Container(
                              width: 100,
                              height: 100,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                border: Border.all(color: customGreen, width: 2),
                                image: (_newProfileImageFile != null)
                                    ? DecorationImage(image: FileImage(_newProfileImageFile!), fit: BoxFit.cover)
                                    : (_profileImageUrl != null && _profileImageUrl!.isNotEmpty)
                                        ? DecorationImage(image: NetworkImage(_profileImageUrl!), fit: BoxFit.cover)
                                        : null,
                                color: (_newProfileImageFile == null && (_profileImageUrl == null || _profileImageUrl!.isEmpty))
                                    ? Colors.grey[200]
                                    : null,
                              ),
                              child: (_newProfileImageFile == null && (_profileImageUrl == null || _profileImageUrl!.isEmpty))
                                  ? const Icon(Icons.person, size: 60, color: Colors.grey)
                                  : null,
                            ),
                            if (_isUploadingImage)
                              Container(
                                width: 100,
                                height: 100,
                                decoration: BoxDecoration(
                                  color: Colors.black.withOpacity(0.4),
                                  shape: BoxShape.circle,
                                ),
                                child: const Center(
                                  child: CircularProgressIndicator(color: Colors.white),
                                ),
                              ),
                          ],
                        ),
                        if (_isEditing)
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              GestureDetector(
                                onTap: _showImageSourceDialog,
                                child: Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(color: customGreen, shape: BoxShape.circle),
                                  child: const Icon(Icons.camera_alt, size: 20, color: Colors.white),
                                ),
                              ),
                              const SizedBox(width: 8),
                              if (_newProfileImageFile != null || (_profileImageUrl != null && _profileImageUrl!.isNotEmpty))
                                Tooltip(
                                  message: 'Remove profile image',
                                  child: GestureDetector(
                                    onTap: _removeProfileImage,
                                    child: AnimatedContainer(
                                      duration: const Duration(milliseconds: 200),
                                      padding: const EdgeInsets.all(8),
                                      decoration: BoxDecoration(
                                        gradient: LinearGradient(
                                          colors: [Colors.red, Colors.orange.shade400],
                                          begin: Alignment.topLeft,
                                          end: Alignment.bottomRight,
                                        ),
                                        shape: BoxShape.circle,
                                        boxShadow: [
                                          BoxShadow(
                                            color: Colors.red.withOpacity(0.3),
                                            blurRadius: 8,
                                            offset: Offset(0, 2),
                                          ),
                                        ],
                                      ),
                                      child: const Icon(Icons.delete_forever, size: 24, color: Colors.white),
                                    ),
                                  ),
                                ),
                            ],
                          ),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              _buildSectionTitle('Personal Information'),

              Container(
                padding: const EdgeInsets.all(20),
                color: Colors.white,
                child: Column(
                  children: [
                    _buildTextField(
                      controller: _nameController,
                      label: 'Full Name',
                      icon: Icons.person_outline,
                      validator: (value) => value == null || value.isEmpty ? 'Please enter your name' : null,
                      enabled: _isEditing,
                    ),
                    const SizedBox(height: 20),
                    _buildTextField(
                      controller: _phoneController,
                      label: 'Phone Number',
                      icon: Icons.phone_outlined,
                      keyboardType: TextInputType.phone,
                      validator: (value) => value == null || value.isEmpty ? 'Please enter your phone number' : null,
                      enabled: _isEditing,
                    ),
                    const SizedBox(height: 20),
                    InkWell(
                      onTap: _isEditing ? () => _selectDate(context) : null,
                      child: InputDecorator(
                        decoration: InputDecoration(
                          labelText: 'Birthday',
                          labelStyle: TextStyle(color: Colors.grey[600]),
                          prefixIcon: Icon(Icons.cake_outlined, color: customGreen),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        child: Text(
                          _selectedDate != null
                              ? DateFormat('MMM dd, yyyy').format(_selectedDate!)
                              : 'Select Date',
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    Row(
                      children: [
                        Expanded(
                          child: _buildTextField(
                            controller: _heightController,
                            label: 'Height (cm)',
                            icon: Icons.height,
                            keyboardType: TextInputType.number,
                            validator: (value) => value == null || value.isEmpty ? 'Required' : null,
                            enabled: _isEditing,
                          ),
                        ),
                        const SizedBox(width: 20),
                        Expanded(
                          child: _buildTextField(
                            controller: _weightController,
                            label: 'Weight (kg)',
                            icon: Icons.monitor_weight_outlined,
                            keyboardType: TextInputType.number,
                            validator: (value) => value == null || value.isEmpty ? 'Required' : null,
                            enabled: _isEditing,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              _buildSectionTitle('Health Goals'),

              Container(
                padding: const EdgeInsets.all(20),
                color: Colors.white,
                child: Column(
                  children: [
                    for (var goal in _goals)
                      GestureDetector(
                        onTap: _isEditing
                            ? () {
                                setState(() {
                                  if (_selectedGoal == goal['title']) {
                                    _selectedGoal = null;
                                  } else {
                                    _selectedGoal = goal['title'];
                                  }
                                });
                              }
                            : null,
                        child: Container(
                          margin: const EdgeInsets.only(bottom: 10),
                          padding: const EdgeInsets.all(15),
                          decoration: BoxDecoration(
                            color: _selectedGoal == goal['title'] ? customGreen.withOpacity(0.1) : Colors.transparent,
                            border: Border.all(
                              color: _selectedGoal == goal['title'] ? customGreen : Colors.grey.shade300,
                              width: 2,
                            ),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            children: [
                              Icon(goal['icon'], color: customGreen, size: 28),
                              const SizedBox(width: 15),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      goal['title'],
                                      style: TextStyle(
                                        color: Colors.black,
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    const SizedBox(height: 5),
                                    // Text(
                                    //   goal['description'],
                                    //   style: TextStyle(
                                    //     color: Colors.black54,
                                    //     fontSize: 14,
                                    //   ),
                                    // ),
                                  ],
                                ),
                              ),
                              if (_selectedGoal == goal['title'])
                                const Icon(Icons.check_circle, color: Color(0xFF4CAF50), size: 24),
                            ],
                          ),
                        ),
                      ),
                  ],
                ),
              ),

              const SizedBox(height: 15),
              // Add Save button below height and weight fields
              if (_isEditing)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Padding(
                    padding: const EdgeInsets.only(bottom: 50),
                    child: SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _isUploadingImage
                            ? null
                            : () async {
                                if (_formKey.currentState!.validate()) {
                                  await _saveUserData();
                                  setState(() {
                                    _isEditing = false;
                                  });
                                }
                              },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: customGreen,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 16),
                        ),
                        child: _isUploadingImage
                            ? const SizedBox(
                                width: 24,
                                height: 24,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : const Text(
                                'Save',
                                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
                              ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 20, bottom: 10),
      child: Text(
        title,
        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
    bool enabled = true,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      validator: validator,
      enabled: enabled,
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(color: Colors.grey[600]),
        prefixIcon: Icon(icon, color: customGreen),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: customGreen, width: 2),
        ),
      ),
    );
  }
}

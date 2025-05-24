import 'package:flutter/material.dart';
import 'package:health_app_3/pages/goal_selection_page.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:permission_handler/permission_handler.dart';

class CompleteProfilePage extends StatefulWidget {
  const CompleteProfilePage({super.key});

  @override
  _CompleteProfilePageState createState() => _CompleteProfilePageState();
}

class _CompleteProfilePageState extends State<CompleteProfilePage> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _usernameController = TextEditingController(); // Add this
  final _phoneController = TextEditingController();    // Add this
  DateTime? _selectedDate;
  String _selectedGender = '';
  File? _imageFile;
  final ImagePicker _picker = ImagePicker();

  // Replace the country code list with a comprehensive one (all countries, code, flag only)
  final List<Map<String, String>> _countryCodes = [
    {'code': '+93', 'flag': '🇦🇫'}, // Afghanistan
    {'code': '+355', 'flag': '🇦🇱'}, // Albania
    {'code': '+213', 'flag': '🇩🇿'}, // Algeria
    {'code': '+1', 'flag': '🇦🇸'}, // American Samoa
    {'code': '+376', 'flag': '🇦🇩'}, // Andorra
    {'code': '+244', 'flag': '🇦🇴'}, // Angola
    {'code': '+1', 'flag': '🇦🇮'}, // Anguilla
    {'code': '+672', 'flag': '🇦🇶'}, // Antarctica
    {'code': '+1', 'flag': '🇦🇬'}, // Antigua and Barbuda
    {'code': '+54', 'flag': '🇦🇷'}, // Argentina
    {'code': '+374', 'flag': '🇦🇲'}, // Armenia
    {'code': '+297', 'flag': '🇦🇼'}, // Aruba
    {'code': '+61', 'flag': '🇦🇺'}, // Australia
    {'code': '+43', 'flag': '🇦🇹'}, // Austria
    {'code': '+994', 'flag': '🇦🇿'}, // Azerbaijan
    {'code': '+1', 'flag': '🇧🇸'}, // Bahamas
    {'code': '+973', 'flag': '🇧🇭'}, // Bahrain
    {'code': '+880', 'flag': '🇧🇩'}, // Bangladesh
    {'code': '+1', 'flag': '🇧🇧'}, // Barbados
    {'code': '+375', 'flag': '🇧🇾'}, // Belarus
    {'code': '+32', 'flag': '🇧🇪'}, // Belgium
    {'code': '+501', 'flag': '🇧🇿'}, // Belize
    {'code': '+229', 'flag': '🇧🇯'}, // Benin
    {'code': '+1', 'flag': '🇧🇲'}, // Bermuda
    {'code': '+975', 'flag': '🇧🇹'}, // Bhutan
    {'code': '+591', 'flag': '🇧🇴'}, // Bolivia
    {'code': '+387', 'flag': '🇧🇦'}, // Bosnia and Herzegovina
    {'code': '+267', 'flag': '🇧🇼'}, // Botswana
    {'code': '+55', 'flag': '🇧🇷'}, // Brazil
    {'code': '+246', 'flag': '🇮🇴'}, // British Indian Ocean Territory
    {'code': '+1', 'flag': '🇻🇬'}, // British Virgin Islands
    {'code': '+673', 'flag': '🇧🇳'}, // Brunei
    {'code': '+359', 'flag': '🇧🇬'}, // Bulgaria
    {'code': '+226', 'flag': '🇧🇫'}, // Burkina Faso
    {'code': '+257', 'flag': '🇧🇮'}, // Burundi
    {'code': '+855', 'flag': '🇰🇭'}, // Cambodia
    {'code': '+237', 'flag': '🇨🇲'}, // Cameroon
    {'code': '+1', 'flag': '🇨🇦'}, // Canada
    {'code': '+238', 'flag': '🇨🇻'}, // Cape Verde
    {'code': '+1', 'flag': '🇧🇶'}, // Caribbean Netherlands
    {'code': '+1', 'flag': '🇰🇾'}, // Cayman Islands
    {'code': '+236', 'flag': '🇨🇫'}, // Central African Republic
    {'code': '+235', 'flag': '🇹🇩'}, // Chad
    {'code': '+56', 'flag': '🇨🇱'}, // Chile
    {'code': '+86', 'flag': '🇨🇳'}, // China
    {'code': '+61', 'flag': '🇨🇽'}, // Christmas Island
    {'code': '+61', 'flag': '🇨🇨'}, // Cocos (Keeling) Islands
    {'code': '+57', 'flag': '🇨🇴'}, // Colombia
    {'code': '+269', 'flag': '🇰🇲'}, // Comoros
    {'code': '+682', 'flag': '🇨🇰'}, // Cook Islands
    {'code': '+506', 'flag': '🇨🇷'}, // Costa Rica
    {'code': '+385', 'flag': '🇭🇷'}, // Croatia
    {'code': '+53', 'flag': '🇨🇺'}, // Cuba
    {'code': '+599', 'flag': '🇨🇼'}, // Curacao
    {'code': '+357', 'flag': '🇨🇾'}, // Cyprus
    {'code': '+420', 'flag': '🇨🇿'}, // Czech Republic
    {'code': '+243', 'flag': '🇨🇩'}, // DR Congo
    {'code': '+45', 'flag': '🇩🇰'}, // Denmark
    {'code': '+253', 'flag': '🇩🇯'}, // Djibouti
    {'code': '+1', 'flag': '🇩🇲'}, // Dominica
    {'code': '+1', 'flag': '🇩🇴'}, // Dominican Republic
    {'code': '+593', 'flag': '🇪🇨'}, // Ecuador
    {'code': '+20', 'flag': '🇪🇬'}, // Egypt
    {'code': '+503', 'flag': '🇸🇻'}, // El Salvador
    {'code': '+240', 'flag': '🇬🇶'}, // Equatorial Guinea
    {'code': '+291', 'flag': '🇪🇷'}, // Eritrea
    {'code': '+372', 'flag': '🇪🇪'}, // Estonia
    {'code': '+268', 'flag': '🇸🇿'}, // Eswatini
    {'code': '+251', 'flag': '🇪🇹'}, // Ethiopia
    {'code': '+500', 'flag': '🇫🇰'}, // Falkland Islands
    {'code': '+298', 'flag': '🇫🇴'}, // Faroe Islands
    {'code': '+679', 'flag': '🇫🇯'}, // Fiji
    {'code': '+358', 'flag': '🇫🇮'}, // Finland
    {'code': '+33', 'flag': '🇫🇷'}, // France
    {'code': '+594', 'flag': '🇬🇫'}, // French Guiana
    {'code': '+689', 'flag': '🇵🇫'}, // French Polynesia
    {'code': '+241', 'flag': '🇬🇦'}, // Gabon
    {'code': '+220', 'flag': '🇬🇲'}, // Gambia
    {'code': '+995', 'flag': '🇬🇪'}, // Georgia
    {'code': '+49', 'flag': '🇩🇪'}, // Germany
    {'code': '+233', 'flag': '🇬🇭'}, // Ghana
    {'code': '+350', 'flag': '🇬🇮'}, // Gibraltar
    {'code': '+30', 'flag': '🇬🇷'}, // Greece
    {'code': '+299', 'flag': '🇬🇱'}, // Greenland
    {'code': '+1', 'flag': '🇬🇩'}, // Grenada
    {'code': '+590', 'flag': '🇬🇵'}, // Guadeloupe
    {'code': '+1', 'flag': '🇬🇺'}, // Guam
    {'code': '+502', 'flag': '🇬🇹'}, // Guatemala
    {'code': '+44', 'flag': '🇬🇬'}, // Guernsey
    {'code': '+224', 'flag': '🇬🇳'}, // Guinea
    {'code': '+245', 'flag': '🇬🇼'}, // Guinea-Bissau
    {'code': '+592', 'flag': '🇬🇾'}, // Guyana
    {'code': '+509', 'flag': '🇭🇹'}, // Haiti
    {'code': '+504', 'flag': '🇭🇳'}, // Honduras
    {'code': '+852', 'flag': '🇭🇰'}, // Hong Kong
    {'code': '+36', 'flag': '🇭🇺'}, // Hungary
    {'code': '+354', 'flag': '🇮🇸'}, // Iceland
    {'code': '+91', 'flag': '🇮🇳'}, // India
    {'code': '+62', 'flag': '🇮🇩'}, // Indonesia
    {'code': '+98', 'flag': '🇮🇷'}, // Iran
    {'code': '+964', 'flag': '🇮🇶'}, // Iraq
    {'code': '+353', 'flag': '🇮🇪'}, // Ireland
    {'code': '+44', 'flag': '🇮🇲'}, // Isle of Man
    {'code': '+972', 'flag': '🇮🇱'}, // Israel
    {'code': '+39', 'flag': '🇮🇹'}, // Italy
    {'code': '+225', 'flag': '🇨🇮'}, // Ivory Coast
    {'code': '+1', 'flag': '🇯🇲'}, // Jamaica
    {'code': '+81', 'flag': '🇯🇵'}, // Japan
    {'code': '+44', 'flag': '🇯🇪'}, // Jersey
    {'code': '+962', 'flag': '🇯🇴'}, // Jordan
    {'code': '+7', 'flag': '🇰🇿'}, // Kazakhstan
    {'code': '+254', 'flag': '🇰🇪'}, // Kenya
    {'code': '+686', 'flag': '🇰🇮'}, // Kiribati
    {'code': '+383', 'flag': '🇽🇰'}, // Kosovo
    {'code': '+965', 'flag': '🇰🇼'}, // Kuwait
    {'code': '+996', 'flag': '🇰🇬'}, // Kyrgyzstan
    {'code': '+856', 'flag': '🇱🇦'}, // Laos
    {'code': '+371', 'flag': '🇱🇻'}, // Latvia
    {'code': '+961', 'flag': '🇱🇧'}, // Lebanon
    {'code': '+266', 'flag': '🇱🇸'}, // Lesotho
    {'code': '+231', 'flag': '🇱🇷'}, // Liberia
    {'code': '+218', 'flag': '🇱🇾'}, // Libya
    {'code': '+423', 'flag': '🇱🇮'}, // Liechtenstein
    {'code': '+370', 'flag': '🇱🇹'}, // Lithuania
    {'code': '+352', 'flag': '🇱🇺'}, // Luxembourg
    {'code': '+853', 'flag': '🇲🇴'}, // Macau
    {'code': '+389', 'flag': '🇲🇰'}, // Macedonia
    {'code': '+261', 'flag': '🇲🇬'}, // Madagascar
    {'code': '+265', 'flag': '🇲🇼'}, // Malawi
    {'code': '+60', 'flag': '🇲🇾'}, // Malaysia
    {'code': '+960', 'flag': '🇲🇻'}, // Maldives
    {'code': '+223', 'flag': '🇲🇱'}, // Mali
    {'code': '+356', 'flag': '🇲🇹'}, // Malta
    {'code': '+692', 'flag': '🇲🇭'}, // Marshall Islands
    {'code': '+596', 'flag': '🇲🇶'}, // Martinique
    {'code': '+222', 'flag': '🇲🇷'}, // Mauritania
    {'code': '+230', 'flag': '🇲🇺'}, // Mauritius
    {'code': '+262', 'flag': '🇾🇹'}, // Mayotte
    {'code': '+52', 'flag': '🇲🇽'}, // Mexico
    {'code': '+691', 'flag': '🇫🇲'}, // Micronesia
    {'code': '+373', 'flag': '🇲🇩'}, // Moldova
    {'code': '+377', 'flag': '🇲🇨'}, // Monaco
    {'code': '+976', 'flag': '🇲🇳'}, // Mongolia
    {'code': '+382', 'flag': '🇲🇪'}, // Montenegro
    {'code': '+1', 'flag': '🇲🇸'}, // Montserrat
    {'code': '+212', 'flag': '🇲🇦'}, // Morocco
    {'code': '+258', 'flag': '🇲🇿'}, // Mozambique
    {'code': '+95', 'flag': '🇲🇲'}, // Myanmar
    {'code': '+264', 'flag': '🇳🇦'}, // Namibia
    {'code': '+674', 'flag': '🇳🇷'}, // Nauru
    {'code': '+977', 'flag': '🇳🇵'}, // Nepal
    {'code': '+31', 'flag': '🇳🇱'}, // Netherlands
    {'code': '+687', 'flag': '🇳🇨'}, // New Caledonia
    {'code': '+64', 'flag': '🇳🇿'}, // New Zealand
    {'code': '+505', 'flag': '🇳🇮'}, // Nicaragua
    {'code': '+227', 'flag': '🇳🇪'}, // Niger
    {'code': '+234', 'flag': '🇳🇬'}, // Nigeria
    {'code': '+683', 'flag': '🇳🇺'}, // Niue
    {'code': '+672', 'flag': '🇳🇫'}, // Norfolk Island
    {'code': '+850', 'flag': '🇰🇵'}, // North Korea
    {'code': '+1', 'flag': '🇲🇵'}, // Northern Mariana Islands
    {'code': '+47', 'flag': '🇳🇴'}, // Norway
    {'code': '+968', 'flag': '🇴🇲'}, // Oman
    {'code': '+92', 'flag': '🇵🇰'}, // Pakistan
    {'code': '+680', 'flag': '🇵🇼'}, // Palau
    {'code': '+970', 'flag': '🇵🇸'}, // Palestine
    {'code': '+507', 'flag': '🇵🇦'}, // Panama
    {'code': '+675', 'flag': '🇵🇬'}, // Papua New Guinea
    {'code': '+595', 'flag': '🇵🇾'}, // Paraguay
    {'code': '+51', 'flag': '🇵🇪'}, // Peru
    {'code': '+63', 'flag': '🇵🇭'}, // Philippines
    {'code': '+48', 'flag': '🇵🇱'}, // Poland
    {'code': '+351', 'flag': '🇵🇹'}, // Portugal
    {'code': '+1', 'flag': '🇵🇷'}, // Puerto Rico
    {'code': '+974', 'flag': '🇶🇦'}, // Qatar
    {'code': '+242', 'flag': '🇨🇬'}, // Republic of the Congo
    {'code': '+262', 'flag': '🇷🇪'}, // Reunion
    {'code': '+40', 'flag': '🇷🇴'}, // Romania
    {'code': '+7', 'flag': '🇷🇺'}, // Russia
    {'code': '+250', 'flag': '🇷🇼'}, // Rwanda
    {'code': '+590', 'flag': '🇧🇱'}, // Saint Barthelemy
    {'code': '+290', 'flag': '🇸🇭'}, // Saint Helena
    {'code': '+1', 'flag': '🇰🇳'}, // Saint Kitts and Nevis
    {'code': '+1', 'flag': '🇱🇨'}, // Saint Lucia
    {'code': '+590', 'flag': '🇲🇫'}, // Saint Martin
    {'code': '+508', 'flag': '🇵🇲'}, // Saint Pierre and Miquelon
    {'code': '+1', 'flag': '🇻🇨'}, // Saint Vincent and the Grenadines
    {'code': '+685', 'flag': '🇼🇸'}, // Samoa
    {'code': '+378', 'flag': '🇸🇲'}, // San Marino
    {'code': '+239', 'flag': '🇸🇹'}, // Sao Tome and Principe
    {'code': '+966', 'flag': '🇸🇦'}, // Saudi Arabia
    {'code': '+221', 'flag': '🇸🇳'}, // Senegal
    {'code': '+381', 'flag': '🇷🇸'}, // Serbia
    {'code': '+248', 'flag': '🇸🇨'}, // Seychelles
    {'code': '+232', 'flag': '🇸🇱'}, // Sierra Leone
    {'code': '+65', 'flag': '🇸🇬'}, // Singapore
    {'code': '+1', 'flag': '🇸🇽'}, // Sint Maarten
    {'code': '+421', 'flag': '🇸🇰'}, // Slovakia
    {'code': '+386', 'flag': '🇸🇮'}, // Slovenia
    {'code': '+677', 'flag': '🇸🇧'}, // Solomon Islands
    {'code': '+252', 'flag': '🇸🇴'}, // Somalia
    {'code': '+27', 'flag': '🇿🇦'}, // South Africa
    {'code': '+82', 'flag': '🇰🇷'}, // South Korea
    {'code': '+211', 'flag': '🇸🇸'}, // South Sudan
    {'code': '+34', 'flag': '🇪🇸'}, // Spain
    {'code': '+94', 'flag': '🇱🇰'}, // Sri Lanka
    {'code': '+249', 'flag': '🇸🇩'}, // Sudan
    {'code': '+597', 'flag': '🇸🇷'}, // Suriname
    {'code': '+47', 'flag': '🇸🇯'}, // Svalbard and Jan Mayen
    {'code': '+268', 'flag': '🇸🇿'}, // Swaziland
    {'code': '+46', 'flag': '🇸🇪'}, // Sweden
    {'code': '+41', 'flag': '🇨🇭'}, // Switzerland
    {'code': '+963', 'flag': '🇸🇾'}, // Syria
    {'code': '+886', 'flag': '🇹🇼'}, // Taiwan
    {'code': '+992', 'flag': '🇹🇯'}, // Tajikistan
    {'code': '+255', 'flag': '🇹🇿'}, // Tanzania
    {'code': '+66', 'flag': '🇹🇭'}, // Thailand
    {'code': '+228', 'flag': '🇹🇬'}, // Togo
    {'code': '+690', 'flag': '🇹🇰'}, // Tokelau
    {'code': '+676', 'flag': '🇹🇴'}, // Tonga
    {'code': '+1', 'flag': '🇹🇹'}, // Trinidad and Tobago
    {'code': '+216', 'flag': '🇹🇳'}, // Tunisia
    {'code': '+90', 'flag': '🇹🇷'}, // Turkey
    {'code': '+993', 'flag': '🇹🇲'}, // Turkmenistan
    {'code': '+1', 'flag': '🇹🇨'}, // Turks and Caicos Islands
    {'code': '+688', 'flag': '🇹🇻'}, // Tuvalu
    {'code': '+256', 'flag': '🇺🇬'}, // Uganda
    {'code': '+380', 'flag': '🇺🇦'}, // Ukraine
    {'code': '+971', 'flag': '🇦🇪'}, // United Arab Emirates
    {'code': '+44', 'flag': '🇬🇧'}, // United Kingdom
    {'code': '+1', 'flag': '🇺🇸'}, // United States
    {'code': '+598', 'flag': '🇺🇾'}, // Uruguay
    {'code': '+998', 'flag': '🇺🇿'}, // Uzbekistan
    {'code': '+678', 'flag': '🇻🇺'}, // Vanuatu
    {'code': '+58', 'flag': '🇻🇪'}, // Venezuela
    {'code': '+84', 'flag': '🇻🇳'}, // Vietnam
    {'code': '+1', 'flag': '🇻🇮'}, // Virgin Islands (U.S.)
    {'code': '+681', 'flag': '🇼🇫'}, // Wallis and Futuna
    {'code': '+212', 'flag': '🇪🇭'}, // Western Sahara
    {'code': '+967', 'flag': '🇾🇪'}, // Yemen
    {'code': '+260', 'flag': '🇿🇲'}, // Zambia
    {'code': '+263', 'flag': '🇿🇼'}, // Zimbabwe
  ];
  String _selectedCountryCode = '+94';

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? DateTime.now(),
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: Color(0xFF86BF3E),
              onPrimary: Colors.white,
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

  Future<void> _pickImage(ImageSource source) async {
    final XFile? pickedFile = await _picker.pickImage(
      source: source,
      imageQuality: 80,
    );

    if (pickedFile != null) {
      setState(() {
        _imageFile = File(pickedFile.path);
      });
    }
  }

  // Before calling _pickImage
  Future<void> _requestAndPickImage(ImageSource source) async {
    try {
      if (source == ImageSource.camera) {
        var status = await Permission.camera.request();
        if (!status.isGranted) {
          print('Camera permission denied');
          return;
        }
      } else {
        var status = await Permission.photos.request(); // or Permission.storage for Android
        if (!status.isGranted) {
          print('Gallery permission denied');
          return;
        }
      }
      await _pickImage(source);
    } catch (e) {
      print('Error requesting permission or picking image: $e');
    }
  }

  void _showImageSourceDialog() {
    showModalBottomSheet(
      context: context,
      builder: (BuildContext context) {
        return SafeArea(
          child: Wrap(
            children: <Widget>[
              ListTile(
                leading: const Icon(Icons.photo_library),
                title: const Text('Choose from Gallery'),
                onTap: () {
                  Navigator.pop(context);
                  Future.delayed(const Duration(milliseconds: 200), () {
                    _requestAndPickImage(ImageSource.gallery);
                  });
                },
              ),
              ListTile(
                leading: const Icon(Icons.photo_camera),
                title: const Text('Take a Photo'),
                onTap: () {
                  Navigator.pop(context);
                  Future.delayed(const Duration(milliseconds: 200), () {
                    _requestAndPickImage(ImageSource.camera);
                  });
                },
              ),
            ],
          ),
        );
      },
    );
  }

  // Helper to upload image to Firebase Storage and get URL
  Future<String?> _uploadProfileImage(File imageFile, String userId) async {
    try {
      final storageRef = FirebaseStorage.instanceFor(
        bucket: 'gs://final-one2002.firebasestorage.app'
      ).ref()
        .child('profile_images')
        .child('$userId.jpg');
      final uploadTask = await storageRef.putFile(imageFile);
      if (uploadTask.state == TaskState.success) {
        final url = await storageRef.getDownloadURL();
        print('Image uploaded. Download URL: $url');
        return url;
      } else {
        print('Image upload failed');
        throw Exception('Image upload failed');
      }
    } catch (e) {
      print('Error uploading image: $e');
      return null;
    }
  }

  Future<void> _saveProfile() async {
    if (_formKey.currentState!.validate()) {
      final user = FirebaseAuth.instance.currentUser;
      String? imageUrl;
      if (_imageFile != null && user != null) {
        imageUrl = await _uploadProfileImage(_imageFile!, user.uid);
      }
      try {
        await FirebaseFirestore.instance.collection('users').doc(user!.uid).set({
          'name': _nameController.text.trim(),
          'username': _usernameController.text.trim(),
          'phoneNumber': '$_selectedCountryCode${_phoneController.text.trim()}',
          'birthday': _selectedDate != null ? _selectedDate!.toIso8601String() : null,
          'gender': _selectedGender,
          'profileImage': imageUrl, // This can be null if no image selected
        }, SetOptions(merge: true));
        print('Profile saved to Firestore');
      } catch (e) {
        print('Error saving profile to Firestore: $e');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          'Complete Profile',
          style: TextStyle(
            color: Colors.black,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
       
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // Profile Picture Section
                Stack(
                  children: [
                    FutureBuilder<DocumentSnapshot>(
                      future: FirebaseFirestore.instance.collection('users').doc(FirebaseAuth.instance.currentUser?.uid).get(),
                      builder: (context, snapshot) {
                        if (snapshot.connectionState == ConnectionState.waiting) {
                          return Container(
                            width: 120,
                            height: 120,
                            alignment: Alignment.center,
                            child: const CircularProgressIndicator(),
                          );
                        }
                        String? imageUrl;
                        if (snapshot.hasData && snapshot.data!.data() != null) {
                          final data = snapshot.data!.data() as Map<String, dynamic>;
                          imageUrl = data['profileImage'] as String?;
                        }
                        if (_imageFile != null) {
                          // Show local image if picked
                          return Container(
                            width: 120,
                            height: 120,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: Colors.grey[200],
                              image: DecorationImage(
                                image: FileImage(_imageFile!),
                                fit: BoxFit.cover,
                              ),
                            ),
                          );
                        } else if (imageUrl != null && imageUrl.isNotEmpty) {
                          // Show image from Firebase Storage if exists
                          return Container(
                            width: 120,
                            height: 120,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: Colors.grey[200],
                              image: DecorationImage(
                                image: NetworkImage(imageUrl),
                                fit: BoxFit.cover,
                              ),
                            ),
                          );
                        } else {
                          // Default icon
                          return Container(
                            width: 120,
                            height: 120,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: Colors.grey[200],
                            ),
                            child: const Icon(
                              Icons.person,
                              size: 60,
                              color: Colors.grey,
                            ),
                          );
                        }
                      },
                    ),
                    Positioned(
                      bottom: 0,
                      right: 0,
                      child: GestureDetector(
                        onTap: _showImageSourceDialog,
                        child: Container(
                          width: 36,
                          height: 36,
                          decoration: const BoxDecoration(
                            color: Color(0xFF86BF3E),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.camera_alt,
                            color: Colors.white,
                            size: 20,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 32),

                // Full Name Field
                TextFormField(
                  controller: _nameController,
                  decoration: InputDecoration(
                    labelText: 'Full Name',
                    prefixIcon: const Icon(Icons.person_outline),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: Color(0xFF86BF3E)),
                    ),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter your name';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 20),

                // Username Field
                TextFormField(
                  controller: _usernameController,
                  decoration: InputDecoration(
                    labelText: 'Username',
                    prefixIcon: const Icon(Icons.alternate_email),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: Color(0xFF86BF3E)),
                    ),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter your username';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 20),

                // Phone Number Field
                Row(
                  children: [
                    Container(
                      width: 120, // Reduced width for country code selection
                      child: DropdownButtonFormField<String>(
                        value: _selectedCountryCode,
                        decoration: InputDecoration(
                          labelText: 'Code',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(color: Color(0xFF86BF3E)),
                          ),
                        ),
                        items: _countryCodes.map((country) {
                          return DropdownMenuItem<String>(
                            value: country['code'],
                            child: Row(
                              children: [
                                Text(country['flag'] ?? '', style: const TextStyle(fontSize: 18)),
                                const SizedBox(width: 8), // Slightly reduced spacing
                                Text(country['code']!),
                              ],
                            ),
                          );
                        }).toList(),
                        onChanged: (value) {
                          setState(() {
                            _selectedCountryCode = value!;
                          });
                        },
                      ),
                    ),
                    const SizedBox(width: 8),
                    SizedBox(
                      width: 215, // Keep phone number input width as is
                      child: TextFormField(
                        controller: _phoneController,
                        keyboardType: TextInputType.phone,
                        decoration: InputDecoration(
                          labelText: 'Phone Number',
                          prefixIcon: const Icon(Icons.phone),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(color: Color(0xFF86BF3E)),
                          ),
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter your phone number';
                          }
                          return null;
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),

                // Birthday Field
                GestureDetector(
                  onTap: () => _selectDate(context),
                  child: AbsorbPointer(
                    child: TextFormField(
                      decoration: InputDecoration(
                        labelText: 'Birthday',
                        prefixIcon: const Icon(Icons.cake_outlined),
                        suffixIcon: const Icon(Icons.calendar_today),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(color: Color(0xFF86BF3E)),
                        ),
                      ),
                      controller: TextEditingController(
                        text: _selectedDate != null
                            ? "${_selectedDate!.day}/${_selectedDate!.month}/${_selectedDate!.year}"
                            : "",
                      ),
                      validator: (value) {
                        if (_selectedDate == null) {
                          return 'Please select your birthday';
                        }
                        return null;
                      },
                    ),
                  ),
                ),
                const SizedBox(height: 20),

                // Gender Selection
                Container(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Padding(
                        padding: EdgeInsets.symmetric(horizontal: 16),
                        child: Text(
                          'Gender',
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.grey,
                          ),
                        ),
                      ),
                      Row(
                        children: [
                          Expanded(
                            child: RadioListTile<String>(
                              title: const Text('Male'),
                              value: 'Male',
                              groupValue: _selectedGender,
                              activeColor: const Color(0xFF86BF3E),
                              onChanged: (value) {
                                setState(() {
                                  _selectedGender = value!;
                                });
                              },
                            ),
                          ),
                          Expanded(
                            child: RadioListTile<String>(
                              title: const Text('Female'),
                              value: 'Female',
                              groupValue: _selectedGender,
                              activeColor: const Color(0xFF86BF3E),
                              onChanged: (value) {
                                setState(() {
                                  _selectedGender = value!;
                                });
                              },
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 32),

                // Save Button
                SizedBox(
                  width: double.infinity,
                  height: 55,
                  child: ElevatedButton(
                    onPressed: () async {
                      if (_formKey.currentState!.validate() && _selectedGender.isNotEmpty) {
                        showDialog(
                          context: context,
                          barrierDismissible: false,
                          builder: (context) => const Center(child: CircularProgressIndicator()),
                        );
                        try {
                          await _saveProfile();
                          Navigator.pop(context); // Close loading
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Profile saved successfully!')),
                          );
                          Navigator.pushReplacementNamed(context, '/goal_selection');
                        } catch (e) {
                          Navigator.pop(context); // Close loading
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('Error: [${e.toString()}')),
                          );
                        }
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF86BF3E),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text(
                      'Save Profile',
                      style: TextStyle(
                        fontSize: 18,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _usernameController.dispose(); // Add this
    _phoneController.dispose();    // Add this
    super.dispose();
  }
}

class Person {
  final String name;
  final int age;

  Person(this.name, this.age);

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Person &&
          runtimeType == other.runtimeType &&
          name == other.name &&
          age == other.age;

  @override
  int get hashCode => name.hashCode ^ age.hashCode;
}
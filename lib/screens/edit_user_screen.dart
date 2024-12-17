import 'dart:io';

import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:hanguiemos_frontend/core/providers/logged_user_provider.dart';
import 'package:hanguiemos_frontend/entities/categoria.dart';
import 'package:hanguiemos_frontend/services/logged_user_service.dart';
import 'package:hanguiemos_frontend/services/user_service.dart';
import 'package:image_picker/image_picker.dart';

class EditUserScreen extends ConsumerStatefulWidget {
  static const String name = 'edit_user_screen';
  const EditUserScreen({Key? key}) : super(key: key);

  @override
  EditUserScreenState createState() => EditUserScreenState();
}

class EditUserScreenState extends ConsumerState<EditUserScreen>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final ImagePicker _picker = ImagePicker();
  File? _image;
  String? _imageUrl;
  Uint8List? _webImage;

  final UserService userService = UserService();
  final LoggedUserService loggedUserService = LoggedUserService();
  final TextEditingController _categoriasController = TextEditingController();
  late String _usuario;
  late List<Categoria> _categorias;
  late AnimationController _animationController;

  @override
  void initState() {
    super.initState();
    final user = ref.read(loggedUserProvider);
    _usuario = user.nombreDeUsuario;
    _categorias = user.intereses
        .map((e) => Categoria.values
            .firstWhere((c) => c.toString().split('.').last == e))
        .toList();
    _categoriasController.text = user.intereses.join(', ');
    _imageUrl = user.imagenUrl;
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final XFile? pickedFile =
        await _picker.pickImage(source: ImageSource.gallery);

    if (pickedFile != null) {
      if (kIsWeb) {
        final Uint8List bytes = await pickedFile.readAsBytes();
        setState(() {
          _webImage = bytes;
          _image = null; // Reset mobile image
        });
      } else {
        setState(() {
          _image = File(pickedFile.path);
          _webImage = null; // Reset web image
        });
      }
    }
  }

  Future<void> _uploadImage() async {
    if (_image == null && _webImage == null) return;

    try {
      final storageRef = FirebaseStorage.instance.ref();
      final imagesRef = storageRef
          .child("images/${DateTime.now().millisecondsSinceEpoch}.jpg");

      if (kIsWeb) {
        final metadata = SettableMetadata(contentType: 'image/jpeg');
        await imagesRef.putData(_webImage!, metadata);
      } else {
        await imagesRef.putFile(_image!);
      }

      String downloadURL = await imagesRef.getDownloadURL();
      await _deleteImage();
      setState(() {
        _imageUrl = downloadURL;
      });
    } catch (e) {
      print('Error uploading image: $e');
    }
  }

  ImageProvider _buildImageProvider() {
    if (kIsWeb) {
      return MemoryImage(_webImage!);
    } else {
      return FileImage(_image!);
    }
  }

  Future<void> _deleteImage() async {
    if (_imageUrl == '') {
      return;
    }
    try {
      final storageRef = FirebaseStorage.instance.refFromURL(_imageUrl!);
      await storageRef.delete();
    } catch (e) {}
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Editar Usuario',
          style: TextStyle(color: Colors.white),
        ),
        backgroundColor: Colors.deepPurple,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                _buildProfileImage(),
                const SizedBox(height: 60),
                _buildUsernameField(),
                const SizedBox(height: 30),
                _buildImagePickerField(),
                const SizedBox(height: 50),
                _buildInterestsSelection(),
                const SizedBox(height: 60),
                _buildSaveButton(context),
                const SizedBox(height: 60),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildProfileImage() {
    return Center(
      child: GestureDetector(
        onTap: _pickImage,
        child: CircleAvatar(
          radius: 60,
          backgroundImage: _image != null || _webImage != null
              ? _buildImageProvider()
              : _imageUrl != null && _imageUrl!.isNotEmpty
                  ? NetworkImage(_imageUrl!) as ImageProvider
                  : const AssetImage('assets/user-placeholder.png'),
          backgroundColor: Colors.grey[200],
        ),
      ),
    );
  }

  Widget _buildUsernameField() {
    return TextFormField(
      initialValue: _usuario,
      decoration: InputDecoration(
        labelText: 'Nombre de usuario',
        hintText: 'Tu nombre de usuario debe tener al menos 4 caracteres',
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        filled: true,
        fillColor: Colors.deepPurple[50],
      ),
      validator: (value) {
        if (value == null || value.isEmpty || value.length < 4) {
          return 'Por favor ingresa un nombre de usuario válido';
        }
        return null;
      },
      onSaved: (value) => _usuario = value!,
    );
  }

  Widget _buildInterestsSelection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Intereses',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        Center(
          child: Wrap(
            alignment: WrapAlignment.center,
            spacing: 12.0, // Aumentado el espaciado horizontal
            runSpacing: 12.0, // Aumentado el espaciado vertical
            children: Categoria.values.map((categoria) {
              final bool isSelected = _categorias.contains(categoria);
              return AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: isSelected ? Colors.deepPurple : Colors.deepPurple[50],
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: isSelected
                        ? Colors.deepPurple
                        : Colors.deepPurple[200]!,
                  ),
                ),
                child: GestureDetector(
                  onTap: () {
                    setState(() {
                      if (isSelected) {
                        _categorias.remove(categoria);
                      } else {
                        _categorias.add(categoria);
                      }
                      _categoriasController.text = _categorias
                          .map((cat) => cat.toString().split('.').last)
                          .join(', ');
                    });
                    _animationController.forward().then((_) {
                      _animationController.reverse();
                    });
                  },
                  child: Text(
                    categoria.toString().split('.').last,
                    style: TextStyle(
                      color: isSelected ? Colors.white : Colors.deepPurple,
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }

  Widget _buildImagePickerField() {
    return GestureDetector(
      onTap: _pickImage,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
        decoration: BoxDecoration(
          color: Colors.deepPurple[50],
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.deepPurple[200]!),
        ),
        child: const Row(
          children: [
            Icon(Icons.photo_camera, color: Colors.deepPurple),
            SizedBox(width: 12),
            Text(
              'Subí una foto desde tu galería',
              style: TextStyle(color: Colors.deepPurple),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSaveButton(BuildContext context) {
    return ElevatedButton(
      onPressed: () async {
        if (_formKey.currentState!.validate()) {
          _formKey.currentState!.save();
          await _uploadImage();
          final user = ref.read(loggedUserProvider);
          await userService.updateUser(
            _usuario,
            _categorias,
            _imageUrl,
            user.token,
          );
          final loggedUser = await loggedUserService
              .fetchUserByToken(ref.watch(userTokenProvider));
          ref.read(loggedUserProvider.notifier).updateLoggedUser(loggedUser);
          context.pop();
        }
      },
      style: ElevatedButton.styleFrom(
        foregroundColor: Colors.white,
        backgroundColor: Colors.deepPurple,
        padding: const EdgeInsets.symmetric(vertical: 16),
        textStyle: const TextStyle(fontSize: 16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
      child: const Text('Guardar Cambios'),
    );
  }
}

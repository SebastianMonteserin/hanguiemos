import 'dart:io';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hanguiemos_frontend/entities/categoria.dart';
import 'package:hanguiemos_frontend/screens/login_screen.dart';
import 'package:hanguiemos_frontend/services/user_auth_service.dart';
import 'package:image_picker/image_picker.dart';

class SignUpScreen extends StatefulWidget {
  static String get name => 'register_user_screen';

  const SignUpScreen({super.key});

  @override
  RegisterUserScreenState createState() => RegisterUserScreenState();
}

class RegisterUserScreenState extends State<SignUpScreen> {
  final _formKey = GlobalKey<FormState>();
  late String _email;
  late String _password;
  late final List<Categoria> _categorias = [];
  late String _nombre;
  late String _apellido;
  late int _edad;
  late String _usuario;
  late String _telefono;

  final ImagePicker _picker = ImagePicker();
  File? _image;
  Uint8List? _webImage;
  String? _imageUrl;

  final UserAuthService userService = UserAuthService();

  final TextEditingController _categoriasController = TextEditingController();

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
      setState(() {
        _imageUrl = downloadURL;
      });
    } catch (e) {
      print('Error uploading image: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Registrarse',
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
                _buildTextField('Nombre', 'Por favor ingresa tu nombre',
                    'Por favor ingresa tu nombre', (value) => _nombre = value!),
                const SizedBox(height: 20),
                _buildTextField(
                    'Apellido',
                    'Por favor ingresa tu apellido',
                    'Por favor ingresa tu apellido',
                    (value) => _apellido = value!),
                const SizedBox(height: 20),
                _buildTextField('Edad', 'Por favor ingresa tu edad',
                    'Por favor ingresa tu edad', (value) {
                  final intAge = int.tryParse(value!);
                  if (intAge == null || intAge < 0) {
                    return 'La edad debe ser un número entero mayor o igual a cero';
                  }
                  _edad = intAge;
                }),
                const SizedBox(height: 20),
                _buildTextField(
                    'Nombre de usuario',
                    'Tu nombre de usuario debe tener al menos 4 caracteres',
                    'Por favor ingresa un nombre de usuario válido',
                    (value) => _usuario = value!,
                    minLength: 4),
                const SizedBox(height: 20),
                _buildTextField(
                    'Correo electrónico',
                    'Ingresá una dirección de correo electrónico válida',
                    'Por favor ingresa un correo electrónico válido',
                    (value) => _email = value!,
                    isEmail: true),
                const SizedBox(height: 20),
                _buildTextField(
                    'Número de telefono',
                    'Ingresá un número de teléfono válido',
                    'Por favor ingresa un número de teléfono válido',
                    (value) => _telefono = value!,
                    isPhone: true),
                const SizedBox(height: 20),
                _buildPasswordTextField(),
                const SizedBox(height: 20),
                _buildInterestsSelection(),
                const SizedBox(height: 20),
                _buildImagePickerField(),
                const SizedBox(height: 20),
                _buildRegisterButton(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTextField(String label, String hint, String validationMessage,
      Function(String?) onSaved,
      {int minLength = 1, bool isEmail = false, bool isPhone = false}) {
    return TextFormField(
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        filled: true,
        fillColor: Colors.deepPurple[50],
      ),
      validator: (value) {
        if (value == null || value.isEmpty) {
          return validationMessage;
        } else if (isEmail && !isEmailValid(value)) {
          return 'Por favor ingresa un correo electrónico válido';
        } else if (isPhone && !isValidPhoneNumber(value)) {
          return 'Por favor ingresa un numero de teléfono valido válido';
        } else if (value.length < minLength) {
          return validationMessage;
        }
        return null;
      },
      onSaved: onSaved,
    );
  }

  Widget _buildPasswordTextField() {
    return TextFormField(
      decoration: InputDecoration(
        labelText: 'Contraseña',
        hintText: 'La contraseña debe tener al menos 8 caracteres',
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        filled: true,
        fillColor: Colors.deepPurple[50],
      ),
      obscureText: true,
      validator: (value) {
        if (value == null || value.isEmpty || value.length < 8) {
          return 'Por favor ingresa una contraseña válida';
        }
        return null;
      },
      onSaved: (value) => _password = value!,
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
            spacing: 12.0,
            runSpacing: 12.0,
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

  Widget _buildRegisterButton() {
    return ElevatedButton(
      onPressed: () async {
        if (_formKey.currentState!.validate()) {
          _formKey.currentState!.save();
          await _uploadImage();
          try {
            await userService.registerUser(
                _email,
                _password,
                _usuario,
                _categorias,
                _edad,
                _imageUrl ?? '',
                _nombre,
                _apellido,
                _telefono);
            context.goNamed(LoginScreen.name);
          } catch (exception) {
            _showSnackBar(
                context, "Ya existe un usuario registrado con ese mail");
          }
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
      child: const Text('Registrarse'),
    );
  }

  bool isEmailValid(String email) {
    final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
    return emailRegex.hasMatch(email);
  }

  bool isValidPhoneNumber(String phoneNumber) {
    if (phoneNumber.isEmpty || phoneNumber.length != 10) {
      return false;
    }
    final RegExp regex = RegExp(r'^[0-9]+$');
    return regex.hasMatch(phoneNumber);
  }

  void _showSnackBar(BuildContext context, String message) {
    final snackBar = SnackBar(
      content: Text(message),
      backgroundColor: const Color.fromARGB(255, 195, 66, 66),
    );
    ScaffoldMessenger.of(context).showSnackBar(snackBar);
  }
}

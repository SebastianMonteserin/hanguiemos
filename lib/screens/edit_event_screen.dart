import 'dart:io';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gap/gap.dart';
import 'package:go_router/go_router.dart';
import 'package:hanguiemos_frontend/core/providers/events_provider.dart';
import 'package:hanguiemos_frontend/core/providers/logged_user_provider.dart';
import 'package:hanguiemos_frontend/entities/event.dart';
import 'package:hanguiemos_frontend/services/event_service.dart';
import 'package:image_picker/image_picker.dart';

class EditEventScreen extends ConsumerStatefulWidget {
  static const String name = 'edit_event_screen';
  final Evento event;

  const EditEventScreen({super.key, required this.event});

  @override
  EditEventScreenState createState() => EditEventScreenState();
}

class EditEventScreenState extends ConsumerState<EditEventScreen> {
  final _formKey = GlobalKey<FormState>();
  final _eventService = EventService();
  final ImagePicker _picker = ImagePicker();

  late TextEditingController _nombreController;
  late TextEditingController _ciudadController;
  late TextEditingController _descripcionController;
  late TextEditingController _direccionController;
  late DateTime _day;
  late TimeOfDay _time;

  File? _image;
  Uint8List? _webImage;
  String? _imageUrl;

  bool isVirtualEvent = false;

  @override
  void initState() {
    super.initState();
    _nombreController = TextEditingController(text: widget.event.nombre);
    _ciudadController = TextEditingController(text: widget.event.ciudad);
    _descripcionController =
        TextEditingController(text: widget.event.descripcion);
    _direccionController = TextEditingController(text: widget.event.direccion);
    _day = widget.event.dia;
    _time = widget.event.hora;
    _imageUrl = widget.event.imagenUrl;
    isVirtualEvent = widget.event.direccion!.isEmpty;
  }

  bool _isPickerActive = false;

  Future<void> _pickImage() async {
    if (_isPickerActive) return;

    _isPickerActive = true;
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
      await _deleteImage();
    } catch (e) {
      print('Error uploading image: $e');
    }
  }

  Future<void> _deleteImage() async {
    if (widget.event.imagenUrl == '') {
      return;
    }
    try {
      final storageRef =
          FirebaseStorage.instance.refFromURL(widget.event.imagenUrl);
      await storageRef.delete();
    } catch (e) {}
  }

  Future<void> _selectTime(BuildContext context) async {
    final TimeOfDay? pickedTime = await showTimePicker(
      context: context,
      initialTime: _time,
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: Colors.deepPurple, // header background color
              onPrimary: Colors.white, // header text color
              onSurface: Colors.deepPurple, // body text color
            ),
            textButtonTheme: TextButtonThemeData(
              style: TextButton.styleFrom(
                foregroundColor: Colors.deepPurple, // button text color
              ),
            ),
          ),
          child: child!,
        );
      },
    );
    if (pickedTime != null && pickedTime != _time) {
      setState(() {
        _time = pickedTime;
      });
    }
  }

  Future<void> _submit() async {
    if (_formKey.currentState!.validate()) {
      await _uploadImage();

      final updatedEvent = widget.event.copyWith(
          nombre: _nombreController.text,
          ciudad: _ciudadController.text,
          descripcion: _descripcionController.text,
          dia: _day,
          hora: _time,
          imagenUrl: _imageUrl!,
          direccion: _direccionController.text);

      await _eventService.updateEvent(
        id: updatedEvent.id,
        name: updatedEvent.nombre,
        category: updatedEvent.categoria,
        city: updatedEvent.ciudad,
        day: updatedEvent.dia,
        time: updatedEvent.hora,
        description: updatedEvent.descripcion,
        imagenUrl: updatedEvent.imagenUrl,
        direccion: updatedEvent.direccion,
        token: ref.read(userTokenProvider),
      );

      ref.read(eventProvider.notifier).updateEvent(updatedEvent);

      context.pop();
    }
  }

  @override
  void dispose() {
    _nombreController.dispose();
    _ciudadController.dispose();
    _descripcionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Editar Evento',
          style: TextStyle(color: Colors.white),
        ),
        backgroundColor: Colors.deepPurple,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              _buildTextField(
                  _nombreController,
                  'Nombre',
                  'Por favor ingresa el nombre del evento',
                  'El nombre del evento debe tener más de 3 caracteres'),
              const Gap(20),
              _buildTextField(
                  _ciudadController,
                  'Ciudad',
                  'Por favor ingresa la ciudad del evento',
                  'La ciudad del evento debe tener más de 3 caracteres'),
              const Gap(20),
              _buildTextField(
                  _descripcionController,
                  'Descripción',
                  'Por favor ingresa una descripción del evento',
                  'La descripción del evento debe tener más de 3 caracteres',
                  maxLines: 3),
              const Gap(20),
              _buildDatePicker(context),
              const Gap(20),
              _buildTimePicker(context),
              const Gap(20),
              Row(
                children: [
                  Checkbox(
                    value: isVirtualEvent,
                    onChanged: (bool? value) {
                      setState(() {
                        isVirtualEvent = value!;
                      });
                    },
                  ),
                  const Text('Evento Virtual'),
                ],
              ),
              const Gap(20),
              TextFormField(
                controller: _direccionController,
                decoration: const InputDecoration(
                  labelText: 'Dirección',
                  border: OutlineInputBorder(),
                ),
                enabled: !isVirtualEvent,
              ),
              const Gap(20),
              _buildImagePicker(),
              const Gap(20),
              ElevatedButton(
                onPressed: _submit,
                style: ElevatedButton.styleFrom(
                  foregroundColor: Colors.white,
                  backgroundColor: Colors.deepPurple,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  textStyle: const TextStyle(fontSize: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text('Editar Evento'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTextField(TextEditingController controller, String label,
      String validationMessage, String lengthValidationMessage,
      {int maxLines = 1}) {
    return TextFormField(
        controller: controller,
        decoration: InputDecoration(
          labelText: label,
          border: const OutlineInputBorder(),
          filled: true,
          fillColor: Colors.deepPurple[50],
        ),
        maxLines: maxLines,
        validator: (value) {
          if (value == null || value.isEmpty) {
            return validationMessage;
          } else if (value.length < 3) {
            return lengthValidationMessage;
          } else if (value.length > 200) {
            return 'La descripción debe tener menos de 200 caracteres';
          }
          return null;
        });
  }

  Widget _buildDatePicker(BuildContext context) {
    return InkWell(
      onTap: () => _selectDate(context),
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: 'Fecha (YYYY-MM-DD)',
          border: const OutlineInputBorder(),
          filled: true,
          fillColor: Colors.deepPurple[50],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: <Widget>[
            Text(
                '${_day.year}-${_day.month.toString().padLeft(2, '0')}-${_day.day.toString().padLeft(2, '0')}'),
            const Icon(Icons.calendar_today),
          ],
        ),
      ),
    );
  }

  Widget _buildTimePicker(BuildContext context) {
    return InkWell(
      onTap: () => _selectTime(context),
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: 'Hora (HH:MM)',
          border: const OutlineInputBorder(),
          filled: true,
          fillColor: Colors.deepPurple[50],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: <Widget>[
            Text(
                '${_time.hour.toString().padLeft(2, '0')}:${_time.minute.toString().padLeft(2, '0')}'),
            const Icon(Icons.access_time),
          ],
        ),
      ),
    );
  }

  Widget _buildImagePicker() {
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

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: _day,
      firstDate: DateTime.now(),
      lastDate: DateTime(2101),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: Colors.deepPurple, // header background color
              onPrimary: Colors.white, // header text color
              onSurface: Colors.deepPurple, // body text color
            ),
            textButtonTheme: TextButtonThemeData(
              style: TextButton.styleFrom(
                foregroundColor: Colors.deepPurple, // button text color
              ),
            ),
          ),
          child: child!,
        );
      },
    );
    if (pickedDate != null && pickedDate != _day) {
      setState(() {
        _day = pickedDate;
      });
    }
  }
}

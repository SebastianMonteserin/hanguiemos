import 'dart:io';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:hanguiemos_frontend/core/providers/events_provider.dart';
import 'package:hanguiemos_frontend/core/providers/logged_user_provider.dart';
import 'package:hanguiemos_frontend/entities/categoria.dart';
import 'package:hanguiemos_frontend/services/event_service.dart';
import 'package:hanguiemos_frontend/services/logged_user_service.dart';
import 'package:image_picker/image_picker.dart';

class CreateEventScreen extends ConsumerStatefulWidget {
  static const String name = 'create_event_screen';

  const CreateEventScreen({super.key});

  @override
  CreateEventScreenState createState() => CreateEventScreenState();
}

class CreateEventScreenState extends ConsumerState<CreateEventScreen> {
  final _formKey = GlobalKey<FormState>();
  Categoria _selectedCategory = Categoria.deporte;
  late String _name;
  late String _city;
  late DateTime _day = DateTime.now();
  late TimeOfDay _time = TimeOfDay.now();
  late String _description;
  bool isVirtualEvent = false;

  final ImagePicker _picker = ImagePicker();
  File? _image;
  Uint8List? _webImage;
  String? _imageUrl;
  String? direccion;
  double? duracion;

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

  List<String> categoryNames = Categoria.values
      .map((category) => category.toString().split('.').last)
      .toList();

  final EventService _eventService = EventService();
  final LoggedUserService loggedUserService = LoggedUserService();

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

  Future<void> _selectTime(BuildContext context) async {
    final TimeOfDay? pickedTime = await showTimePicker(
      context: context,
      initialTime: _time,
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: Colors.deepPurple,
              onPrimary: Colors.white,
              onSurface: Colors.deepPurple,
            ),
            textButtonTheme: TextButtonThemeData(
              style: TextButton.styleFrom(
                foregroundColor: Colors.deepPurple,
              ),
            ),
          ),
          child: child!,
        );
      },
    );
    if (pickedTime != null) {
      final now = TimeOfDay.now();
      final pickedDateTime = DateTime(
        _day.year,
        _day.month,
        _day.day,
        pickedTime.hour,
        pickedTime.minute,
      );
      final nowDateTime = DateTime(
        DateTime.now().year,
        DateTime.now().month,
        DateTime.now().day,
        now.hour,
        now.minute,
      );

      if (pickedDateTime.isAfter(nowDateTime)) {
        setState(() {
          _time = pickedTime;
        });
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            backgroundColor: Colors.red,
            content: Text(
                'La hora seleccionada es en el pasado. Por favor selecciona una hora futura.'),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Crear Evento',
          style: TextStyle(color: Colors.white),
        ),
        backgroundColor: Colors.deepPurple,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                const SizedBox(height: 10),
                DropdownButtonFormField<String>(
                  value: categoryNames.first,
                  onChanged: (String? newValue) {
                    setState(() {
                      _selectedCategory =
                          Categoria.values[categoryNames.indexOf(newValue!)];
                    });
                  },
                  items: categoryNames
                      .map<DropdownMenuItem<String>>((String value) {
                    return DropdownMenuItem<String>(
                      value: value,
                      child: Text(value),
                    );
                  }).toList(),
                  decoration: const InputDecoration(
                    labelText: 'Categoría',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 20),
                TextFormField(
                  decoration: const InputDecoration(
                    labelText: 'Nombre del evento',
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Por favor ingresa el nombre del evento';
                    } else if (value.length < 3) {
                      return 'El nombre del evento debe tener más de 3 caracteres';
                    } else if (value.length > 33) {
                      return 'El nombre del evento no debe tener más de 33 caracteres';
                    }
                    return null;
                  },
                  onSaved: (value) => _name = value!,
                ),
                const SizedBox(height: 20),
                TextFormField(
                  decoration: const InputDecoration(
                    labelText: 'Ciudad',
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Por favor ingresa la ciudad';
                    } else if (value.length < 3) {
                      return 'La ciudad del evento debe tener más de 3 caracteres';
                    }
                    return null;
                  },
                  onSaved: (value) => _city = value!,
                ),
                const SizedBox(height: 20),
                InkWell(
                  onTap: () => _selectDate(context),
                  child: InputDecorator(
                    decoration: const InputDecoration(
                      labelText: 'Fecha (YYYY-MM-DD)',
                      border: OutlineInputBorder(),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      mainAxisSize: MainAxisSize.min,
                      children: <Widget>[
                        Text(
                            '${_day.year}-${_day.month.toString().padLeft(2, '0')}-${_day.day.toString().padLeft(2, '0')}'),
                        const Icon(Icons.calendar_today),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                InkWell(
                  onTap: () => _selectTime(context),
                  child: InputDecorator(
                    decoration: const InputDecoration(
                      labelText: 'Hora (HH:MM)',
                      border: OutlineInputBorder(),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      mainAxisSize: MainAxisSize.min,
                      children: <Widget>[
                        Text(
                            '${_time.hour.toString().padLeft(2, '0')}:${_time.minute.toString().padLeft(2, '0')}'),
                        const Icon(Icons.access_time),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                TextFormField(
                  decoration: const InputDecoration(
                    labelText: 'Descripción',
                    border: OutlineInputBorder(),
                  ),
                  maxLines: 3,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Por favor ingresa la descripción';
                    } else if (value.length < 3) {
                      return 'La descripción debe tener más de 3 caracteres';
                    } else if (value.length > 200) {
                      return 'La descripción debe tener menos de 200 caracteres';
                    }
                    return null;
                  },
                  onSaved: (value) => _description = value!,
                ),
                const SizedBox(height: 20),
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
                const SizedBox(height: 20),
                TextFormField(
                  decoration: const InputDecoration(
                    labelText: 'Dirección',
                    border: OutlineInputBorder(),
                  ),
                  onSaved: (value) => direccion = value!,
                  enabled: !isVirtualEvent,
                ),
                const SizedBox(height: 20),
                GestureDetector(
                  onTap: _pickImage,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        vertical: 16, horizontal: 12),
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
                ),
                const SizedBox(height: 20),
                ElevatedButton(
                  onPressed: () async {
                    if (_formKey.currentState!.validate()) {
                      _formKey.currentState!.save();

                      await _uploadImage();

                      await _eventService.createEvent(
                          name: _name,
                          category: _selectedCategory,
                          city: _city,
                          day: _day,
                          time: _time,
                          description: _description,
                          imagenUrl: _imageUrl,
                          direccion: direccion!,
                          token: ref.watch(userTokenProvider));

                      ref.read(eventProvider.notifier).setEvents(
                          await _eventService.fetchEvents(
                              token: ref.watch(userTokenProvider)));
                      final loggedUser = await loggedUserService
                          .fetchUserByToken(ref.watch(userTokenProvider));
                      ref
                          .read(loggedUserProvider.notifier)
                          .updateLoggedUser(loggedUser);

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
                  child: const Text('Crear Evento'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

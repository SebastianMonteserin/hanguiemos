import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:hanguiemos_frontend/core/providers/logged_user_provider.dart';
import 'package:hanguiemos_frontend/entities/event.dart';
import 'package:hanguiemos_frontend/screens/detail_event_screen.dart';
import 'package:hanguiemos_frontend/screens/edit_user_screen.dart';
import 'package:hanguiemos_frontend/screens/login_screen.dart';
import 'package:hanguiemos_frontend/services/event_service.dart';
import 'package:hanguiemos_frontend/services/local_storage.dart';

class UserProfileScreen extends ConsumerStatefulWidget {
  static const String name = 'user_profile_screen';

  const UserProfileScreen({super.key});

  @override
  UserProfileScreenState createState() => UserProfileScreenState();
}

class UserProfileScreenState extends ConsumerState<UserProfileScreen> {
  void _showEventsDialog(
      BuildContext context, List<String> ids, String titulo) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return CustomEventDialog(
          idsEventos: ids,
          titulo: titulo,
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final loggedUser = ref.watch(loggedUserProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Perfil de Usuario',
          style: TextStyle(color: Colors.white),
        ),
        backgroundColor: Colors.deepPurple,
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16.0),
            child: IconButton(
              icon: const Icon(
                Icons.logout,
                color: Colors.white,
              ),
              onPressed: () async {
                LocalStorage.prefs.remove("token");
                context.goNamed(LoginScreen.name);
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(right: 16.0),
            child: IconButton(
              icon: const Icon(
                Icons.edit,
                color: Colors.white,
              ),
              onPressed: () => context.pushNamed(EditUserScreen.name),
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: CircleAvatar(
                  radius: 50,
                  backgroundImage: loggedUser.imagenUrl != ""
                      ? NetworkImage(loggedUser.imagenUrl)
                      : const AssetImage('assets/user-placeholder.png')
                          as ImageProvider,
                  backgroundColor: Colors.grey[200],
                ),
              ),
              const SizedBox(height: 16),
              Center(
                child: Text(
                  loggedUser.nombreDeUsuario,
                  style: const TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: Colors.deepPurple,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'Intereses',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: Colors.deepPurple,
                ),
              ),
              const Divider(
                color: Colors.deepPurple,
                thickness: 2,
              ),
              const SizedBox(height: 8),
              Container(
                decoration: BoxDecoration(
                  color: Colors.deepPurple[50],
                  borderRadius: BorderRadius.circular(10),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.grey.withOpacity(0.2),
                      spreadRadius: 2,
                      blurRadius: 5,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: loggedUser.intereses.length,
                    itemBuilder: (context, index) {
                      return ListTile(
                        leading: const Icon(
                          Icons.label,
                          color: Colors.deepPurple,
                        ),
                        title: Text(
                          loggedUser.intereses[index],
                          style: const TextStyle(
                            fontSize: 18,
                            color: Colors.black87,
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ),
              const SizedBox(height: 80),
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () {
                        _showEventsDialog(context, loggedUser.eventosCreados,
                            "Eventos Creados");
                      },
                      icon: const Icon(Icons.event),
                      label: const Text('Eventos Creados'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.deepPurple,
                        foregroundColor: Colors.white,
                        textStyle: const TextStyle(fontSize: 16),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 20, vertical: 10),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 20),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () {
                        _showEventsDialog(context, loggedUser.eventosSuscriptos,
                            "Eventos Suscriptos");
                      },
                      icon: const Icon(Icons.event_available),
                      label: const Text('Eventos Suscriptos'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.deepPurple,
                        foregroundColor: Colors.white,
                        textStyle: const TextStyle(fontSize: 16),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 20, vertical: 10),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class CustomEventDialog extends ConsumerStatefulWidget {
  const CustomEventDialog({
    super.key,
    required this.idsEventos,
    required this.titulo,
  });

  final List<String> idsEventos;
  final String titulo;

  @override
  CustomEventDialogState createState() => CustomEventDialogState();
}

class CustomEventDialogState extends ConsumerState<CustomEventDialog> {
  late List<Evento> eventos;
  bool isLoading = true;
  String? errorMessage;

  @override
  void initState() {
    super.initState();
    _fetchEvents(widget.idsEventos);
  }

  Future<void> _fetchEvents(List<String> ids) async {
    try {
      final eventService = EventService();
      final userToken = ref.read(userTokenProvider);
      eventos = await eventService.obtenerListaEventosPorId(ids, userToken);
    } catch (error) {
      errorMessage = "Error al cargar eventos";
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
      child: Container(
        padding: const EdgeInsets.all(16.0),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
        ),
        child: isLoading
            ? const Center(child: CircularProgressIndicator())
            : errorMessage != null
                ? Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        errorMessage!,
                        style: const TextStyle(color: Colors.red),
                      ),
                      const SizedBox(height: 20),
                      ElevatedButton(
                        onPressed: () {
                          Navigator.of(context).pop();
                        },
                        child: const Text("Cerrar"),
                      )
                    ],
                  )
                : eventos.isEmpty
                    ? Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Text("Sin eventos"),
                          const SizedBox(height: 20),
                          ElevatedButton(
                            onPressed: () {
                              Navigator.of(context).pop();
                            },
                            child: const Text("Cerrar"),
                          )
                        ],
                      )
                    : Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            widget.titulo,
                            style: const TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: Colors.deepPurple,
                            ),
                          ),
                          const SizedBox(height: 10),
                          const Divider(color: Colors.deepPurple, thickness: 2),
                          SizedBox(
                            height: 300,
                            child: ListView.builder(
                              shrinkWrap: true,
                              itemCount: eventos.length,
                              itemBuilder: (context, index) {
                                final evento = eventos[index];
                                return ListTile(
                                  title: Text(evento.nombre),
                                  trailing: IconButton(
                                    icon: const Icon(Icons.info_rounded),
                                    onPressed: () => context.pushNamed(
                                        EventDetailScreen.name,
                                        extra: evento),
                                  ),
                                );
                              },
                            ),
                          ),
                          const SizedBox(height: 10),
                          ElevatedButton(
                            onPressed: () {
                              Navigator.of(context).pop();
                            },
                            style: ElevatedButton.styleFrom(
                              foregroundColor: Colors.white,
                              backgroundColor: Colors.deepPurple,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                            child: const Text("Cerrar"),
                          ),
                        ],
                      ),
      ),
    );
  }
}

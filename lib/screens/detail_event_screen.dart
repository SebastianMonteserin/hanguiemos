import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gap/gap.dart';
import 'package:go_router/go_router.dart';
import 'package:hanguiemos_frontend/core/providers/events_provider.dart';
import 'package:hanguiemos_frontend/core/providers/logged_user_provider.dart';
import 'package:hanguiemos_frontend/entities/event.dart';
import 'package:hanguiemos_frontend/entities/logged_user.dart';
import 'package:hanguiemos_frontend/entities/user.dart';
import 'package:hanguiemos_frontend/screens/edit_event_screen.dart';
import 'package:hanguiemos_frontend/screens/events_screen.dart';
import 'package:hanguiemos_frontend/services/event_service.dart';
import 'package:hanguiemos_frontend/services/logged_user_service.dart';
import 'package:hanguiemos_frontend/services/user_service.dart';

class EventDetailScreen extends ConsumerStatefulWidget {
  static const String name = 'event_detail_screen';
  final Evento eventoInicial;

  const EventDetailScreen({super.key, required this.eventoInicial});

  @override
  EventDetailScreenState createState() => EventDetailScreenState();
}

class EventDetailScreenState extends ConsumerState<EventDetailScreen> {
  late Usuario usuarioCreador;
  late String userToken;
  late LoggedUser loggedUser;
  late Evento evento;
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    evento = widget.eventoInicial;
    userToken = ref.read(userTokenProvider);
    loggedUser = ref.read(loggedUserProvider);
    _initializeUser();
  }

  Future<void> _initializeUser() async {
    usuarioCreador = await _fetchUser(evento.idUsuarioCreador);
    setState(() {
      isLoading = false;
    });
  }

  Future<Usuario> _fetchUser(String id) async {
    final userService = UserService();
    return userService.fetchUserByID(id, userToken);
  }

  Future<void> _refreshEvent() async {
    final eventService = EventService();
    final updatedEvent = await eventService.obtenerEvento(evento.id, userToken);
    ref.read(eventProvider.notifier).updateEvent(updatedEvent);
    setState(() {
      evento = updatedEvent;
    });
  }

  @override
  Widget build(BuildContext context) {
    try {
      evento = ref.watch(eventProvider.notifier).getEventById(evento.id);
    } catch (exception) {}

    return SafeArea(
      child: Scaffold(
        appBar: PreferredSize(
          preferredSize: const Size.fromHeight(70.0),
          child: AppBar(
            backgroundColor: Colors.deepPurple,
            iconTheme: const IconThemeData(color: Colors.white),
            title: Row(
              children: [
                Flexible(
                  child: Text(
                    evento.nombre,
                    style: const TextStyle(fontSize: 26, color: Colors.white),
                    maxLines: 2,
                  ),
                ),
              ],
            ),
          ),
        ),
        body: isLoading
            ? const Center(child: CircularProgressIndicator())
            : ScreenBody(
                evento: evento,
                usuarioCreador: usuarioCreador,
                refreshEvent: _refreshEvent,
                loggedUser: loggedUser,
              ),
      ),
    );
  }
}

class ScreenBody extends StatelessWidget {
  ScreenBody(
      {super.key,
      required this.evento,
      required this.usuarioCreador,
      required this.refreshEvent,
      required this.loggedUser});

  final EventService eventService = EventService();
  final LoggedUser loggedUser;
  final Evento evento;
  final Usuario usuarioCreador;
  final Future<void> Function() refreshEvent;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          OrganizadorParticipantesBotones(
            usuario: usuarioCreador,
            evento: evento,
          ),
          DatosEvento(evento: evento),
          const Gap(15),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: BotonSuscripcionEvento(
                loggedUser: loggedUser,
                usuarioCreador: usuarioCreador,
                eventService: eventService,
                evento: evento,
                refreshEvent: refreshEvent),
          )
        ],
      ),
    );
  }
}

class DatosEvento extends StatelessWidget {
  const DatosEvento({
    super.key,
    required this.evento,
  });

  final Evento evento;

  Widget selectImage() {
    if (evento.imagenUrl.isNotEmpty) {
      return Stack(
        children: [
          Image.network(
            evento.imagenUrl,
            width: double.infinity,
            height: 250,
            fit: BoxFit.contain,
            loadingBuilder: (BuildContext context, Widget child,
                ImageChunkEvent? loadingProgress) {
              if (loadingProgress == null) {
                return child;
              } else {
                return const SizedBox(
                  width: double.infinity,
                  height: 250,
                  child: Center(
                    child: CircularProgressIndicator(),
                  ),
                );
              }
            },
            errorBuilder: (BuildContext context, Object exception,
                StackTrace? stackTrace) {
              return Image.asset(
                'assets/evento-placeholder.png',
                width: double.infinity,
                height: 250,
                fit: BoxFit.cover,
              );
            },
          ),
        ],
      );
    } else {
      return Image.asset(
        'assets/evento-placeholder.png',
        width: double.infinity,
        height: 250,
        fit: BoxFit.cover,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Center(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: selectImage(),
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Gap(16),
              Center(
                child: Text(
                  evento.descripcion,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                      fontSize: 18, color: Color.fromARGB(255, 36, 35, 35)),
                ),
              ),
              const Gap(16),
              Container(
                decoration: BoxDecoration(
                  color: Colors.deepPurple[50],
                  borderRadius: BorderRadius.circular(12.0),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.grey.withOpacity(0.2),
                      spreadRadius: 2,
                      blurRadius: 5,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Ciudad: ${evento.ciudad}",
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const Gap(10),
                    Text(
                      evento.direccion!.isNotEmpty
                          ? "Dirección: ${evento.direccion}"
                          : 'Evento Virtual',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const Gap(10),
                    Text(
                      "Fecha: ${evento.dia.day}/${evento.dia.month}/${evento.dia.year} -- ${evento.hora.format(context)}",
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const Gap(10),
                    Text(
                      'Duración: ${evento.duracion != null ? "${evento.duracion!.ceil()} hs" : "Sin duración especificada"}',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class BotonSuscripcionEvento extends ConsumerWidget {
  BotonSuscripcionEvento(
      {super.key,
      required this.eventService,
      required this.evento,
      required this.refreshEvent,
      required this.loggedUser,
      required this.usuarioCreador});

  final Usuario usuarioCreador;
  final EventService eventService;
  final LoggedUserService loggedUserService = LoggedUserService();
  final LoggedUser loggedUser;
  final Evento evento;
  final Future<void> Function() refreshEvent;

  void _showDeleteConfirmationDialog(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Confirmación'),
          content:
              const Text('¿Estás seguro de que quieres eliminar el evento?'),
          actions: [
            TextButton(
              child: const Text('Cancelar'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: const Text('Eliminar'),
              onPressed: () async {
                await eventService.eliminarEvento(evento.id, loggedUser.token);
                ref.read(loggedUserProvider.notifier).updateLoggedUser(
                    await loggedUserService.fetchUserByToken(loggedUser.token));
                GoRouter.of(context).pushNamed(EventsScreen.name);
              },
            ),
          ],
        );
      },
    );
  }

  Widget createButtons(context, WidgetRef ref) {
    if (usuarioCreador.id == loggedUser.id) {
      return Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          ElevatedButton(
            onPressed: () {
              GoRouter.of(context)
                  .pushNamed(EditEventScreen.name, extra: evento);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.deepPurple,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            child: const Text("Editar evento",
                style: TextStyle(color: Colors.white)),
          ),
          ElevatedButton(
            onPressed: () {
              _showDeleteConfirmationDialog(context, ref);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            child: const Text("Eliminar evento",
                style: TextStyle(color: Colors.white)),
          ),
        ],
      );
    } else if (!evento.suscriptoresIds.contains(loggedUser.id)) {
      return Padding(
        padding: const EdgeInsets.only(left: 230),
        child: ElevatedButton(
          onPressed: () async {
            await eventService.suscribirAEvento(evento.id, loggedUser.token);
            ref.read(loggedUserProvider.notifier).updateLoggedUser(
                await loggedUserService.fetchUserByToken(loggedUser.token));
            await refreshEvent();
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.deepPurpleAccent,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
          child: const Text(
            "Unirse",
            style: TextStyle(color: Colors.white, fontSize: 20),
          ),
        ),
      );
    } else {
      return Padding(
        padding: const EdgeInsets.only(left: 230),
        child: ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.deepPurple,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
          onPressed: () async {
            await eventService.desuscribirAEvento(evento.id, loggedUser.token);
            ref.read(loggedUserProvider.notifier).updateLoggedUser(
                await loggedUserService.fetchUserByToken(loggedUser.token));
            await refreshEvent();
          },
          child: const Text(
            "Salirse",
            style: TextStyle(color: Colors.white, fontSize: 20),
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return createButtons(context, ref);
  }
}

class OrganizadorParticipantesBotones extends StatelessWidget {
  const OrganizadorParticipantesBotones({
    super.key,
    required this.usuario,
    required this.evento,
  });

  final Evento evento;
  final Usuario usuario;

  void _showParticipantsDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return ListaParticipantes(evento: evento);
      },
    );
  }

  void _showOrganizerDialog(BuildContext context, Usuario usuario) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text("Información del Organizador"),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              CircleAvatar(
                backgroundImage: usuario.imagenUrl != ""
                    ? NetworkImage(usuario.imagenUrl)
                    : const AssetImage('assets/user-placeholder.png')
                        as ImageProvider,
                backgroundColor: Colors.grey[200],
                radius: 40,
              ),
              const SizedBox(height: 20),
              Text("Nombre de Usuario: ${usuario.nombreDeUsuario}"),
              const SizedBox(height: 10),
              Text("Mail: ${usuario.mail}"),
              const SizedBox(height: 10),
              Text("Teléfono: ${usuario.telefono}"),
            ],
          ),
          actions: <Widget>[
            TextButton(
              child: const Text("Cerrar"),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          TextButton.icon(
            onPressed: () {
              _showParticipantsDialog(context);
            },
            icon: const Icon(Icons.people, color: Colors.deepPurple),
            label: const Text(
              "Participantes",
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.deepPurple,
              ),
            ),
          ),
          TextButton.icon(
            onPressed: () {
              _showOrganizerDialog(context, usuario);
            },
            icon: const Icon(Icons.person, color: Colors.deepPurple),
            label: Text(
              "Organizador:\n${usuario.nombreDeUsuario}",
              textAlign: TextAlign.right,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.deepPurple,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class ListaParticipantes extends ConsumerStatefulWidget {
  const ListaParticipantes({
    super.key,
    required this.evento,
  });

  final Evento evento;

  @override
  _ListaParticipantesState createState() => _ListaParticipantesState();
}

class _ListaParticipantesState extends ConsumerState<ListaParticipantes> {
  late List<Usuario> usuarios;
  bool isLoading = true;
  String? errorMessage;

  @override
  void initState() {
    super.initState();
    _fetchUsers(widget.evento.suscriptoresIds);
  }

  Future<void> _fetchUsers(List<String> ids) async {
    try {
      final userService = UserService();
      final userToken = ref.read(userTokenProvider);
      usuarios = await userService.fetchUsersByIDList(ids, userToken);
    } catch (error) {
      errorMessage = "Error al cargar participantes";
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (errorMessage != null) {
      return AlertDialog(
        title: const Text("Error"),
        content: Text(errorMessage!),
        actions: [
          TextButton(
            child: const Text("Cerrar"),
            onPressed: () {
              Navigator.of(context).pop();
            },
          ),
        ],
      );
    }

    if (usuarios.isEmpty) {
      return AlertDialog(
        title: const Text("Participantes"),
        content: const Text("Sin participantes"),
        actions: [
          TextButton(
            child: const Text("Cerrar"),
            onPressed: () {
              Navigator.of(context).pop();
            },
          ),
        ],
      );
    }

    return AlertDialog(
      title: const Text("Participantes"),
      content: SizedBox(
        height: 300,
        width: double.maxFinite,
        child: ListView.builder(
          shrinkWrap: true,
          itemCount: usuarios.length,
          itemBuilder: (context, index) {
            final usuario = usuarios[index];
            return ListTile(title: Text(usuario.nombreDeUsuario));
          },
        ),
      ),
      actions: [
        TextButton(
          child: const Text("Cerrar"),
          onPressed: () {
            Navigator.of(context).pop();
          },
        ),
      ],
    );
  }
}

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gap/gap.dart';
import 'package:go_router/go_router.dart';
import 'package:hanguiemos_frontend/core/providers/events_provider.dart';
import 'package:hanguiemos_frontend/core/providers/logged_user_provider.dart';
import 'package:hanguiemos_frontend/entities/categoria.dart';
import 'package:hanguiemos_frontend/entities/event.dart';
import 'package:hanguiemos_frontend/entities/logged_user.dart';
import 'package:hanguiemos_frontend/screens/create_event_screen.dart';
import 'package:hanguiemos_frontend/screens/detail_event_screen.dart';
import 'package:hanguiemos_frontend/screens/user_profile_screen.dart';
import 'package:hanguiemos_frontend/services/event_service.dart';

class EventsScreen extends ConsumerStatefulWidget {
  static const String name = 'events_screen';

  const EventsScreen({super.key});

  @override
  EventsScreenState createState() => EventsScreenState();
}

class EventsScreenState extends ConsumerState<EventsScreen> {
  bool isLoading = true;
  String? errorMessage;
  Categoria? selectedCategory;
  late LoggedUser loggedUser;

  @override
  void initState() {
    super.initState();
    loggedUser = ref.read(loggedUserProvider);
    _fetchEvents();
  }

  Future<void> _fetchEvents({Categoria? category}) async {
    final userToken = ref.read(userTokenProvider);
    final eventNotifier = ref.read(eventProvider.notifier);

    try {
      List<Evento> fetchedEvents;
      if (category != null) {
        fetchedEvents = await EventService().fetchEvents(
          token: userToken,
          showByCategories: true,
          categoria: category,
        );
      } else {
        fetchedEvents = await EventService().fetchEvents(token: userToken);
      }

      eventNotifier.setEvents(fetchedEvents);

      setState(() {
        isLoading = false;
        errorMessage = null;
      });
    } catch (error) {
      setState(() {
        errorMessage = "Error al cargar eventos";
        isLoading = false;
      });
    }
  }

  Widget crearItemLista(List<Evento> filteredEvents, int index) {
    return SizedBox(
      height: 250,
      child: Card(
        margin: const EdgeInsets.symmetric(vertical: 6.0, horizontal: 25.0),
        child: InkWell(
          onTap: () => context.pushNamed(
            EventDetailScreen.name,
            extra: filteredEvents[index],
          ),
          child: Stack(
            children: [
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: SizedBox(
                          width: double.infinity,
                          height: 150,
                          child: filteredEvents[index].imagenUrl.isNotEmpty
                              ? Image.network(
                                  filteredEvents[index].imagenUrl,
                                  fit: kIsWeb ? BoxFit.contain : BoxFit.cover,
                                  loadingBuilder: (BuildContext context,
                                      Widget child,
                                      ImageChunkEvent? loadingProgress) {
                                    if (loadingProgress == null) {
                                      return child;
                                    } else {
                                      return const Center(
                                        child: CircularProgressIndicator(),
                                      );
                                    }
                                  },
                                )
                              : Image.asset(
                                  'assets/evento-placeholder.png',
                                  fit: BoxFit.contain,
                                )),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            filteredEvents[index].nombre,
                            style: const TextStyle(
                              fontSize: 18.0,
                              fontWeight: FontWeight.bold,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const Gap(8),
                          Text(
                            filteredEvents[index].descripcion,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final events = ref.watch(eventProvider).values.toList();
    final filteredEvents = selectedCategory == null
        ? events
        : events.where((event) => event.categoria == selectedCategory).toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Hanguiemos',
          style: TextStyle(color: Colors.white),
        ),
        backgroundColor: Colors.deepPurple,
        automaticallyImplyLeading: false,
        actions: [
          IconButton(
            icon: const Icon(
              Icons.account_circle,
              size: 35,
              color: Colors.white,
            ),
            onPressed: () async {
              context.pushNamed(UserProfileScreen.name);
            },
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: Colors.deepPurple,
        child: const Icon(Icons.add, color: Colors.white),
        onPressed: () => context.pushNamed(CreateEventScreen.name),
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : errorMessage != null
              ? Center(child: Text(errorMessage!))
              : filteredEvents.isEmpty
                  ? const Center(
                      child: Text(
                      "No hay eventos disponibles",
                      style: TextStyle(color: Colors.deepPurple, fontSize: 20),
                    ))
                  : Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: Text(
                            selectedCategory != null
                                ? 'Categoria: ${selectedCategory.toString().split('.').last}'
                                : 'Eventos según tus intereses',
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: Colors.deepPurple,
                            ),
                          ),
                        ),
                        Expanded(
                          child: ListView.builder(
                            itemCount: filteredEvents.length,
                            itemBuilder: (context, index) {
                              return crearItemLista(filteredEvents, index);
                            },
                          ),
                        ),
                      ],
                    ),
      bottomNavigationBar: BottomAppBar(
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              ElevatedButton(
                style: const ButtonStyle(
                    backgroundColor:
                        MaterialStatePropertyAll(Colors.deepPurple)),
                onPressed: () {
                  _showCategorySelectionModal(context);
                },
                child: const Text('Filtrar',
                    style: TextStyle(color: Colors.white)),
              ),
              const Gap(40),
              ElevatedButton(
                style: const ButtonStyle(
                    backgroundColor:
                        MaterialStatePropertyAll(Colors.deepPurple)),
                onPressed: () {
                  setState(() {
                    selectedCategory = null;
                    isLoading = true;
                  });
                  _fetchEvents(category: null);
                },
                child: const Text('Restaurar por intereses',
                    style: TextStyle(color: Colors.white)),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _showCategorySelectionModal(BuildContext context) async {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(25.0)),
      ),
      backgroundColor: Colors.white,
      isScrollControlled: true,
      builder: (BuildContext context) {
        return SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'Seleccionar Categoría',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.deepPurple,
                  ),
                ),
                const Divider(color: Colors.deepPurple, thickness: 2),
                ...Categoria.values.map((category) {
                  return ListTile(
                    title: Text(category.toString().split('.').last),
                    onTap: () {
                      _fetchEvents(category: category);
                      Navigator.pop(context, category);
                      setState(() {
                        selectedCategory = category;
                        isLoading = true;
                      });
                    },
                  );
                }),
              ],
            ),
          ),
        );
      },
    );
  }
}

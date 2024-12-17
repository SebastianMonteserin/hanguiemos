import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hanguiemos_frontend/entities/event.dart';

class EventNotifier extends StateNotifier<Map<String, Evento>> {
  EventNotifier() : super({});

  void addEvent(Evento event) {
    state = {...state, event.id: event};
  }

  void addEvents(List<Evento> events) {
    final newEvents = {for (var event in events) event.id: event};
    state = {...state, ...newEvents};
  }
  
  void setEvents(List<Evento> events) {
    state = {for (var event in events) event.id: event};
  }

  void updateEvent(Evento event) {
    if (state.containsKey(event.id)) {
      state = {...state, event.id: event};
    }
  }

  void removeEvent(String id) {
    state = {...state}..remove(id);
  }

  Evento getEventById(String id) {
    return state[id] as Evento;
  }
}

final eventProvider =
    StateNotifierProvider<EventNotifier, Map<String, Evento>>((ref) {
  return EventNotifier();
});

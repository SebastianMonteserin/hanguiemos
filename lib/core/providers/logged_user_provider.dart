import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hanguiemos_frontend/entities/logged_user.dart';

class LoggedUserNotifier extends StateNotifier<LoggedUser> {
  LoggedUserNotifier()
      : super(
          LoggedUser(
            id: "",
            mail: "",
            token: "",
            intereses: [""],
            nombreDeUsuario: "",
            imagenUrl: "",
            eventosCreados: [""],
            eventosSuscriptos: [""],
            telefono: "",
          ),
        );

  void updateLoggedUser(LoggedUser user) {
    state = user;
  }
}

final loggedUserProvider =
    StateNotifierProvider<LoggedUserNotifier, LoggedUser>(
  (ref) => LoggedUserNotifier(),
);

final userTokenProvider = Provider<String>((ref) {
  final loggedUser = ref.watch(loggedUserProvider);
  return loggedUser.token;
});

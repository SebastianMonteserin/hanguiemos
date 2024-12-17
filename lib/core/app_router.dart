import 'package:go_router/go_router.dart';
import 'package:hanguiemos_frontend/entities/event.dart';
import 'package:hanguiemos_frontend/screens/create_event_screen.dart';
import 'package:hanguiemos_frontend/screens/edit_event_screen.dart';
import 'package:hanguiemos_frontend/screens/detail_event_screen.dart';
import 'package:hanguiemos_frontend/screens/edit_user_screen.dart';
import 'package:hanguiemos_frontend/screens/events_screen.dart';
import 'package:hanguiemos_frontend/screens/home_screen.dart';
import 'package:hanguiemos_frontend/screens/login_screen.dart';
import 'package:hanguiemos_frontend/screens/sign_up_screen.dart';
import 'package:hanguiemos_frontend/screens/user_profile_screen.dart';

final appRouter = GoRouter(
  routes: [
    GoRoute(
        name: HomeScreen.name,
        path: '/',
        builder: (context, state) => const HomeScreen()),
    GoRoute(
        name: LoginScreen.name,
        path: '/login',
        builder: (context, state) => const LoginScreen()),
    GoRoute(
        name: SignUpScreen.name,
        path: '/sign-up',
        builder: (context, state) => const SignUpScreen()),
    GoRoute(
        name: EventsScreen.name,
        path: '/events',
        builder: (context, state) => const EventsScreen()),
    GoRoute(
        name: CreateEventScreen.name,
        path: '/create-event',
        builder: (context, state) => const CreateEventScreen()),
    GoRoute(
        name: EventDetailScreen.name,
        path: '/event-detail',
        builder: (context, state) => EventDetailScreen(
              eventoInicial: state.extra as Evento,
            )),
    GoRoute(
        name: EditEventScreen.name,
        path: '/edit-event',
        builder: (context, state) => EditEventScreen(
              event: state.extra as Evento,
            )),
    GoRoute(
        name: EditUserScreen.name,
        path: '/edit-user',
        builder: (context, state) => const EditUserScreen()),
    GoRoute(
        name: UserProfileScreen.name,
        path: '/user-profile',
        builder: (context, state) => const UserProfileScreen()),
  ],
);

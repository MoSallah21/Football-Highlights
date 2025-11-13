import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:firebase_core/firebase_core.dart';
import 'core/app_theme.dart';
import 'data/repositories/firestore_repository.dart';
import 'data/repositories/youtube_repository.dart';
import 'logic/cubits/banner/banner_cubit.dart';
import 'logic/cubits/highlights/highlights_cubit.dart';
import 'presentation/screens/home_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Firebase for banners
  await Firebase.initializeApp();

  // Force landscape orientation for TV
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.landscapeLeft,
    DeviceOrientation.landscapeRight,
  ]);
  // Set fullscreen mode
  await SystemChrome.setEnabledSystemUIMode(
    SystemUiMode.immersiveSticky,
    overlays: [],
  );
  runApp(const FootballHighlightsApp());
}

class FootballHighlightsApp extends StatelessWidget {
  const FootballHighlightsApp({super.key});

  @override
  Widget build(BuildContext context) {
    // Initialize repositories
    final youtubeRepository = YouTubeRepository();
    final firestoreRepository = FirestoreRepository();

    return MultiRepositoryProvider(
      providers: [
        RepositoryProvider.value(value: youtubeRepository),
        RepositoryProvider.value(value: firestoreRepository),
      ],
      child: MultiBlocProvider(
        providers: [
          // Highlights cubit with YouTube repository
          BlocProvider(
            create: (context) => HighlightsCubit(youtubeRepository),
          ),
          // Banner cubit with Firestore repository
          BlocProvider(
            create: (context) => BannerCubit(firestoreRepository)..loadBanners(),
          ),
        ],
        child: MaterialApp(
          title: 'Football Highlights',
          debugShowCheckedModeBanner: false,
          theme: AppTheme.darkTheme,
          home:  HighlightsScreen(),
        ),
      ),
    );
  }
}
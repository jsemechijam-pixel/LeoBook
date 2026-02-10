
import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';
import '../../logic/cubit/home_cubit.dart';
import '../../data/repositories/data_repository.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'presentation/screens/home_screen.dart';
import 'data/repositories/news_repository.dart';

void main() {
  runApp(const LeoBookApp());
}

class LeoBookApp extends StatelessWidget {
  const LeoBookApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiRepositoryProvider(
      providers: [
        RepositoryProvider(create: (context) => DataRepository()),
        RepositoryProvider(create: (context) => NewsRepository()),
      ],
      child: BlocProvider(
        create: (context) => HomeCubit(
          context.read<DataRepository>(),
          context.read<NewsRepository>(),
        )..loadDashboard(),
        child: MaterialApp(
          title: 'LeoBook',
          theme: AppTheme.darkTheme,
          home: const HomeScreen(),
          debugShowCheckedModeBanner: false,
        ),
      ),
    );
  }
}

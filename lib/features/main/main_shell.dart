import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../core/widgets/app_bottom_nav.dart';
import '../chat/conversations_screen.dart';
import '../home/home_screen.dart';
import '../orders/orders_screen.dart';
import '../profile/profile_screen.dart';
import 'nav_cubit.dart';

class MainShell extends StatelessWidget {
  const MainShell({super.key});

  static const _pages = <Widget>[
    HomeScreen(),
    OrdersScreen(),
    ConversationsScreen(),
    ProfileScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<NavCubit, int>(
      builder: (context, index) {
        return Scaffold(
          extendBody: true,
          body: IndexedStack(index: index, children: _pages),
          bottomNavigationBar: AppBottomNav(
            index: index,
            onChanged: context.read<NavCubit>().select,
          ),
        );
      },
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../core/theme/app_colors.dart';
import 'provider_home_screen.dart';
import 'provider_messages_screen.dart';
import 'provider_orders_screen.dart';
import 'provider_profile_screen.dart';
import 'provider_workspace_cubit.dart';

class ProviderShell extends StatefulWidget {
  const ProviderShell({super.key});

  @override
  State<ProviderShell> createState() => _ProviderShellState();
}

class _ProviderShellState extends State<ProviderShell> {
  int _index = 0;

  static const _pages = <Widget>[
    ProviderHomeScreen(),
    ProviderOrdersScreen(),
    ProviderMessagesScreen(),
    ProviderProfileScreen(),
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) context.read<ProviderWorkspaceCubit>().start();
    });
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<ProviderWorkspaceCubit, ProviderWorkspaceState>(
      listenWhen: (previous, current) =>
          previous.message != current.message && current.message != null,
      listener: (context, state) {
        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(SnackBar(content: Text(state.message!)));
        context.read<ProviderWorkspaceCubit>().clearMessage();
      },
      child: Scaffold(
        extendBody: true,
        body: IndexedStack(index: _index, children: _pages),
        bottomNavigationBar: _ProviderBottomNav(
          index: _index,
          onChanged: (value) => setState(() => _index = value),
        ),
      ),
    );
  }
}

class _ProviderBottomNav extends StatelessWidget {
  const _ProviderBottomNav({required this.index, required this.onChanged});

  final int index;
  final ValueChanged<int> onChanged;

  static const _items = <({String label, IconData icon})>[
    (label: 'الرئيسية', icon: Icons.dashboard_rounded),
    (label: 'الطلبات', icon: Icons.assignment_outlined),
    (label: 'الرسائل', icon: Icons.chat_bubble_outline_rounded),
    (label: 'حسابي', icon: Icons.engineering_outlined),
  ];

  @override
  Widget build(BuildContext context) {
    final workspace = context.watch<ProviderWorkspaceCubit>().state;
    return SafeArea(
      child: Container(
        height: 72,
        padding: const EdgeInsets.fromLTRB(8, 8, 8, 7),
        decoration: BoxDecoration(
          color: Colors.white,
          border: const Border(top: BorderSide(color: AppColors.border)),
          boxShadow: <BoxShadow>[
            BoxShadow(
              color: AppColors.ink.withOpacity(0.06),
              blurRadius: 18,
              offset: const Offset(0, -4),
            ),
          ],
        ),
        child: Row(
          children: List<Widget>.generate(_items.length, (itemIndex) {
            final item = _items[itemIndex];
            final selected = itemIndex == index;
            return Expanded(
              child: InkWell(
                onTap: () => onChanged(itemIndex),
                borderRadius: BorderRadius.circular(14),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 220),
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  decoration: const BoxDecoration(),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: <Widget>[
                      Stack(
                        clipBehavior: Clip.none,
                        children: <Widget>[
                          Icon(
                            item.icon,
                            size: 21,
                            color: selected
                                ? AppColors.primary
                                : AppColors.textMuted,
                          ),
                          if ((itemIndex == 1 &&
                                  workspace.incoming.isNotEmpty) ||
                              (itemIndex == 2 && workspace.unreadMessages > 0))
                            PositionedDirectional(
                              end: -5,
                              top: -5,
                              child: Container(
                                width: 9,
                                height: 9,
                                decoration: BoxDecoration(
                                  color: AppColors.primary,
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: Colors.white,
                                    width: 1.2,
                                  ),
                                ),
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 3),
                      Text(
                        item.label,
                        overflow: TextOverflow.fade,
                        softWrap: false,
                        style: TextStyle(
                          color: selected
                              ? AppColors.primaryDark
                              : AppColors.textMuted,
                          fontSize: 10,
                          fontWeight: selected
                              ? FontWeight.w700
                              : FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          }),
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

class AppBottomNav extends StatelessWidget {
  const AppBottomNav({super.key, required this.index, required this.onChanged});

  final int index;
  final ValueChanged<int> onChanged;

  static const _items = <({String label, IconData icon})>[
    (label: 'الرئيسية', icon: Icons.home_rounded),
    (label: 'طلباتي', icon: Icons.assignment_outlined),
    (label: 'الرسائل', icon: Icons.chat_bubble_outline_rounded),
    (label: 'حسابي', icon: Icons.person_outline_rounded),
  ];

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Container(
        height: 72,
        padding: const EdgeInsets.fromLTRB(8, 8, 8, 7),
        decoration: BoxDecoration(
          color: Colors.white,
          border: const Border(top: BorderSide(color: AppColors.border)),
          boxShadow: [
            BoxShadow(
              color: AppColors.ink.withOpacity(0.06),
              blurRadius: 18,
              offset: const Offset(0, -4),
            ),
          ],
        ),
        child: Row(
          children: List.generate(_items.length, (itemIndex) {
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
                    children: [
                      Icon(
                        item.icon,
                        size: 23,
                        color: selected
                            ? AppColors.primary
                            : AppColors.textMuted,
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

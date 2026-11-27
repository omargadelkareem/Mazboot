import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/app_colors.dart';
import '../../models/provider_conversation.dart';
import '../../models/service_order.dart';
import '../home/home_cubit.dart';
import 'provider_order_card.dart';
import 'provider_workspace_cubit.dart';

class ProviderMessagesScreen extends StatelessWidget {
  const ProviderMessagesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final state = context.watch<ProviderWorkspaceCubit>().state;
    return SafeArea(
      bottom: false,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Padding(
            padding: const EdgeInsets.fromLTRB(18, 18, 18, 13),
            child: Row(
              children: <Widget>[
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      'رسائل العملاء',
                      style: Theme.of(context).textTheme.headlineSmall,
                    ),
                    Text(
                      state.unreadMessages == 0
                          ? 'كل الرسائل مقروءة'
                          : '${state.unreadMessages} رسالة غير مقروءة',
                      style: const TextStyle(
                        color: AppColors.textMuted,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
                const Spacer(),
                Container(
                  width: 45,
                  height: 45,
                  decoration: const BoxDecoration(
                    color: AppColors.powderBlue,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.forum_outlined,
                    color: AppColors.navy,
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: state.loading
                ? const Center(child: CircularProgressIndicator())
                : state.conversations.isEmpty
                ? const _EmptyMessages()
                : ListView.separated(
                    padding: const EdgeInsets.fromLTRB(15, 4, 15, 116),
                    itemCount: state.conversations.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 9),
                    itemBuilder: (context, index) {
                      final conversation = state.conversations[index];
                      return _ConversationTile(
                        conversation: conversation,
                        order: state.orderById(conversation.orderId),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}

class _ConversationTile extends StatelessWidget {
  const _ConversationTile({required this.conversation, required this.order});

  final ProviderConversation conversation;
  final ServiceOrder? order;

  @override
  Widget build(BuildContext context) {
    final category = context.watch<HomeCubit>().state.categoryById(
      order?.categoryId ?? '',
    );
    final unread = conversation.unreadCount > 0;
    final status = order?.status;
    return InkWell(
      onTap: () => context.push(
        '/provider/chat/${conversation.orderId}/${conversation.customerId}',
      ),
      borderRadius: BorderRadius.circular(20),
      child: Ink(
        padding: const EdgeInsets.all(13),
        decoration: BoxDecoration(
          color: unread ? AppColors.powderBlue : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: unread ? AppColors.navy.withOpacity(0.15) : AppColors.border,
          ),
        ),
        child: Row(
          children: <Widget>[
            Stack(
              clipBehavior: Clip.none,
              children: <Widget>[
                CircleAvatar(
                  radius: 26,
                  backgroundColor: Colors.white,
                  child: Icon(
                    category?.icon ?? Icons.person_outline_rounded,
                    color: AppColors.navy,
                  ),
                ),
                if (unread)
                  PositionedDirectional(
                    start: -2,
                    top: -2,
                    child: Container(
                      constraints: const BoxConstraints(minWidth: 19),
                      height: 19,
                      padding: const EdgeInsets.symmetric(horizontal: 5),
                      alignment: Alignment.center,
                      decoration: const BoxDecoration(
                        color: AppColors.orange,
                        shape: BoxShape.circle,
                      ),
                      child: Text(
                        '${conversation.unreadCount}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 9,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(width: 11),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Row(
                    children: <Widget>[
                      Expanded(
                        child: Text(
                          'عميل الطلب #${_shortId(conversation.orderId)}',
                          textDirection: TextDirection.rtl,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontWeight: unread
                                ? FontWeight.w800
                                : FontWeight.w700,
                          ),
                        ),
                      ),
                      Text(
                        conversation.timeLabel,
                        style: const TextStyle(
                          color: AppColors.textMuted,
                          fontSize: 9,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 3),
                  Text(
                    conversation.lastMessage.isEmpty
                        ? 'ابدأ المحادثة مع العميل'
                        : conversation.lastMessage,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: unread ? AppColors.text : AppColors.textMuted,
                      fontSize: 11,
                      fontWeight: unread ? FontWeight.w600 : FontWeight.w400,
                    ),
                  ),
                  if (status != null) ...<Widget>[
                    const SizedBox(height: 6),
                    Row(
                      children: <Widget>[
                        Container(
                          width: 7,
                          height: 7,
                          decoration: BoxDecoration(
                            color: providerOrderStatusColor(status),
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 5),
                        Text(
                          status.label,
                          style: const TextStyle(
                            color: AppColors.textMuted,
                            fontSize: 9,
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(width: 5),
            const Icon(
              Icons.arrow_back_ios_new_rounded,
              size: 14,
              color: AppColors.textMuted,
            ),
          ],
        ),
      ),
    );
  }

  static String _shortId(String value) {
    if (value.length <= 6) return value;
    return value.substring(value.length - 6).toUpperCase();
  }
}

class _EmptyMessages extends StatelessWidget {
  const _EmptyMessages();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Padding(
        padding: EdgeInsets.all(28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Icon(
              Icons.mark_chat_unread_outlined,
              size: 66,
              color: AppColors.textMuted,
            ),
            SizedBox(height: 14),
            Text(
              'مفيش محادثات لسه',
              style: TextStyle(fontWeight: FontWeight.w700),
            ),
            SizedBox(height: 4),
            Text(
              'كل طلب جديد بيكون له محادثة مستقلة مع العميل.',
              textAlign: TextAlign.center,
              style: TextStyle(color: AppColors.textMuted, fontSize: 11),
            ),
          ],
        ),
      ),
    );
  }
}

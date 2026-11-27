import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_picker/image_picker.dart';

import '../../core/services/image_service.dart';
import '../../core/theme/app_colors.dart';
import '../../core/utils/ui_utils.dart';
import '../../models/chat_message.dart';
import '../../repositories/provider_repository.dart';
import 'provider_chat_cubit.dart';
import 'provider_order_card.dart';
import 'provider_workspace_cubit.dart';

class ProviderChatScreen extends StatefulWidget {
  const ProviderChatScreen({
    super.key,
    required this.orderId,
    required this.customerId,
  });

  final String orderId;
  final String customerId;

  @override
  State<ProviderChatScreen> createState() => _ProviderChatScreenState();
}

class _ProviderChatScreenState extends State<ProviderChatScreen> {
  final _messageController = TextEditingController();
  final _scrollController = ScrollController();
  String? _pendingImage;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) context.read<ProviderChatCubit>().start();
    });
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    try {
      final image = await context.read<ImageService>().pickBase64(
            source: ImageSource.gallery,
          );
      if (mounted && image != null) setState(() => _pendingImage = image);
    } on ImageTooLargeException {
      if (mounted)
        UiUtils.showSnackBar(context, 'الصورة كبيرة، اختار صورة أصغر.');
    } catch (_) {
      if (mounted) UiUtils.showSnackBar(context, 'تعذر فتح الصورة.');
    }
  }

  Future<void> _send() async {
    final text = _messageController.text;
    final image = _pendingImage;
    final sent = await context.read<ProviderChatCubit>().send(
          text,
          imageBase64: image,
        );
    if (!mounted || !sent) return;
    _messageController.clear();
    setState(() => _pendingImage = null);
    _scrollToBottom();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scrollController.hasClients) return;
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOut,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final order = context.watch<ProviderWorkspaceCubit>().state.orderById(
          widget.orderId,
        );
    return BlocConsumer<ProviderChatCubit, ProviderChatState>(
      listenWhen: (previous, current) =>
          previous.messages.length != current.messages.length ||
          previous.message != current.message,
      listener: (context, state) {
        if (state.message != null)
          UiUtils.showSnackBar(context, state.message!);
        if (state.messages.isNotEmpty) _scrollToBottom();
      },
      builder: (context, state) {
        return Scaffold(
          appBar: AppBar(
            titleSpacing: 0,
            title: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  'عميل الطلب #${_shortId(widget.orderId)}',
                  style: const TextStyle(fontSize: 15),
                ),
                if (order != null)
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: <Widget>[
                      Container(
                        width: 7,
                        height: 7,
                        decoration: BoxDecoration(
                          color: providerOrderStatusColor(order.status),
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 5),
                      Text(
                        order.status.name,
                        style: const TextStyle(
                          color: AppColors.textMuted,
                          fontSize: 9,
                        ),
                      ),
                    ],
                  ),
              ],
            ),
          ),
          body: SafeArea(
            top: false,
            child: Column(
              children: <Widget>[
                if (order != null)
                  Container(
                    width: double.infinity,
                    margin: const EdgeInsets.fromLTRB(14, 4, 14, 7),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 9,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.powderBlue,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Text(
                      order.problem,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontSize: 10),
                    ),
                  ),
                Expanded(
                  child: state.loading
                      ? const Center(child: CircularProgressIndicator())
                      : state.messages.isEmpty
                          ? const _EmptyChat()
                          : ListView.builder(
                              controller: _scrollController,
                              padding:
                                  const EdgeInsets.fromLTRB(14, 12, 14, 15),
                              itemCount: state.messages.length,
                              itemBuilder: (context, index) {
                                final message = state.messages[index];
                                final mine = message.senderId ==
                                    context
                                        .read<ProviderRepository>()
                                        .currentUid;
                                return _MessageBubble(
                                    message: message, mine: mine);
                              },
                            ),
                ),
                if (_pendingImage != null)
                  _PendingImage(
                    value: _pendingImage!,
                    onRemove: () => setState(() => _pendingImage = null),
                  ),
                Container(
                  padding: const EdgeInsets.fromLTRB(12, 8, 12, 10),
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    border: Border(top: BorderSide(color: AppColors.border)),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: <Widget>[
                      IconButton.filledTonal(
                        onPressed: state.sending ? null : _pickImage,
                        icon: const Icon(Icons.image_outlined),
                      ),
                      const SizedBox(width: 7),
                      Expanded(
                        child: TextField(
                          controller: _messageController,
                          minLines: 1,
                          maxLines: 4,
                          maxLength: 2000,
                          decoration: const InputDecoration(
                            hintText: 'اكتب رسالة للعميل…',
                            counterText: '',
                            isDense: true,
                          ),
                        ),
                      ),
                      const SizedBox(width: 7),
                      IconButton.filled(
                        onPressed: state.sending ? null : _send,
                        style: IconButton.styleFrom(
                          backgroundColor: AppColors.orange,
                          foregroundColor: Colors.white,
                        ),
                        icon: state.sending
                            ? const SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : const Icon(Icons.send_rounded),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  static String _shortId(String value) {
    if (value.length <= 6) return value;
    return value.substring(value.length - 6).toUpperCase();
  }
}

class _MessageBubble extends StatelessWidget {
  const _MessageBubble({required this.message, required this.mine});

  final ChatMessage message;
  final bool mine;

  @override
  Widget build(BuildContext context) {
    final image = context.read<ImageService>().decode(message.imageBase64);
    final date = DateTime.fromMillisecondsSinceEpoch(message.sentAt);
    final hour = date.hour % 12 == 0 ? 12 : date.hour % 12;
    final time =
        '$hour:${date.minute.toString().padLeft(2, '0')} ${date.hour >= 12 ? 'م' : 'ص'}';
    return Align(
      alignment: mine ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        constraints: BoxConstraints(
          maxWidth: MediaQuery.sizeOf(context).width * 0.78,
        ),
        margin: const EdgeInsets.only(bottom: 8),
        padding: EdgeInsets.all(image == null ? 11 : 6),
        decoration: BoxDecoration(
          color: mine ? AppColors.navy : Colors.white,
          borderRadius: BorderRadiusDirectional.only(
            topStart: const Radius.circular(17),
            topEnd: const Radius.circular(17),
            bottomStart: Radius.circular(mine ? 17 : 5),
            bottomEnd: Radius.circular(mine ? 5 : 17),
          ),
          border: mine ? null : Border.all(color: AppColors.border),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            if (image != null) ...<Widget>[
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.memory(image, fit: BoxFit.cover),
              ),
              if (message.text.isNotEmpty) const SizedBox(height: 7),
            ],
            if (message.text.isNotEmpty)
              Padding(
                padding: EdgeInsets.symmetric(
                  horizontal: image == null ? 0 : 5,
                ),
                child: Text(
                  message.text,
                  style: TextStyle(
                    color: mine ? Colors.white : AppColors.text,
                    fontSize: 12,
                    height: 1.5,
                  ),
                ),
              ),
            const SizedBox(height: 3),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: image == null ? 0 : 5),
              child: Text(
                time,
                textDirection: TextDirection.ltr,
                style: TextStyle(
                  color: mine ? Colors.white60 : AppColors.textMuted,
                  fontSize: 8,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PendingImage extends StatelessWidget {
  const _PendingImage({required this.value, required this.onRemove});

  final String value;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    final bytes = context.read<ImageService>().decode(value);
    if (bytes == null) return const SizedBox.shrink();
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(12, 7, 12, 0),
      color: Colors.white,
      child: Align(
        alignment: Alignment.centerRight,
        child: Stack(
          clipBehavior: Clip.none,
          children: <Widget>[
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Image.memory(
                bytes,
                width: 80,
                height: 80,
                fit: BoxFit.cover,
              ),
            ),
            PositionedDirectional(
              start: -8,
              top: -8,
              child: InkWell(
                onTap: onRemove,
                child: const CircleAvatar(
                  radius: 12,
                  backgroundColor: AppColors.danger,
                  child: Icon(
                    Icons.close_rounded,
                    color: Colors.white,
                    size: 15,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _EmptyChat extends StatelessWidget {
  const _EmptyChat();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Icon(Icons.waving_hand_outlined, size: 50, color: AppColors.orange),
          SizedBox(height: 10),
          Text('ابدأ المحادثة مع العميل'),
          Text(
            'اتفقوا على التفاصيل والسعر قبل بدء التنفيذ.',
            style: TextStyle(color: AppColors.textMuted, fontSize: 10),
          ),
        ],
      ),
    );
  }
}

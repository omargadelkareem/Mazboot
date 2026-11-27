import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_picker/image_picker.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/services/image_service.dart';
import '../../core/theme/app_colors.dart';
import '../../core/utils/ui_utils.dart';
import '../../core/widgets/remote_image.dart';
import '../../models/chat_message.dart';
import '../../repositories/customer_repository.dart';
import '../home/home_cubit.dart';
import 'chat_cubit.dart';

class ChatScreen extends StatelessWidget {
  const ChatScreen({
    super.key,
    required this.orderId,
    required this.technicianId,
  });

  final String orderId;
  final String technicianId;

  @override
  Widget build(BuildContext context) {
    return BlocProvider<ChatCubit>(
      create: (_) => ChatCubit(
        repository: context.read<CustomerRepository>(),
        orderId: orderId,
        technicianId: technicianId,
      ),
      child: _ChatView(orderId: orderId, technicianId: technicianId),
    );
  }
}

class _ChatView extends StatefulWidget {
  const _ChatView({required this.orderId, required this.technicianId});

  final String orderId;
  final String technicianId;

  @override
  State<_ChatView> createState() => _ChatViewState();
}

class _ChatViewState extends State<_ChatView> {
  final _messageController = TextEditingController();
  final _scrollController = ScrollController();

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _send({String? imageBase64}) async {
    final text = _messageController.text;
    final sent = await context.read<ChatCubit>().send(
      text,
      imageBase64: imageBase64,
    );
    if (!mounted || !sent) return;
    _messageController.clear();
    _scrollToBottom();
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      final image = await context.read<ImageService>().pickBase64(
        source: source,
      );
      if (!mounted || image == null) return;
      await _send(imageBase64: image);
    } on ImageTooLargeException {
      if (mounted)
        UiUtils.showSnackBar(
          context,
          'الصورة أكبر من الحد المسموح 900 كيلوبايت.',
        );
    } catch (_) {
      if (mounted) UiUtils.showSnackBar(context, 'تعذر إرفاق الصورة.');
    }
  }

  void _showImageOptions() {
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (sheetContext) => SafeArea(
        child: Wrap(
          children: <Widget>[
            ListTile(
              leading: const Icon(Icons.photo_library_outlined),
              title: const Text('اختيار صورة من الهاتف'),
              onTap: () {
                Navigator.pop(sheetContext);
                _pickImage(ImageSource.gallery);
              },
            ),
            ListTile(
              leading: const Icon(Icons.camera_alt_outlined),
              title: const Text('التقاط صورة'),
              onTap: () {
                Navigator.pop(sheetContext);
                _pickImage(ImageSource.camera);
              },
            ),
          ],
        ),
      ),
    );
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scrollController.hasClients) return;
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 260),
        curve: Curves.easeOut,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final technician = context.watch<HomeCubit>().state.technicianById(
      widget.technicianId,
    );
    if (technician == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('المحادثة')),
        body: const Center(child: Text('تعذر تحميل بيانات الفني')),
      );
    }
    return BlocConsumer<ChatCubit, ChatState>(
      listenWhen: (previous, current) =>
          previous.messages.length != current.messages.length ||
          previous.message != current.message,
      listener: (context, state) {
        if (state.message != null)
          UiUtils.showSnackBar(context, state.message!);
        _scrollToBottom();
      },
      builder: (context, state) {
        return Scaffold(
          appBar: AppBar(
            titleSpacing: 0,
            title: Row(
              children: <Widget>[
                RemoteImage(
                  url: technician.imageUrl,
                  base64Data: technician.imageBase64,
                  width: 40,
                  height: 40,
                  borderRadius: 13,
                ),
                const SizedBox(width: 9),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Row(
                        children: <Widget>[
                          Flexible(
                            child: Text(
                              technician.name,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                          if (technician.isVerified) ...<Widget>[
                            const SizedBox(width: 3),
                            const Icon(
                              Icons.verified_rounded,
                              color: AppColors.navy,
                              size: 15,
                            ),
                          ],
                        ],
                      ),
                      Text(
                        'طلب ${widget.orderId}',
                        style: const TextStyle(
                          color: AppColors.textMuted,
                          fontSize: 9,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            actions: <Widget>[
              IconButton(
                onPressed: () => _call(technician.phone),
                icon: const Icon(Icons.call_outlined),
              ),
            ],
          ),
          body: Column(
            children: <Widget>[
              Container(
                margin: const EdgeInsets.fromLTRB(16, 6, 16, 8),
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 9,
                ),
                decoration: BoxDecoration(
                  color: AppColors.powderGreen,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Row(
                  children: <Widget>[
                    Icon(
                      Icons.lock_outline_rounded,
                      color: AppColors.success,
                      size: 17,
                    ),
                    SizedBox(width: 7),
                    Expanded(
                      child: Text(
                        'المحادثة مرتبطة بالطلب ومحفوظة داخل Mazboot',
                        style: TextStyle(
                          fontSize: 9,
                          color: AppColors.textMuted,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: state.loading
                    ? const Center(child: CircularProgressIndicator())
                    : state.messages.isEmpty
                    ? const _EmptyChat()
                    : ListView.builder(
                        controller: _scrollController,
                        padding: const EdgeInsets.fromLTRB(16, 10, 16, 18),
                        itemCount: state.messages.length + 1,
                        itemBuilder: (_, index) {
                          if (index == 0) {
                            return const Padding(
                              padding: EdgeInsets.only(bottom: 15),
                              child: Center(
                                child: Text(
                                  'المحادثة الخاصة بالطلب',
                                  style: TextStyle(
                                    color: AppColors.textMuted,
                                    fontSize: 10,
                                  ),
                                ),
                              ),
                            );
                          }
                          final message = state.messages[index - 1];
                          return _MessageBubble(
                            message: message,
                            fromMe:
                                message.senderId ==
                                context.read<CustomerRepository>().currentUid,
                            isSystem: message.senderId == 'system',
                          );
                        },
                      ),
              ),
              SafeArea(
                top: false,
                child: Container(
                  padding: const EdgeInsets.fromLTRB(12, 9, 12, 11),
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    border: Border(top: BorderSide(color: AppColors.border)),
                  ),
                  child: Row(
                    children: <Widget>[
                      IconButton(
                        onPressed: state.sending ? null : _showImageOptions,
                        icon: const Icon(
                          Icons.add_circle_outline_rounded,
                          color: AppColors.navy,
                        ),
                      ),
                      Expanded(
                        child: TextField(
                          controller: _messageController,
                          minLines: 1,
                          maxLines: 4,
                          textInputAction: TextInputAction.send,
                          onSubmitted: state.sending ? null : (_) => _send(),
                          decoration: const InputDecoration(
                            hintText: 'اكتب رسالتك…',
                            contentPadding: EdgeInsets.symmetric(
                              horizontal: 15,
                              vertical: 11,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      InkWell(
                        onTap: state.sending ? null : _send,
                        customBorder: const CircleBorder(),
                        child: Container(
                          width: 46,
                          height: 46,
                          alignment: Alignment.center,
                          decoration: const BoxDecoration(
                            color: AppColors.orange,
                            shape: BoxShape.circle,
                          ),
                          child: state.sending
                              ? const SizedBox.square(
                                  dimension: 20,
                                  child: CircularProgressIndicator(
                                    color: Colors.white,
                                    strokeWidth: 2,
                                  ),
                                )
                              : const Icon(
                                  Icons.send_rounded,
                                  color: Colors.white,
                                  size: 21,
                                ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _call(String phone) async {
    if (phone.isEmpty) {
      UiUtils.showSnackBar(context, 'رقم الفني غير متاح حاليًا.');
      return;
    }
    final opened = await launchUrl(Uri(scheme: 'tel', path: phone));
    if (!opened && mounted) UiUtils.showSnackBar(context, 'تعذر فتح الاتصال.');
  }
}

class _MessageBubble extends StatelessWidget {
  const _MessageBubble({
    required this.message,
    required this.fromMe,
    required this.isSystem,
  });

  final ChatMessage message;
  final bool fromMe;
  final bool isSystem;

  @override
  Widget build(BuildContext context) {
    if (isSystem) {
      return Container(
        margin: const EdgeInsets.symmetric(vertical: 7, horizontal: 28),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: AppColors.powderBlue,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Text(
          message.text,
          textAlign: TextAlign.center,
          style: const TextStyle(color: AppColors.textMuted, fontSize: 10),
        ),
      );
    }
    final bytes = context.read<ImageService>().decode(message.imageBase64);
    return Align(
      alignment: fromMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        constraints: BoxConstraints(
          maxWidth: MediaQuery.sizeOf(context).width * 0.76,
        ),
        margin: const EdgeInsets.only(bottom: 9),
        padding: const EdgeInsets.all(7),
        decoration: BoxDecoration(
          color: fromMe ? AppColors.navy : Colors.white,
          borderRadius: BorderRadiusDirectional.only(
            topStart: const Radius.circular(17),
            topEnd: const Radius.circular(17),
            bottomStart: Radius.circular(fromMe ? 17 : 4),
            bottomEnd: Radius.circular(fromMe ? 4 : 17),
          ),
          border: fromMe ? null : Border.all(color: AppColors.border),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            if (bytes != null)
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.memory(
                  bytes,
                  width: 230,
                  height: 170,
                  fit: BoxFit.cover,
                ),
              ),
            if (message.text.isNotEmpty) ...<Widget>[
              if (bytes != null) const SizedBox(height: 6),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                child: Text(
                  message.text,
                  style: TextStyle(
                    color: fromMe ? Colors.white : AppColors.text,
                    fontSize: 12,
                    height: 1.55,
                  ),
                ),
              ),
            ],
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  Text(
                    _time(message.sentAt),
                    style: TextStyle(
                      color: fromMe ? Colors.white60 : AppColors.textMuted,
                      fontSize: 8,
                    ),
                  ),
                  if (fromMe) ...<Widget>[
                    const SizedBox(width: 4),
                    Icon(
                      message.seen
                          ? Icons.done_all_rounded
                          : Icons.done_rounded,
                      size: 13,
                      color: message.seen
                          ? AppColors.powderBlue
                          : Colors.white60,
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  static String _time(int milliseconds) {
    final date = DateTime.fromMillisecondsSinceEpoch(milliseconds);
    final hour = date.hour % 12 == 0 ? 12 : date.hour % 12;
    return '$hour:${date.minute.toString().padLeft(2, '0')} ${date.hour >= 12 ? 'م' : 'ص'}';
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
          Icon(Icons.forum_outlined, size: 58, color: AppColors.textMuted),
          SizedBox(height: 10),
          Text('ابدأ المحادثة مع الفني بخصوص الطلب'),
        ],
      ),
    );
  }
}

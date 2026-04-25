import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:easy_localization/easy_localization.dart';
import '../../data/datasources/room_remote_data_source.dart';
import '../../data/datasources/chat_remote_data_source.dart';
import '../cubits/watch_room_cubit.dart';
import '../cubits/watch_room_state.dart';

class WatchTogetherPage extends StatefulWidget {
  final int contentId;
  final String contentType;
  final int? season;
  final int? episode;
  final String? subOrDub;
  final String? contentTitle;

  const WatchTogetherPage({
    super.key,
    required this.contentId,
    required this.contentType,
    this.season,
    this.episode,
    this.subOrDub,
    this.contentTitle,
  });

  @override
  State<WatchTogetherPage> createState() => _WatchTogetherPageState();
}

class _WatchTogetherPageState extends State<WatchTogetherPage>
    with TickerProviderStateMixin {
  final _codeController = TextEditingController();
  late AnimationController _pulseCtrl;
  late Animation<double> _pulseAnim;

  @override
  void initState() {
    super.initState();
    _pulseCtrl = AnimationController(
      vsync: this, duration: const Duration(seconds: 2),
    )..repeat(reverse: true);
    _pulseAnim = Tween<double>(begin: 0.85, end: 1.0).animate(
      CurvedAnimation(parent: _pulseCtrl, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _codeController.dispose();
    _pulseCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => WatchRoomCubit(
        roomDataSource: RoomRemoteDataSource(),
        chatDataSource: ChatRemoteDataSource(),
      ),
      child: BlocConsumer<WatchRoomCubit, WatchRoomState>(
        listener: (ctx, state) {
          if (state is WatchRoomCreated) {
            ctx.pushReplacement('/room/${state.room.roomId}');
          } else if (state is WatchRoomActive) {
            ctx.pushReplacement('/room/${state.room.roomId}');
          } else if (state is WatchRoomError) {
            ScaffoldMessenger.of(ctx).showSnackBar(SnackBar(
              content: Text(state.message),
              backgroundColor: const Color(0xFFE50914),
            ));
          }
        },
        builder: (ctx, state) {
          final isDark = Theme.of(ctx).brightness == Brightness.dark;
          final textColor = Theme.of(ctx).textTheme.bodyLarge?.color ?? Colors.white;
          return Scaffold(
            appBar: AppBar(title: Text('watch_together'.tr())),
            body: state is WatchRoomLoading
                ? Center(
                    child: Column(mainAxisSize: MainAxisSize.min, children: [
                      const CircularProgressIndicator(color: Color(0xFFE50914)),
                      const SizedBox(height: 20),
                      Text(state.message, style: TextStyle(color: textColor)),
                    ]),
                  )
                : _body(ctx, isDark, textColor),
          );
        },
      ),
    );
  }

  Widget _body(BuildContext ctx, bool isDark, Color textColor) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        // Pulsing icon
        AnimatedBuilder(
          animation: _pulseAnim,
          builder: (_, __) => Transform.scale(
            scale: _pulseAnim.value,
            child: Container(
              width: 80, height: 80,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: const LinearGradient(
                  colors: [Color(0xFFE50914), Color(0xFFFF6B35)],
                ),
                boxShadow: [BoxShadow(
                  color: const Color(0xFFE50914).withOpacity(0.4),
                  blurRadius: 20, spreadRadius: 2,
                )],
              ),
              child: const Icon(Icons.people_alt_rounded, color: Colors.white, size: 40),
            ),
          ),
        ),
        const SizedBox(height: 20),
        Text('watch_together'.tr(), textAlign: TextAlign.center,
          style: TextStyle(color: textColor, fontSize: 26, fontWeight: FontWeight.w900)),
        const SizedBox(height: 6),
        Text('watch_together_desc'.tr(), textAlign: TextAlign.center,
          style: TextStyle(color: textColor.withOpacity(0.6), fontSize: 14)),
        const SizedBox(height: 36),

        // --- Create Room Card ---
        _glass(isDark, child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          _cardHeader(Icons.add_circle_outline, const Color(0xFFE50914),
            'create_room'.tr(), 'create_room_desc'.tr(), textColor),
          const SizedBox(height: 20),
          SizedBox(height: 52, child: ElevatedButton(
            onPressed: () => ctx.read<WatchRoomCubit>().createRoom(
              contentId: widget.contentId, contentType: widget.contentType,
              season: widget.season, episode: widget.episode, subOrDub: widget.subOrDub,
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFE50914), foregroundColor: Colors.white,
              elevation: 8, shadowColor: const Color(0xFFE50914).withOpacity(0.5),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            ),
            child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
              const Icon(Icons.play_circle_filled, size: 22),
              const SizedBox(width: 10),
              Text('create_and_share'.tr(),
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            ]),
          )),
        ])),
        const SizedBox(height: 20),

        // Divider
        Row(children: [
          Expanded(child: Divider(color: textColor.withOpacity(0.15))),
          Padding(padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Text('or'.tr(), style: TextStyle(
              color: textColor.withOpacity(0.4), fontWeight: FontWeight.w600))),
          Expanded(child: Divider(color: textColor.withOpacity(0.15))),
        ]),
        const SizedBox(height: 20),

        // --- Join Room Card ---
        _glass(isDark, child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          _cardHeader(Icons.login_rounded, Colors.blue,
            'join_room'.tr(), 'join_room_desc'.tr(), textColor),
          const SizedBox(height: 20),
          TextField(
            controller: _codeController,
            textCapitalization: TextCapitalization.characters,
            maxLength: 6,
            style: TextStyle(color: textColor, fontSize: 24,
              fontWeight: FontWeight.bold, letterSpacing: 12),
            textAlign: TextAlign.center,
            decoration: InputDecoration(
              hintText: '_ _ _ _ _ _',
              hintStyle: TextStyle(color: textColor.withOpacity(0.2),
                fontSize: 24, letterSpacing: 12),
              counterText: '',
              filled: true,
              fillColor: isDark ? Colors.white.withOpacity(0.05) : Colors.black.withOpacity(0.03),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(14),
                borderSide: BorderSide(color: textColor.withOpacity(0.1))),
              focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14),
                borderSide: const BorderSide(color: Color(0xFFE50914), width: 2)),
            ),
            inputFormatters: [
              FilteringTextInputFormatter.allow(RegExp(r'[A-Za-z0-9]')),
              _UpperCaseFmt(),
            ],
          ),
          const SizedBox(height: 16),
          SizedBox(height: 52, child: OutlinedButton(
            onPressed: () {
              final code = _codeController.text.trim();
              if (code.length == 6) {
                ctx.read<WatchRoomCubit>().joinRoom(code);
              } else {
                ScaffoldMessenger.of(ctx).showSnackBar(SnackBar(
                  content: Text('enter_valid_code'.tr()),
                  backgroundColor: const Color(0xFFE50914),
                ));
              }
            },
            style: OutlinedButton.styleFrom(
              foregroundColor: Colors.blue,
              side: const BorderSide(color: Colors.blue, width: 1.5),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            ),
            child: Text('join_room'.tr(),
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          )),
        ])),
        const SizedBox(height: 28),

        // Info
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: Colors.amber.withOpacity(0.08),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: Colors.amber.withOpacity(0.2)),
          ),
          child: Row(children: [
            Icon(Icons.info_outline, color: Colors.amber[600], size: 20),
            const SizedBox(width: 12),
            Expanded(child: Text('watch_together_info'.tr(),
              style: TextStyle(color: textColor.withOpacity(0.7), fontSize: 13, height: 1.4))),
          ]),
        ),
      ]),
    );
  }

  Widget _cardHeader(IconData icon, Color color, String title, String desc, Color textColor) {
    return Row(children: [
      Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: color.withOpacity(0.15), borderRadius: BorderRadius.circular(12)),
        child: Icon(icon, color: color, size: 24),
      ),
      const SizedBox(width: 16),
      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(title, style: TextStyle(color: textColor, fontSize: 18, fontWeight: FontWeight.bold)),
        const SizedBox(height: 4),
        Text(desc, style: TextStyle(color: textColor.withOpacity(0.5), fontSize: 13)),
      ])),
    ]);
  }

  Widget _glass(bool isDark, {required Widget child}) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: isDark ? Colors.white.withOpacity(0.06) : Colors.white.withOpacity(0.8),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: isDark ? Colors.white.withOpacity(0.1) : Colors.black.withOpacity(0.05)),
            boxShadow: [BoxShadow(
              color: Colors.black.withOpacity(isDark ? 0.3 : 0.05),
              blurRadius: 20, offset: const Offset(0, 8))],
          ),
          child: child,
        ),
      ),
    );
  }
}

class _UpperCaseFmt extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(TextEditingValue old, TextEditingValue nv) =>
    TextEditingValue(text: nv.text.toUpperCase(), selection: nv.selection);
}

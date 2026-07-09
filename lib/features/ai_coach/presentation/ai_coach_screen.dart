import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:turf_app/core/theme/app_theme.dart';
import 'package:turf_app/features/ai_coach/presentation/providers/ai_coach_provider.dart';
import 'package:turf_app/features/ai_coach/presentation/widgets/chat_bubble.dart';
import 'package:turf_app/features/ai_coach/presentation/widgets/typing_indicator.dart';
import 'package:turf_app/features/ai_coach/presentation/widgets/quick_action_chips.dart';
import 'package:turf_app/features/ai_coach/domain/models/chat_message.dart';

class AiCoachScreen extends ConsumerStatefulWidget {
  const AiCoachScreen({super.key});

  @override
  ConsumerState<AiCoachScreen> createState() => _AiCoachScreenState();
}

class _AiCoachScreenState extends ConsumerState<AiCoachScreen>
    with TickerProviderStateMixin {
  final _textController = TextEditingController();
  final _scrollController = ScrollController();
  final _focusNode = FocusNode();
  bool _hasText = false;

  late final AnimationController _onlinePulseController;
  late final Animation<double> _onlinePulseAnimation;

  @override
  void initState() {
    super.initState();

    _textController.addListener(() {
      final hasText = _textController.text.trim().isNotEmpty;
      if (hasText != _hasText) {
        setState(() => _hasText = hasText);
      }
    });

    _onlinePulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);

    _onlinePulseAnimation = Tween<double>(begin: 0.4, end: 1.0).animate(
      CurvedAnimation(parent: _onlinePulseController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _textController.dispose();
    _scrollController.dispose();
    _focusNode.dispose();
    _onlinePulseController.dispose();
    super.dispose();
  }

  void _scrollToBottom({bool animated = true}) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        if (animated) {
          _scrollController.animateTo(
            _scrollController.position.maxScrollExtent,
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeOutCubic,
          );
        } else {
          _scrollController.jumpTo(
            _scrollController.position.maxScrollExtent,
          );
        }
      }
    });
  }

  void _sendMessage() {
    final text = _textController.text.trim();
    if (text.isEmpty) return;

    HapticFeedback.lightImpact();
    ref.read(aiCoachProvider.notifier).sendMessage(text);
    _textController.clear();
    _scrollToBottom();
  }

  void _showClearDialog() {
    HapticFeedback.mediumImpact();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppTheme.cardDark,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          'Clear Chat?',
          style: GoogleFonts.spaceGrotesk(
            color: AppTheme.textPrimary,
            fontWeight: FontWeight.bold,
          ),
        ),
        content: Text(
          'This will clear all messages and start a fresh conversation.',
          style: GoogleFonts.inter(
            color: AppTheme.textSecondary,
            fontSize: 14,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(
              'Cancel',
              style: GoogleFonts.inter(color: AppTheme.textSecondary),
            ),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              ref.read(aiCoachProvider.notifier).clearChat();
              _scrollToBottom(animated: false);
            },
            child: Text(
              'Clear',
              style: GoogleFonts.inter(
                color: AppTheme.danger,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(aiCoachProvider);
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;
    final bottomPadding = MediaQuery.of(context).padding.bottom;
    final topPadding = MediaQuery.of(context).padding.top;

    // Auto-scroll when new messages arrive or typing state changes
    ref.listen(aiCoachProvider.select((s) => s.messages.length), (prev, next) {
      if (prev != null && next > prev) {
        _scrollToBottom();
      }
    });

    ref.listen(aiCoachProvider.select((s) => s.isTyping), (prev, next) {
      if (next) _scrollToBottom();
    });

    // Auto-scroll when keyboard opens
    if (bottomInset > 0) {
      _scrollToBottom();
    }

    return Scaffold(
      backgroundColor: AppTheme.backgroundDark,
      body: Column(
        children: [
          // ─── CUSTOM APP BAR ───
          _buildAppBar(topPadding),

          // ─── MESSAGE AREA ───
          Expanded(
            child: Stack(
              children: [
                if (state.isLoading)
                  const Center(
                    child: CircularProgressIndicator(
                      color: AppTheme.primaryColor,
                    ),
                  )
                else
                  _buildMessageList(state),

                // Top gradient overlay for scroll depth effect
                Positioned(
                  top: 0,
                  left: 0,
                  right: 0,
                  height: 32,
                  child: IgnorePointer(
                    child: Container(
                      decoration: const BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            AppTheme.backgroundDark,
                            Colors.transparent,
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // ─── COMPACT QUICK ACTION CHIPS ───
          if (state.messages.length <= 1 && !_hasText)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: QuickActionChips(
                compact: true,
                onChipTapped: (text) {
                  HapticFeedback.selectionClick();
                  ref.read(aiCoachProvider.notifier).sendMessage(text);
                  _scrollToBottom();
                },
              ),
            ),

          // ─── INPUT BAR ───
          _buildInputBar(bottomPadding, bottomInset, state.isTyping),
        ],
      ),
    );
  }

  // ────────────────────────────────────────────────
  // CUSTOM APP BAR
  // ────────────────────────────────────────────────
  Widget _buildAppBar(double topPadding) {
    return Container(
      padding: EdgeInsets.only(
        top: topPadding + 8,
        bottom: 12,
        left: 8,
        right: 8,
      ),
      decoration: BoxDecoration(
        color: AppTheme.backgroundDark,
        boxShadow: [
          BoxShadow(
            color: AppTheme.backgroundDark.withOpacity(0.8),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          // Back button
          GestureDetector(
            onTap: () {
              HapticFeedback.lightImpact();
              Navigator.of(context).pop();
            },
            child: Container(
              width: 40,
              height: 40,
              decoration: const BoxDecoration(
                color: AppTheme.cardDark,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.arrow_back_rounded,
                color: AppTheme.textPrimary,
                size: 20,
              ),
            ),
          ),

          const SizedBox(width: 12),

          // Center: Title, subtitle, online status
          Expanded(
            child: Hero(
              tag: 'ai_coach_fab',
              child: Material(
                color: Colors.transparent,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Title row
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(
                          Icons.auto_awesome,
                          size: 16,
                          color: AppTheme.primaryColor,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          'TURF Coach',
                          style: GoogleFonts.spaceGrotesk(
                            color: AppTheme.textPrimary,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 2),
                    // Subtitle
                    Text(
                      'Powered by Gemma AI',
                      style: GoogleFonts.inter(
                        color: AppTheme.textSecondary,
                        fontSize: 11,
                      ),
                    ),
                    const SizedBox(height: 4),
                    // Online indicator
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        AnimatedBuilder(
                          animation: _onlinePulseAnimation,
                          builder: (context, child) {
                            return Container(
                              width: 6,
                              height: 6,
                              decoration: BoxDecoration(
                                color: AppTheme.primaryColor.withOpacity(
                                  _onlinePulseAnimation.value,
                                ),
                                shape: BoxShape.circle,
                                boxShadow: [
                                  BoxShadow(
                                    color: AppTheme.primaryColor.withOpacity(
                                      0.4 * _onlinePulseAnimation.value,
                                    ),
                                    blurRadius: 6,
                                    spreadRadius: 1,
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                        const SizedBox(width: 5),
                        Text(
                          'Online',
                          style: GoogleFonts.inter(
                            color: AppTheme.primaryColor,
                            fontSize: 10,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),

          const SizedBox(width: 12),

          // TTS toggle button
          GestureDetector(
            onTap: () {
              HapticFeedback.lightImpact();
              ref.read(aiCoachProvider.notifier).toggleTts();
            },
            child: Container(
              width: 40,
              height: 40,
              decoration: const BoxDecoration(
                color: Colors.transparent,
                shape: BoxShape.circle,
              ),
              child: Icon(
                ref.watch(aiCoachProvider).isTtsEnabled
                    ? Icons.volume_up_rounded
                    : Icons.volume_off_rounded,
                color: AppTheme.textSecondary,
                size: 22,
              ),
            ),
          ),
          
          // Clear chat button
          GestureDetector(
            onTap: _showClearDialog,
            child: Container(
              width: 40,
              height: 40,
              decoration: const BoxDecoration(
                color: Colors.transparent,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.refresh_rounded,
                color: AppTheme.textSecondary,
                size: 22,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ────────────────────────────────────────────────
  // MESSAGE LIST
  // ────────────────────────────────────────────────
  Widget _buildMessageList(AiCoachState state) {
    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      itemCount: state.messages.length +
          (state.isTyping ? 1 : 0) +
          (state.messages.length <= 1 ? 1 : 0), // +1 for quick actions
      itemBuilder: (context, index) {
        // Messages
        if (index < state.messages.length) {
          return _buildAnimatedMessage(state.messages[index], index);
        }

        // Quick action chips (after welcome message)
        if (state.messages.length <= 1 && index == state.messages.length) {
          return Padding(
            padding: const EdgeInsets.only(top: 8, bottom: 16),
            child: QuickActionChips(
              onChipTapped: (text) {
                HapticFeedback.selectionClick();
                ref.read(aiCoachProvider.notifier).sendMessage(text);
                _scrollToBottom();
              },
            ),
          );
        }

        // Typing indicator
        if (state.isTyping) {
          return const TypingIndicator();
        }

        return const SizedBox.shrink();
      },
    );
  }

  Widget _buildAnimatedMessage(ChatMessage message, int index) {
    return TweenAnimationBuilder<double>(
      key: ValueKey(message.id),
      tween: Tween(begin: 0.0, end: 1.0),
      duration: const Duration(milliseconds: 350),
      curve: Curves.easeOutCubic,
      builder: (context, value, child) {
        return Opacity(
          opacity: value,
          child: Transform.translate(
            offset: Offset(0, 12 * (1 - value)),
            child: child,
          ),
        );
      },
      child: ChatBubble(message: message),
    );
  }

  // ────────────────────────────────────────────────
  // INPUT BAR
  // ────────────────────────────────────────────────
  Widget _buildInputBar(
      double bottomPadding, double bottomInset, bool isTyping) {
    return Container(
      padding: EdgeInsets.fromLTRB(
        16,
        12,
        16,
        bottomInset > 0 ? 12 : 12 + bottomPadding,
      ),
      decoration: const BoxDecoration(
        color: AppTheme.surfaceDark,
        border: Border(
          top: BorderSide(color: Color(0xFF2C2C2E), width: 0.5),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          // Text field
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: AppTheme.cardDark,
                borderRadius: BorderRadius.circular(24),
              ),
              child: TextField(
                controller: _textController,
                focusNode: _focusNode,
                maxLines: 4,
                minLines: 1,
                textCapitalization: TextCapitalization.sentences,
                style: GoogleFonts.inter(
                  color: AppTheme.textPrimary,
                  fontSize: 15,
                ),
                decoration: InputDecoration(
                  hintText: 'Ask your coach...',
                  hintStyle: GoogleFonts.inter(
                    color: AppTheme.textSecondary,
                    fontSize: 15,
                  ),
                  filled: false,
                  border: InputBorder.none,
                  enabledBorder: InputBorder.none,
                  focusedBorder: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 12,
                  ),
                ),
                onSubmitted: (_) => _sendMessage(),
              ),
            ),
          ),

          const SizedBox(width: 8),

          // Send button
          GestureDetector(
            onTap: (_hasText && !isTyping) ? _sendMessage : null,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              curve: Curves.easeInOut,
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: _hasText && !isTyping
                    ? AppTheme.primaryColor
                    : const Color(0xFF2C2C2E),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.arrow_upward_rounded,
                color: _hasText && !isTyping
                    ? AppTheme.backgroundDark
                    : AppTheme.textSecondary,
                size: 22,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

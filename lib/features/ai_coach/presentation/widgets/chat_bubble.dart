import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:turf_app/core/theme/app_theme.dart';
import 'package:turf_app/features/ai_coach/domain/models/chat_message.dart';

class ChatBubble extends StatelessWidget {
  final ChatMessage message;

  const ChatBubble({super.key, required this.message});

  @override
  Widget build(BuildContext context) {
    final isUser = message.isUser;

    return Padding(
      padding: EdgeInsets.only(
        left: isUser ? 60 : 0,
        right: isUser ? 0 : 60,
        bottom: 8,
      ),
      child: Align(
        alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
        child: Column(
          crossAxisAlignment:
              isUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
          children: [
            if (!isUser) _buildAssistantLabel(),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: isUser
                    ? AppTheme.primaryColor
                    : message.isError
                        ? AppTheme.danger.withOpacity(0.15)
                        : AppTheme.cardDark,
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(18),
                  topRight: const Radius.circular(18),
                  bottomLeft: Radius.circular(isUser ? 18 : 4),
                  bottomRight: Radius.circular(isUser ? 4 : 18),
                ),
                border: message.isError
                    ? Border.all(
                        color: AppTheme.danger.withOpacity(0.3), width: 1)
                    : null,
              ),
              child: Text(
                message.content,
                style: GoogleFonts.inter(
                  color: isUser
                      ? AppTheme.backgroundDark
                      : message.isError
                          ? AppTheme.danger
                          : AppTheme.textPrimary,
                  fontSize: 14.5,
                  height: 1.45,
                  fontWeight: isUser ? FontWeight.w500 : FontWeight.w400,
                ),
              ),
            ),
            const SizedBox(height: 4),
            _buildTimestamp(isUser),
          ],
        ),
      ),
    );
  }

  Widget _buildAssistantLabel() {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 6),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.auto_awesome,
            size: 12,
            color: AppTheme.primaryColor,
          ),
          const SizedBox(width: 4),
          Text(
            'TURF Coach',
            style: GoogleFonts.spaceGrotesk(
              color: AppTheme.primaryColor,
              fontSize: 11,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTimestamp(bool isUser) {
    final time = message.timestamp;
    final hour = time.hour;
    final minute = time.minute.toString().padLeft(2, '0');
    final period = hour >= 12 ? 'PM' : 'AM';
    final displayHour = hour > 12 ? hour - 12 : (hour == 0 ? 12 : hour);

    return Padding(
      padding: EdgeInsets.only(left: isUser ? 0 : 4, right: isUser ? 4 : 0),
      child: Text(
        '$displayHour:$minute $period',
        style: GoogleFonts.inter(
          color: AppTheme.textTertiary,
          fontSize: 10,
        ),
      ),
    );
  }
}

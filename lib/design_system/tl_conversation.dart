import 'package:flutter/material.dart';

import '../config/appTheme.dart';

/// Reusable message presentation. Message fetch/send/state remains in ChatRoomPage.
class TLMessageBubble extends StatelessWidget {
  final bool own;
  final String sender;
  final String? avatarUrl;
  final String message;
  final String time;
  const TLMessageBubble({
    super.key,
    required this.own,
    required this.sender,
    this.avatarUrl,
    required this.message,
    required this.time,
  });

  Widget _avatarInitial(Color textColor) {
    return Center(
      child: Text(
        sender.isEmpty ? '?' : sender.substring(0, 1).toUpperCase(),
        style: TextStyle(
          fontWeight: FontWeight.w900,
          color: textColor,
          fontSize: 12,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final p = context.tl;
    final bubble = own ? p.primary : p.fieldBg;
    return Semantics(
      label: '$sender: $message',
      child: Align(
        alignment: own ? Alignment.centerRight : Alignment.centerLeft,
        child: Container(
          margin: const EdgeInsets.only(bottom: 13),
          constraints: BoxConstraints(
            maxWidth: MediaQuery.sizeOf(context).width * .81,
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            mainAxisSize: MainAxisSize.min,
            children: [
              if (!own) ...[
                CircleAvatar(
                  radius: 17,
                  backgroundColor: p.creamDark,
                  child: ClipOval(
                    child: SizedBox.square(
                      dimension: 34,
                      child: avatarUrl != null && avatarUrl!.trim().isNotEmpty
                          ? Image.network(
                              avatarUrl!.trim(),
                              fit: BoxFit.cover,
                              errorBuilder: (_, _, _) => _avatarInitial(p.navy),
                            )
                          : _avatarInitial(p.navy),
                    ),
                  ),
                ),
                const SizedBox(width: 7),
              ],
              Flexible(
                child: Container(
                  padding: const EdgeInsets.fromLTRB(15, 12, 14, 10),
                  decoration: BoxDecoration(
                    color: bubble,
                    border: Border.all(color: own ? p.primary : p.fieldBorder),
                    borderRadius: BorderRadius.only(
                      topLeft: const Radius.circular(21),
                      topRight: const Radius.circular(21),
                      bottomLeft: Radius.circular(own ? 21 : 5),
                      bottomRight: Radius.circular(own ? 5 : 21),
                    ),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        own ? 'Kamu' : sender,
                        style: TextStyle(
                          fontWeight: FontWeight.w900,
                          fontSize: 11,
                          color: own ? Colors.white : p.navy,
                        ),
                      ),
                      const SizedBox(height: 6),
                      SelectableText(
                        message,
                        style: TextStyle(
                          color: own ? Colors.white : p.navy,
                          height: 1.46,
                          fontSize: 13.5,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Align(
                        alignment: Alignment.centerRight,
                        child: Text(
                          time,
                          style: TextStyle(
                            fontSize: 10,
                            color: own ? Colors.white70 : p.grey,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

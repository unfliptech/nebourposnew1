import 'dart:async';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

class CustomFooterBar extends StatefulWidget {
  const CustomFooterBar({super.key});

  @override
  State<CustomFooterBar> createState() => _CustomFooterBarState();
}

class _CustomFooterBarState extends State<CustomFooterBar> {
  late Timer _timer;
  String _timeLabel = '';

  @override
  void initState() {
    super.initState();
    _updateTime();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) => _updateTime());
  }

  void _updateTime() {
    setState(() {
      _timeLabel =
          DateFormat('EEEE, dd MMMM yyyy hh:mm:ss a').format(DateTime.now());
    });
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? const Color(0xFF0C0C0C) : Colors.grey[200];
    final fg = isDark ? Colors.white : const Color(0xFF000000);

    return Container(
      height: 25,
      width: double.infinity,
      color: bg,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // --- Left side ---
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // ─── Company Name ─────────────────────────────
              Text(
                'Powered by Unflip Technologies LLP',
                style: TextStyle(
                  color: fg,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  height: 1.2,
                ),
              ),
              const SizedBox(width: 25),

              // ─── WhatsApp ─────────────────────────────────
              Row(
                children: [
                  const FaIcon(FontAwesomeIcons.whatsapp, size: 13),
                  const SizedBox(width: 6),
                  Text(
                    '+91 9999 9999 99',
                    style: TextStyle(color: fg, fontSize: 12, height: 1.2),
                  ),
                ],
              ),
              const SizedBox(width: 25),

              // ─── Email ────────────────────────────────────
              Row(
                children: [
                  const FaIcon(FontAwesomeIcons.envelope, size: 12),
                  const SizedBox(width: 6),
                  Text(
                    'support@nebour.app',
                    style: TextStyle(color: fg, fontSize: 12, height: 1.2),
                  ),
                ],
              ),
              const SizedBox(width: 25),
              Row(
                children: [
                  Text(
                    'version 0.1.0',
                    style: TextStyle(color: fg, fontSize: 12, height: 1.2),
                  ),
                ],
              ),
            ],
          ),

          // --- Right side (clock) ---
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Text(
                _timeLabel,
                style: TextStyle(color: fg, fontSize: 12, height: 1.2),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

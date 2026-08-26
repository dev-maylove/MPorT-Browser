import 'dart:async';
import 'package:flutter/material.dart';
import '../core/theme/app_theme.dart';

class BrowserToolbar extends StatefulWidget {
  const BrowserToolbar({
    super.key,
    required this.controller,
    required this.onSubmitted,
    required this.onBack,
    required this.onForward,
    required this.onRefresh,
    required this.onTabs,
    required this.onMenu,
    this.onEditingChanged,
  });

  final TextEditingController controller;
  final ValueChanged<String> onSubmitted;
  final FutureOr<void> Function() onBack;
  final FutureOr<void> Function() onForward;
  final FutureOr<void> Function() onRefresh;
  final VoidCallback onTabs;
  final VoidCallback onMenu;
  final ValueChanged<bool>? onEditingChanged;

  @override
  State<BrowserToolbar> createState() => _BrowserToolbarState();
}

class _BrowserToolbarState extends State<BrowserToolbar> {
  late final FocusNode _focus;

  @override
  void initState() {
    super.initState();
    _focus = FocusNode();
    _focus.addListener(() {
      widget.onEditingChanged?.call(_focus.hasFocus);
    });
  }

  @override
  void dispose() {
    _focus.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      bottom: false,
      child: Container(
        color: AppTheme.bgDeep,
        padding: const EdgeInsets.fromLTRB(4, 6, 4, 6),
        child: Row(
          children: [
            IconButton(
              onPressed: widget.onBack,
              icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 18),
              color: AppTheme.textSecondary,
            ),
            IconButton(
              onPressed: widget.onForward,
              icon: const Icon(Icons.arrow_forward_ios_rounded, size: 18),
              color: AppTheme.textSecondary,
            ),
            Expanded(
              child: TextField(
                controller: widget.controller,
                focusNode: _focus,
                style: const TextStyle(
                  color: AppTheme.textPrimary,
                  fontSize: 14,
                ),
                textInputAction: TextInputAction.go,
                onSubmitted: (v) {
                  _focus.unfocus();
                  widget.onSubmitted(v);
                },
                decoration: InputDecoration(
                  isDense: true,
                  prefixIcon: const Icon(
                    Icons.lock_outline_rounded,
                    size: 16,
                    color: AppTheme.greenStatus,
                  ),
                  suffixIcon: IconButton(
                    onPressed: widget.onRefresh,
                    icon: const Icon(Icons.refresh_rounded, size: 20),
                    color: AppTheme.cyanNeon,
                  ),
                  hintText: 'Search, URL, or g / ddg + keywords',
                  hintStyle: const TextStyle(color: AppTheme.textMuted),
                  filled: true,
                  fillColor: AppTheme.bgCard,
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(22),
                    borderSide: BorderSide.none,
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(22),
                    borderSide: BorderSide(
                      color: AppTheme.cyanNeon.withValues(alpha: 0.15),
                    ),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(22),
                    borderSide: const BorderSide(color: AppTheme.cyanNeon),
                  ),
                ),
              ),
            ),
            IconButton(
              onPressed: widget.onTabs,
              icon: const Icon(Icons.tab_rounded),
              color: AppTheme.cyanNeon,
            ),
            IconButton(
              onPressed: widget.onMenu,
              icon: const Icon(Icons.menu_rounded),
              color: AppTheme.textSecondary,
            ),
          ],
        ),
      ),
    );
  }
}

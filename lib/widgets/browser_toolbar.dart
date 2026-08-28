import 'dart:async';
import 'package:flutter/material.dart';
import '../core/theme/app_theme.dart';

class BrowserToolbar extends StatefulWidget {
  const BrowserToolbar({
    super.key,
    required this.controller,
    required this.onSubmitted,
    required this.onHome,
    required this.onRefresh,
    required this.onTabs,
    required this.onMenu,
    this.tabCount = 1,
    this.onEditingChanged,
  });

  final TextEditingController controller;
  final ValueChanged<String> onSubmitted;
  final VoidCallback onHome;
  final FutureOr<void> Function() onRefresh;
  final VoidCallback onTabs;
  final VoidCallback onMenu;
  final ValueChanged<bool>? onEditingChanged;
  final int tabCount;

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
              tooltip: 'Home',
              onPressed: widget.onHome,
              icon: const Icon(Icons.home_outlined, size: 27),
              color: AppTheme.textPrimary,
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
                    Icons.info_outline_rounded,
                    size: 18,
                    color: AppTheme.textPrimary,
                  ),
                  hintText: 'Search, URL, or g / ddg + keywords',
                  hintStyle: const TextStyle(color: AppTheme.textMuted),
                  filled: true,
                  fillColor: AppTheme.bgCard,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 12, vertical: 10,
                  ),
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
              tooltip: 'New tab',
              onPressed: widget.onTabs,
              icon: const Icon(Icons.add_rounded, size: 30),
              color: AppTheme.textPrimary,
            ),
            Semantics(
              label: 'Tabs, ${widget.tabCount} open',
              button: true,
              child: InkWell(
                onTap: widget.onTabs,
                borderRadius: BorderRadius.circular(9),
                child: Container(
                  width: 34,
                  height: 34,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    border: Border.all(
                      color: AppTheme.textPrimary.withValues(alpha: 0.9),
                      width: 2,
                    ),
                    borderRadius: BorderRadius.circular(9),
                  ),
                  child: Text(
                    widget.tabCount > 99 ? '99+' : '${widget.tabCount}',
                    style: const TextStyle(
                      color: AppTheme.textPrimary,
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
            ),
            IconButton(
              tooltip: 'Menu',
              onPressed: widget.onMenu,
              icon: const Icon(Icons.more_vert_rounded, size: 29),
              color: AppTheme.textPrimary,
            ),
          ],
        ),
      ),
    );
  }
}

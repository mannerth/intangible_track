import 'package:flutter/material.dart';

import '../../common/app_theme.dart';

enum SearchHeaderMode {
  /// 地图页 / 发现页：仅搜索框
  searchOnly,

  /// 省份名录页：返回按钮 + 标题 + 搜索框
  titled,
}

/// 顶部奶油色头部，作为 [Scaffold.appBar] 使用。
///
/// 内部自动处理状态栏安全区域，不需要外部再套 SafeArea。
class SearchHeader extends StatefulWidget implements PreferredSizeWidget {
  const SearchHeader.searchOnly({
    super.key,
    required this.hintText,
    this.leadingIcon,
    this.controller,
    this.onChanged,
    this.onSubmitted,
    this.onIconPress
  }) : mode = SearchHeaderMode.searchOnly,
       title = null,
       onBack = null;

  const SearchHeader.titled({
    super.key,
    required this.title,
    required this.hintText,
    this.controller,
    this.onChanged,
    this.onSubmitted,
    this.onBack,
  }) : mode = SearchHeaderMode.titled,
       leadingIcon = null,
       onIconPress = null;

  final SearchHeaderMode mode;
  final String? title;
  final String hintText;

  /// 搜索框左侧的装饰图标（如定位 / 罗盘），点击聚焦搜索框
  final Widget? leadingIcon;
  final TextEditingController? controller;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onSubmitted;
  final VoidCallback? onBack;
  final Function? onIconPress;

  @override
  Size get preferredSize =>
      Size.fromHeight(mode == SearchHeaderMode.titled ? 168 : 126);

  @override
  State<SearchHeader> createState() => _SearchHeaderState();
}

class _SearchHeaderState extends State<SearchHeader> {
  late final TextEditingController _controller;
  final _focusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    _controller = widget.controller ?? TextEditingController();
  }

  @override
  void dispose() {
    _focusNode.dispose();
    if (widget.controller == null) {
      _controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final topInset = MediaQuery.paddingOf(context).top;
    final content = widget.mode == SearchHeaderMode.titled
        ? _buildTitledContent()
        : Center(child: _buildSearchRow());

    return Container(
      width: double.infinity,
      height: widget.preferredSize.height,
      color: AppColors.white,
      child: ColoredBox(
        color: AppColors.header,
        child: Stack(
          fit: StackFit.expand,
          children: [
            // 山形水印
            Opacity(
              opacity: 0.3,
              child: Image.asset('assets/山.png', fit: BoxFit.cover),
            ),
            Padding(
              padding: EdgeInsets.only(top: topInset, left: 24, right: 24),
              child: content,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTitledContent() {
    return Column(
      children: [
        Expanded(
          child: Row(
            children: [
              SizedBox(
                width: 48,
                child: IconButton(
                  padding: EdgeInsets.zero,
                  icon: const Icon(
                    Icons.arrow_back_ios_new,
                    size: 20,
                    color: AppColors.textHint,
                  ),
                  onPressed: widget.onBack,
                ),
              ),
              Expanded(
                child: Center(
                  child: Text(
                    widget.title ?? '',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w500,
                      color: AppColors.textHint,
                    ),
                  ),
                ),
              ),
              // 与左侧返回按钮等宽，保证标题真正居中
              const SizedBox(width: 48),
            ],
          ),
        ),
        _buildSearchRow(),
        const SizedBox(height: 14),
      ],
    );
  }

  Widget _buildSearchRow() {
    return Row(
      children: [
        if (widget.leadingIcon case final icon?) ...[
          IconButton(
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints.tightFor(width: 32, height: 32),
            icon: icon,
            onPressed: () => widget.onIconPress,
          ),
          const SizedBox(width: 8),
        ],
        Expanded(child: _buildSearchField()),
      ],
    );
  }

  Widget _buildSearchField() {
    return Container(
      height: 34,
      padding: const EdgeInsets.only(left: 14, right: 4),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(17),
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _controller,
              focusNode: _focusNode,
              textInputAction: TextInputAction.search,
              style: const TextStyle(
                fontSize: 12,
                color: AppColors.textPrimary,
              ),
              onChanged: widget.onChanged,
              onSubmitted: widget.onSubmitted,
              decoration: InputDecoration(
                isCollapsed: true,
                border: InputBorder.none,
                hintText: widget.hintText,
                hintStyle: const TextStyle(
                  fontSize: 12,
                  color: AppColors.textHint,
                ),
              ),
            ),
          ),
          IconButton(
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints.tightFor(width: 30, height: 30),
            icon: const Icon(Icons.search, size: 20, color: AppColors.textHint),
            onPressed: () {
              _focusNode.unfocus();
              widget.onSubmitted?.call(_controller.text);
            },
          ),
        ],
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class OneMailPanel extends StatefulWidget {
  final bool isAdmin;

  const OneMailPanel({super.key, required this.isAdmin});

  @override
  State<OneMailPanel> createState() => _OneMailPanelState();
}

class _OneMailPanelState extends State<OneMailPanel> {
  static const Color _yellow = Color(0xFFF5C518);
  static const Color _yellowLight = Color(0xFFFFFBDE);
  static const Color _yellowDark = Color(0xFFC8A000);
  static const Color _dark = Color(0xFF1A1A1A);
  static const Color _mid = Color(0xFF4A4A4A);
  static const Color _muted = Color(0xFF9A9A9A);
  static const Color _border = Color(0xFFEDEDED);
  static const Color _white = Color(0xFFFFFFFF);
  static const Color _bg = Color(0xFFF5F5F5);
  static const Color _green = Color(0xFF22C55E);
  static const Color _red = Color(0xFFEF4444);
  static const Color _blue = Color(0xFF3B82F6);
  static const Color _bottomNav = Color(0xFF1A1A1A);
  static const String _demoToastMessage = 'OneMAIL Demo - browse around and stay tuned for coming live update.';

  final TextEditingController _composeController = TextEditingController();
  final ScrollController _messagesController = ScrollController();

  final List<String> _tabs = const ['All', 'Unread', 'Work', 'Personal', 'Pinned'];

  final List<_QuickAction> _quickActions = const [
    _QuickAction(label: 'Invoices', prompt: 'Find invoices from last week'),
    _QuickAction(label: 'Reminder', prompt: 'Set a follow-up reminder'),
    _QuickAction(label: 'Unsubscribe', prompt: 'Unsubscribe from newsletters'),
    _QuickAction(label: 'Sarah', prompt: 'Show thread with Sarah'),
    _QuickAction(label: 'Priorities', prompt: 'What are my priorities today?'),
  ];

  late final List<_MailAccount> _accounts;
  late List<_ChatMessage> _messages;

  int _selectedTabIndex = 0;
  int _selectedBottomNavIndex = 0;
  int _selectedAccountIndex = 0;
  int _selectedSubThreadIndex = 0;
  int? _openedAccountIndex;
  bool _openedFromSubThread = false;

  @override
  void initState() {
    super.initState();
    _accounts = _buildAccounts();
    _messages = _seedMessagesForAccount(0);
  }

  @override
  void dispose() {
    _composeController.dispose();
    _messagesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: _white,
      child: AnimatedSwitcher(
        duration: const Duration(milliseconds: 220),
        child: _openedAccountIndex == null ? _buildThreadListScreen() : _buildMessagesScreen(),
      ),
    );
  }

  Widget _buildThreadListScreen() {
    return KeyedSubtree(
      key: const ValueKey<String>('thread-list-screen'),
      child: Column(
        children: [
          _buildThreadHeader(),
          _buildPersistentDemoToast(),
          Expanded(
            child: Stack(
              children: [
                _buildAccountList(),
                Positioned(right: 16, bottom: 16, child: _buildFloatingComposeButton()),
              ],
            ),
          ),
          _buildBottomNav(),
        ],
      ),
    );
  }

  Widget _buildMessagesScreen() {
    final _MailAccount account = _accounts[_openedAccountIndex!];
    final bool showingThread = _openedFromSubThread && account.subThreads.isNotEmpty;

    final String title = showingThread ? account.subThreads[_selectedSubThreadIndex].title : account.name;
    final String subtitle = showingThread ? 'Pinned thread - 3 participants' : account.syncLabel;

    return KeyedSubtree(
      key: const ValueKey<String>('messages-screen'),
      child: Column(
        children: [
          _buildMessagesHeader(account: account, title: title, subtitle: subtitle),
          _buildPersistentDemoToast(),
          _buildQuickActionsRow(),
          Expanded(child: _buildMessageList()),
          _buildComposer(),
        ],
      ),
    );
  }

  Widget _buildThreadHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(18, 12, 18, 10),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              RichText(
                text: TextSpan(
                  children: [
                    TextSpan(
                      text: '.eCG ',
                      style: _nunito(9.5, FontWeight.w800, color: _blue),
                    ),
                    TextSpan(
                      text: 'One',
                      style: _nunito(21, FontWeight.w700, color: const Color(0xFF555555), letterSpacing: -0.8),
                    ),
                    TextSpan(
                      text: 'Mail',
                      style: _nunito(21, FontWeight.w900, color: _yellow, letterSpacing: -0.8),
                    ),
                  ],
                ),
              ),
              Row(
                children: [
                  _headerButton(icon: Icons.notifications_none_rounded, showDot: true),
                  const SizedBox(width: 8),
                  _headerButton(icon: Icons.search_rounded),
                  const SizedBox(width: 8),
                  Container(
                    width: 32,
                    height: 32,
                    decoration: const BoxDecoration(color: _yellow, shape: BoxShape.circle),
                    alignment: Alignment.center,
                    child: Text('O', style: _nunito(12, FontWeight.w900, color: _dark)),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 8),
          SizedBox(
            height: 30,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: _tabs.length,
              separatorBuilder: (_, __) => const SizedBox(width: 5),
              itemBuilder: (context, index) {
                final bool selected = _selectedTabIndex == index;
                return GestureDetector(
                  onTap: () {
                    setState(() => _selectedTabIndex = index);
                  },
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 120),
                    padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 5),
                    decoration: BoxDecoration(color: selected ? _yellow : _bg, borderRadius: BorderRadius.circular(20)),
                    child: Text(_tabs[index], style: _nunito(10.5, FontWeight.w800, color: selected ? _dark : _muted)),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _headerButton({required IconData icon, bool showDot = false}) {
    return Container(
      width: 33,
      height: 33,
      decoration: const BoxDecoration(color: _bg, shape: BoxShape.circle),
      child: Stack(
        children: [
          Center(child: Icon(icon, size: 15, color: _mid)),
          if (showDot)
            Positioned(
              right: 3,
              top: 3,
              child: Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  color: _red,
                  shape: BoxShape.circle,
                  border: Border.all(color: _white, width: 1.5),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildAccountList() {
    return ListView(
      padding: EdgeInsets.zero,
      children: [
        for (int index = 0; index < _accounts.length; index++) ...[
          _buildAccountRow(index),
          if (index == 0) _buildSubThreadList(),
        ],
      ],
    );
  }

  Widget _buildAccountRow(int index) {
    final _MailAccount account = _accounts[index];
    final bool selected = _selectedAccountIndex == index;

    return InkWell(
      onTap: () => _openAccount(index),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 120),
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
        decoration: BoxDecoration(
          color: selected ? _yellowLight : _white,
          border: Border(bottom: BorderSide(color: _border)),
        ),
        child: Row(
          children: [
            _buildAvatar(account.avatar, size: 46),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          account.name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: _nunito(13.5, FontWeight.w800, color: _dark),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(account.timeLabel, style: _nunitoSans(10, FontWeight.w600, color: _muted)),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Row(
                    children: [
                      if (account.hasAiTag) ...[
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                          decoration: BoxDecoration(color: _yellow, borderRadius: BorderRadius.circular(3)),
                          child: Text('AI', style: _nunito(8.5, FontWeight.w900, color: _dark)),
                        ),
                        const SizedBox(width: 4),
                      ],
                      Expanded(
                        child: Text(
                          account.preview,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: _nunitoSans(11.5, FontWeight.w600, color: _muted),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            if (account.unreadCount > 0) ...[
              const SizedBox(width: 8),
              Container(
                constraints: const BoxConstraints(minWidth: 18, minHeight: 18),
                padding: const EdgeInsets.symmetric(horizontal: 4),
                decoration: BoxDecoration(
                  color: account.isUrgent ? _red : _yellow,
                  borderRadius: BorderRadius.circular(10),
                ),
                alignment: Alignment.center,
                child: Text(
                  '${account.unreadCount}',
                  style: _nunito(9.5, FontWeight.w900, color: account.isUrgent ? _white : _dark),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildSubThreadList() {
    final List<_SubThread> threads = _accounts[0].subThreads;
    if (threads.isEmpty) {
      return const SizedBox.shrink();
    }

    return Container(
      color: const Color(0xFFFAFAFA),
      child: Column(
        children: [for (int index = 0; index < threads.length; index++) _buildSubThreadRow(threads[index], index)],
      ),
    );
  }

  Widget _buildSubThreadRow(_SubThread thread, int index) {
    final bool selected = _selectedAccountIndex == 0 && _selectedSubThreadIndex == index;

    return InkWell(
      onTap: () => _openSubThread(index),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 100),
        padding: const EdgeInsets.fromLTRB(50, 8, 18, 8),
        decoration: BoxDecoration(
          color: selected ? _yellowLight : Colors.transparent,
          border: Border(bottom: BorderSide(color: _border)),
        ),
        child: Row(
          children: [
            Container(
              width: 30,
              height: 30,
              decoration: const BoxDecoration(color: _yellow, shape: BoxShape.circle),
              alignment: Alignment.center,
              child: Text(thread.avatar, style: _nunito(9, FontWeight.w900, color: _dark)),
            ),
            const SizedBox(width: 9),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    thread.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: _nunito(11, FontWeight.w800, color: _dark),
                  ),
                  const SizedBox(height: 1),
                  Text(
                    thread.preview,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: _nunitoSans(10, FontWeight.w600, color: _muted),
                  ),
                ],
              ),
            ),
            if (thread.pinned) Icon(Icons.push_pin_rounded, size: 12, color: _yellowDark),
          ],
        ),
      ),
    );
  }

  Widget _buildFloatingComposeButton() {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(24),
        onTap: () => _openAccount(_selectedAccountIndex),
        child: Ink(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: _yellow,
            shape: BoxShape.circle,
            boxShadow: [BoxShadow(color: _yellow.withValues(alpha: 0.5), blurRadius: 18, offset: const Offset(0, 4))],
          ),
          child: const Icon(Icons.add_rounded, color: _dark, size: 20),
        ),
      ),
    );
  }

  Widget _buildBottomNav() {
    const List<_BottomNavItem> navItems = [
      _BottomNavItem(icon: Icons.chat_bubble_outline_rounded, label: 'INBOX'),
      _BottomNavItem(icon: Icons.call_outlined, label: 'CALLS', hasDot: true),
      _BottomNavItem(icon: Icons.person_outline_rounded, label: 'PROFILE'),
      _BottomNavItem(icon: Icons.monitor_rounded, label: 'COMPUTE'),
      _BottomNavItem(icon: Icons.settings_outlined, label: 'SETTINGS'),
    ];

    return Container(
      color: _bottomNav,
      padding: const EdgeInsets.fromLTRB(0, 8, 0, 16),
      child: Row(
        children: [
          for (int index = 0; index < navItems.length; index++)
            Expanded(
              child: GestureDetector(
                onTap: () {
                  setState(() => _selectedBottomNavIndex = index);
                },
                child: Opacity(
                  opacity: _selectedBottomNavIndex == index ? 1 : 0.45,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Stack(
                        clipBehavior: Clip.none,
                        children: [
                          Icon(
                            navItems[index].icon,
                            size: 19,
                            color: _selectedBottomNavIndex == index ? _yellow : _white,
                          ),
                          if (navItems[index].hasDot)
                            Positioned(
                              right: -2,
                              top: -2,
                              child: Container(
                                width: 7,
                                height: 7,
                                decoration: BoxDecoration(
                                  color: _red,
                                  shape: BoxShape.circle,
                                  border: Border.all(color: _bottomNav, width: 1.5),
                                ),
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 3),
                      Text(
                        navItems[index].label,
                        style: _nunito(
                          8.5,
                          FontWeight.w800,
                          color: _selectedBottomNavIndex == index ? _yellow : _white,
                          letterSpacing: 0.6,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildMessagesHeader({required _MailAccount account, required String title, required String subtitle}) {
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 16, 14, 12),
      decoration: BoxDecoration(
        color: _white,
        border: Border(bottom: BorderSide(color: _border, width: 1.5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              IconButton(
                onPressed: _goBackToThreads,
                icon: const Icon(Icons.arrow_back_ios_new_rounded),
                iconSize: 17,
                color: _dark,
                style: IconButton.styleFrom(
                  backgroundColor: _bg,
                  minimumSize: const Size(32, 32),
                  padding: EdgeInsets.zero,
                ),
              ),
              const SizedBox(width: 10),
              _buildAvatar(account.avatar, size: 38, withStatus: false),
              const SizedBox(width: 11),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: _nunito(14.5, FontWeight.w800, color: _dark),
                    ),
                    const SizedBox(height: 2),
                    Text(subtitle, style: _nunitoSans(11, FontWeight.w700, color: _green)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 5,
            runSpacing: 5,
            children: [
              _detailActionButton(label: 'Summarise', onTap: () => _injectPrompt('Summarise my inbox')),
              _detailActionButton(label: 'Actions', onTap: () => _injectPrompt('What needs action today?')),
              _detailActionButton(
                label: '+ Compose',
                isPrimary: true,
                onTap: () => _injectPrompt('Compose a new email'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _detailActionButton({required String label, required VoidCallback onTap, bool isPrimary = false}) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(7),
        onTap: onTap,
        child: Ink(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
          decoration: BoxDecoration(
            color: isPrimary ? _yellow : _white,
            borderRadius: BorderRadius.circular(7),
            border: Border.all(color: isPrimary ? _yellow : _border, width: 1.5),
          ),
          child: Text(label, style: _nunito(10.5, FontWeight.w800, color: _dark)),
        ),
      ),
    );
  }

  Widget _buildQuickActionsRow() {
    return Container(
      height: 42,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: _border)),
      ),
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: _quickActions.length,
        separatorBuilder: (_, __) => const SizedBox(width: 5),
        itemBuilder: (context, index) {
          final action = _quickActions[index];
          return _quickActionButton(action.label, action.prompt);
        },
      ),
    );
  }

  Widget _quickActionButton(String label, String prompt) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(6),
        onTap: () => _injectPrompt(prompt),
        child: Ink(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
          decoration: BoxDecoration(
            color: _white,
            borderRadius: BorderRadius.circular(6),
            border: Border.all(color: _border, width: 1.5),
          ),
          child: Text(label, style: _nunito(10, FontWeight.w800, color: _mid)),
        ),
      ),
    );
  }

  Widget _buildMessageList() {
    return Container(
      color: _bg,
      padding: const EdgeInsets.all(14),
      child: ListView.separated(
        controller: _messagesController,
        itemCount: _messages.length,
        separatorBuilder: (_, __) => const SizedBox(height: 11),
        itemBuilder: (context, index) {
          final _ChatMessage message = _messages[index];
          final bool outgoing = message.kind == _MessageKind.outgoing;

          return Column(
            crossAxisAlignment: outgoing ? CrossAxisAlignment.end : CrossAxisAlignment.start,
            children: [
              if (!outgoing)
                Padding(
                  padding: const EdgeInsets.only(bottom: 3),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                        decoration: BoxDecoration(color: _yellow, borderRadius: BorderRadius.circular(3)),
                        child: Text('AI AGENT', style: _nunito(8.5, FontWeight.w900, color: _dark)),
                      ),
                      const SizedBox(width: 4),
                      Text(message.label, style: _nunitoSans(9.5, FontWeight.w700, color: _muted)),
                    ],
                  ),
                ),
              ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 560),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 10),
                  decoration: BoxDecoration(
                    color: outgoing ? _dark : _yellowLight,
                    borderRadius: outgoing
                        ? const BorderRadius.only(
                            topLeft: Radius.circular(13),
                            topRight: Radius.circular(3),
                            bottomLeft: Radius.circular(13),
                            bottomRight: Radius.circular(13),
                          )
                        : const BorderRadius.only(
                            topLeft: Radius.circular(3),
                            topRight: Radius.circular(13),
                            bottomLeft: Radius.circular(13),
                            bottomRight: Radius.circular(13),
                          ),
                    border: outgoing ? null : Border.all(color: _yellow, width: 1.5),
                  ),
                  child: Text(
                    message.text,
                    style: _nunitoSans(
                      12.5,
                      FontWeight.w600,
                      color: outgoing ? _white : const Color(0xFF3A2D00),
                      height: 1.55,
                    ),
                  ),
                ),
              ),
              if (outgoing)
                Padding(
                  padding: const EdgeInsets.only(top: 2),
                  child: Text(message.timeLabel ?? '', style: _nunitoSans(9, FontWeight.w600, color: _muted)),
                ),
              if (!outgoing && message.suggestions.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 5),
                  child: Wrap(
                    spacing: 5,
                    runSpacing: 5,
                    children: message.suggestions.map((suggestion) {
                      return Material(
                        color: Colors.transparent,
                        child: InkWell(
                          borderRadius: BorderRadius.circular(6),
                          onTap: () => _injectPrompt(suggestion.prompt),
                          child: Ink(
                            padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
                            decoration: BoxDecoration(
                              color: _white,
                              borderRadius: BorderRadius.circular(6),
                              border: Border.all(color: _yellow, width: 1.5),
                            ),
                            child: Text(suggestion.label, style: _nunito(10, FontWeight.w800, color: _yellowDark)),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildComposer() {
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 10, 14, 10),
      decoration: BoxDecoration(
        color: _white,
        border: Border(top: BorderSide(color: _border, width: 1.5)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Expanded(
            child: TextField(
              controller: _composeController,
              minLines: 1,
              maxLines: 4,
              style: _nunitoSans(12.5, FontWeight.w600, color: _dark),
              decoration: InputDecoration(
                hintText: 'Ask the agent or type a message...',
                hintStyle: _nunitoSans(12.5, FontWeight.w600, color: _muted),
                filled: true,
                fillColor: _bg,
                isDense: true,
                contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(20),
                  borderSide: BorderSide(color: _border, width: 1.5),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(20),
                  borderSide: BorderSide(color: _border, width: 1.5),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(20),
                  borderSide: const BorderSide(color: _yellow, width: 1.5),
                ),
              ),
              onSubmitted: (_) => _sendMessage(),
            ),
          ),
          const SizedBox(width: 8),
          GestureDetector(
            onTap: _sendMessage,
            child: Container(
              width: 37,
              height: 37,
              decoration: const BoxDecoration(color: _yellow, shape: BoxShape.circle),
              alignment: Alignment.center,
              child: const Icon(Icons.send_rounded, size: 15, color: _dark),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAvatar(_AvatarStyle avatar, {required double size, bool withStatus = true}) {
    final double fontSize = size >= 40 ? 15 : 13;

    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Container(
            width: size,
            height: size,
            decoration: BoxDecoration(color: avatar.background, shape: BoxShape.circle),
            alignment: Alignment.center,
            child: Text(avatar.text, style: _nunito(fontSize, FontWeight.w900, color: avatar.foreground)),
          ),
          if (withStatus && avatar.online)
            Positioned(
              right: 1,
              bottom: 1,
              child: Container(
                width: 12,
                height: 12,
                decoration: BoxDecoration(
                  color: _green,
                  shape: BoxShape.circle,
                  border: Border.all(color: _white, width: 2),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildPersistentDemoToast() {
    return Container(
      margin: const EdgeInsets.fromLTRB(18, 0, 18, 8),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF8DA),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFE9D48C)),
      ),
      child: Row(
        children: [
          const Icon(Icons.campaign_rounded, size: 16, color: _yellowDark),
          const SizedBox(width: 8),
          Expanded(
            child: Text(_demoToastMessage, style: _nunitoSans(11, FontWeight.w700, color: _dark)),
          ),
        ],
      ),
    );
  }

  void _openAccount(int index) {
    setState(() {
      _selectedAccountIndex = index;
      _selectedSubThreadIndex = 0;
      _openedAccountIndex = index;
      _openedFromSubThread = false;
      _messages = _seedMessagesForAccount(index);
    });
    _scrollMessagesToBottom();
  }

  void _openSubThread(int index) {
    final List<_SubThread> threads = _accounts[0].subThreads;
    if (index < 0 || index >= threads.length) {
      return;
    }

    setState(() {
      _selectedAccountIndex = 0;
      _selectedSubThreadIndex = index;
      _openedAccountIndex = 0;
      _openedFromSubThread = true;
      _messages = [_ChatMessage.agent(label: 'Thread AI', text: threads[index].summary)];
    });
    _scrollMessagesToBottom();
  }

  void _goBackToThreads() {
    setState(() {
      _openedAccountIndex = null;
    });
  }

  void _injectPrompt(String prompt) {
    _sendText(prompt.trim());
  }

  void _sendMessage() {
    _sendText(_composeController.text.trim());
  }

  void _sendText(String text) {
    if (text.isEmpty) {
      return;
    }

    setState(() {
      _messages.add(_ChatMessage.outgoing(text: text, timeLabel: _timeLabel(DateTime.now())));
      _composeController.clear();
    });

    _scrollMessagesToBottom();

    Future.delayed(const Duration(milliseconds: 700), () {
      if (!mounted || _openedAccountIndex == null) {
        return;
      }
      setState(() {
        _messages.add(_responseFor(text));
      });
      _scrollMessagesToBottom();
    });
  }

  void _scrollMessagesToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_messagesController.hasClients) {
        return;
      }
      _messagesController.animateTo(
        _messagesController.position.maxScrollExtent + 80,
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeOut,
      );
    });
  }

  List<_ChatMessage> _seedMessagesForAccount(int accountIndex) {
    if (accountIndex == 0) {
      return [
        _ChatMessage.agent(
          label: 'OneMail',
          text:
              'Good morning. Here is your work inbox digest:\n\n- Action: CFO awaiting Q3 budget approval - deadline 5pm today\n- FYI: Sarah shared the 2026 roadmap deck - no reply needed\n- Resolved: IT confirmed your access is restored\n\n7 unread total. Want me to draft a reply to the CFO?',
          suggestions: const [
            _Suggestion(label: 'Draft reply', prompt: 'Yes, draft a reply approving the budget'),
            _Suggestion(label: 'Show email', prompt: 'Show me the CFO email'),
            _Suggestion(label: 'Remind at 4pm', prompt: 'Remind me at 4pm'),
          ],
        ),
        _ChatMessage.outgoing(text: 'Yes, draft a reply approving the budget', timeLabel: '9:42 AM'),
        _ChatMessage.agent(
          label: 'Draft ready',
          text:
              'Here is a draft reply to Marcus (CFO):\n\n"Hi Marcus, I have reviewed the Q3 budget proposal and I approve it as submitted. Please proceed with the allocation."\n\nTone: formal - 32 words.',
          suggestions: const [
            _Suggestion(label: 'Send', prompt: 'Send this draft'),
            _Suggestion(label: 'More concise', prompt: 'Make it more concise'),
            _Suggestion(label: 'Add condition', prompt: 'Add a budget condition'),
          ],
        ),
      ];
    }

    return [_ChatMessage.agent(label: 'OneMail', text: _accounts[accountIndex].greeting)];
  }

  _ChatMessage _responseFor(String input) {
    final String text = input.toLowerCase();

    if (text.contains('summar')) {
      return _ChatMessage.agent(
        label: 'OneMail',
        text:
            'Summary: 7 emails today. Top priority is the CFO budget thread at 5pm. Sarah sent a roadmap deck for Friday feedback. Three newsletters were auto-filtered.',
      );
    }

    if (text.contains('action') || text.contains('today')) {
      return _ChatMessage.agent(
        label: 'OneMail',
        text:
            'Today\'s actions:\n\n1. Approve Q3 budget for CFO Marcus by 5pm\n2. Reply to Sarah with roadmap feedback by Friday\n3. No other urgent actions pending',
      );
    }

    if (text.contains('compose') || text.contains('new email')) {
      return _ChatMessage.agent(
        label: 'OneMail',
        text: 'Sure. Who should I address the email to, and what is the subject?',
      );
    }

    if (text.contains('send this') || text.contains('send draft')) {
      return _ChatMessage.agent(
        label: 'Sent',
        text:
            'Email sent to Marcus (CFO) at ${_timeLabel(DateTime.now())}. I can remind you if there is no reply by 5pm.',
      );
    }

    if (text.contains('concise')) {
      return _ChatMessage.agent(
        label: 'OneMail',
        text: 'More concise version:\n\n"Hi Marcus, Q3 budget approved. Please proceed."\n\nTone: formal - 6 words.',
      );
    }

    if (text.contains('condition')) {
      return _ChatMessage.agent(
        label: 'OneMail',
        text:
            'With condition:\n\n"Hi Marcus, I approve the Q3 budget subject to the contingency reserve remaining at or below 42k as discussed. Please proceed."',
      );
    }

    if (text.contains('invoice')) {
      return _ChatMessage.agent(
        label: 'OneMail',
        text:
            'Found 3 invoice emails from last week:\n\n1. Acme Corp - Invoice #4421 (18500) - Mar 12\n2. Office Supplies - Inv #209 (340) - Mar 11\n3. AWS - Cloud bill (2140) - Mar 10\n\nShould I export these to a summary?',
      );
    }

    if (text.contains('reminder') || text.contains('remind')) {
      return _ChatMessage.agent(
        label: 'OneMail',
        text:
            'Reminder set for tomorrow at 9am about the Acme Corp follow-up. Want me to draft the follow-up email now?',
      );
    }

    if (text.contains('unsubscribe')) {
      return _ChatMessage.agent(
        label: 'OneMail',
        text:
            'Found 4 newsletter senders:\n\n- TechCrunch Daily\n- Retail Weekly\n- Company newsletter\n- Industry digest\n\nShould I unsubscribe from the first two?',
      );
    }

    if (text.contains('sarah')) {
      return _ChatMessage.agent(
        label: 'OneMail',
        text:
            'Thread with Sarah (Product):\n\nSarah shared the 2026 roadmap deck (14 slides, Mar 17). She requested feedback on the AI features section by Friday. No reply has been sent yet.\n\nWant me to draft a quick acknowledgement?',
      );
    }

    if (text.contains('priorit')) {
      return _ChatMessage.agent(
        label: 'OneMail',
        text:
            'Today\'s priorities:\n\n1. CFO budget reply (5pm deadline)\n2. Roadmap feedback to Sarah (Friday)\n3. Pinned thread: Q3 Budget - 3 new messages',
      );
    }

    return _ChatMessage.agent(label: 'OneMail', text: 'Processing your request. Checking your emails now.');
  }

  String _timeLabel(DateTime dateTime) {
    final TimeOfDay time = TimeOfDay.fromDateTime(dateTime);
    final int hour = time.hourOfPeriod == 0 ? 12 : time.hourOfPeriod;
    final String minute = time.minute.toString().padLeft(2, '0');
    final String period = time.period == DayPeriod.am ? 'AM' : 'PM';
    return '$hour:$minute $period';
  }

  TextStyle _nunito(double size, FontWeight fontWeight, {Color color = _dark, double? letterSpacing, double? height}) {
    return GoogleFonts.nunito(
      fontSize: size,
      fontWeight: fontWeight,
      color: color,
      letterSpacing: letterSpacing,
      height: height,
    );
  }

  TextStyle _nunitoSans(
    double size,
    FontWeight fontWeight, {
    Color color = _dark,
    double? letterSpacing,
    double? height,
  }) {
    return GoogleFonts.nunitoSans(
      fontSize: size,
      fontWeight: fontWeight,
      color: color,
      letterSpacing: letterSpacing,
      height: height,
    );
  }

  List<_MailAccount> _buildAccounts() {
    return [
      _MailAccount(
        name: 'work@company.com',
        timeLabel: '2m',
        preview: 'Budget approval from CFO - urgent',
        hasAiTag: true,
        unreadCount: 7,
        isUrgent: true,
        syncLabel: 'Agent active - synced 2 min ago',
        greeting:
            'Good morning. 7 unread in your work inbox. CFO needs budget approval by 5pm and should be your top priority. Want me to draft a reply?',
        avatar: const _AvatarStyle(text: 'W', background: _yellow, foreground: _dark, online: true),
        subThreads: const [
          _SubThread(
            avatar: 'Q3',
            title: 'Q3 Budget - Finance',
            preview: 'CFO: Can you approve by EOD?',
            pinned: true,
            summary:
                'Thread summary (3 emails):\n\nCFO Marcus sent the Q3 budget on Monday and requested approval by end of day Friday. You replied asking for contingency figures. Marcus confirmed the reserve is 42k today. Ready for your approval.',
          ),
          _SubThread(
            avatar: 'RL',
            title: 'Roadmap 2026 - Product',
            preview: 'Sarah: attached the new deck',
            pinned: true,
            summary:
                'Thread summary (2 emails):\n\nSarah shared the 2026 roadmap deck (14 slides, Mar 17). She requested feedback on the AI features section by Friday. No reply from you yet.',
          ),
        ],
      ),
      _MailAccount(
        name: 'Jhan',
        timeLabel: '15m',
        preview: 'Flight confirmed - no action needed',
        hasAiTag: true,
        unreadCount: 3,
        isUrgent: false,
        syncLabel: 'Agent active - synced 15 min ago',
        greeting:
            'Your personal inbox is calm. Flight to NYC is confirmed. One delivery notification and no urgent items.',
        avatar: const _AvatarStyle(text: 'JA', background: Color(0xFFD1FAE5), foreground: Color(0xFF065F46)),
      ),
      _MailAccount(
        name: 'Karin',
        timeLabel: '1h',
        preview: '2 follow-ups overdue this week',
        hasAiTag: true,
        unreadCount: 12,
        isUrgent: true,
        syncLabel: 'Agent active - synced 1 hour ago',
        greeting:
            '12 unread in your sales inbox. Two follow-ups are overdue this week. Want me to draft both responses?',
        avatar: const _AvatarStyle(text: 'KA', background: Color(0xFFDBEAFE), foreground: Color(0xFF1E40AF)),
      ),
      _MailAccount(
        name: 'Neno',
        timeLabel: '2h',
        preview: 'OK let me check on that for you',
        hasAiTag: false,
        unreadCount: 0,
        isUrgent: false,
        syncLabel: 'Agent active - synced 2 hours ago',
        greeting: 'A few threads to catch up on in your Neno inbox. Nothing urgent. Want a quick summary?',
        avatar: const _AvatarStyle(text: 'NE', background: _yellow, foreground: _dark),
      ),
      _MailAccount(
        name: 'Bond',
        timeLabel: '3h',
        preview: 'Invoice #4421 - awaiting signature',
        hasAiTag: true,
        unreadCount: 2,
        isUrgent: false,
        syncLabel: 'Agent active - synced 3 hours ago',
        greeting: 'Invoice #4421 from Acme Corp is waiting for your signature. I can draft a follow-up if you want.',
        avatar: const _AvatarStyle(text: 'BO', background: Color(0xFFFCE7F3), foreground: Color(0xFF9D174D)),
      ),
      _MailAccount(
        name: 'Jhansen',
        timeLabel: '5h',
        preview: 'Sounds good, see you Thursday',
        hasAiTag: false,
        unreadCount: 0,
        isUrgent: false,
        syncLabel: 'Agent active - synced 5 hours ago',
        greeting: 'Thursday meeting confirmed. Inbox is quiet and no action is needed.',
        avatar: const _AvatarStyle(text: 'JH', background: Color(0xFFFEF3C7), foreground: Color(0xFF92400E)),
      ),
      _MailAccount(
        name: 'Mark',
        timeLabel: 'Yesterday',
        preview: 'Quiet - 2 newsletters, nothing urgent',
        hasAiTag: true,
        unreadCount: 0,
        isUrgent: false,
        syncLabel: 'Agent active - synced yesterday',
        greeting: 'Your Mark inbox is quiet. Two newsletters arrived and neither requires action.',
        avatar: const _AvatarStyle(text: 'MA', background: _yellow, foreground: _dark),
      ),
      _MailAccount(
        name: 'Roy',
        timeLabel: 'Yesterday',
        preview: 'Thanks for the update!',
        hasAiTag: false,
        unreadCount: 0,
        isUrgent: false,
        syncLabel: 'Agent active - synced yesterday',
        greeting: 'Roy sent a quick acknowledgement. Inbox is clear.',
        avatar: const _AvatarStyle(text: 'RO', background: Color(0xFFDBEAFE), foreground: Color(0xFF1E40AF)),
      ),
      _MailAccount(
        name: 'Varid',
        timeLabel: 'Mon',
        preview: 'Contract renewal - review by Friday',
        hasAiTag: true,
        unreadCount: 1,
        isUrgent: false,
        syncLabel: 'Agent active - synced Monday',
        greeting: 'Contract renewal from Varid needs review by Friday. Want a summary of key changes?',
        avatar: const _AvatarStyle(text: 'VA', background: Color(0xFFD1FAE5), foreground: Color(0xFF065F46)),
      ),
    ];
  }
}

class _AvatarStyle {
  final String text;
  final Color background;
  final Color foreground;
  final bool online;

  const _AvatarStyle({required this.text, required this.background, required this.foreground, this.online = false});
}

class _MailAccount {
  final String name;
  final String timeLabel;
  final String preview;
  final bool hasAiTag;
  final int unreadCount;
  final bool isUrgent;
  final String syncLabel;
  final String greeting;
  final _AvatarStyle avatar;
  final List<_SubThread> subThreads;

  const _MailAccount({
    required this.name,
    required this.timeLabel,
    required this.preview,
    required this.hasAiTag,
    required this.unreadCount,
    required this.isUrgent,
    required this.syncLabel,
    required this.greeting,
    required this.avatar,
    this.subThreads = const [],
  });
}

class _SubThread {
  final String avatar;
  final String title;
  final String preview;
  final bool pinned;
  final String summary;

  const _SubThread({
    required this.avatar,
    required this.title,
    required this.preview,
    required this.pinned,
    required this.summary,
  });
}

class _QuickAction {
  final String label;
  final String prompt;

  const _QuickAction({required this.label, required this.prompt});
}

class _BottomNavItem {
  final IconData icon;
  final String label;
  final bool hasDot;

  const _BottomNavItem({required this.icon, required this.label, this.hasDot = false});
}

enum _MessageKind { agent, outgoing }

class _ChatMessage {
  final _MessageKind kind;
  final String label;
  final String text;
  final String? timeLabel;
  final List<_Suggestion> suggestions;

  const _ChatMessage._({
    required this.kind,
    required this.label,
    required this.text,
    this.timeLabel,
    this.suggestions = const [],
  });

  factory _ChatMessage.agent({required String label, required String text, List<_Suggestion> suggestions = const []}) {
    return _ChatMessage._(kind: _MessageKind.agent, label: label, text: text, suggestions: suggestions);
  }

  factory _ChatMessage.outgoing({required String text, required String timeLabel}) {
    return _ChatMessage._(kind: _MessageKind.outgoing, label: '', text: text, timeLabel: timeLabel);
  }
}

class _Suggestion {
  final String label;
  final String prompt;

  const _Suggestion({required this.label, required this.prompt});
}

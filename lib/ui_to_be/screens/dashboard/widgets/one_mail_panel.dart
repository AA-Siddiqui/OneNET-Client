import 'package:flutter/material.dart';

class OneMailPanel extends StatefulWidget {
  final bool isAdmin;

  const OneMailPanel({super.key, required this.isAdmin});

  @override
  State<OneMailPanel> createState() => _OneMailPanelState();
}

class _OneMailPanelState extends State<OneMailPanel> {
  final TextEditingController _searchController = TextEditingController();
  final TextEditingController _replyPromptController =
      TextEditingController(text: 'Keep it short and professional');
  final TextEditingController _draftController = TextEditingController();

  int _activeEmailIndex = 0;
  bool _showSettings = false;

  final TextEditingController _mailboxEmailController =
      TextEditingController(text: 'team@company.com');
  final TextEditingController _imapHostController =
      TextEditingController(text: 'imap.company.com');
  final TextEditingController _imapPortController = TextEditingController(text: '993');
  final TextEditingController _smtpHostController =
      TextEditingController(text: 'smtp.company.com');
  final TextEditingController _smtpPortController = TextEditingController(text: '587');
  final TextEditingController _usernameController =
      TextEditingController(text: 'team@company.com');
  final TextEditingController _passwordController =
      TextEditingController(text: 'app-password');

  final List<_EmailItem> _emails = <_EmailItem>[
    _EmailItem(
      id: '1',
      from: 'marcus.cfo@company.com',
      subject: 'Q3 budget approval by Friday',
      body:
          'Hi team,\n\nPlease review the attached Q3 budget and approve it by Friday EOD.\n\nThanks,\nMarcus',
      date: DateTime(2026, 5, 6, 17, 10),
    ),
    _EmailItem(
      id: '2',
      from: 'sarah.pm@company.com',
      subject: 'Roadmap deck feedback request',
      body:
          'Hello,\n\nI shared the 2026 roadmap deck. Can you send feedback on AI features by Friday?\n\nBest,\nSarah',
      date: DateTime(2026, 5, 6, 14, 35),
    ),
    _EmailItem(
      id: '3',
      from: 'billing@aws.amazon.com',
      subject: 'Invoice available for April',
      body:
          'Your monthly AWS invoice is now available. Total amount due: 2140 USD.\n\nVisit billing dashboard for details.',
      date: DateTime(2026, 5, 5, 9, 22),
    ),
  ];

  @override
  void dispose() {
    _searchController.dispose();
    _replyPromptController.dispose();
    _draftController.dispose();
    _mailboxEmailController.dispose();
    _imapHostController.dispose();
    _imapPortController.dispose();
    _smtpHostController.dispose();
    _smtpPortController.dispose();
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  List<_EmailItem> get _filteredEmails {
    final String query = _searchController.text.trim().toLowerCase();
    if (query.isEmpty) return _emails;
    return _emails
        .where((e) => '${e.subject} ${e.from}'.toLowerCase().contains(query))
        .toList();
  }

  _EmailItem? get _activeEmail {
    final List<_EmailItem> list = _filteredEmails;
    if (list.isEmpty) return null;
    if (_activeEmailIndex >= list.length) return list.first;
    return list[_activeEmailIndex];
  }

  @override
  Widget build(BuildContext context) {
    if (_showSettings) {
      return _buildSettingsView(context);
    }
    return _buildInboxView(context);
  }

  Widget _buildInboxView(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final List<_EmailItem> filtered = _filteredEmails;
    final _EmailItem? active = _activeEmail;

    return Column(
      children: [
        Container(
          height: 56,
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            color: theme.colorScheme.surface,
            border: Border(bottom: BorderSide(color: theme.dividerColor)),
          ),
          child: Row(
            children: [
              const Text('OneMAIL', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
              const SizedBox(width: 12),
              Expanded(
                child: SizedBox(
                  height: 36,
                  child: TextField(
                    controller: _searchController,
                    onChanged: (_) => setState(() => _activeEmailIndex = 0),
                    decoration: const InputDecoration(
                      hintText: 'Search emails',
                      isDense: true,
                      border: OutlineInputBorder(),
                      contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              OutlinedButton.icon(
                onPressed: _fakeSync,
                icon: const Icon(Icons.sync, size: 16),
                label: const Text('Sync'),
              ),
              const SizedBox(width: 8),
              TextButton(
                onPressed: () => setState(() => _showSettings = true),
                child: const Text('Settings'),
              ),
            ],
          ),
        ),
        Expanded(
          child: Row(
            children: [
              Container(
                width: 360,
                decoration: BoxDecoration(border: Border(right: BorderSide(color: theme.dividerColor))),
                child: filtered.isEmpty
                    ? const Center(child: Text('No matching emails'))
                    : ListView.builder(
                        itemCount: filtered.length,
                        itemBuilder: (BuildContext context, int index) {
                          final _EmailItem email = filtered[index];
                          final bool selected = active?.id == email.id;
                          return InkWell(
                            onTap: () => setState(() => _activeEmailIndex = index),
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                              decoration: BoxDecoration(
                                color: selected ? theme.colorScheme.surfaceContainerHighest : Colors.transparent,
                                border: Border(bottom: BorderSide(color: theme.dividerColor)),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(email.subject.isEmpty ? '(no subject)' : email.subject,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(fontWeight: FontWeight.w600)),
                                  const SizedBox(height: 4),
                                  Text(email.from,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: TextStyle(color: theme.colorScheme.onSurfaceVariant, fontSize: 12)),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
              ),
              Expanded(
                child: active == null
                    ? const Center(child: Text('No emails yet. Use sync after mailbox setup.'))
                    : Padding(
                        padding: const EdgeInsets.all(16),
                        child: ListView(
                          children: [
                            Text(active.subject.isEmpty ? '(no subject)' : active.subject,
                                style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w700)),
                            const SizedBox(height: 6),
                            Text(
                              'From ${active.from} at ${_formatDate(active.date)}',
                              style: TextStyle(color: theme.colorScheme.onSurfaceVariant),
                            ),
                            const SizedBox(height: 14),
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                border: Border.all(color: theme.dividerColor),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(active.body),
                            ),
                            const SizedBox(height: 16),
                            TextField(
                              controller: _replyPromptController,
                              decoration: const InputDecoration(
                                labelText: 'Prompt for AI reply',
                                border: OutlineInputBorder(),
                              ),
                            ),
                            const SizedBox(height: 10),
                            Align(
                              alignment: Alignment.centerLeft,
                              child: ElevatedButton(
                                onPressed: _generateDraft,
                                child: const Text('Generate AI draft'),
                              ),
                            ),
                            const SizedBox(height: 10),
                            TextField(
                              controller: _draftController,
                              minLines: 7,
                              maxLines: 12,
                              decoration: const InputDecoration(
                                hintText: 'Reply draft',
                                border: OutlineInputBorder(),
                              ),
                            ),
                            const SizedBox(height: 10),
                            Align(
                              alignment: Alignment.centerLeft,
                              child: ElevatedButton.icon(
                                onPressed: _sendReply,
                                icon: const Icon(Icons.send, size: 16),
                                label: const Text('Send reply'),
                              ),
                            ),
                          ],
                        ),
                      ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSettingsView(BuildContext context) {
    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Row(
            children: [
              TextButton.icon(
                onPressed: () => setState(() => _showSettings = false),
                icon: const Icon(Icons.arrow_back, size: 18),
                label: const Text('Back'),
              ),
              const SizedBox(width: 8),
              const Text('Mailbox settings', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700)),
            ],
          ),
          const SizedBox(height: 16),
          _field('Mailbox email', _mailboxEmailController),
          _field('IMAP host', _imapHostController),
          _field('IMAP port', _imapPortController),
          _field('SMTP host', _smtpHostController),
          _field('SMTP port', _smtpPortController),
          _field('Username', _usernameController),
          _field('Password', _passwordController, obscure: true),
          const SizedBox(height: 12),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              ElevatedButton(onPressed: _saveConnection, child: const Text('Save connection')),
              OutlinedButton(onPressed: _fakeSync, child: const Text('Sync now')),
            ],
          ),
        ],
      ),
    );
  }

  Widget _field(String label, TextEditingController controller, {bool obscure = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: TextField(
        controller: controller,
        obscureText: obscure,
        decoration: InputDecoration(labelText: label, border: const OutlineInputBorder()),
      ),
    );
  }

  void _saveConnection() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Mailbox connected (UI demo only)')),
    );
  }

  void _fakeSync() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Sync complete. Ingested 3 messages (UI demo only)')),
    );
  }

  void _generateDraft() {
    final _EmailItem? active = _activeEmail;
    if (active == null) return;
    setState(() {
      _draftController.text =
          'Hi,\n\nThanks for your email about "${active.subject}". '
          'I have reviewed it and will follow up shortly.\n\nBest regards,\nTeam';
    });
  }

  void _sendReply() {
    if (_draftController.text.trim().isEmpty) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Reply sent (UI demo only)')),
    );
  }

  String _formatDate(DateTime date) {
    String two(int v) => v.toString().padLeft(2, '0');
    return '${date.year}-${two(date.month)}-${two(date.day)} ${two(date.hour)}:${two(date.minute)}';
  }
}

class _EmailItem {
  final String id;
  final String from;
  final String subject;
  final String body;
  final DateTime date;

  const _EmailItem({
    required this.id,
    required this.from,
    required this.subject,
    required this.body,
    required this.date,
  });
}

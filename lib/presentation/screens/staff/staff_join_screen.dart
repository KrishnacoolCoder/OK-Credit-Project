import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme.dart';
import '../../../services/invite_service.dart';
import '../../../core/context_extensions.dart';

class StaffJoinScreen extends ConsumerStatefulWidget {
  final String token;
  const StaffJoinScreen({super.key, required this.token});

  @override
  ConsumerState<StaffJoinScreen> createState() => _StaffJoinScreenState();
}

class _StaffJoinScreenState extends ConsumerState<StaffJoinScreen> {
  bool _loading = true;
  Map<String, String>? _invite;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    _invite = await InviteService.validateToken(widget.token);
    if (mounted) setState(() => _loading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Join staff')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _invite == null
              ? const Center(child: Text('Invalid or expired invite link'))
              : Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text('Join ${_invite!['shopId']}', style: AppTextStyles.h2),
                    const SizedBox(height: 12),
                    Text('Staff member: ${_invite!['staffName']}', style: AppTextStyles.body),
                    const SizedBox(height: 12),
                    Text('This pilot uses a dedicated join link instead of signup. Tap below to continue to staff login.', style: AppTextStyles.caption),
                    const SizedBox(height: 24),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () {
                          context.go('/login');
                          context.showSnack('Use the staff username/password given by the shop owner');
                        },
                        child: const Text('Continue'),
                      ),
                    ),
                  ]),
                ),
    );
  }
}

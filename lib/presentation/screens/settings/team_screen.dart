import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme.dart';
import '../../../core/context_extensions.dart';
import '../../../domain/entities/app_user.dart';
import '../../providers/providers.dart';

class TeamScreen extends ConsumerStatefulWidget {
  const TeamScreen({super.key});

  @override
  ConsumerState<TeamScreen> createState() => _TeamScreenState();
}

class _TeamScreenState extends ConsumerState<TeamScreen> {
  bool _loading = false;

  void _addStaff() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
        child: _AddStaffSheet(
          onInviteCreated: () {
            ref.invalidate(usersProvider);
          },
        ),
      ),
    );
  }

  Future<void> _removeStaff(AppUser user) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Remove Staff'),
        content: Text('Are you sure you want to remove ${user.name} from your shop? They will lose access immediately.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Remove', style: TextStyle(color: AppColors.error)),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    setState(() => _loading = true);
    try {
      await ref.read(authServiceProvider).removeUser(user.id);
      ref.invalidate(usersProvider);
      if (mounted) context.showSnack('${user.name} removed');
    } catch (e) {
      if (mounted) context.showSnack('Failed to remove staff', isError: true);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final me = ref.watch(currentUserProvider);
    final usersAsync = ref.watch(usersProvider);

    if (me == null) return const Scaffold(body: Center(child: CircularProgressIndicator()));

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Team & Staff'),
        leading: BackButton(onPressed: () => context.pop()),
      ),
      floatingActionButton: me.isAdmin
          ? FloatingActionButton.extended(
              onPressed: _loading ? null : _addStaff,
              backgroundColor: AppColors.saffron,
              foregroundColor: Colors.white,
              icon: const Icon(Icons.person_add_alt_1_rounded),
              label: const Text('Add Staff'),
            )
          : null,
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : usersAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (err, _) => Center(child: Text('Error loading team: $err')),
              data: (users) {
                if (users.isEmpty) {
                  return const Center(child: Text('No team members found'));
                }
                return ListView.separated(
                  padding: const EdgeInsets.all(20),
                  itemCount: users.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 12),
                  itemBuilder: (context, index) {
                    final user = users[index];
                    final isMe = user.id == me.id;
                    return Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        borderRadius: BorderRadius.circular(AppRadius.lg),
                        border: Border.all(color: AppColors.borderLight),
                        boxShadow: AppShadows.sm,
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 48, height: 48,
                            decoration: BoxDecoration(
                              color: user.isAdmin ? AppColors.saffronLight : AppColors.surfaceTinted,
                              shape: BoxShape.circle,
                            ),
                            child: Center(
                              child: Text(
                                user.name.isNotEmpty ? user.name[0].toUpperCase() : '?',
                                style: TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.w700,
                                  color: user.isAdmin ? AppColors.saffron : AppColors.text3,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Text(
                                      isMe ? '${user.name} (You)' : user.name,
                                      style: AppTextStyles.bodyMd.copyWith(fontWeight: FontWeight.w600),
                                    ),
                                    if (user.isAdmin) ...[
                                      const SizedBox(width: 8),
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                        decoration: BoxDecoration(
                                          color: AppColors.saffronLight,
                                          borderRadius: BorderRadius.circular(4),
                                        ),
                                        child: Text(
                                          'Owner',
                                          style: AppTextStyles.caption.copyWith(
                                            fontSize: 10,
                                            color: AppColors.saffron,
                                            fontWeight: FontWeight.w700,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  user.username.isNotEmpty ? user.username : 'No contact info',
                                  style: AppTextStyles.caption.copyWith(color: AppColors.text3),
                                ),
                              ],
                            ),
                          ),
                          if (me.isAdmin && !user.isAdmin)
                            IconButton(
                              icon: const Icon(Icons.remove_circle_outline_rounded, color: AppColors.error),
                              tooltip: 'Remove Staff',
                              onPressed: () => _removeStaff(user),
                            ),
                        ],
                      ),
                    );
                  },
                );
              },
            ),
    );
  }
}

class _AddStaffSheet extends ConsumerStatefulWidget {
  final VoidCallback onInviteCreated;
  const _AddStaffSheet({required this.onInviteCreated});

  @override
  ConsumerState<_AddStaffSheet> createState() => _AddStaffSheetState();
}

class _AddStaffSheetState extends ConsumerState<_AddStaffSheet> {
  final _nameCtrl = TextEditingController();
  bool _loading = false;
  String? _inviteCode;

  @override
  void dispose() {
    _nameCtrl.dispose();
    super.dispose();
  }

  Future<void> _createInvite() async {
    final name = _nameCtrl.text.trim();
    if (name.isEmpty) return;

    setState(() => _loading = true);
    try {
      final code = await ref.read(authServiceProvider).createInvite(name: name, canEdit: true);
      if (mounted) {
        setState(() {
          _inviteCode = code;
          _loading = false;
        });
        widget.onInviteCreated();
      }
    } catch (e) {
      if (mounted) {
        setState(() => _loading = false);
        context.showSnack('Failed to create invite: $e', isError: true);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: const BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(_inviteCode == null ? 'Add Staff' : 'Invite Code Created', style: AppTextStyles.h3),
              IconButton(
                icon: const Icon(Icons.close_rounded),
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),
          const SizedBox(height: 16),
          
          if (_inviteCode == null) ...[
            Text('Staff Name', style: AppTextStyles.labelCaps),
            const SizedBox(height: 8),
            TextField(
              controller: _nameCtrl,
              textCapitalization: TextCapitalization.words,
              decoration: const InputDecoration(
                hintText: 'e.g. Ramesh',
              ),
              autofocus: true,
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                onPressed: _loading ? null : _createInvite,
                child: _loading 
                    ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                    : const Text('Generate Invite Code'),
              ),
            ),
          ] else ...[
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: AppColors.successBg,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.success.withValues(alpha: 0.3)),
              ),
              child: Column(
                children: [
                  const Text('Give this code to your staff member:', style: AppTextStyles.body),
                  const SizedBox(height: 16),
                  Text(
                    _inviteCode!,
                    style: const TextStyle(
                      fontSize: 40,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 4,
                      color: AppColors.success,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              '1. They download the app and tap "Join as staff"\n2. They sign in with Google\n3. They enter this 6-character code',
              style: AppTextStyles.bodySm,
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                onPressed: () {
                  Clipboard.setData(ClipboardData(text: _inviteCode!));
                  context.showSnack('Invite code copied to clipboard');
                  Navigator.pop(context);
                },
                child: const Text('Copy Code & Close'),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

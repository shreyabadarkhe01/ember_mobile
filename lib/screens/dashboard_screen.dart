import 'package:flutter/material.dart';
import '../models/habit.dart';
import '../models/checkin.dart';
import '../services/auth_service.dart';
import '../services/habit_service.dart';
import '../services/checkin_service.dart';
import 'edit_habit_screen.dart';
import '../services/api_client.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  int? _userId;
  CheckIn? _todayCheckin;
  List<Habit> _habits = [];
  bool _loading = true;
  bool _checkingIn = false;
  int _selectedEnergy = 3;

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
  _userId = await AuthService.getUserId();
  print('=== userId: $_userId ===');
  if (_userId == null) {
    // Token exists but userId missing — force logout and re-login
    if (mounted) Navigator.pushReplacementNamed(context, '/login');
    return;
  }
  await _loadData();
  }

  Future<void> _loadData() async {
    if (_userId == null) return;
    setState(() => _loading = true);

    final checkin = await CheckInService.getTodayCheckin(_userId!);
    final habits = await HabitService.getHabits(_userId!);

  
    habits.sort((a, b) {
      final aArchived = a.status == 'ARCHIVED' ? 1 : 0;
      final bArchived = b.status == 'ARCHIVED' ? 1 : 0;
      return aArchived.compareTo(bArchived);
    });

    setState(() {
      _todayCheckin = checkin;
      _habits = habits;
      _loading = false;
    });
  }

  Future<void> _submitCheckin() async {
    if (_userId == null) return;
    setState(() => _checkingIn = true);

    final checkin = await CheckInService.createCheckin(_userId!, _selectedEnergy);

    setState(() {
      _checkingIn = false;
      if (checkin != null) _todayCheckin = checkin;
    });

    await _loadData();
  }

  void _showArchiveDialog(BuildContext context, Habit habit) {
  
  final isArchived = habit.status == 'ARCHIVED';
  showDialog(
    context: context,
    builder: (_) => AlertDialog(
      backgroundColor: const Color(0xFF1E1E1E),
      title: Text(
        isArchived ? 'Unarchive habit?' : 'Archive habit?',
        style: const TextStyle(color: Colors.white),
      ),
      content: Text(
        isArchived
            ? '"${habit.name}" will move back to your active habits.'
            : '"${habit.name}" will be moved to the bottom and hidden from your daily flow.',
        style: const TextStyle(color: Colors.white70),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel', style: TextStyle(color: Colors.white54)),
        ),
        TextButton(
          onPressed: () async {
            Navigator.pop(context);
            try {
              if (isArchived) {
                await HabitService.unarchiveHabit(_userId!, habit.id);
              } else {
                await HabitService.archiveHabit(_userId!, habit.id);
              }
              await _loadData(); // your existing refresh method
            } catch (e) {
              if (mounted) {
                print('Archive error: $e');
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Failed: $e')),
                );
              }
            }
          },
          child: Text(
            isArchived ? 'Unarchive' : 'Archive',
            style: TextStyle(
              color: isArchived ? Colors.orange : Colors.redAccent,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ],
    ),
  );
}

  Future<void> _showPostDoneDialog(Habit habit) async {
  double _selectedRatio = 1.0;
  String _selectedFeeling = 'NEUTRAL';

  await showDialog(
    context: context,
    barrierDismissible: false,
    builder: (context) {
      return StatefulBuilder(
        builder: (context, setDialogState) {
          return Dialog(
            backgroundColor: const Color(0xFF1A1A1A),
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16)),
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          '✓ ${habit.name}',
                          style: const TextStyle(
                              color: Color(0xFF66BB6A),
                              fontSize: 16,
                              fontWeight: FontWeight.bold),
                        ),
                      ),
                      GestureDetector(
                        onTap: () => Navigator.pop(context),
                        child: const Icon(Icons.close,
                            color: Color(0xFF888888), size: 20),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'Quick check — takes 5 seconds',
                    style: TextStyle(
                        color: Color(0xFF888888), fontSize: 12),
                  ),
                  const SizedBox(height: 20),

                  // How much did you complete
                  const Text(
                    'How much did you complete?',
                    style: TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 10),
                  ...[
                    _CompletionOption(
                        emoji: '🌓',
                        label: 'Partial',
                        subtitle: 'Got through some of it',
                        ratio: 0.25),
                    _CompletionOption(
                        emoji: '⚡',
                        label: '~75%',
                        subtitle: 'Most of it done',
                        ratio: 0.75),
                    _CompletionOption(
                        emoji: '✅',
                        label: 'Full',
                        subtitle: 'Completed as planned',
                        ratio: 1.0),
                    _CompletionOption(
                        emoji: '🔥',
                        label: 'Went beyond',
                        subtitle: 'Exceeded the version',
                        ratio: 1.25),
                  ].map((opt) {
                    final selected = _selectedRatio == opt.ratio;
                    return GestureDetector(
                      onTap: () =>
                          setDialogState(() => _selectedRatio = opt.ratio),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 150),
                        margin: const EdgeInsets.only(bottom: 8),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 12),
                        decoration: BoxDecoration(
                          color: selected
                              ? const Color(0xFF2A3A2A)
                              : const Color(0xFF252525),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: selected
                                ? const Color(0xFF4CAF50)
                                : const Color(0xFF333333),
                          ),
                        ),
                        child: Row(
                          children: [
                            Text(opt.emoji,
                                style: const TextStyle(fontSize: 16)),
                            const SizedBox(width: 10),
                            Text(opt.label,
                                style: TextStyle(
                                    color: selected
                                        ? const Color(0xFF66BB6A)
                                        : Colors.white,
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600)),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(opt.subtitle,
                                  style: const TextStyle(
                                      color: Color(0xFF888888),
                                      fontSize: 12)),
                            ),
                          ],
                        ),
                      ),
                    );
                  }).toList(),
                  const SizedBox(height: 16),

                  // How did it feel
                  const Text(
                    'How did it feel?',
                    style: TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      _FeelingOption(
                          emoji: '🤢',
                          label: 'Drained',
                          tag: 'DRAINED'),
                      _FeelingOption(
                          emoji: '⚡',
                          label: 'Just right',
                          tag: 'NEUTRAL'),
                      _FeelingOption(
                          emoji: '🔥',
                          label: 'Energised',
                          tag: 'ENERGISED'),
                    ].map((opt) {
                      final selected = _selectedFeeling == opt.tag;
                      return Expanded(
                        child: GestureDetector(
                          onTap: () => setDialogState(
                              () => _selectedFeeling = opt.tag),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 150),
                            margin: const EdgeInsets.only(right: 8),
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            decoration: BoxDecoration(
                              color: selected
                                  ? const Color(0xFF2A2A3A)
                                  : const Color(0xFF252525),
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(
                                color: selected
                                    ? const Color(0xFFFF6B35)
                                    : const Color(0xFF333333),
                              ),
                            ),
                            child: Column(
                              children: [
                                Text(opt.emoji,
                                    style: const TextStyle(fontSize: 20)),
                                const SizedBox(height: 4),
                                Text(opt.label,
                                    style: TextStyle(
                                        color: selected
                                            ? const Color(0xFFFF6B35)
                                            : const Color(0xFF888888),
                                        fontSize: 11)),
                              ],
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 20),

                  // Buttons
                  Row(
                    children: [
                      OutlinedButton(
                        onPressed: () => Navigator.pop(context),
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(color: Color(0xFF333333)),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 20, vertical: 12),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8)),
                        ),
                        child: const Text('Skip',
                            style: TextStyle(
                                color: Color(0xFF888888), fontSize: 13)),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () async {
                            Navigator.pop(context);
                            await ApiClient.patch(
                              '/users/$_userId/habits/${habit.id}/log-completion',
                              {
                                'completionRatio': _selectedRatio,
                                'feelingTag': _selectedFeeling,
                              },
                            );
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFFBF6E1A),
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8)),
                          ),
                          child: const Text('Log it →',
                              style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600)),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          );
        },
      );
    },
  );
}

 Future<void> _completeHabit(Habit habit) async {
  setState(() {
    _habits = _habits.map((h) {
      if (h.id == habit.id) {
        return Habit(
          id: h.id,
          name: h.name,
          minimalVersion: h.minimalVersion,
          liteVersion: h.liteVersion,
          fullVersion: h.fullVersion,
          status: 'DONE',
          streakCount: h.streakCount + 1,
        );
      }
      return h;
    }).toList();
  });
  await HabitService.completeHabit(_userId!, habit.id);
  await _showPostDoneDialog(habit); // show dialog after marking done
}

Future<void> _skipHabit(Habit habit) async {
  setState(() {
    _habits = _habits.map((h) {
      if (h.id == habit.id) {
        return Habit(
          id: h.id,
          name: h.name,
          minimalVersion: h.minimalVersion,
          liteVersion: h.liteVersion,
          fullVersion: h.fullVersion,
          status: 'SKIPPED',
          streakCount: h.streakCount,
        );
      }
      return h;
    }).toList();
  });
  await HabitService.skipHabit(_userId!, habit.id);
}

Future<void> _resetHabit(Habit habit) async {
  setState(() {
    _habits = _habits.map((h) {
      if (h.id == habit.id) {
        return Habit(
          id: h.id,
          name: h.name,
          minimalVersion: h.minimalVersion,
          liteVersion: h.liteVersion,
          fullVersion: h.fullVersion,
          status: 'ACTIVE',
          streakCount: h.status == 'DONE' ? h.streakCount - 1 : h.streakCount,
        );
      }
      return h;
    }).toList();
  });
  await HabitService.resetHabit(_userId!, habit.id);
}

  Future<void> _logout() async {
    await AuthService.logout();
    if (mounted) Navigator.pushReplacementNamed(context, '/login');
  }

  String _energyEmoji(int score) {
    switch (score) {
      case 1: return '😴';
      case 2: return '😓';
      case 3: return '😐';
      case 4: return '⚡';
      case 5: return '🔥';
      default: return '😐';
    }
  }

  String _energyLabel(int score) {
    switch (score) {
      case 1: return 'Exhausted';
      case 2: return 'Low';
      case 3: return 'Okay';
      case 4: return 'Good';
      case 5: return 'Amazing';
      default: return 'Okay';
    }
  }

  String _habitVersion(Habit habit, int energy) {
    if (energy <= 2) return habit.minimalVersion;
    if (energy == 3) return habit.liteVersion;
    return habit.fullVersion;
  }

  String _versionLabel(int energy) {
    if (energy <= 2) return '😴 Minimal';
    if (energy == 3) return '⚡ Lite';
    return '🔥 Full';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F0F0F),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0F0F0F),
        elevation: 0,
        title: const Text(
          '🔥 Ember',
          style: TextStyle(
              color: Colors.white, fontWeight: FontWeight.bold, fontSize: 20),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout, color: Color(0xFF888888)),
            onPressed: _logout,
          )
        ],
      ),
      body: _loading
          ? const Center(
              child: CircularProgressIndicator(color: Color(0xFFFF6B35)))
          : RefreshIndicator(
              color: const Color(0xFFFF6B35),
              backgroundColor: const Color(0xFF1A1A1A),
              onRefresh: _loadData,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildCheckinSection(),
                    const SizedBox(height: 28),
                    _buildHabitList(),
                  ],
                ),
              ),
            ),
    
    floatingActionButton: FloatingActionButton(
  backgroundColor: const Color(0xFFFF6B35),
  onPressed: () async {
    final result = await Navigator.pushNamed(context, '/add-habit');
    if (result == true) await _loadData(); // refresh on return
  },
  child: const Icon(Icons.add, color: Colors.white),
),
);
  }

  Widget _buildCheckinSection() {
    if (_todayCheckin != null) {
      // Already checked in
      return Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: const Color(0xFF1A1A1A),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: const Color(0xFF2A2A2A)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  _energyEmoji(_todayCheckin!.energyScore),
                  style: const TextStyle(fontSize: 28),
                ),
                const SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text("Today's energy",
                        style: TextStyle(
                            color: Color(0xFF888888), fontSize: 12)),
                    Text(
                      _energyLabel(_todayCheckin!.energyScore),
                      style: const TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
                const Spacer(),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFF6B35).withOpacity(0.15),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    _versionLabel(_todayCheckin!.energyScore),
                    style: const TextStyle(
                        color: Color(0xFFFF6B35), fontSize: 12),
                  ),
                ),
              ],
            ),
            if (_todayCheckin!.nudgeText != null) ...[
              const SizedBox(height: 14),
              const Divider(color: Color(0xFF2A2A2A)),
              const SizedBox(height: 10),
              Text(
                _todayCheckin!.nudgeText!,
                style: const TextStyle(
                    color: Color(0xFFCCCCCC),
                    fontSize: 13,
                    height: 1.5),
              ),
            ],
          ],
        ),
      );
    }

    // Not checked in yet
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A1A),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFF2A2A2A)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'How are you feeling today?',
            style: TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 18),

          // Energy selector
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: List.generate(5, (i) {
              final score = i + 1;
              final selected = score == _selectedEnergy;
              return GestureDetector(
                onTap: () => setState(() => _selectedEnergy = score),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 150),
                  width: 52,
                  height: 60,
                  decoration: BoxDecoration(
                    color: selected
                        ? const Color(0xFFFF6B35).withOpacity(0.2)
                        : const Color(0xFF252525),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: selected
                          ? const Color(0xFFFF6B35)
                          : const Color(0xFF333333),
                      width: selected ? 2 : 1,
                    ),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(_energyEmoji(score),
                          style: const TextStyle(fontSize: 20)),
                      const SizedBox(height: 2),
                      Text('$score',
                          style: TextStyle(
                              color: selected
                                  ? const Color(0xFFFF6B35)
                                  : const Color(0xFF888888),
                              fontSize: 12,
                              fontWeight: FontWeight.w600)),
                    ],
                  ),
                ),
              );
            }),
          ),
          const SizedBox(height: 8),
          Center(
            child: Text(
              _energyLabel(_selectedEnergy),
              style: const TextStyle(
                  color: Color(0xFF888888), fontSize: 13),
            ),
          ),
          const SizedBox(height: 18),

          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _checkingIn ? null : _submitCheckin,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFFF6B35),
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10)),
              ),
              child: _checkingIn
                  ? const SizedBox(
                      height: 18,
                      width: 18,
                      child: CircularProgressIndicator(
                          color: Colors.white, strokeWidth: 2))
                  : const Text('Check in',
                      style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: Colors.white)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHabitList() {
    final energy = _todayCheckin?.energyScore ?? 3;
    final activeHabits =
        _habits.where((h) => h.status == 'ACTIVE').toList();
    final doneHabits =
        _habits.where((h) => h.status == 'DONE').toList();
    final skippedHabits =
        _habits.where((h) => h.status == 'SKIPPED').toList();
    final archivedHabits =
        _habits.where((h) => h.status == 'ARCHIVED').toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Habits',
          style: TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 14),
        if (_habits.isEmpty)
          const Center(
            child: Padding(
              padding: EdgeInsets.symmetric(vertical: 40),
              child: Text(
                'No habits yet.\nAdd some on the web app!',
                textAlign: TextAlign.center,
                style: TextStyle(color: Color(0xFF555555), fontSize: 14),
              ),
            ),
          ),
        ...activeHabits.map((h) => _buildHabitCard(h, energy)),
        ...doneHabits.map((h) => _buildHabitCard(h, energy)),
        ...skippedHabits.map((h) => _buildHabitCard(h, energy)),
        ...archivedHabits.map((h) => _buildHabitCard(h, energy)),
      ],
    );
  }

  Widget _buildHabitCard(Habit habit, int energy) {
    final isDone = habit.status == 'DONE';
    final isSkipped = habit.status == 'SKIPPED';
    final isActive = habit.status == 'ACTIVE';
    final isArchived = habit.status == 'ARCHIVED';
    final version = _habitVersion(habit, energy);

  
    return GestureDetector(
    onLongPress: () => _showArchiveDialog(context, habit),
    child: Opacity(
      opacity: isArchived ? 0.45 : 1.0,
      child : Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDone
            ? const Color(0xFF1A2A1A)
            : isSkipped
                ? const Color(0xFF1A1A1A)
                : const Color(0xFF1A1A1A),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isDone
              ? const Color(0xFF2A5A2A)
              : isSkipped
                  ? const Color(0xFF333333)
                  : const Color(0xFF2A2A2A),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
  children: [
    Expanded(
      child: Text(
        habit.name,
        style: TextStyle(
          color: isDone
              ? const Color(0xFF66BB6A)
              : isSkipped
                  ? const Color(0xFF555555)
                  : Colors.white,
          fontSize: 15,
          fontWeight: FontWeight.w600,
          decoration: isSkipped
              ? TextDecoration.lineThrough
              : TextDecoration.none,
        ),
      ),
    ),
    if (habit.streakCount > 0)
      Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        decoration: BoxDecoration(
          color: const Color(0xFFFF6B35).withOpacity(0.15),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          '🔥 ${habit.streakCount}',
          style: const TextStyle(color: Color(0xFFFF6B35), fontSize: 11),
        ),
      ),
    const SizedBox(width: 8),
    GestureDetector(
      onTap: () async {
        final result = await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => EditHabitScreen(habit: habit),
          ),
        );
        if (result == true) await _loadData();
      },
      child: const Icon(Icons.edit_outlined,
          color: Color(0xFF555555), size: 18),
    ),
  ],
),
          const SizedBox(height: 6),
          Text(
            version,
            style: TextStyle(
              color: isDone
                  ? const Color(0xFF4CAF50).withOpacity(0.8)
                  : isSkipped
                      ? const Color(0xFF444444)
                      : const Color(0xFF888888),
              fontSize: 13,
              height: 1.4,
            ),
          ),
          if (isActive) ...[
            const SizedBox(height: 14),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => _skipHabit(habit),
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: Color(0xFF333333)),
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8)),
                    ),
                    child: const Text('Skip',
                        style: TextStyle(
                            color: Color(0xFF888888), fontSize: 13)),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  flex: 2,
                  child: ElevatedButton(
                    onPressed: () => _completeHabit(habit),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF2A5A2A),
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8)),
                    ),
                    child: const Text('Done ✓',
                        style: TextStyle(
                            color: Color(0xFF66BB6A), fontSize: 13)),
                  ),
                ),
              ],
            ),
          ],
          if (isDone || isSkipped) ...[
            const SizedBox(height: 10),
            GestureDetector(
              onTap: () => _resetHabit(habit),
              child: Text(
                'Undo',
                style: TextStyle(
                    color: const Color(0xFF555555),
                    fontSize: 12,
                    decoration: TextDecoration.underline,
                    decorationColor: const Color(0xFF555555)),
              ),
            ),
          ],
        ],
      ),
    ),
    ),
    );
  }

}
class _CompletionOption {
  final String emoji;
  final String label;
  final String subtitle;
  final double ratio;
  const _CompletionOption(
      {required this.emoji,
      required this.label,
      required this.subtitle,
      required this.ratio});
}

class _FeelingOption {
  final String emoji;
  final String label;
  final String tag;
  const _FeelingOption(
      {required this.emoji, required this.label, required this.tag});
}
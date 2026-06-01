import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../services/autopsy_service.dart';

class AutopsyScreen extends StatefulWidget {
  final int userId;
  const AutopsyScreen({super.key, required this.userId});

  @override
  State<AutopsyScreen> createState() => _AutopsyScreenState();
}

class _AutopsyScreenState extends State<AutopsyScreen> {
  Map<String, dynamic>? _data;
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final data = await AutopsyService.getAutopsy(widget.userId);
      setState(() { _data = data; _loading = false; });
    } catch (e) {
      setState(() { _error = e.toString(); _loading = false; });
    }
  }

  String _formatDateArray(dynamic raw) {
  if (raw is List && raw.length >= 3) {
    final month = raw[1].toString().padLeft(2, '0');
    final day = raw[2].toString().padLeft(2, '0');
    // return '${raw[0]}/$month/$day';
    return '$month/$day/${raw[0]}';
  }
  return raw.toString();
}

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0D0D0D),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0D0D0D),
        title: const Text('Weekly Autopsy',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: Color(0xFFFF6B35)))
          : _error != null
              ? Center(child: Text(_error!, style: const TextStyle(color: Colors.redAccent)))
              : _buildBody(),
    );
  }

  Widget _buildBody() {
    final d = _data!;
    final energyByDay = (d['energyByDay'] as List?) ?? [];
    final patterns = (d['patterns'] as List?)?.cast<String>() ?? [];
    final habitSummaries = (d['habitSummaries'] as List?) ?? [];

    final dividerIndex = patterns.indexOf('__DIVIDER__');
    final habitPatterns = dividerIndex >= 0 ? patterns.sublist(0, dividerIndex) : patterns;
    final energyPatterns = dividerIndex >= 0 ? patterns.sublist(dividerIndex + 1) : [];

    return RefreshIndicator(
      onRefresh: _load,
      color: const Color(0xFFFF6B35),
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(d),
            const SizedBox(height: 24),
            _buildBarChart(energyByDay),
            const SizedBox(height: 24),
            _buildStatsRow(d),
            const SizedBox(height: 24),
            if (habitPatterns.isNotEmpty) ...[
              _buildSectionTitle('Habit Patterns'),
              const SizedBox(height: 10),
              ...habitPatterns.map((p) => _buildPatternTile(p)),
              const SizedBox(height: 24),
            ],
            if (energyPatterns.isNotEmpty) ...[
              _buildSectionTitle('Energy Patterns'),
              const SizedBox(height: 10),
              ...energyPatterns.map((p) => _buildPatternTile(p)),
              const SizedBox(height: 24),
            ],
            if (habitSummaries.isNotEmpty) ...[
              _buildSectionTitle('Habit Performance'),
              const SizedBox(height: 10),
              ...habitSummaries.map((h) => _buildHabitSummaryCard(h)),
              const SizedBox(height: 24),
            ],
            _buildCorrelations(d),
            const SizedBox(height: 24),
            _buildAiInsight(d['aiInsight']),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(Map<String, dynamic> d) {
  return Row(
    mainAxisAlignment: MainAxisAlignment.spaceBetween,
    children: [
      Expanded(                          // ← added this for spacing
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              d['weekSummary'] ?? '',
              style: const TextStyle(
                  color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
              softWrap: true,            // ← added this
            ),
            const SizedBox(height: 4),
            Text(
              _formatDateArray(d['weekStart']) + ' → ' + _formatDateArray(d['weekEnd']),
              style: const TextStyle(color: Color(0xFF666666), fontSize: 12),
            ),
          ],
        ),
      ),                                 // ← closes Expanded
      const SizedBox(width: 12),        // ← add breathing room
      Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: const Color(0xFFFF6B35).withOpacity(0.15),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: const Color(0xFFFF6B35).withOpacity(0.3)),
        ),
        child: Text(
          'avg ${d['avgEnergyScore']} ⚡',
          style: const TextStyle(
              color: Color(0xFFFF6B35),
              fontWeight: FontWeight.bold,
              fontSize: 14),
        ),
      ),
    ],
  );
}

  Widget _buildBarChart(List energyByDay) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle('Energy This Week'),
        const SizedBox(height: 14),
        SizedBox(
          height: 180,
          child: BarChart(
            BarChartData(
              maxY: 5,
              minY: 0,
              gridData: FlGridData(
                show: true,
                drawVerticalLine: false,
                horizontalInterval: 1,
                getDrawingHorizontalLine: (_) => FlLine(
                  color: const Color(0xFF222222),
                  strokeWidth: 1,
                ),
              ),
              borderData: FlBorderData(show: false),
              titlesData: FlTitlesData(
                leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                bottomTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    getTitlesWidget: (value, _) {
                      final idx = value.toInt();
                      if (idx < 0 || idx >= energyByDay.length) return const SizedBox();
                      final day = energyByDay[idx];
                      final name = (day['dayName'] as String?) ?? '';
                      return Padding(
                        padding: const EdgeInsets.only(top: 6),
                        child: Text(
                          name.length >= 3 ? name.substring(0, 3) : name,
                          style: const TextStyle(color: Color(0xFF666666), fontSize: 11),
                        ),
                      );
                    },
                  ),
                ),
              ),
              barGroups: energyByDay.asMap().entries.map((entry) {
                final idx = entry.key;
                final day = entry.value;
                final score = (day['energyScore'] as num?)?.toDouble() ?? 0;
                final checkedIn = day['checkedIn'] == true;
                return BarChartGroupData(
                  x: idx,
                  barRods: [
                    BarChartRodData(
                      toY: checkedIn ? score : 0.3,
                      color: checkedIn ? _barColor(score) : const Color(0xFF2A2A2A),
                      width: 28,
                      borderRadius: const BorderRadius.vertical(top: Radius.circular(6)),
                    ),
                  ],
                );
              }).toList(),
              barTouchData: BarTouchData(
                touchTooltipData: BarTouchTooltipData(
                  getTooltipColor: (_) => Colors.transparent,
                ),
                touchCallback: (event, response) {
                  if (event is FlTapUpEvent &&
                      response?.spot != null) {
                    final idx = response!.spot!.touchedBarGroupIndex;
                    if (idx >= 0 && idx < energyByDay.length) {
                      _showDayBottomSheet(energyByDay[idx]);
                    }
                  }
                },
              ),
            ),
          ),
        ),
        const SizedBox(height: 8),
        const Center(
          child: Text('Tap a bar for details',
              style: TextStyle(color: Color(0xFF444444), fontSize: 11)),
        ),
      ],
    );
  }

  Color _barColor(double score) {
    if (score >= 4) return const Color(0xFF66BB6A);
    if (score >= 3) return const Color(0xFFFF6B35);
    return const Color(0xFFE57373);
  }

  void _showDayBottomSheet(Map<String, dynamic> day) {
    final checkedIn = day['checkedIn'] == true;
    final habitsDone = (day['habitsDone'] as List?)?.cast<String>() ?? [];

    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF1A1A1A),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => Padding(
        padding: const EdgeInsets.fromLTRB(24, 20, 24, 36),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  day['dayName'] ?? '',
                  style: const TextStyle(
                      color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                ),
                if (checkedIn)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: _barColor((day['energyScore'] as num?)?.toDouble() ?? 0)
                          .withOpacity(0.15),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      'Energy ${day['energyScore']}',
                      style: TextStyle(
                          color: _barColor((day['energyScore'] as num?)?.toDouble() ?? 0),
                          fontWeight: FontWeight.bold),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 16),
            if (!checkedIn)
              const Text('No check-in on this day',
                  style: TextStyle(color: Color(0xFF666666)))
            else ...[
              _buildSheetRow('😴 Sleep', day['sleepHours'] != null ? '${day['sleepHours']}h' : '—'),
              _buildSheetRow('❤️ Resting HR', day['restingHeartRate'] != null ? '${day['restingHeartRate']} bpm' : '—'),
              _buildSheetRow('👟 Steps', day['steps'] != null ? '${day['steps']}' : '—'),
              _buildSheetRow('✅ Habits done', habitsDone.isEmpty ? '—' : habitsDone.join(', ')),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildSheetRow(String label, String value) {
  return Padding(
    padding: const EdgeInsets.only(bottom: 10),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 130,
          child: Text(label,
              style: const TextStyle(color: Color(0xFF888888), fontSize: 14)),
        ),
        Expanded(
          child: Text(value,
              style: const TextStyle(color: Colors.white, fontSize: 14),
              textAlign: TextAlign.right),
        ),
      ],
    ),
  );
}

  Widget _buildStatsRow(Map<String, dynamic> d) {
    return Row(
      children: [
        _buildStatCard('Consistency', '${d['consistencyScore']}%', const Color(0xFF64B5F6)),
        const SizedBox(width: 10),
        _buildStatCard('Completion', '${d['habitCompletionRate']}%', const Color(0xFF66BB6A)),
        const SizedBox(width: 10),
        _buildStatCard('🔥 Days', '${d['highEnergyDays']}', const Color(0xFFFF6B35)),
      ],
    );
  }

  Widget _buildStatCard(String label, String value, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: const Color(0xFF1A1A1A),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFF2A2A2A)),
        ),
        child: Column(
          children: [
            Text(value,
                style: TextStyle(color: color, fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 4),
            Text(label,
                style: const TextStyle(color: Color(0xFF666666), fontSize: 11)),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(title,
        style: const TextStyle(
            color: Colors.white, fontSize: 15, fontWeight: FontWeight.bold));
  }

  Widget _buildPatternTile(String pattern) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A1A),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFF2A2A2A)),
      ),
      child: Text(pattern, style: const TextStyle(color: Color(0xFFCCCCCC), fontSize: 13, height: 1.4)),
    );
  }

  Widget _buildHabitSummaryCard(Map<String, dynamic> h) {
    final done = h['weeklyDone'] as int? ?? 0;
    final skipped = h['weeklySkipped'] as int? ?? 0;
    final total = done + skipped;
    final rate = total > 0 ? (done / total) : 0.0;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A1A),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF2A2A2A)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(h['habitName'] ?? '',
                  style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w600)),
              Text('$done done · $skipped skipped',
                  style: const TextStyle(color: Color(0xFF666666), fontSize: 12)),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: rate,
              backgroundColor: const Color(0xFF2A2A2A),
              color: rate >= 0.7
                  ? const Color(0xFF66BB6A)
                  : rate >= 0.4
                      ? const Color(0xFFFF6B35)
                      : const Color(0xFFE57373),
              minHeight: 6,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCorrelations(Map<String, dynamic> d) {
    final sleep = d['sleepCorrelation'] as String?;
    final hrv = d['hrvCorrelation'] as String?;
    if (sleep == null && hrv == null) return const SizedBox();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle('Correlations'),
        const SizedBox(height: 10),
        if (sleep != null) _buildPatternTile('💤 $sleep'),
        if (hrv != null) _buildPatternTile('❤️ $hrv'),
      ],
    );
  }

  Widget _buildAiInsight(String? insight) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A1A),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFFF6B35).withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('✨ AI Insight',
              style: TextStyle(
                  color: Color(0xFFFF6B35), fontSize: 13, fontWeight: FontWeight.bold)),
          const SizedBox(height: 10),
          Text(
            insight ?? 'AI insight unavailable — add an OpenAI key to the backend.',
            style: const TextStyle(color: Color(0xFFCCCCCC), fontSize: 13, height: 1.5),
          ),
        ],
      ),
    );
  }
}
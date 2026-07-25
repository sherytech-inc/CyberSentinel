import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:go_router/go_router.dart';
import '../core/theme/app_theme.dart';
import '../providers/threat_response_provider.dart';

class InvestigationScreen extends StatefulWidget {
  final String alertId;

  const InvestigationScreen({super.key, required this.alertId});

  @override
  State<InvestigationScreen> createState() => _InvestigationScreenState();
}

class _InvestigationScreenState extends State<InvestigationScreen> {
  bool _isLoading = true;
  bool _isAIGenerating = false;
  bool _showAIExplanation = false;
  Map<String, dynamic>? _explanation;
  List<dynamic> _notes = [];
  final TextEditingController _noteController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _fetchData();
  }

  Future<void> _fetchData() async {
    setState(() => _isLoading = true);
    final provider = context.read<ThreatResponseProvider>();
    final expl = await provider.fetchThreatExplanation(widget.alertId);
    final notes = await provider.fetchThreatNotes(widget.alertId);
    if (mounted) {
      setState(() {
        _explanation = expl;
        _notes = notes;
        _isLoading = false;
      });
    }
  }

  Future<void> _addNote() async {
    if (_noteController.text.trim().isEmpty) return;
    final provider = context.read<ThreatResponseProvider>();
    try {
      await provider.addThreatNote(widget.alertId, _noteController.text.trim());
      _noteController.clear();
      await _fetchData();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Failed to add note: $e')));
      }
    }
  }

  @override
  void dispose() {
    _noteController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: AppTheme.bgSecondary,
        title: const Text('Incident Investigation',
            style: TextStyle(color: AppTheme.textPrimary)),
        leading: IconButton(
          icon: const Icon(LucideIcons.arrowLeft, color: AppTheme.textPrimary),
          onPressed: () => context.pop(),
        ),
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: AppTheme.primary))
          : _explanation == null
              ? const Center(
                  child: Text('Alert details not found.',
                      style: TextStyle(color: AppTheme.textSecondary)))
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(AppTheme.spacing24),
                  child: AppTheme.isMobile(context)
                      ? Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (!_showAIExplanation) _buildAIPromptButton(),
                            if (_showAIExplanation)
                              _buildAIExplanationSection(),
                            const SizedBox(height: AppTheme.spacing24),
                            _buildNotesSection(),
                          ],
                        )
                      : Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                                flex: 2,
                                child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      if (!_showAIExplanation)
                                        _buildAIPromptButton(),
                                      if (_showAIExplanation)
                                        _buildAIExplanationSection(),
                                    ])),
                            const SizedBox(width: AppTheme.spacing24),
                            Expanded(flex: 1, child: _buildNotesSection()),
                          ],
                        ),
                ),
    );
  }

  Widget _buildAIPromptButton() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppTheme.spacing32),
      decoration: BoxDecoration(
        color: AppTheme.bgSecondary,
        border: Border.all(color: AppTheme.borderPrimary),
        borderRadius: BorderRadius.circular(AppTheme.radiusLg),
      ),
      child: Column(
        children: [
          const Icon(LucideIcons.bot, size: 48, color: AppTheme.primary),
          const SizedBox(height: AppTheme.spacing16),
          const Text('Need deeper insights?',
              style: TextStyle(
                  color: AppTheme.textPrimary,
                  fontSize: 18,
                  fontWeight: FontWeight.bold)),
          const SizedBox(height: AppTheme.spacing8),
          const Text(
              'Let the CyberSentinel AI Analyst investigate this threat.',
              style: TextStyle(color: AppTheme.textSecondary)),
          const SizedBox(height: AppTheme.spacing24),
          _isAIGenerating
              ? const CircularProgressIndicator(color: AppTheme.primary)
              : ElevatedButton.icon(
                  onPressed: () async {
                    setState(() => _isAIGenerating = true);
                    await Future.delayed(
                        const Duration(seconds: 2)); // Simulate AI thinking
                    if (mounted) {
                      setState(() {
                        _isAIGenerating = false;
                        _showAIExplanation = true;
                      });
                    }
                  },
                  icon: const Icon(LucideIcons.sparkles, size: 18),
                  label: const Text('Investigate With AI'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 32, vertical: 16),
                    textStyle: const TextStyle(
                        fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ),
        ],
      ),
    );
  }

  Widget _buildAIExplanationSection() {
    final breakdown = _explanation?['breakdown'] ?? {};
    final rf = breakdown['random_forest_contribution'] ?? 0;
    final iso = breakdown['isolation_forest_contribution'] ?? 0;
    final intel = breakdown['threat_intel_contribution'] ?? 0;
    final recs = _explanation?['recommendations'] as List<dynamic>? ?? [];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Threat Score Breakdown',
            style: TextStyle(
                color: AppTheme.textPrimary,
                fontSize: 20,
                fontWeight: FontWeight.bold)),
        const SizedBox(height: AppTheme.spacing16),
        Container(
          padding: const EdgeInsets.all(AppTheme.spacing24),
          decoration: BoxDecoration(
            color: AppTheme.bgSecondary,
            border: Border.all(color: AppTheme.borderPrimary),
            borderRadius: BorderRadius.circular(AppTheme.radiusLg),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildScoreBar(
                  'Random Forest (Known Signatures)', rf, AppTheme.error),
              const SizedBox(height: AppTheme.spacing16),
              _buildScoreBar(
                  'Isolation Forest (Anomalies)', iso, AppTheme.warning),
              const SizedBox(height: AppTheme.spacing16),
              _buildScoreBar(
                  'Threat Intelligence (Reputation)', intel, AppTheme.primary),
            ],
          ),
        ),
        const SizedBox(height: AppTheme.spacing24),
        Text('AI Recommendations',
            style: TextStyle(
                color: AppTheme.textPrimary,
                fontSize: 20,
                fontWeight: FontWeight.bold)),
        const SizedBox(height: AppTheme.spacing16),
        Container(
          padding: const EdgeInsets.all(AppTheme.spacing24),
          decoration: BoxDecoration(
            color: AppTheme.bgSecondary,
            border: Border.all(color: AppTheme.borderPrimary),
            borderRadius: BorderRadius.circular(AppTheme.radiusLg),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: recs
                .map((r) => Padding(
                      padding: const EdgeInsets.only(bottom: 8.0),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Icon(LucideIcons.check,
                              color: AppTheme.success, size: 20),
                          const SizedBox(width: 8),
                          Expanded(
                              child: Text(r.toString(),
                                  style: const TextStyle(
                                      color: AppTheme.textPrimary))),
                        ],
                      ),
                    ))
                .toList(),
          ),
        ),
      ],
    );
  }

  Widget _buildScoreBar(String label, num score, Color color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label, style: const TextStyle(color: AppTheme.textSecondary)),
            Text('+${score.toStringAsFixed(1)}',
                style: TextStyle(color: color, fontWeight: FontWeight.bold)),
          ],
        ),
        const SizedBox(height: 8),
        LinearProgressIndicator(
          value: score / 100.0,
          backgroundColor: AppTheme.bgPrimary,
          valueColor: AlwaysStoppedAnimation<Color>(color),
          minHeight: 8,
          borderRadius: BorderRadius.circular(4),
        ),
      ],
    );
  }

  Widget _buildNotesSection() {
    return Container(
      padding: const EdgeInsets.all(AppTheme.spacing24),
      decoration: BoxDecoration(
        color: AppTheme.bgSecondary,
        border: Border.all(color: AppTheme.borderPrimary),
        borderRadius: BorderRadius.circular(AppTheme.radiusLg),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Analyst Notes',
              style: TextStyle(
                  color: AppTheme.textPrimary,
                  fontSize: 18,
                  fontWeight: FontWeight.bold)),
          const SizedBox(height: AppTheme.spacing16),
          if (_notes.isEmpty)
            const Text('No notes yet.',
                style: TextStyle(color: AppTheme.textTertiary))
          else
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _notes.length,
              itemBuilder: (context, index) {
                final note = _notes[index];
                return Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppTheme.bgPrimary,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: AppTheme.borderPrimary),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(note['author'] ?? 'Analyst',
                          style: const TextStyle(
                              color: AppTheme.primary,
                              fontWeight: FontWeight.bold,
                              fontSize: 12)),
                      const SizedBox(height: 4),
                      Text(note['note'] ?? '',
                          style: const TextStyle(color: AppTheme.textPrimary)),
                    ],
                  ),
                );
              },
            ),
          const SizedBox(height: AppTheme.spacing16),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _noteController,
                  style: const TextStyle(color: AppTheme.textPrimary),
                  decoration: const InputDecoration(
                    hintText: 'Add a note...',
                    hintStyle: TextStyle(color: AppTheme.textSecondary),
                    filled: true,
                    fillColor: AppTheme.bgPrimary,
                    border: OutlineInputBorder(),
                    enabledBorder: OutlineInputBorder(
                        borderSide: BorderSide(color: AppTheme.borderPrimary)),
                    contentPadding:
                        EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  ),
                  onSubmitted: (_) => _addNote(),
                ),
              ),
              const SizedBox(width: 8),
              IconButton(
                icon: const Icon(LucideIcons.send, color: AppTheme.primary),
                onPressed: _addNote,
              )
            ],
          ),
        ],
      ),
    );
  }
}

import 'package:flutter/material.dart';
import '../../../config/theme.dart';
import '../../../core/models/models.dart';
import '../../../core/utils/role_helper.dart';
import '../../../data/repositories/governance_repository.dart';

class GovernanceScreen extends StatefulWidget {
  const GovernanceScreen({super.key});

  @override
  State<GovernanceScreen> createState() => _GovernanceScreenState();
}

class _GovernanceScreenState extends State<GovernanceScreen> {
  final _governanceRepo = GovernanceRepository();
  List<Committee> _committees = [];
  List<Meeting> _meetings = [];
  List<Map<String, dynamic>> _projects = [];
  Map<String, int> _committeeMemberCounts = {};
  bool _isLoading = true;
  String? _estateId;
  bool _isAdmin = false;

  @override
  void initState() {
    super.initState();
    _loadGovernanceData();
  }

  Future<void> _loadGovernanceData() async {
    setState(() => _isLoading = true);
    try {
      _isAdmin = await RoleHelper.canManageGovernance();
      _estateId = await _governanceRepo.getCurrentEstateId();
      if (_estateId != null) {
        final results = await Future.wait([
          _governanceRepo.getCommittees(_estateId!),
          _governanceRepo.getMeetings(_estateId!),
          _governanceRepo.getProjects(_estateId!),
        ]);
        _committees = results[0] as List<Committee>;
        _meetings = results[1] as List<Meeting>;
        _projects = results[2] as List<Map<String, dynamic>>;

        // Load member counts for each committee
        _committeeMemberCounts = {};
        for (final committee in _committees) {
          final count = await _governanceRepo.getCommitteeMemberCount(committee.id);
          _committeeMemberCounts[committee.id] = count;
        }

        setState(() => _isLoading = false);
      } else {
        setState(() => _isLoading = false);
      }
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to load governance data: $e')),
        );
      }
    }
  }

  String _formatDate(DateTime date) {
    final months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return '${months[date.month - 1]} ${date.day}, ${date.year}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: RezaColors.backgroundDark,
      appBar: AppBar(
        backgroundColor: RezaColors.backgroundDark,
        title: const Text('Governance'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: RezaColors.accentGold))
          : RefreshIndicator(
              onRefresh: _loadGovernanceData,
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _sectionHeader('Committees', '+ Add', _isAdmin ? () => _showAddCommitteeSheet(context) : null),
                    const SizedBox(height: 12),
                    if (_committees.isEmpty)
                      _buildEmptyState('No committees yet')
                    else
                      ..._committees.map((c) => _buildCommitteeCard(c)),
                    const SizedBox(height: 24),
                    _sectionHeader('Meeting Minutes', '+ New', _isAdmin ? () => _showAddMeetingSheet(context) : null),
                    const SizedBox(height: 12),
                    if (_meetings.isEmpty)
                      _buildEmptyState('No meetings recorded')
                    else
                      ..._meetings.map((m) => _buildMeetingCard(m)),
                    const SizedBox(height: 24),
                    _sectionHeader('Ongoing Projects', '+ Add', _isAdmin ? () => _showAddProjectSheet(context) : null),
                    const SizedBox(height: 12),
                    if (_projects.isEmpty)
                      _buildEmptyState('No projects yet')
                    else
                      ..._projects.map((p) => _buildProjectCard(p)),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _sectionHeader(String title, String action, VoidCallback? onTap) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(title, style: Theme.of(context).headlineMedium),
        if (onTap != null)
          TextButton(onPressed: onTap, child: Text(action)),
      ],
    );
  }

  Widget _buildEmptyState(String message) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: RezaColors.cardDark,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Center(
        child: Text(message, style: const TextStyle(color: RezaColors.textGray)),
      ),
    );
  }

  Widget _buildCommitteeCard(Committee committee) {
    final memberCount = _committeeMemberCounts[committee.id] ?? 0;
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: RezaColors.cardDark,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: RezaColors.accentGold.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.commit, color: RezaColors.accentGold, size: 22),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(committee.name, style: const TextStyle(color: RezaColors.textWhite, fontWeight: FontWeight.w600)),
                if (committee.description != null)
                  Text(committee.description!, style: Theme.of(context).bodyMedium, maxLines: 1, overflow: TextOverflow.ellipsis),
                Text('$memberCount members', style: Theme.of(context).bodyMedium),
              ],
            ),
          ),
          const Icon(Icons.chevron_right, color: RezaColors.textGray),
        ],
      ),
    );
  }

  Widget _buildMeetingCard(Meeting meeting) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: RezaColors.cardDark,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(meeting.title, style: const TextStyle(color: RezaColors.textWhite, fontWeight: FontWeight.w600)),
              ),
              Text(_formatDate(meeting.meetingDate), style: Theme.of(context).bodyMedium?.copyWith(fontSize: 12)),
            ],
          ),
          if (meeting.minutes != null) ...[
            const SizedBox(height: 8),
            Text(meeting.minutes!, style: Theme.of(context).bodyMedium, maxLines: 2, overflow: TextOverflow.ellipsis),
          ],
        ],
      ),
    );
  }

  Widget _buildProjectCard(Map<String, dynamic> project) {
    final name = project['name'] ?? 'Unnamed';
    final budget = (project['budget'] as num?)?.toDouble() ?? 0;
    final spent = (project['spent'] as num?)?.toDouble() ?? 0;
    final progress = budget > 0 ? spent / budget : 0.0;

    String formatBudget(double amount) {
      if (amount >= 1000000) return '₦${(amount / 1000000).toStringAsFixed(1)}M';
      if (amount >= 1000) return '₦${(amount / 1000).toStringAsFixed(0)}K';
      return '₦${amount.toStringAsFixed(0)}';
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: RezaColors.cardDark,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(name, style: const TextStyle(color: RezaColors.textWhite, fontWeight: FontWeight.w600)),
              Text('${formatBudget(spent)} / ${formatBudget(budget)}', style: Theme.of(context).bodyMedium),
            ],
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: progress.clamp(0.0, 1.0),
              backgroundColor: RezaColors.borderDark,
              color: RezaColors.accentGold,
              minHeight: 8,
            ),
          ),
          const SizedBox(height: 8),
          Text('${(progress * 100).toInt()}% Complete', style: Theme.of(context).bodyMedium?.copyWith(fontSize: 12)),
        ],
      ),
    );
  }

  void _showAddCommitteeSheet(BuildContext context) {
    final nameController = TextEditingController();
    final descController = TextEditingController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: RezaColors.cardDark,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) {
        return Padding(
          padding: EdgeInsets.only(left: 24, right: 24, top: 24, bottom: MediaQuery.of(context).viewInsets.bottom + 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('New Committee', style: TextStyle(color: RezaColors.textWhite, fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 20),
              TextField(controller: nameController, decoration: const InputDecoration(hintText: 'Committee Name', prefixIcon: Icon(Icons.group_outlined))),
              const SizedBox(height: 12),
              TextField(controller: descController, decoration: const InputDecoration(hintText: 'Description (optional)', prefixIcon: Icon(Icons.description))),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () async {
                    if (_estateId != null && nameController.text.isNotEmpty) {
                      final navigator = Navigator.of(context);
                      final messenger = ScaffoldMessenger.of(context);
                      try {
                        await _governanceRepo.createCommittee(
                          estateId: _estateId!,
                          name: nameController.text,
                          description: descController.text.isNotEmpty ? descController.text : null,
                        );
                        navigator.pop();
                        _loadGovernanceData();
                        messenger.showSnackBar(const SnackBar(content: Text('Committee created')));
                      } catch (e) {
                        messenger.showSnackBar(SnackBar(content: Text('Failed: $e')));
                      }
                    }
                  },
                  child: const Text('Create Committee'),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _showAddMeetingSheet(BuildContext context) {
    final titleController = TextEditingController();
    final minutesController = TextEditingController();
    DateTime selectedDate = DateTime.now();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: RezaColors.cardDark,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Padding(
              padding: EdgeInsets.only(left: 24, right: 24, top: 24, bottom: MediaQuery.of(context).viewInsets.bottom + 24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('New Meeting', style: TextStyle(color: RezaColors.textWhite, fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 20),
                  TextField(controller: titleController, decoration: const InputDecoration(hintText: 'Meeting Title', prefixIcon: Icon(Icons.title))),
                  const SizedBox(height: 12),
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: const Icon(Icons.calendar_today, color: RezaColors.textGray),
                    title: Text('Date: ${_formatDate(selectedDate)}', style: const TextStyle(color: RezaColors.textWhite)),
                    onTap: () async {
                      final picked = await showDatePicker(
                        context: context,
                        initialDate: selectedDate,
                        firstDate: DateTime(2020),
                        lastDate: DateTime.now(),
                      );
                      if (picked != null) setModalState(() => selectedDate = picked);
                    },
                  ),
                  const SizedBox(height: 12),
                  TextField(controller: minutesController, maxLines: 3, decoration: const InputDecoration(hintText: 'Minutes / Summary (optional)', prefixIcon: Icon(Icons.notes))),
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () async {
                        if (_estateId != null && titleController.text.isNotEmpty) {
                          final navigator = Navigator.of(context);
                          final messenger = ScaffoldMessenger.of(context);
                          try {
                            await _governanceRepo.createMeeting(
                              estateId: _estateId!,
                              title: titleController.text,
                              meetingDate: selectedDate,
                              minutes: minutesController.text.isNotEmpty ? minutesController.text : null,
                            );
                            navigator.pop();
                            _loadGovernanceData();
                            messenger.showSnackBar(const SnackBar(content: Text('Meeting recorded')));
                          } catch (e) {
                            messenger.showSnackBar(SnackBar(content: Text('Failed: $e')));
                          }
                        }
                      },
                      child: const Text('Save Meeting'),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  void _showAddProjectSheet(BuildContext context) {
    final nameController = TextEditingController();
    final descController = TextEditingController();
    final budgetController = TextEditingController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: RezaColors.cardDark,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) {
        return Padding(
          padding: EdgeInsets.only(left: 24, right: 24, top: 24, bottom: MediaQuery.of(context).viewInsets.bottom + 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('New Project', style: TextStyle(color: RezaColors.textWhite, fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 20),
              TextField(controller: nameController, decoration: const InputDecoration(hintText: 'Project Name', prefixIcon: Icon(Icons.work_outline))),
              const SizedBox(height: 12),
              TextField(controller: descController, decoration: const InputDecoration(hintText: 'Description (optional)', prefixIcon: Icon(Icons.description))),
              const SizedBox(height: 12),
              TextField(controller: budgetController, keyboardType: TextInputType.number, decoration: const InputDecoration(hintText: 'Budget (₦) (optional)', prefixIcon: Icon(Icons.money))),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () async {
                    if (_estateId != null && nameController.text.isNotEmpty) {
                      final navigator = Navigator.of(context);
                      final messenger = ScaffoldMessenger.of(context);
                      try {
                        await _governanceRepo.createProject(
                          estateId: _estateId!,
                          name: nameController.text,
                          description: descController.text.isNotEmpty ? descController.text : null,
                          budget: double.tryParse(budgetController.text),
                        );
                        navigator.pop();
                        _loadGovernanceData();
                        messenger.showSnackBar(const SnackBar(content: Text('Project created')));
                      } catch (e) {
                        messenger.showSnackBar(SnackBar(content: Text('Failed: $e')));
                      }
                    }
                  },
                  child: const Text('Create Project'),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

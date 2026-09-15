import 'package:flutter/material.dart';
import '../../../config/theme.dart';
import '../../../core/models/models.dart';
import '../../../core/utils/role_helper.dart';
import '../../../data/repositories/security_repository.dart';

class SecurityScreen extends StatefulWidget {
  const SecurityScreen({super.key});

  @override
  State<SecurityScreen> createState() => _SecurityScreenState();
}

class _SecurityScreenState extends State<SecurityScreen> {
  final _securityRepo = SecurityRepository();
  List<SecurityAlert> _alerts = [];
  List<GuestManifest> _guests = [];
  bool _isLoading = true;
  String? _estateId;
  bool _canManage = false;

  @override
  void initState() {
    super.initState();
    _loadSecurityData();
  }

  Future<void> _loadSecurityData() async {
    setState(() => _isLoading = true);
    try {
      _canManage = await RoleHelper.canManageSecurity();
      _estateId = await _securityRepo.getCurrentEstateId();
      if (_estateId != null) {
        final results = await Future.wait([
          _securityRepo.getActiveAlerts(_estateId!),
          _securityRepo.getGuestManifest(_estateId!),
        ]);
        setState(() {
          _alerts = results[0] as List<SecurityAlert>;
          _guests = results[1] as List<GuestManifest>;
          _isLoading = false;
        });
      } else {
        setState(() => _isLoading = false);
      }
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to load security data: $e')),
        );
      }
    }
  }

  String _formatTime(DateTime time) {
    final now = DateTime.now();
    final diff = now.difference(time);
    if (diff.inDays > 0) return '${diff.inDays}d ago';
    if (diff.inHours > 0) return '${diff.inHours}h ago';
    if (diff.inMinutes > 0) return '${diff.inMinutes}m ago';
    return 'Just now';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: RezaColors.backgroundDark,
      appBar: AppBar(
        backgroundColor: RezaColors.backgroundDark,
        title: const Text('Security'),
        actions: [
          if (_canManage)
            IconButton(
              icon: const Icon(Icons.warning_amber_outlined),
              onPressed: () => _showAlertDialog(context),
            ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: RezaColors.accentGold))
          : RefreshIndicator(
              onRefresh: _loadSecurityData,
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    GestureDetector(
                      onTap: () => _sendPanicAlert(),
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: RezaColors.errorRed.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: RezaColors.errorRed.withValues(alpha: 0.3)),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.emergency, color: RezaColors.errorRed),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text('Emergency Alert', style: TextStyle(color: RezaColors.errorRed, fontWeight: FontWeight.bold)),
                                  Text('Tap to send panic alert to security', style: Theme.of(context).bodyMedium),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Active Alerts', style: Theme.of(context).headlineMedium),
                        Text('${_alerts.length}', style: const TextStyle(color: RezaColors.textGray, fontSize: 13)),
                      ],
                    ),
                    const SizedBox(height: 12),
                    if (_alerts.isEmpty)
                      _buildEmptyState('No active alerts')
                    else
                      ..._alerts.map((alert) => _buildAlertCard(alert)),
                    const SizedBox(height: 24),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Guest Manifest', style: Theme.of(context).headlineMedium),
                        if (_canManage)
                          IconButton(
                            icon: const Icon(Icons.person_add_outlined, color: RezaColors.accentGold),
                            onPressed: () => _showCheckInSheet(context),
                          ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    if (_guests.isEmpty)
                      _buildEmptyState('No guests today')
                    else
                      ..._guests.map((guest) => _buildGuestCard(guest)),
                  ],
                ),
              ),
            ),
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

  Widget _buildAlertCard(SecurityAlert alert) {
    Color severityColor = alert.severity == 'high' ? RezaColors.errorRed : RezaColors.accentGold;
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
              color: severityColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(Icons.warning_amber, color: severityColor, size: 22),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(alert.title, style: const TextStyle(color: RezaColors.textWhite, fontWeight: FontWeight.w600)),
                Text(alert.description, style: Theme.of(context).bodyMedium, maxLines: 2, overflow: TextOverflow.ellipsis),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: severityColor.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(alert.severity, style: TextStyle(color: severityColor, fontSize: 12)),
              ),
              const SizedBox(height: 4),
              Text(_formatTime(alert.createdAt), style: Theme.of(context).bodyMedium?.copyWith(fontSize: 11)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildGuestCard(GuestManifest guest) {
    bool isCheckedIn = guest.checkOutTime == null;
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: RezaColors.cardDark,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 20,
            backgroundColor: RezaColors.accentGold.withValues(alpha: 0.2),
            child: Text(guest.visitorName[0].toUpperCase(), style: const TextStyle(color: RezaColors.accentGold, fontWeight: FontWeight.bold)),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(guest.visitorName, style: const TextStyle(color: RezaColors.textWhite, fontWeight: FontWeight.w600)),
                Text(guest.purpose ?? 'No purpose', style: Theme.of(context).bodyMedium),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(_formatTime(guest.checkInTime), style: Theme.of(context).bodyMedium?.copyWith(fontSize: 12)),
              if (isCheckedIn && _canManage)
                IconButton(
                  icon: const Icon(Icons.logout, size: 18),
                  color: RezaColors.errorRed,
                  tooltip: 'Check Out',
                  onPressed: () async {
                    try {
                      await _securityRepo.checkOutGuest(guest.id);
                      _loadSecurityData();
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('${guest.visitorName} checked out')),
                        );
                      }
                    } catch (e) {
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Failed: $e')),
                        );
                      }
                    }
                  },
                ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: isCheckedIn ? RezaColors.successGreen.withValues(alpha: 0.2) : RezaColors.textGray.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  isCheckedIn ? 'Checked In' : 'Checked Out',
                  style: TextStyle(color: isCheckedIn ? RezaColors.successGreen : RezaColors.textGray, fontSize: 12),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _sendPanicAlert() async {
    if (_estateId == null) return;
    try {
      await _securityRepo.createAlert(
        estateId: _estateId!,
        title: 'EMERGENCY',
        description: 'Panic alert triggered by resident',
        severity: 'high',
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Emergency alert sent to security')),
        );
        _loadSecurityData();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to send alert: $e')),
        );
      }
    }
  }

  void _showAlertDialog(BuildContext context) {
    final titleController = TextEditingController();
    final descController = TextEditingController();
    String severity = 'medium';

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              backgroundColor: RezaColors.cardDark,
              title: const Text('Send Security Alert'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(controller: titleController, decoration: const InputDecoration(hintText: 'Alert Title')),
                  const SizedBox(height: 12),
                  TextField(controller: descController, decoration: const InputDecoration(hintText: 'Description'), maxLines: 3),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    initialValue: severity,
                    decoration: const InputDecoration(hintText: 'Severity'),
                    items: const [
                      DropdownMenuItem(value: 'low', child: Text('Low')),
                      DropdownMenuItem(value: 'medium', child: Text('Medium')),
                      DropdownMenuItem(value: 'high', child: Text('High')),
                    ],
                    onChanged: (v) => setDialogState(() => severity = v ?? 'medium'),
                  ),
                ],
              ),
              actions: [
                TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
                ElevatedButton(
                  onPressed: () async {
                    if (_estateId != null && titleController.text.isNotEmpty) {
                      final navigator = Navigator.of(context);
                      final messenger = ScaffoldMessenger.of(context);
                      try {
                        await _securityRepo.createAlert(
                          estateId: _estateId!,
                          title: titleController.text,
                          description: descController.text,
                          severity: severity,
                        );
                        navigator.pop();
                        _loadSecurityData();
                        messenger.showSnackBar(const SnackBar(content: Text('Alert sent')));
                      } catch (e) {
                        messenger.showSnackBar(SnackBar(content: Text('Failed: $e')));
                      }
                    }
                  },
                  child: const Text('Send Alert'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _showCheckInSheet(BuildContext context) {
    final nameController = TextEditingController();
    final phoneController = TextEditingController();
    final purposeController = TextEditingController();

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
              const Text('Check In Guest', style: TextStyle(color: RezaColors.textWhite, fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 20),
              TextField(controller: nameController, decoration: const InputDecoration(hintText: 'Visitor Name', prefixIcon: Icon(Icons.person_outlined))),
              const SizedBox(height: 12),
              TextField(controller: phoneController, keyboardType: TextInputType.phone, decoration: const InputDecoration(hintText: 'Phone (optional)', prefixIcon: Icon(Icons.phone_outlined))),
              const SizedBox(height: 12),
              TextField(controller: purposeController, decoration: const InputDecoration(hintText: 'Purpose', prefixIcon: Icon(Icons.info_outline))),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () async {
                    if (_estateId != null && nameController.text.isNotEmpty) {
                      final navigator = Navigator.of(context);
                      final messenger = ScaffoldMessenger.of(context);
                      try {
                        await _securityRepo.checkInGuest(
                          estateId: _estateId!,
                          visitorName: nameController.text,
                          visitorPhone: phoneController.text.isNotEmpty ? phoneController.text : null,
                          purpose: purposeController.text.isNotEmpty ? purposeController.text : null,
                        );
                        navigator.pop();
                        _loadSecurityData();
                        messenger.showSnackBar(const SnackBar(content: Text('Guest checked in')));
                      } catch (e) {
                        messenger.showSnackBar(SnackBar(content: Text('Failed: $e')));
                      }
                    }
                  },
                  child: const Text('Check In'),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

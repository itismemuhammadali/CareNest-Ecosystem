import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:star_sitter_family/widgets/app_background.dart';
import 'package:star_sitter_family/widgets/header2.dart';

class NotificationPreferencesScreen extends StatefulWidget {
  const NotificationPreferencesScreen({super.key});

  @override
  State<NotificationPreferencesScreen> createState() => _NotificationPreferencesScreenState();
}

class _NotificationPreferencesScreenState extends State<NotificationPreferencesScreen> {
  bool _emailNotifications = true;
  bool _smsNotifications = true;
  bool _pushNotifications = true;
  bool _newApplicants = true;
  bool _newMessages = true;
  bool _upcomingReminders = true;
  SharedPreferences? _prefs;

  @override
  void initState() {
    super.initState();
    SharedPreferences.getInstance().then((prefs) {
      if (!mounted) return;
      setState(() {
        _prefs = prefs;
        _emailNotifications = prefs.getBool('family_notif_email') ?? true;
        _smsNotifications = prefs.getBool('family_notif_sms') ?? true;
        _pushNotifications = prefs.getBool('family_notif_push') ?? true;
        _newApplicants = prefs.getBool('family_notif_applicants') ?? true;
        _newMessages = prefs.getBool('family_notif_messages') ?? true;
        _upcomingReminders = prefs.getBool('family_notif_reminders') ?? true;
      });
    });
  }

  Future<void> _savePreferences() async {
    await _prefs?.setBool('family_notif_email', _emailNotifications);
    await _prefs?.setBool('family_notif_sms', _smsNotifications);
    await _prefs?.setBool('family_notif_push', _pushNotifications);
    await _prefs?.setBool('family_notif_applicants', _newApplicants);
    await _prefs?.setBool('family_notif_messages', _newMessages);
    await _prefs?.setBool('family_notif_reminders', _upcomingReminders);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: AppBackground(
        child: Column(
          children: [
            // Header
            Header2(
              title: 'Notification Preferences',
              subtitle: 'Manage how you receive alerts and updates',
            ),
            // Form container
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.only(top: 20, left: 24, right: 24, bottom: 24),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: const Color(0x991E293B),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Section header
                      const Text(
                        'Choose how you want to receive notifications',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.white70,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Email Notifications
                      _buildNotificationRow(
                        icon: 'assets/mail.svg',
                        title: 'Email Notifications',
                        value: _emailNotifications,
                        onChanged: (value) {
                          setState(() {
                            _emailNotifications = value ?? false;
                          });
                        },
                      ),
                      const SizedBox(height: 12),

                      // SMS Notifications
                      _buildNotificationRow(
                        icon: 'assets/phone.svg',
                        title: 'SMS Notifications',
                        value: _smsNotifications,
                        onChanged: (value) {
                          setState(() {
                            _smsNotifications = value ?? false;
                          });
                        },
                      ),
                      const SizedBox(height: 12),

                      // Push Notifications
                      _buildNotificationRow(
                        icon: 'assets/bell.svg',
                        title: 'Push Notifications',
                        value: _pushNotifications,
                        onChanged: (value) {
                          setState(() {
                            _pushNotifications = value ?? false;
                          });
                        },
                      ),
                      const SizedBox(height: 24),

                      // Alert me about section
                      const Text(
                        'Alert me about:',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.white70,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 12),

                      // New Applicants
                      _buildAlertRow(
                        title: 'New Applicants',
                        value: _newApplicants,
                        onChanged: (value) {
                          setState(() {
                            _newApplicants = value ?? false;
                          });
                        },
                      ),
                      const SizedBox(height: 12),

                      // New Messages
                      _buildAlertRow(
                        title: 'New Messages',
                        value: _newMessages,
                        onChanged: (value) {
                          setState(() {
                            _newMessages = value ?? false;
                          });
                        },
                      ),
                      const SizedBox(height: 12),

                      // Upcoming Job Reminders
                      _buildAlertRow(
                        title: 'Upcoming Job Reminders',
                        value: _upcomingReminders,
                        onChanged: (value) {
                          setState(() {
                            _upcomingReminders = value ?? false;
                          });
                        },
                      ),
                      const SizedBox(height: 32),

                      // Buttons
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Expanded(
                            child: SizedBox(
                              height: 44,
                              child: OutlinedButton(
                                onPressed: () => Navigator.of(context).pop(),
                                style: OutlinedButton.styleFrom(
                                  side: BorderSide(color: Colors.white.withValues(alpha: 0.3)),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  padding: EdgeInsets.zero,
                                ),
                                child: const Text(
                                  'Cancel',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w600,
                                    fontSize: 12,
                                  ),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: SizedBox(
                              height: 44,
                              child: ElevatedButton(
                                onPressed: () async {
                                  await _savePreferences();
                                  if (!context.mounted) return;
                                  Navigator.of(context).pop();
                                },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFFC8F0FF),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  padding: EdgeInsets.zero,
                                ),
                                child: const Text(
                                  'Save Changes',
                                  style: TextStyle(
                                    color: Color(0xFF0F172A),
                                    fontWeight: FontWeight.w600,
                                    fontSize: 12,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNotificationRow({
    required String icon,
    required String title,
    required bool value,
    required Function(bool?) onChanged,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.transparent,
        border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          SvgPicture.asset(
            icon,
            width: 20,
            height: 20,
            colorFilter: const ColorFilter.mode(
              Color(0xFFA8D8EA),
              BlendMode.srcIn,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              title,
              style: const TextStyle(
                fontSize: 14,
                color: Colors.white,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Checkbox(
            value: value,
            onChanged: onChanged,
            fillColor: WidgetStateProperty.resolveWith((states) {
              if (states.contains(WidgetState.selected)) {
                return const Color(0xFFC8F0FF);
              }
              return Colors.transparent;
            }),
            side: BorderSide(
              color: Colors.white.withValues(alpha: 0.3),
              width: 1.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAlertRow({
    required String title,
    required bool value,
    required Function(bool?) onChanged,
  }) {
    return Row(
      children: [
        Expanded(
          child: Text(
            title,
            style: const TextStyle(
              fontSize: 14,
              color: Colors.white,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        const SizedBox(width: 2),
        Checkbox(
          value: value,
          onChanged: onChanged,
          fillColor: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.selected)) {
              return const Color(0xFFC8F0FF);
            }
            return Colors.transparent;
          }),
          side: BorderSide(
            color: Colors.white.withValues(alpha: 0.3),
            width: 1.5,
          ),
        ),
      ],
    );
  }
}

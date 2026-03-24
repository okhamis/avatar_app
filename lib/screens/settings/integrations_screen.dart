import 'package:flutter/material.dart';

class IntegrationsScreen extends StatefulWidget {
  const IntegrationsScreen({super.key});

  @override
  State<IntegrationsScreen> createState() => _IntegrationsScreenState();
}

class _IntegrationsScreenState extends State<IntegrationsScreen> {
  bool _googleCalendar = false;
  bool _appleCalendar = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Integrations')),
      body: ListView(
        children: [
          SwitchListTile(
            title: const Text('Google Calendar'),
            value: _googleCalendar,
            onChanged: (v) => setState(() => _googleCalendar = v),
          ),
          SwitchListTile(
            title: const Text('Apple Calendar'),
            value: _appleCalendar,
            onChanged: (v) => setState(() => _appleCalendar = v),
          ),
          const ListTile(
            title: Text('Phone Calls'),
            trailing: Text('Coming soon', style: TextStyle(color: Colors.grey)),
          ),
          const ListTile(
            title: Text('Healthcare Booking'),
            trailing: Text('Coming soon', style: TextStyle(color: Colors.grey)),
          ),
          const ListTile(
            title: Text('Email'),
            trailing: Text('Coming soon', style: TextStyle(color: Colors.grey)),
          ),
        ],
      ),
    );
  }
}

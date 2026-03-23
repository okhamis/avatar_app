import 'package:flutter/material.dart';

class IntegrationsScreen extends StatelessWidget {
  const IntegrationsScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Integrations")),
      body: ListView(
        children: [
          SwitchListTile(
            title: const Text("Google Calendar"),
            value: true,
            onChanged: (val) {},
          ),
          SwitchListTile(
            title: const Text("Apple Calendar"),
            value: false,
            onChanged: (val) {},
          ),
          const ListTile(
            title: Text("Phone Calls"),
            trailing: Text("Coming soon", style: TextStyle(color: Colors.grey)),
          ),
          const ListTile(
            title: Text("Healthcare Booking"),
            trailing: Text("Coming soon", style: TextStyle(color: Colors.grey)),
          ),
          const ListTile(
            title: Text("Email"),
            trailing: Text("Coming soon", style: TextStyle(color: Colors.grey)),
          ),
        ],
      ),
    );
  }
}

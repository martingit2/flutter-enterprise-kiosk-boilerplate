import 'dart:async';
import 'package:flutter/material.dart';
import '../config/theme.dart';
import '../models/task_model.dart';
import '../core/kiosk_controller.dart';
import '../widgets/task_card.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  // Demo Data
  int _myPoints = 120;
  final List<String> _recentActivity = [
    "Ola tømte oppvaskmaskinen (+50p)",
    "Kari kokte kaffe (+20p)",
    "Pål ryddet møterommet (+30p)",
  ];

  final List<TaskModel> _tasks = [
    const TaskModel(title: 'Ny Kaffe', points: 20, icon: Icons.coffee, color: Colors.brown),
    const TaskModel(title: 'Tømme Oppvask', points: 50, icon: Icons.local_dining, color: Colors.blue),
    const TaskModel(title: 'Kaste Søppel', points: 30, icon: Icons.delete_outline, color: Colors.green),
    const TaskModel(title: 'Rydde Møterom', points: 40, icon: Icons.meeting_room, color: Colors.purple),
    const TaskModel(title: 'Vanne Planter', points: 15, icon: Icons.local_florist, color: Colors.teal),
    const TaskModel(title: 'Fylle Printer', points: 25, icon: Icons.print, color: Colors.orange),
  ];

  // Logic Variables
  int _logoTaps = 0;
  Timer? _tapResetTimer;
  late Timer _clockTimer;
  DateTime _now = DateTime.now();

  @override
  void initState() {
    super.initState();
    _clockTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted) setState(() => _now = DateTime.now());
    });
  }

  @override
  void dispose() {
    _clockTimer.cancel();
    super.dispose();
  }

  void _registerTask(TaskModel task) {
    setState(() {
      _myPoints += task.points;
      _recentActivity.insert(0, "Du: ${task.title} (+${task.points})");
      if (_recentActivity.length > 6) _recentActivity.removeLast();
    });
    ScaffoldMessenger.of(context).clearSnackBars();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text("${task.points} poeng registrert!"),
        backgroundColor: AppColors.successGreen,
        duration: const Duration(milliseconds: 1500),
      ),
    );
  }

  void _handleAdminAccess() {
    _logoTaps++;
    _tapResetTimer?.cancel();
    _tapResetTimer = Timer(const Duration(seconds: 1), () => _logoTaps = 0);
    if (_logoTaps >= 5) {
      _logoTaps = 0;
      _showSecureLogin();
    }
  }

  void _showSecureLogin() {
    final pinController = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("System Maintenance"),
        content: TextField(
          controller: pinController,
          obscureText: true,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(labelText: "PIN Code", border: OutlineInputBorder()),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancel")),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent, foregroundColor: Colors.white),
            onPressed: () {
              if (pinController.text == AppConfig.adminPin) {
                Navigator.pop(context);
                KioskController.unlockDevice();
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Device Unlocked")));
              }
            },
            child: const Text("Unlock"),
          )
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final timeStr = "${_now.hour.toString().padLeft(2, '0')}:${_now.minute.toString().padLeft(2, '0')}";

    return Scaffold(
      body: Row(
        children: [
          // --- SIDEBAR ---
          Container(
            width: 250,
            color: AppColors.sidebar,
            padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                GestureDetector(
                  onTap: _handleAdminAccess,
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(color: AppColors.primaryDark, borderRadius: BorderRadius.circular(8)),
                        child: const Icon(Icons.pets, color: Colors.white, size: 20),
                      ),
                      const SizedBox(width: 10),
                      const Text("Taskhamster", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.primaryDark)),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                Text(timeStr, style: const TextStyle(fontSize: 40, fontWeight: FontWeight.w300, color: AppColors.textDark)),
                Text("Kontor Oslo", style: TextStyle(fontSize: 14, color: Colors.grey[500])),
                const SizedBox(height: 20),

                // POENG KORT
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(colors: [Colors.blue.shade800, Colors.blue.shade600]),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text("Dine poeng", style: TextStyle(color: Colors.white70, fontSize: 12)),
                      Text("$_myPoints XP", style: const TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.bold)),
                    ],
                  ),
                ),

                const Spacer(),
                const Divider(),
                const Text("SISTE AKTIVITET", style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppColors.textLight)),
                const SizedBox(height: 10),
                Expanded(
                  flex: 2,
                  child: ListView.builder(
                    itemCount: _recentActivity.length,
                    itemBuilder: (ctx, i) => Padding(
                      padding: const EdgeInsets.only(bottom: 6.0),
                      child: Text(_recentActivity[i], style: const TextStyle(fontSize: 12, color: AppColors.textDark)),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // --- MAIN GRID ---
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text("Registrer Oppgave", style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: AppColors.primaryDark)),
                  const SizedBox(height: 16),
                  Expanded(
                    child: GridView.builder(
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 3,
                        childAspectRatio: 0.95, // Vår layout-fiks
                        crossAxisSpacing: 12,
                        mainAxisSpacing: 12,
                      ),
                      itemCount: _tasks.length,
                      itemBuilder: (ctx, i) => TaskCard(
                        task: _tasks[i],
                        onTap: () => _registerTask(_tasks[i]),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
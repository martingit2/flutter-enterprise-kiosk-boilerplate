import 'package:flutter/material.dart';

class TaskModel {
  final String title;
  final int points;
  final IconData icon;
  final Color color;

  const TaskModel({
    required this.title,
    required this.points,
    required this.icon,
    required this.color,
  });
}
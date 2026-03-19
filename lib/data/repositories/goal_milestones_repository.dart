import 'package:financier/data/services/local_storage_service.dart';
import 'package:financier/domain/models/goal_milestone.dart';
import 'package:flutter/foundation.dart';

class GoalMilestonesRepository extends ChangeNotifier {
  final LocalStorageService _storage;
  List<GoalMilestone> _cache = [];

  GoalMilestonesRepository(this._storage) {
    _load();
  }

  void _load() {
    _cache = _storage.readMilestones().map(GoalMilestone.fromJson).toList();
    notifyListeners();
  }

  List<GoalMilestone> get all => List.unmodifiable(_cache);

  GoalMilestone? findById(String id) {
    try {
      return _cache.firstWhere((m) => m.id == id);
    } catch (_) {
      return null;
    }
  }

  List<GoalMilestone> milestonesForGoal(String goalId) {
    final milestones = _cache.where((m) => m.goalId == goalId).toList();
    // Sort by order
    milestones.sort((a, b) => a.order.compareTo(b.order));
    return milestones;
  }

  int completedMilestonesForGoal(String goalId) {
    return _cache.where((m) => m.goalId == goalId && m.isCompleted).length;
  }

  Future<void> add(GoalMilestone milestone) async {
    _cache.add(milestone);
    await _persist();
    notifyListeners();
  }

  Future<void> update(GoalMilestone milestone) async {
    final idx = _cache.indexWhere((m) => m.id == milestone.id);
    if (idx == -1) return;
    _cache[idx] = milestone;
    await _persist();
    notifyListeners();
  }

  Future<void> delete(String id) async {
    _cache.removeWhere((m) => m.id == id);
    await _persist();
    notifyListeners();
  }

  Future<void> deleteForGoal(String goalId) async {
    _cache.removeWhere((m) => m.goalId == goalId);
    await _persist();
    notifyListeners();
  }

  Future<void> replaceAll(List<GoalMilestone> milestones) async {
    _cache = List<GoalMilestone>.from(milestones);
    await _persist();
    notifyListeners();
  }

  Future<void> _persist() =>
      _storage.writeMilestones(_cache.map((m) => m.toJson()).toList());
}

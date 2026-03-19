import 'package:financier/data/repositories/goal_milestones_repository.dart';
import 'package:financier/domain/models/goal_milestone.dart';
import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';

class GoalMilestonesViewModel extends ChangeNotifier {
  final GoalMilestonesRepository _milestonesRepo;

  bool _isLoading = false;
  String? _error;

  bool get isLoading => _isLoading;
  String? get error => _error;

  GoalMilestonesViewModel(this._milestonesRepo) {
    _milestonesRepo.addListener(_onRepositoryChanged);
  }

  List<GoalMilestone> milestonesForGoal(String goalId) {
    return _milestonesRepo.milestonesForGoal(goalId);
  }

  int completedMilestonesForGoal(String goalId) {
    return _milestonesRepo.completedMilestonesForGoal(goalId);
  }

  /// Create a new milestone for a goal
  Future<void> addMilestone({
    required String goalId,
    required String name,
    required double targetAmount,
    required int order,
  }) async {
    try {
      _setLoading(true);
      _error = null;

      final milestone = GoalMilestone(
        id: const Uuid().v4(),
        goalId: goalId,
        name: name,
        targetAmount: targetAmount,
        order: order,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      await _milestonesRepo.add(milestone);
      notifyListeners();
    } catch (e) {
      _error = 'Failed to add milestone: ${e.toString()}';
    } finally {
      _setLoading(false);
    }
  }

  /// Mark a milestone as complete
  Future<void> completeMilestone(String milestoneId) async {
    try {
      final milestone = _milestonesRepo.findById(milestoneId);
      if (milestone == null) {
        _error = 'Milestone not found';
        return;
      }

      final updated = milestone.copyWith(
        completedAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
      await _milestonesRepo.update(updated);
      notifyListeners();
    } catch (e) {
      _error = 'Failed to complete milestone: ${e.toString()}';
    }
  }

  /// Mark a milestone as incomplete
  Future<void> uncompleteMilestone(String milestoneId) async {
    try {
      final milestone = _milestonesRepo.findById(milestoneId);
      if (milestone == null) {
        _error = 'Milestone not found';
        return;
      }

      final updated = milestone.copyWith(
        completedAt: null,
        updatedAt: DateTime.now(),
      );
      await _milestonesRepo.update(updated);
      notifyListeners();
    } catch (e) {
      _error = 'Failed to uncomplete milestone: ${e.toString()}';
    }
  }

  /// Delete a milestone
  Future<void> deleteMilestone(String milestoneId) async {
    try {
      _setLoading(true);
      _error = null;

      await _milestonesRepo.delete(milestoneId);
      notifyListeners();
    } catch (e) {
      _error = 'Failed to delete milestone: ${e.toString()}';
    } finally {
      _setLoading(false);
    }
  }

  /// Update a milestone
  Future<void> updateMilestone(GoalMilestone milestone) async {
    try {
      _setLoading(true);
      _error = null;

      final updated = milestone.copyWith(updatedAt: DateTime.now());
      await _milestonesRepo.update(updated);
      notifyListeners();
    } catch (e) {
      _error = 'Failed to update milestone: ${e.toString()}';
    } finally {
      _setLoading(false);
    }
  }

  /// Force UI refresh when repository is updated externally.
  void refresh() {
    notifyListeners();
  }

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }

  void _onRepositoryChanged() {
    notifyListeners();
  }

  @override
  void dispose() {
    _milestonesRepo.removeListener(_onRepositoryChanged);
    super.dispose();
  }
}

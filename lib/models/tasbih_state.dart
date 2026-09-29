class TasbihStageDefinition {
  final String id;
  final String label;
  final int target;

  const TasbihStageDefinition({
    required this.id,
    required this.label,
    required this.target,
  });
}

class TasbihZahraState {
  static const List<TasbihStageDefinition> stages = <TasbihStageDefinition>[
    TasbihStageDefinition(id: 'allahu_akbar', label: 'الله أكبر', target: 34),
    TasbihStageDefinition(id: 'alhamdulillah', label: 'الحمد لله', target: 33),
    TasbihStageDefinition(id: 'subhanallah', label: 'سبحان الله', target: 33),
  ];

  final int stageIndex;
  final int count;
  final int completedCycles;
  final int lifetimeTotal;

  const TasbihZahraState({
    this.stageIndex = 0,
    this.count = 0,
    this.completedCycles = 0,
    this.lifetimeTotal = 0,
  });

  TasbihStageDefinition get stage => stages[stageIndex];

  TasbihZahraState increment() {
    final nextCount = count + 1;
    final nextLifetime = lifetimeTotal + 1;
    if (nextCount < stage.target) {
      return TasbihZahraState(
        stageIndex: stageIndex,
        count: nextCount,
        completedCycles: completedCycles,
        lifetimeTotal: nextLifetime,
      );
    }

    if (stageIndex < stages.length - 1) {
      return TasbihZahraState(
        stageIndex: stageIndex + 1,
        count: 0,
        completedCycles: completedCycles,
        lifetimeTotal: nextLifetime,
      );
    }

    return TasbihZahraState(
      stageIndex: 0,
      count: 0,
      completedCycles: completedCycles + 1,
      lifetimeTotal: nextLifetime,
    );
  }

  TasbihZahraState resetStage() {
    return TasbihZahraState(
      stageIndex: stageIndex,
      count: 0,
      completedCycles: completedCycles,
      lifetimeTotal: lifetimeTotal,
    );
  }

  TasbihZahraState copyWith({
    int? stageIndex,
    int? count,
    int? completedCycles,
    int? lifetimeTotal,
  }) {
    final nextStage =
        (stageIndex ?? this.stageIndex).clamp(0, stages.length - 1).toInt();
    final nextTarget = stages[nextStage].target;
    return TasbihZahraState(
      stageIndex: nextStage,
      count: (count ?? this.count).clamp(0, nextTarget - 1).toInt(),
      completedCycles:
          (completedCycles ?? this.completedCycles).clamp(0, 1 << 31).toInt(),
      lifetimeTotal:
          (lifetimeTotal ?? this.lifetimeTotal).clamp(0, 1 << 31).toInt(),
    );
  }
}

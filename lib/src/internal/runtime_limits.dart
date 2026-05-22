/// Compile-time safety limits for BranchIQ.
/// These constraints prevent stack overflows, excessive memory consumption,
/// and runaway graph exploration during evaluation.
class RuntimeLimits {
  RuntimeLimits._();

  /// The maximum allowed depth of any node in the decision tree.
  /// Rationale: Prevents stack overflow (deep recursion) during DFS/BFS traversals
  /// and configures memory usage upper bounds.
  static const int defaultMaxDepth = 12;

  /// The default beam width for BeamSearch traversal.
  /// Rationale: Bounds the maximum branching factor tracked at each frontier level,
  /// keeping traversal runtime within strict deterministic time slices.
  static const int defaultBeamWidth = 5;

  /// The maximum total number of nodes allowed in a decision tree.
  /// Rationale: Prevents runaway expansion and out-of-memory errors from malicious
  /// or generated pathological tree structures.
  static const int defaultMaxNodes = 1000;

  /// The maximum number of iterations allowed during graph traversal.
  /// Rationale: Halts cyclic graphs or excessively complex trees, ensuring
  /// evaluation terminates in a predictable execution window.
  static const int defaultMaxTraversalIterations = 1000;

  /// The maximum number of children any single node can possess.
  /// Rationale: Limits local fan-out, reducing width search space explosion
  /// and protecting against memory allocation spikes.
  static const int defaultMaxChildrenPerNode = 10;
}

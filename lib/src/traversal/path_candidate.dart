/// Internal representation of a search path candidate inside the priority-first traversal frontier.
class PathCandidate {
  /// The unique identifier of the node representing the tip of the search path.
  final String nodeId;

  /// The ordered list of node IDs from the root up to (but not including) the tip [nodeId].
  final List<String> parentPathIds;

  /// The accumulated sum of node utility scores along the path (including the tip node).
  final double accumulatedScore;

  /// The depth of this candidate (number of transitions from the root node).
  final int depth;

  /// Indicates whether this candidate represents a terminal leaf path or cannot be expanded further.
  final bool isTerminal;

  /// Creates a [PathCandidate] instance.
  ///
  /// Forces unmodifiable copy of [parentPathIds] to preserve immutability.
  PathCandidate({
    required this.nodeId,
    required List<String> parentPathIds,
    required this.accumulatedScore,
    required this.depth,
    required this.isTerminal,
  }) : parentPathIds = List<String>.unmodifiable(parentPathIds);
}

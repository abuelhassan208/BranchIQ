import '../models/decision_node.dart';

/// Compares two [DecisionNode]s by their scores in descending order.
///
/// Returns a negative integer if [a]'s score is greater than [b]'s score,
/// a positive integer if [a]'s score is less than [b]'s score,
/// and zero if they are equal.
///
/// Deterministic Guarantee: This comparison is based purely on the double values
/// of the node scores and is completely deterministic.
/// Safety Note: Does not resolve ties. If you require stable, deterministic tie-breaking,
/// use [compareNodes] instead.
int compareScoresDescending(DecisionNode a, DecisionNode b) {
  if (a.score > b.score) {
    return -1;
  }
  if (a.score < b.score) {
    return 1;
  }
  return 0;
}

/// Compares two [DecisionNode]s by their unique identifiers lexicographically (ascending).
///
/// Returns a negative integer if [a]'s ID is lexicographically less than [b]'s ID,
/// a positive integer if it is greater, and zero if they are equal.
///
/// Deterministic Guarantee: Standard string comparison ensures identical ordering
/// across different runs, platforms, and environments.
int compareNodeIds(DecisionNode a, DecisionNode b) {
  return a.id.compareTo(b.id);
}

/// Compares two [DecisionNode]s using a deterministic score-first, ID-second strategy.
///
/// Nodes are first compared by score in descending order using [compareScoresDescending].
/// If the scores are identical, the tie is broken lexicographically by their unique
/// identifiers in ascending order using [compareNodeIds].
///
/// Deterministic Guarantee: Because IDs are unique within the decision space,
/// this comparison ensures a total ordering, preventing any platform-specific or
/// run-to-run instability.
int compareNodes(DecisionNode a, DecisionNode b) {
  final scoreDiff = compareScoresDescending(a, b);
  if (scoreDiff != 0) {
    return scoreDiff;
  }
  return compareNodeIds(a, b);
}

/// Sorts the given list of [DecisionNode]s in-place using a stable, deterministic ordering.
///
/// The resulting list will be ordered descending by score, with ties broken lexicographically
/// by node ID (ascending).
///
/// Performance Safety: This operation sorts the list in-place to avoid unnecessary heap
/// allocations or creating temporary lists.
/// Deterministic Guarantee: Ensures reproducible results on all platforms.
void stableNodeSort(List<DecisionNode> nodes) {
  nodes.sort(compareNodes);
}

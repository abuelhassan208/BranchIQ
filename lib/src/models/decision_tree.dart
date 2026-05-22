import '../validation/tree_validator.dart';
import 'decision_node.dart';

/// Represents a directed, acyclic hierarchy of decision nodes.
class DecisionTree {
  final Map<String, DecisionNode> _nodes;

  const DecisionTree._(this._nodes);

  /// Creates a [DecisionTree] from a flat list of decision nodes.
  ///
  /// Runs complete structural validation checking during construction.
  factory DecisionTree.fromNodes(List<DecisionNode> nodesList) {
    final map = {for (final node in nodesList) node.id: node};
    final tree = DecisionTree._(Map<String, DecisionNode>.unmodifiable(map));
    tree.validateOrThrow();
    return tree;
  }

  /// Retrieves the root node of the decision tree.
  DecisionNode get root {
    return TreeValidator.validateRoot(this);
  }

  /// Exposes the internal lookup registry map of node IDs to decision nodes.
  Map<String, DecisionNode> get nodes => _nodes;

  /// Retrieves a decision node by its unique ID. Returns null if not found.
  DecisionNode? getNode(String id) => _nodes[id];

  /// Returns the children nodes of the target node.
  ///
  /// Returns an empty list if the node has no children or does not exist.
  List<DecisionNode> childrenOf(String id) {
    final node = _nodes[id];
    if (node == null) return const [];
    return node.childIds.map((cid) {
      final child = _nodes[cid];
      if (child == null) {
        throw OrphanNodeException(
            'Node "$id" references missing child "$cid".');
      }
      return child;
    }).toList();
  }

  /// Returns true if the node ID exists in the tree.
  bool containsNode(String id) => _nodes.containsKey(id);

  /// Returns true if the tree has no cycle loops and contains no orphan nodes.
  bool isValid() {
    try {
      validateOrThrow();
      return true;
    } catch (_) {
      return false;
    }
  }

  /// Validates structural rules or throws an exception detailing violations.
  void validateOrThrow() {
    TreeValidator.validate(this);
  }

  /// Deserializes a [DecisionTree] from a JSON map.
  factory DecisionTree.fromJson(Map<String, dynamic> json) {
    final rawNodes = json['nodes'] as List<dynamic>? ?? const [];
    final nodes = rawNodes
        .map((n) => DecisionNode.fromJson(n as Map<String, dynamic>))
        .toList();
    return DecisionTree.fromNodes(nodes);
  }

  /// Serializes this [DecisionTree] into a JSON map with stable, sorted key order.
  Map<String, dynamic> toJson() {
    // stable JSON export ordering: sort nodes by their ID lexicographically to be 100% deterministic!
    final sortedKeys = _nodes.keys.toList()..sort();
    final serializedNodes =
        sortedKeys.map((key) => _nodes[key]!.toJson()).toList();
    return {
      'nodes': serializedNodes,
    };
  }
}

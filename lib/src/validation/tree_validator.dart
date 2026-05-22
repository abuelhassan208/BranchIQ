import '../models/decision_node.dart';
import '../models/decision_tree.dart';

/// Exception thrown when tree hierarchy validation fails due to general structure flaws.
class InvalidTreeException implements Exception {
  /// The detail message explaining the structural validation failure.
  final String message;

  /// Creates an [InvalidTreeException] with the provided message.
  const InvalidTreeException(this.message);

  @override
  String toString() => 'InvalidTreeException: $message';
}

/// Exception thrown when nodes are not connected to the root or reference missing children.
class OrphanNodeException implements Exception {
  /// The detail message explaining the orphan node validation failure.
  final String message;

  /// Creates an [OrphanNodeException] with the provided message.
  const OrphanNodeException(this.message);

  @override
  String toString() => 'OrphanNodeException: $message';
}

/// Exception thrown when a cycle is detected within the decision tree.
class CycleDetectedException implements Exception {
  /// The detail message explaining the detected loop trajectory.
  final String message;

  /// Creates a [CycleDetectedException] with the provided message.
  const CycleDetectedException(this.message);

  @override
  String toString() => 'CycleDetectedException: $message';
}

/// A deterministic validation engine for [DecisionTree] structures.
///
/// Implements stack-based DFS to guarantee safety against recursion stack overflow.
class TreeValidator {
  /// Runs the full structural validation suite on a [DecisionTree].
  ///
  /// Throws [InvalidTreeException], [OrphanNodeException], or [CycleDetectedException] on failure.
  static void validate(DecisionTree tree) {
    if (tree.nodes.isEmpty) {
      throw const InvalidTreeException('Tree must contain at least one node.');
    }

    final root = validateRoot(tree);
    validateChildReferences(tree);
    validateNoCycles(tree);
    validateParentChildConsistency(tree);

    final visited = <String>{};
    validateDepthLimits(tree, root, visited);
    validateNoOrphans(tree, visited);
  }

  /// Asserts that there is exactly one root node in the tree and returns it.
  static DecisionNode validateRoot(DecisionTree tree) {
    final roots = tree.nodes.values.where((n) => n.parentId == null).toList();
    if (roots.isEmpty) {
      throw const InvalidTreeException(
          'Tree has no root node (parentId is null).');
    }
    if (roots.length > 1) {
      final ids = roots.map((r) => r.id).join(', ');
      throw InvalidTreeException(
          'Tree must have exactly one root node. Found multiple roots: $ids.');
    }
    return roots.first;
  }

  /// Validates that all child identifiers correspond to existing registry entries.
  static void validateChildReferences(DecisionTree tree) {
    final nodes = tree.nodes;
    for (final node in nodes.values) {
      for (final childId in node.childIds) {
        if (!nodes.containsKey(childId)) {
          throw OrphanNodeException(
              'Node "${node.id}" references a missing child node "$childId".');
        }
      }
    }
  }

  /// Validates that there are no cycle loops anywhere in the tree nodes.
  static void validateNoCycles(DecisionTree tree) {
    final nodes = tree.nodes;
    final visited = <String>{};

    // Sort keys deterministically for stable validation order
    final sortedIds = nodes.keys.toList()..sort();

    for (final startId in sortedIds) {
      if (visited.contains(startId)) continue;

      final List<_CycleFrame> stack = [
        _CycleFrame(startId, List<String>.unmodifiable([startId]))
      ];

      while (stack.isNotEmpty) {
        final frame = stack.removeLast();
        final currentId = frame.nodeId;
        final path = frame.path;

        visited.add(currentId);

        final node = nodes[currentId];
        if (node == null) continue;

        // Sort children in descending order before pushing to stack
        final sortedChildren = List<String>.from(node.childIds)
          ..sort((a, b) => b.compareTo(a));

        for (final childId in sortedChildren) {
          if (path.contains(childId)) {
            final cyclePath = [...path, childId].join(' -> ');
            throw CycleDetectedException('Cycle detected: $cyclePath');
          }
          stack.add(_CycleFrame(
              childId, List<String>.unmodifiable([...path, childId])));
        }
      }
    }
  }

  /// Validates that parent-child bidirectional relationships match up correctly.
  static void validateParentChildConsistency(DecisionTree tree) {
    final nodes = tree.nodes;
    final roots = nodes.values.where((n) => n.parentId == null).toList();
    final rootId = roots.isNotEmpty ? roots.first.id : null;

    for (final node in nodes.values) {
      // Non-root parent checks
      if (node.id != rootId) {
        final parentId = node.parentId;
        if (parentId == null) {
          throw InvalidTreeException(
              'Node "${node.id}" has no parentId, but is not the root node.');
        }
        final parentNode = nodes[parentId];
        if (parentNode == null) {
          throw OrphanNodeException(
              'Node "${node.id}" references missing parent "$parentId".');
        }
        if (!parentNode.childIds.contains(node.id)) {
          throw InvalidTreeException(
              'Parent node "$parentId" of node "${node.id}" does not list it in childIds.');
        }
      }

      // Children parent checks
      for (final childId in node.childIds) {
        final childNode = nodes[childId];
        if (childNode != null && childNode.parentId != node.id) {
          throw InvalidTreeException(
              'Child node "$childId" of node "${node.id}" has parentId "${childNode.parentId}".');
        }
      }
    }
  }

  /// Traverses the tree using DFS to find depth breaches and check node depths.
  static void validateDepthLimits(
      DecisionTree tree, DecisionNode root, Set<String> visited) {
    final nodes = tree.nodes;

    // Stack contains nodes along with the path leading to them.
    final List<_DFSFrame> stack = [
      _DFSFrame(root, List<String>.unmodifiable([root.id]))
    ];

    while (stack.isNotEmpty) {
      final frame = stack.removeLast();
      final node = frame.node;
      final path = frame.path;

      visited.add(node.id);

      final depth = path.length - 1;
      if (depth > 12) {
        throw InvalidTreeException(
            'Max depth limit of 12 levels exceeded at node "${node.id}".');
      }

      if (node.depth != depth) {
        throw InvalidTreeException(
            'Node "${node.id}" has inconsistent depth field: ${node.depth}. Expected: $depth.');
      }

      // Sort child IDs lexicographically in descending order before pushing to
      // stack so they are popped in ascending lexicographical order (stable traversal).
      final sortedChildren = List<String>.from(node.childIds)
        ..sort((a, b) => b.compareTo(a));

      for (final childId in sortedChildren) {
        final childNode = nodes[childId]!;
        stack.add(_DFSFrame(
            childNode, List<String>.unmodifiable([...path, childId])));
      }
    }
  }

  /// Identifies and throws an exception if any nodes are unreachable from the root.
  static void validateNoOrphans(DecisionTree tree, Set<String> visited) {
    if (visited.length < tree.nodes.length) {
      final orphans =
          tree.nodes.keys.where((id) => !visited.contains(id)).toList()..sort();
      throw OrphanNodeException(
          'Orphan nodes detected (unreachable from root): ${orphans.join(', ')}.');
    }
  }
}

class _DFSFrame {
  final DecisionNode node;
  final List<String> path;
  _DFSFrame(this.node, this.path);
}

class _CycleFrame {
  final String nodeId;
  final List<String> path;
  const _CycleFrame(this.nodeId, this.path);
}

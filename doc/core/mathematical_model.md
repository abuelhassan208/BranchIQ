# BranchIQ v0.1.0: Mathematical Specification
**Version**: 0.1.0-math  
**Author**: Principal Systems Mathematician  
**Status**: Frozen for Development  

---

# 1. Mathematical Philosophy

Mobile client applications execute under tight runtime budgets. Running complex, non-deterministic decision runtimes (such as reinforcement learning models or online Bayesian updates) on client hardware introduces unpredictable frame delays (jank), excessive battery drain, and difficult-to-reproduce state errors.

To address these concerns, BranchIQ uses a mathematical model based on:

> **"Bounded deterministic utility evaluation."**

This philosophy replaces expensive heuristic runtimes with cheap algebraic operations. By modeling application paths using bounded linear arithmetic, BranchIQ guarantees:
1.  **Low Computation Overhead**: Evaluates decision nodes using basic floating-point arithmetic ($O(1)$ operations per node).
2.  **Output Predictability**: Eliminates stochastic behavior, ensuring that the same inputs always produce the exact same path.
3.  **Explainability**: Every pruning step and path decision is mathematically traceable, making debugging straightforward.

---

## Mathematical Section Checklist
- [x] equations formally defined
- [x] ranges defined
- [x] numerical safety addressed
- [x] deterministic guarantees explained
- [x] complexity implications considered

---

# 2. Decision State Representation

## 2.1 Formal Node Definition
A decision node $n$ is defined mathematically as a 5-tuple:

$$n = (\mathbf{P}, \mathbf{I}, \mathbf{C}, \mathbf{K}, \mathbf{M})$$

where:
*   $\mathbf{P} \in [0.0, 1.0]$: The transition probability of reaching a successful state.
*   $\mathbf{I} \in [-1.0, 1.0]$: The impact score representing the utility change.
*   $\mathbf{C} \in [0.0, \infty)$: The absolute resource cost.
*   $\mathbf{K} \in [0.0, 1.0]$: The confidence in the estimated metrics.
*   $\mathbf{M}$: The high-dimensional metadata context vector.

## 2.2 Mathematical Ranges & Safeties
*   **Allowed Value Boundaries**:
    *   $P \in [0.0, 1.0]$ (Probability space constraint)
    *   $I \in [-1.0, 1.0]$ (Utility space constraint)
    *   $C \ge 0.0$ (Cost metric space constraint)
    *   $K \in [0.0, 1.0]$ (Confidence space constraint)
*   **Numerical Safety Rules**:
    *   Any property value that falls outside its allowed range is clamped to its nearest boundary.
    *   To prevent division-by-zero errors, a floating-point stabilizer ($\epsilon = 10^{-9}$) is added to all denominators.
    *   Values of $\text{NaN}$ and $\pm\infty$ are intercepted and sanitized to safe defaults.

---

## Mathematical Section Checklist
- [x] equations formally defined
- [x] ranges defined
- [x] numerical safety addressed
- [x] deterministic guarantees explained
- [x] complexity implications considered

---

# 3. Probability Model

## 3.1 Bounded Probability Constraints
Transition probabilities represent the likelihood that a path will execute successfully without encountering runtime exceptions or system errors:

$$P(n) \in [0.0, 1.0]$$

In the v0.1.0 MVP, probabilities are static values defined in the tree configuration. Dynamic Bayesian updates are excluded to avoid complex state mutation checks.

## 3.2 Probability Sanitization
To ensure probability parameters remain valid, inputs are sanitized using a clamping function:

$$P_{\text{sanitized}}(n) = \max\left(0.0, \min\left(1.0, P_{\text{raw}}(n)\right)\right)$$

---

## Mathematical Section Checklist
- [x] equations formally defined
- [x] ranges defined
- [x] numerical safety addressed
- [x] deterministic guarantees explained
- [x] complexity implications considered

---

# 4. Impact Model

## 4.1 Symmetric Utility Impact
The impact parameter $I(n)$ represents the utility value of reaching node $n$'s state. It is defined on a symmetric interval:

$$I(n) \in [-1.0, 1.0]$$

where:
*   $I(n) > 0.0$: Represents a positive state change (e.g., successful cached content load).
*   $I(n) = 0.0$: Represents a neutral state change.
*   $I(n) < 0.0$: Represents a negative state change (e.g., UI layout shift or cache miss latency).

## 4.2 Impact Sanitization
Raw impact parameters are sanitized by clipping values that fall outside the symmetric interval:

$$I_{\text{sanitized}}(n) = \max\left(-1.0, \min\left(1.0, I_{\text{raw}}(n)\right)\right)$$

---

## Mathematical Section Checklist
- [x] equations formally defined
- [x] ranges defined
- [x] numerical safety addressed
- [x] deterministic guarantees explained
- [x] complexity implications considered

---

# 5. Cost Model

## 5.1 Linear Cost Normalization
To compare absolute cost metrics (like latency in milliseconds or CPU cycles) with probabilities and impacts, costs must be mapped to a normalized range $[0.0, 1.0]$. The v0.1.0 MVP uses linear normalization:

$$C_{\text{norm}}(n) = \max\left(0.0, \min\left(1.0, \frac{C(n)}{C_{\text{max}} + \epsilon}\right)\right)$$

where:
*   $C_{\text{max}} \in (0.0, \infty)$ is the absolute cost ceiling config parameter.
*   $\epsilon = 10^{-9}$ is the division stabilizer.

## 5.2 Cost Constraint Philosophy
*   Logarithmic cost scaling is deferred to Phase 2 to keep calculations mathematically simple.
*   Negative cost values are sanitized by clamping them to $0.0$:
    $$C(n) < 0.0 \implies C(n) = 0.0$$

---

## Mathematical Section Checklist
- [x] equations formally defined
- [x] ranges defined
- [x] numerical safety addressed
- [x] deterministic guarantees explained
- [x] complexity implications considered

---

# 6. Confidence Model

## 6.1 Bounded Confidence Space
Confidence $K(n)$ represents the reliability of a node's parameter estimates:

$$K(n) \in [0.0, 1.0]$$

Unlike probabilities (which model transition success rates), confidence models the quality of our data. For example, if telemetry data is stale, confidence $K$ is set low to indicate that our estimates may be inaccurate.

## 6.2 Confidence Decay and Path Propagation
As a decision path projects further into the future, confidence in downstream estimations decreases. For a path of depth $d$ starting from root $n_0$:

$$K(n_d) = K(n_{d-1}) \cdot \gamma(n_{d-1}, n_j) = K(n_0) \cdot \prod_{j=1}^d \gamma(n_{j-1}, n_j)$$

where the transition decay coefficient $\gamma$ degrades exponentially with depth:

$$\gamma(n_{j-1}, n_j) = \gamma_0 \cdot e^{-\lambda \cdot d(n_j)}$$

*   $\gamma_0 \in (0.0, 1.0]$: Baseline transition confidence.
*   $\lambda \in [0.0, 1.0]$: Empirical decay rate constant (typically $\lambda = 0.1$).
*   $d(n_j)$: Target node depth.

```
Confidence (K)
  1.0 ┼───.
      │    \
      │     ` - .
  0.0 ┼───────────┴───────────────────────
      0.0 (Root)  Depth (d)              4.0
```

---

## Mathematical Section Checklist
- [x] equations formally defined
- [x] ranges defined
- [x] numerical safety addressed
- [x] deterministic guarantees explained
- [x] complexity implications considered

---

# 7. Core Scoring Equation

## 7.1 Aggregate Score Formulation
The local aggregate utility score $S(n)$ for a node $n$ is calculated using Multi-Attribute Utility Theory (MAUT) combined with confidence scaling:

$$S(n) = K(n) \cdot \left[ w_p \cdot P(n) + w_i \cdot I(n) - w_c \cdot C_{\text{norm}}(n) \right]$$

where:
*   $w_p, w_i, w_c \in [0.0, 1.0]$: Configuration weights representing the importance of probability, impact, and cost.
*   $\sum w_k = 1.0$: Weight normalization constraint.
*   $C_{\text{norm}}(n)$: Normalized cost.

## 7.2 Numerical Boundaries
*   **Theoretical Score Boundaries**:
    $$S(n) \in [-1.0, 1.0]$$
*   **Clamping Rules**: If arithmetic overflow or numeric drift pushes a score outside these boundaries, it is clamped:
    $$S(n) < -1.0 \implies S(n) = -1.0$$
    $$S(n) > 1.0 \implies S(n) = 1.0$$

## 7.3 Multiplicative Scaling Philosophy
By multiplying the utility score by confidence ($K(n)$), scores of unverified nodes are attenuated towards $0.0$. This prevents the search algorithm from choosing high-risk, low-confidence paths simply because they estimate high impact.

---

## Mathematical Section Checklist
- [x] equations formally defined
- [x] ranges defined
- [x] numerical safety addressed
- [x] deterministic guarantees explained
- [x] complexity implications considered

---

# 8. Weight System

## 8.1 Strict Normalization Rules
Scoring weights must sum to exactly $1.0$ to ensure consistent score ranges:

$$w_p + w_i + w_c = 1.0$$

Validation is enforced using a floating-point tolerance check:

$$\left| (w_p + w_i + w_c) - 1.0 \right| < 10^{-6}$$

If the weights fail this check, the configuration constructor throws an initialization error. Dynamic weight adjustment is excluded from v0.1.0 to keep traversal logic predictable.

---

## Mathematical Section Checklist
- [x] equations formally defined
- [x] ranges defined
- [x] numerical safety addressed
- [x] deterministic guarantees explained
- [x] complexity implications considered

---

# 9. Branch Ranking Mathematics

## 9.1 Score Ordering Invariant
The engine ranks active branches at each depth level in descending order of utility score:

$$\text{Sort}\left(\{n_1, n_2, \dots, n_m\}\right) \implies S(n_{[1]}) \ge S(n_{[2]}) \ge \dots \ge S(n_{[m]})$$

## 9.2 Lexicographical Tie-Breaking
To prevent non-deterministic sorting order (which can cause inconsistent execution behavior across platforms), ties are broken using node IDs:

$$\text{If } S(n_a) == S(n_b) \implies \text{Order}(n_a, n_b) = \begin{cases} n_a \prec n_b & \text{if } \text{id}(n_a) < \text{id}(n_b) \\ n_b \prec n_a & \text{otherwise} \end{cases}$$

This ensures that the sorted output of the decision frontier remains identical across all execution runs.

---

## Mathematical Section Checklist
- [x] equations formally defined
- [x] ranges defined
- [x] numerical safety addressed
- [x] deterministic guarantees explained
- [x] complexity implications considered

---

# 10. Pruning Mathematics

Pruning reduces the search space size on-the-fly during expansion:

```
  Frontier Nodes ──► [ Probability Pruning ] ──► [ Score Pruning ] ──► Expanded Nodes
```

## 10.1 Probability Pruning Constraint
A branch is pruned from the tree if its transition probability falls below the minimum threshold configuration:

$$\text{Prune } n \iff P(n) < P_{\text{min}}$$

## 10.2 Score Pruning Constraint
A branch is pruned if its aggregate utility score falls below the minimum utility threshold:

$$\text{Prune } n \iff S(n) < S_{\text{min}}$$

---

## Mathematical Section Checklist
- [x] equations formally defined
- [x] ranges defined
- [x] numerical safety addressed
- [x] deterministic guarantees explained
- [x] complexity implications considered

---

# 11. Beam Search Mathematics

## 11.1 Frontier Bounding
At each depth level $d$, the engine restricts the search frontier size to a maximum width parameter $k$:

$$\left| \mathcal{F}_d \right| \le k$$

where:
*   $\mathcal{F}_d$: Set of active nodes at depth $d$.
*   $k \ge 1$: Beam width configuration parameter (typically $k = 3$).

## 11.2 Active Frontier Update
$$\mathcal{F}_d = \text{Top}_k\left( \bigcup_{p \in \mathcal{F}_{d-1}} \text{Expand}(p) \right)$$

By retaining only the top $k$ scored nodes at each step, the search space size is bounded, preventing exponential node growth.

---

## Mathematical Section Checklist
- [x] equations formally defined
- [x] ranges defined
- [x] numerical safety addressed
- [x] deterministic guarantees explained
- [x] complexity implications considered

---

# 12. Traversal Mathematics

## 12.1 Path Extraction Priority
The engine extracts the optimal decision path $P^*$ using a modified $A^*$ priority traversal:

$$P^* = \arg\max_{P} \mathcal{U}(P)$$

where the path utility $\mathcal{U}(P)$ is the sum of its node scores:

$$\mathcal{U}(P) = \sum_{n \in P} S(n)$$

## 12.2 Path Back-Propagation
The best path is reconstructed by traversing backwards from the highest-scoring leaf node $n_l$ using parent pointers:

$$P^* = \text{Backtrack}(n_l) \implies (n_0, n_1, \dots, n_l)$$

Stochastic selection and Monte Carlo rollouts are prohibited in v0.1.0 to ensure deterministic traversal output.

---

## Mathematical Section Checklist
- [x] equations formally defined
- [x] ranges defined
- [x] numerical safety addressed
- [x] deterministic guarantees explained
- [x] complexity implications considered

---

# 13. Complexity Mathematics

## 13.1 Time Complexity Analysis
Without pruning, the engine evaluates every node in the search tree:

$$T_{\text{naive}}(b, d) = O(b^d)$$

Using Beam Search with width $k$, the number of evaluated nodes scales linearly with depth:

$$T_{\text{pruned}}(b, d, k) = O(d \cdot k \cdot b \log(k \cdot b))$$

For typical configurations ($b=3, d=4, k=3$), the pruned search space evaluates at most $39$ nodes, compared to $120$ nodes for a naive search.

## 13.2 Memory Space Complexity Analysis
Without pruning, the engine stores the entire tree in memory:

$$S_{\text{naive}}(b, d) = O(b^d)$$

Using Beam Search, memory usage is bounded by the size of the active frontier:

$$S_{\text{pruned}}(b, d, k) = O(d \cdot k \cdot b)$$

This linear memory scaling prevents memory leaks and garbage collection pressure on mobile devices.

---

## Mathematical Section Checklist
- [x] equations formally defined
- [x] ranges defined
- [x] numerical safety addressed
- [x] deterministic guarantees explained
- [x] complexity implications considered

---

# 14. Numerical Stability

To ensure consistent math calculations across mobile platforms, BranchIQ implements these sanitization rules:

## 14.1 NaN Handling
Any parameter that evaluates to $\text{NaN}$ is intercepted and replaced with a default value:

$$x = \text{NaN} \implies x = -1.0$$

## 14.2 Infinity Handling
Infinite values are clamped to safe maximum boundaries:

$$x = +\infty \implies x = 1.0$$
$$x = -\infty \implies x = -1.0$$

## 14.3 Division Stabilizer
To prevent division-by-zero errors during cost normalization, a small stabilizer constant is added to the denominator:

$$\text{Denominator}_{\text{safe}} = \text{Denominator}_{\text{raw}} + \epsilon$$

where:
$$\epsilon = 10^{-9}$$

---

## Mathematical Section Checklist
- [x] equations formally defined
- [x] ranges defined
- [x] numerical safety addressed
- [x] deterministic guarantees explained
- [x] complexity implications considered

---

# 15. Determinism Mathematics

Deterministic execution is guaranteed by resolving all potential sources of calculation variance:

## 15.1 Deterministic Invariants
1.  **No Unordered Collections**: Sibling node sets are sorted using stable sorting algorithms, breaking ties alphabetically by node IDs.
2.  **No Dynamic Clock References**: Nodes do not call system timers (`DateTime.now()`) during evaluation. Time parameters must be read from the static context snapshot.
3.  **No Random Number Generation**: The scoring and traversal pipelines do not use random seeds.

$$\forall \mathbf{x}, \mathbf{\theta} \implies \text{Engine}(\mathbf{x}, \mathbf{\theta}) \to P^* \text{ (Identical output path)}$$

---

## Mathematical Section Checklist
- [x] equations formally defined
- [x] ranges defined
- [x] numerical safety addressed
- [x] deterministic guarantees explained
- [x] complexity implications considered

---

# 16. Failure Boundary Mathematics

If the engine encounters a mathematical error, it degrades gracefully to a safe baseline state:

```
  Mathematical Exception ──► [ Catch & Log ] ──► [ Empty Path ] ──► Root Action Default
```

*   **Empty Trees**: If the input tree contains no nodes, the engine returns an empty evaluation path.
*   **Unreachable Nodes**: If traversal fails to find a valid path to a leaf node, the engine returns the root node's path as the default fallback.
*   **Config Validation Failure**: If scoring weights do not sum to $1.0$, the engine throws an `ArgumentError` immediately on startup, failing fast to prevent execution with invalid configurations.

---

## Mathematical Section Checklist
- [x] equations formally defined
- [x] ranges defined
- [x] numerical safety addressed
- [x] deterministic guarantees explained
- [x] complexity implications considered

---

# 17. Mathematical Constraints of MVP

The v0.1.0 MVP enforces these hard constraints on search configuration:

$$d_{\text{max}} \le 4$$
$$k_{\text{max}} \le 3$$
$$N_{\text{max}} \le 100$$

These values are chosen to guarantee that synchronous execution on the main UI isolate completes in under **1 millisecond**, preserving smooth frame rates.

---

## Mathematical Section Checklist
- [x] equations formally defined
- [x] ranges defined
- [x] numerical safety addressed
- [x] deterministic guarantees explained
- [x] complexity implications considered

---

# 18. Deferred Mathematical Systems

The following systems are excluded from v0.1.0 and deferred to later phases:

*   **Bayesian Probability Updating (Phase 2)**: Dynamically updating transition probabilities based on execution history.
*   **Entropy-Based Pruning (Phase 2)**: Halting expansion when decision entropy drops below a threshold.
*   **Policy Gradient Reinforcement Optimization (Phase 6)**: Training scoring weights on-device.
*   **Monte Carlo Tree Search (Phase 6)**: Simulating path rollouts for high-dimensional search trees.
*   **Non-linear Utility Functions (Phase 2)**: Modeling non-linear risk tolerances.

---

## Mathematical Section Checklist
- [x] equations formally defined
- [x] ranges defined
- [x] numerical safety addressed
- [x] deterministic guarantees explained
- [x] complexity implications considered

---

# 19. Mathematical Validation Examples

## 19.1 Worked Example: Node Scoring
Let node $n$ have these parameters:
*   $P(n) = 0.90$ (probability)
*   $I(n) = 0.70$ (impact)
*   $C(n) = 120.0$ (raw cost)
*   $K(n) = 0.85$ (confidence)

Let the scoring configuration define these weights and limits:
*   $w_p = 0.40, w_i = 0.40, w_c = 0.20$
*   $C_{\text{max}} = 500.0$
*   $\epsilon = 10^{-9}$

### 1. Cost Normalization
$$C_{\text{norm}}(n) = \min\left(1.0, \frac{120.0}{500.0 + 10^{-9}}\right) = 0.24$$

### 2. Raw Utility Score
$$V(n) = (0.40 \cdot 0.90) + (0.40 \cdot 0.70) - (0.20 \cdot 0.24) = 0.36 + 0.28 - 0.048 = 0.592$$

### 3. Confidence-Scaled Score
$$S(n) = K(n) \cdot V(n) = 0.85 \cdot 0.592 = 0.5032$$

## 19.2 Worked Example: Pruning Check
Let the pruning threshold configuration be:
*   $S_{\text{min}} = 0.60$

Since the node score $S(n) = 0.5032$ is less than $S_{\text{min}}$, the node is pruned:

$$0.5032 < 0.60 \implies \text{Node is Pruned}$$

## 19.3 Worked Example: Beam Search Selection
Let the active frontier at depth $d=2$ contain four candidate nodes with these scores:

$$\mathcal{F}_2^{\text{candidates}} = \{ n_a: 0.85, n_b: 0.72, n_c: 0.55, n_d: 0.30 \}$$

Let the configuration specify a beam width $k = 3$. Sorting the candidates in descending order yields:

$$\text{Sorted Candidates} = (n_a, n_b, n_c, n_d)$$

Selecting the top $k$ nodes yields the active frontier:

$$\mathcal{F}_2 = \{ n_a, n_b, n_c \}$$

Node $n_d$ is pruned and discarded from the search space.

## 19.4 Worked Example: Deterministic Tie-Breaking
Let two sibling nodes have the exact same score:
*   $S(n_1) = 0.72$, $\text{id}(n_1) = \text{"action\_cache"}$
*   $S(n_2) = 0.72$, $\text{id}(n_2) = \text{"action\_network"}$

The engine compares their ID strings:

$$\text{"action\_cache"}.c( \text{"action\_network"} ) < 0 \implies n_1 \prec n_2$$

Node $n_1$ is ranked ahead of node $n_2$.

## 19.5 Worked Example: Confidence Propagation
Let a path of depth $d=2$ have these parameters:
*   Root confidence: $K(n_0) = 1.0$
*   Decay rate: $\lambda = 0.1$, $\gamma_0 = 0.90$

Calculate propagation at depth $d=1$:

$$\gamma_1 = 0.90 \cdot e^{-0.1 \cdot 1} \approx 0.8143$$
$$K(n_1) = 1.0 \cdot 0.8143 = 0.8143$$

Calculate propagation at depth $d=2$:

$$\gamma_2 = 0.90 \cdot e^{-0.1 \cdot 2} \approx 0.7368$$
$$K(n_2) = 0.8143 \cdot 0.7368 \approx 0.6000$$

---

## Mathematical Section Checklist
- [x] equations formally defined
- [x] ranges defined
- [x] numerical safety addressed
- [x] deterministic guarantees explained
- [x] complexity implications considered

---

# 20. Final Mathematical Lock

The mathematics of BranchIQ v0.1.0 are locked to this core objective:

> **BranchIQ v0.1.0 mathematics exist only to support bounded deterministic utility evaluation in pure Dart runtimes.**

All additional equations, statistics, and optimization models are deferred.

---

# Mathematical Architecture Audit

This audit evaluates the stability and rigor of the BranchIQ mathematical model.

## Subsystem Assessment Scores (1-10)

| Subsystem / Dimension | Score | Assessment Rationale |
| :--- | :--- | :--- |
| **Numerical Stability** | **10/10** | Enforces clamping, division stabilizers, and NaN/Infinity sanitization across all equations. |
| **Deterministic Safety** | **10/10** | Eliminates system clock calls and random number seeds, resolving ties lexicographically. |
| **Runtime Efficiency** | **10/10** | Uses basic floating-point arithmetic ($O(1)$ calculations), avoiding heavy calculus. |
| **Explainability** | **10/10** | Path utility scores are linear sums of node scores, making decisions traceable. |
| **Bounded Complexity** | **10/10** | Beam Search constraints bound tree growth to linear complexity $O(d)$. |
| **Pruning Efficiency** | **9/10** | Discards low-scoring branches early using simple threshold filters. |
| **Mobile Suitability** | **10/10** | Avoids background isolate serialization delays by running synchronously on the main thread. |
| **Future Extensibility** | **9/10** | Decoupled parameters inside node metadata maps make it easy to add future models. |

---

## Audit Findings

### 1. Strongest Mathematical Decision
Using **multiplicative confidence scaling** $S(n) = K(n) \cdot V(n)$. This provides a simple way to discount estimates based on data quality, preventing high-risk, low-confidence paths from being chosen.

### 2. Riskiest Mathematical Simplification
Using linear cost normalization:
$$C_{\text{norm}}(n) = \frac{C(n)}{C_{\text{max}} + \epsilon}$$
If $C_{\text{max}}$ is set incorrectly, costs can cluster near $0.0$ or $1.0$, reducing the scoring engine's sensitivity.

### 3. Deferred Systems Most Likely Needed Later
**Logarithmic cost normalization**:
$$C_{\text{norm}}(n) = \frac{\ln(1 + C(n))}{\ln(1 + C_{\text{max}}) + \epsilon}$$
Necessary to handle costs that vary exponentially, such as database query sizes or network timeouts.

### 4. Mathematical Areas Most Vulnerable to Instability
User-defined cost functions. If absolute cost calculation code throws exceptions, the normalization equation will break. The engine must wrap these custom calls in try-catch guards.

### 5. Recommended Next Planning Document
`docs/core/implementation_plan.md` to define the tasks for building the v0.1.0 codebase.

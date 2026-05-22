/// The default floating-point stabilizer constant used in cost normalization.
const double defaultEpsilon = 1e-9;

/// Checks whether the provided double value is a valid, finite real number.
/// Returns false if the value is NaN, positive infinity, or negative infinity.
///
/// Safety: This validation is critical to prevent calculations with undefined states.
bool isFiniteNumber(double value) {
  return !value.isNaN && !value.isInfinite;
}

/// Sanitizes the provided double value to ensure it is a finite number.
/// Intercepts NaN and returns the [fallback] value (defaults to -1.0).
/// Intercepts positive infinity and returns 1.0.
/// Intercepts negative infinity and returns -1.0.
///
/// Deterministic Guarantee: Ensures that calculation results remain stable and reproducible
/// even in the presence of arithmetic errors or extreme parameter bounds.
double sanitizeDouble(double value, {double fallback = -1.0}) {
  if (value.isNaN) {
    return fallback;
  }
  if (value == double.infinity) {
    return 1.0;
  }
  if (value == double.negativeInfinity) {
    return -1.0;
  }
  return value;
}

/// Safely performs division by adding an epsilon stabilizer to the denominator.
///
/// If [denominator] is 0.0, the calculation adds [epsilon] to prevent a division-by-zero error.
/// Sanitizes the input values first to ensure no NaN or Infinity is passed.
///
/// Deterministic Guarantee: Returns a stable finite result instead of throwing an exception or
/// returning positive infinity.
double safeDivide(double numerator, double denominator,
    {double epsilon = defaultEpsilon}) {
  final cleanNumerator = sanitizeDouble(numerator, fallback: 0.0);
  final cleanDenominator = sanitizeDouble(denominator, fallback: epsilon);

  // Apply division stabilizer to protect denominator from zero values.
  final safeDenom = cleanDenominator == 0.0
      ? (cleanDenominator >= 0.0 ? epsilon : -epsilon)
      : cleanDenominator;

  return cleanNumerator / safeDenom;
}

/// Clamps the value to the specified lower and upper bounds.
/// Sanitizes the value first to guarantee it is a finite real number before clamping.
///
/// Safety: Ensures that parameters like probability (range [0.0, 1.0]) or impact
/// (range [-1.0, 1.0]) are strictly within their theoretical boundaries.
double safeClamp(double value, double lower, double upper) {
  final cleanVal = sanitizeDouble(value, fallback: lower);
  if (cleanVal < lower) {
    return lower;
  }
  if (cleanVal > upper) {
    return upper;
  }
  return cleanVal;
}

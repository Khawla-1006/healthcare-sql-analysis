
-- DIAGNOSTIC TEST PERFORMANCE ANALYSIS
-- Glucose test limitations

-- ============================================
-- CONFUSION MATRIX for Glucose Test (≥126 as cutoff)
-- ============================================

WITH confusion_matrix AS (
  SELECT 
    -- Test result (using glucose ≥ 126 as positive test)
    CASE 
      WHEN Glucose >= 126 THEN 'Test Positive (High Glucose)'
      ELSE 'Test Negative (Normal/Pre-diabetic)'
    END as test_result,
    
    -- Actual condition
    CASE 
      WHEN Outcome = 1 THEN 'Actually Diabetic'
      ELSE 'Actually Non-Diabetic'
    END as actual_condition,
    
    COUNT(*) as count
    
  FROM diabetes_analysis_ready
  WHERE Glucose IS NOT NULL
  GROUP BY 1, 2
),
totals AS (
  SELECT 
    SUM(CASE WHEN actual_condition = 'Actually Diabetic' THEN count ELSE 0 END) as total_diabetic,
    SUM(CASE WHEN actual_condition = 'Actually Non-Diabetic' THEN count ELSE 0 END) as total_non_diabetic,
    SUM(count) as total_patients
  FROM confusion_matrix
)
SELECT 
  test_result,
  actual_condition,
  cm.count,
  
  -- Standard diagnostic metrics
  CASE 
    WHEN test_result = 'Test Positive (High Glucose)' AND actual_condition = 'Actually Diabetic' THEN
      CONCAT('True Positive: ', ROUND(100.0 * cm.count / t.total_diabetic, 1), '% of diabetics detected')
    WHEN test_result = 'Test Positive (High Glucose)' AND actual_condition = 'Actually Non-Diabetic' THEN
      CONCAT('False Positive: ', ROUND(100.0 * cm.count / t.total_non_diabetic, 1), '% of non-diabetics incorrectly flagged')
    WHEN test_result = 'Test Negative (Normal/Pre-diabetic)' AND actual_condition = 'Actually Diabetic' THEN
      CONCAT('False Negative: ', ROUND(100.0 * cm.count / t.total_diabetic, 1), '% of diabetics missed')
    WHEN test_result = 'Test Negative (Normal/Pre-diabetic)' AND actual_condition = 'Actually Non-Diabetic' THEN
      CONCAT('True Negative: ', ROUND(100.0 * cm.count / t.total_non_diabetic, 1), '% of non-diabetics correctly identified')
  END as metric_interpretation,
  
  
  CASE 
    WHEN test_result = 'Test Positive (High Glucose)' THEN
      CONCAT('Of patients with positive test (high glucose): ', 
      ROUND(100.0 * 
        SUM(CASE WHEN actual_condition = 'Actually Diabetic' THEN cm.count ELSE 0 END) OVER (PARTITION BY test_result) /
        SUM(cm.count) OVER (PARTITION BY test_result),
      1), '% actually have diabetes')
    ELSE ''
  END as ppv_interpretation
  
FROM confusion_matrix cm, totals t
ORDER BY 
  CASE test_result 
    WHEN 'Test Positive (High Glucose)' THEN 1 
    ELSE 2 
  END,
  CASE actual_condition 
    WHEN 'Actually Diabetic' THEN 1 
    ELSE 2 
  END;

/* INSIGHT:
  - The glucose test (≥126 cutoff) shows a significant false positive rate:
      many patients with high glucose do not have diabetes. 
    - While a high glucose level is indicative, it is not definitive for diabetes diagnosis.
    - Clinical diagnosis should incorporate additional tests (e.g., HbA1c) and patient history.
*/
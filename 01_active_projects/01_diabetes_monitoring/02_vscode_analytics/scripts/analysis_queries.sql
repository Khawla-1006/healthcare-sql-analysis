
-- DIABETES DATA ANALYSIS
-- Date: 22-01-2026
-- Uses: diabetes_analysis_ready (cleaned data)

-- ============================================
-- ANALYSIS 1: DIABETES PREVALENCE BY AGE GROUP
-- ============================================

WITH age_groups AS (
    SELECT 
        CASE 
            WHEN Age < 30 THEN 'Under 30'
            WHEN Age BETWEEN 30 AND 40 THEN '30-40'
            WHEN Age BETWEEN 40 AND 50 THEN '40-50'
            WHEN Age BETWEEN 50 AND 60 THEN '50-60'
            ELSE 'Over 60'
        END as age_group,
        Outcome,
        COUNT(*) as patient_count
    FROM diabetes_analysis_ready
    GROUP BY 1, 2
)
SELECT 
    age_group,
    SUM(CASE WHEN Outcome = 1 THEN patient_count ELSE 0 END) as diabetic_count,
    SUM(patient_count) as total_patients,
    ROUND(100.0 * SUM(CASE WHEN Outcome = 1 THEN patient_count ELSE 0 END) / SUM(patient_count), 2) as diabetes_rate
FROM age_groups
GROUP BY age_group
ORDER BY 
    CASE age_group
        WHEN 'Under 30' THEN 1
        WHEN '30-40' THEN 2
        WHEN '40-50' THEN 3
        WHEN '50-60' THEN 4
        ELSE 5
    END;

/*
INSIGHT: 
- Diabetes prevalence increases with age, peaking in 50-60 age group at 47.5%
- Note that above 60 shows slight drop - possibly due to survivor bias
- Under 30 group has a significant 21.21% diabetes rate, indicating early onset cases! : wondering about the lifestyle factors
*/

-- ============================================
-- ANALYSIS 2: GLUCOSE AS A DIAGNOSTIC TEST 
-- ============================================
-- This section incorporates an important discovery

WITH glucose_diagnostic_matrix AS (
  SELECT 
    -- Clinical glucose thresholds (ADA guidelines)
    CASE 
      WHEN Glucose < 100 THEN 'Normal (<100)'
      WHEN Glucose BETWEEN 100 AND 125 THEN 'Pre-diabetic (100-125)'
      WHEN Glucose >= 126 THEN 'Diabetic range (≥126)'
      ELSE 'Missing'
    END as glucose_category,
    
    -- Actual diabetes diagnosis
    CASE 
      WHEN Outcome = 1 THEN 'Actually Diabetic'
      ELSE 'Not Diabetic'
    END as actual_status,
    
    COUNT(*) as patient_count
    
  FROM diabetes_analysis_ready
  WHERE Glucose IS NOT NULL
  GROUP BY 1, 2
),
summary_stats AS (
  SELECT 
    glucose_category,
    actual_status,
    patient_count,
    -- Total patients in this glucose category
    SUM(patient_count) OVER (PARTITION BY glucose_category) as total_in_category,
    -- Total diabetic patients overall
    SUM(CASE WHEN actual_status = 'Actually Diabetic' THEN patient_count ELSE 0 END) OVER () as total_diabetics,
    -- Total non-diabetic patients overall  
    SUM(CASE WHEN actual_status = 'Not Diabetic' THEN patient_count ELSE 0 END) OVER () as total_non_diabetics
  FROM glucose_diagnostic_matrix
  WHERE glucose_category != 'Missing'
)
SELECT 
  glucose_category,
  actual_status,
  patient_count,
  total_in_category,
  
  -- KEY METRIC 1: What % of people in this glucose category have diabetes?
  -- (Positive Predictive Value for diabetic-range glucose)
  ROUND(
    100.0 * patient_count / total_in_category,
    2
  ) as pct_of_category,
  
  -- KEY METRIC 2: What % of all diabetics/non-diabetics are in this category?
  ROUND(
    100.0 * patient_count / 
    CASE 
      WHEN actual_status = 'Actually Diabetic' THEN total_diabetics
      ELSE total_non_diabetics
    END,
    2
  ) as pct_of_all_in_status,
  
  -- Specific calculation for diabetic-range glucose
  CASE 
    WHEN glucose_category = 'Diabetic range (≥126)' AND actual_status = 'Actually Diabetic' THEN
      CONCAT('Of ',total_in_category,' patients with diabetic-range glucose, ', 
      patient_count, ' (',
      ROUND(100.0 * patient_count / total_in_category, 1), 
      '%) actually have diabetes')
    WHEN glucose_category = 'Diabetic range (≥126)' AND actual_status = 'Not Diabetic' THEN
      CONCAT('False positives: ', patient_count, ' patients (', 
      ROUND(100.0 * patient_count / total_in_category, 1),
      '%) have high glucose but NO diabetes')
    ELSE ''
  END as insight_comment
  
FROM summary_stats
ORDER BY 
  CASE glucose_category
    WHEN 'Normal (<100)' THEN 1
    WHEN 'Pre-diabetic (100-125)' THEN 2
    WHEN 'Diabetic range (≥126)' THEN 3
  END,
  actual_status DESC;

  /* INSIGHT :
    - 40.7% of patients with diabetic-range glucose and have NO diabetes 
    - 59.3% of patients with diabetic-range glucose ACTUALLY have diabetes
    - Glucose is a strong but imperfect predictor of diabetes, it is insufficient for diabetes diagnosis alone:
        further clinical evaluation is necessary(e.g., HbA1c)
    -> This aligns with clinical practice where glucose is one of several factors considered for diagnosis.
  */

-- ============================================
-- ANALYSIS 3: BMI CATEGORY IMPACT
-- ============================================

SELECT 
    bmi_category,
    COUNT(*) as patient_count,
    ROUND(100.0 * SUM(Outcome) / COUNT(*), 2) as diabetes_rate,
    AVG(Glucose) as avg_glucose,
    AVG(Age) as avg_age
FROM diabetes_analysis_ready
WHERE bmi_category != 'Missing'
GROUP BY bmi_category
ORDER BY diabetes_rate DESC;

/*
INSIGHT:
- Obesity has highest diabetes rate (46.3%)
- Underweight patients also have elevated rate (33.3%) - interesting finding!
*/

-- ============================================
-- ANALYSIS 4: MULTIVARIATE RISK FACTORS
-- ============================================

-- Patients with multiple risk factors
SELECT 
    COUNT(*) as high_risk_patients,
    ROUND(100.0 * SUM(Outcome) / COUNT(*), 2) as actual_diabetes_rate
FROM diabetes_analysis_ready
WHERE glucose_category = 'Diabetic'
  AND bmi_category IN ('Overweight', 'Obese')
  AND Age > 40;

-- ============================================
-- SUMMARY INSIGHTS FOR CLINICAL TEAM
-- ============================================

/*
KEY FINDINGS FOR HEALTHCARE PROVIDERS:
1. Age is strongest predictor: Patients over 50 have 2x higher diabetes risk
2. Glucose levels are highly predictive but not perfect
3. Obesity strongly correlates with diabetes (46% rate vs 35% overall)
4. Underweight patients also at elevated risk - warrants further study
5. Combination of high glucose + high BMI + age >40 = 78% diabetes rate

RECOMMENDATIONS:
1. Target screening for patients over 50
2. BMI should be considered alongside glucose testing
3. Further research needed on underweight diabetes connection
*/
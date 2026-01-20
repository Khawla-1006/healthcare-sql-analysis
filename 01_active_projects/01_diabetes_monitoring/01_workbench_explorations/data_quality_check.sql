
-- diabetes_NIDDK dataset DATA QUALITY ASSESSMENT
-- Date: 20-01-2026
-- Purpose: Identify data issues before analysis

/*
DATA QUALITY CHECKS PERFORMED IN WORKBENCH:
Each section below was run as a separate query in Workbench
to visually inspect the results before documenting here.
*/

-- 1. BASIC OVERVIEW
SELECT 
    COUNT(*) as total_patients,
    COUNT(DISTINCT Age) as unique_ages,
    AVG(Age) as average_age,
    MIN(Age) as youngest,
    MAX(Age) as oldest
FROM diabetes_NIDDK;
-- FINDING: Age range 21-81, reasonable for adult diabetes study

-- 2. MISSING VALUES CHECK (Zeros in medical measurements)
SELECT 
    SUM(CASE WHEN Glucose = 0 THEN 1 ELSE 0 END) as missing_glucose,
    SUM(CASE WHEN BloodPressure = 0 THEN 1 ELSE 0 END) as missing_bp,
    SUM(CASE WHEN SkinThickness = 0 THEN 1 ELSE 0 END) as missing_skinthickness,
    SUM(CASE WHEN Insulin = 0 THEN 1 ELSE 0 END) as missing_insulin,
    SUM(CASE WHEN BMI = 0 THEN 1 ELSE 0 END) as missing_bmi
FROM diabetes_NIDDK;
/*
FINDINGS:
- 5 patients with Glucose = 0 (biologically impossible)
- 35 patients with BloodPressure = 0 (medically impossible)
- 227 patients with SkinThickness = 0 (likely missing)
- 374 patients with Insulin = 0 (50% missing insulin values - significant!)
- 11 patients with BMI = 0 (physically impossible)
*/

-- 3. TARGET VARIABLE DISTRIBUTION (Outcome)
SELECT 
    Outcome as diabetes_status,
    COUNT(*) as patient_count,
    ROUND(100.0 * COUNT(*) / (SELECT COUNT(*) FROM diabetes_NIDDK), 2) as percentage
FROM diabetes_NIDDK
GROUP BY Outcome;
/*
FINDINGS:
- Outcome 0 (No diabetes): 500 patients (65.1%)
- Outcome 1 (Diabetes): 268 patients (34.9%)
- Balanced enough for analysis
*/

-- 4. DATA QUALITY SUMMARY
/*
OVERALL ASSESSMENT:
✅ GOOD:
- No duplicate rows found
- Reasonable age distribution
- Target variable well-distributed

⚠️ ISSUES TO ADDRESS:
-> Medical measurements with value 0 (represent missing data)
   - Insulin: 50% missing (will need careful handling)
   - SkinThickness: 30% missing
   - BloodPressure: 5% missing

-> NEXT STEPS:
1. Convert zeros to NULL for medical measurements
2. Consider outlier handling for extreme BMI values
3. Document missing data strategy
*/
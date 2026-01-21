
-- DIABETES DATA CLEANING PROCESS
-- Date: 21-01-2026


/*
CLEANING DECISIONS (Based on Workbench findings):
1. Zeros in medical measurements = Missing data (convert to NULL)
2. Keep extreme BMI values (medically possible, just rare)
3. Create cleaned view for analysis
*/

-- ============================================
-- STEP 1: CREATE CLEANED VERSION OF DATA
-- ============================================

CREATE OR REPLACE VIEW diabetes_patients_clean AS
SELECT 
    Pregnancies,
    
    -- Medical measurements: Convert zeros to NULL
    CASE WHEN Glucose = 0 THEN NULL ELSE Glucose END as Glucose,
    CASE WHEN BloodPressure = 0 THEN NULL ELSE BloodPressure END as BloodPressure,
    CASE WHEN SkinThickness = 0 THEN NULL ELSE SkinThickness END as SkinThickness,
    CASE WHEN Insulin = 0 THEN NULL ELSE Insulin END as Insulin,
    CASE WHEN BMI = 0 THEN NULL ELSE BMI END as BMI,
    
    DiabetesPedigreeFunction,
    Age,
    Outcome,
    
    -- Add derived columns for analysis
    CASE 
        WHEN Glucose IS NULL THEN 'Missing'
        WHEN Glucose < 100 THEN 'Normal'
        WHEN Glucose BETWEEN 100 AND 125 THEN 'Pre-diabetic'
        ELSE 'Diabetic'
    END as glucose_category,
    
    CASE 
        WHEN BMI IS NULL THEN 'Missing'
        WHEN BMI < 18.5 THEN 'Underweight'
        WHEN BMI BETWEEN 18.5 AND 25 THEN 'Normal'
        WHEN BMI BETWEEN 25 AND 30 THEN 'Overweight'
        ELSE 'Obese'
    END as bmi_category
    
FROM diabetes_NIDDK;

-- ============================================
-- STEP 2: VALIDATE CLEANING
-- ============================================

-- Check missing values after cleaning
SELECT 
    'After Cleaning' as stage,
    COUNT(*) as total_patients,
    SUM(CASE WHEN Glucose IS NULL THEN 1 ELSE 0 END) as missing_glucose,
    SUM(CASE WHEN Insulin IS NULL THEN 1 ELSE 0 END) as missing_insulin,
    ROUND(100.0 * SUM(CASE WHEN Glucose IS NULL THEN 1 ELSE 0 END) / COUNT(*), 2) as pct_missing_glucose
FROM diabetes_patients_clean;

-- Compare with original (from Workbench findings)
/*
BEFORE CLEANING (from data_quality_check.sql):
- Missing glucose: 5 patients (0.65%)
- Missing insulin: 374 patients (48.7%)

AFTER CLEANING:
- Missing glucose: 5 patients (0.65%) ✓
- Missing insulin: 374 patients (48.7%) ✓
- Now properly labeled as NULL instead of 0
*/

-- ============================================
-- STEP 3: CREATE ANALYSIS-READY TABLE
-- ============================================

CREATE TABLE diabetes_analysis_ready AS
SELECT * FROM diabetes_patients_clean;

-- Add index for performance
CREATE INDEX idx_glucose ON diabetes_analysis_ready(Glucose);
CREATE INDEX idx_outcome ON diabetes_analysis_ready(Outcome);

SELECT 'Data cleaning complete. Analysis-ready table created.' as status;
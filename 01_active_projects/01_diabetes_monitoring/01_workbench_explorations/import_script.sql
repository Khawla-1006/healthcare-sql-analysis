
-- DIABETES DATASET IMPORT PROCESS:
-- Date: 20-01-2026
-- Analyst: BEN NACEUR Khawla


-- DATA SOURCE INFORMATION:
-- Name: Diabetes Database
-- Source: Kaggle.com : https://www.kaggle.com/datasets/akshaydattatraykhare/diabetes-dataset 
-- Original Source: This dataset is originally from the National Institute of Diabetes and Digestive and Kidney Diseases (NIDDK).
-- Description: Diagnostic measurements for diabetes prediction
-- Rows: 768
-- Columns: 9


-- IMPORT METHOD: MySQL Workbench Import Wizard :
-- Downloaded CSV from Kaggle.com. 
-- In Workbench: Right-click database → Table Data Import Wizard. 
-- Selected diabetes_NIDDK.csv  Created new table: diabetes_NIDDKs . 
-- Used these settings:   
-- - Format: CSV   - Encoding: UTF-8   - Header: Yes (first row contains column names)   - Delimiter: Comma   - Quote char: "


-- COLUMN MAPPING (Workbench detected):
-- 1. Pregnancies → INT
-- 2. Glucose → INT  
-- 3. BloodPressure → INT
-- 4. SkinThickness → INT
-- 5. Insulin → INT
-- 6. BMI → DECIMAL(5,2)
-- 7. DiabetesPedigreeFunction → DECIMAL(5,3)
-- 8. Age → INT
-- 9. Outcome → INT (0 = No diabetes, 1 = Diabetes)



-- IMPORT ISSUES ENCOUNTERED:
-- 1. Some zeros in medical measurements (likely missing data)
-- 2. Workbench warning: "Some columns contain zeros where not expected"
-- 3. Handled by: Importing as-is, will clean in data_cleaning.sql



-- VALIDATION QUERY AFTER IMPORT:

-- Check total rows : 768 rows imported ✓
SELECT * 
FROM diabetes_NIDDK; 

-- Test queries to validate data integrity: 
-- get average age of patients:
SELECT AVG(age) AS avg_age
FROM diabetes_NIDDK;
-- get patients with diabetes:
SELECT * FROM diabetes_NIDDK
WHERE Outcome = 1
ORDER BY Glucose DESC;
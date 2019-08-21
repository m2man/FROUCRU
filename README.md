# FROUCRU INSTRUCTION

## Summary
This project (**F**OI **R**egression **OUCRU**) is about using a simple regression algorithm to estimate FOI at regions where we do not have age-stratified cases data. Regarding the regions we have data, we perform Catalytic model to find the FOI distribution at these regions, then use them as training data to estimate FOI. The project is in R programming language.

The main workflow is as followed:
1. **Summary feature for each Study region** (Study region is a region where we have age-stratified case data and run Catalytic Model to estimate FOI for that region). Since the dataframe **Imputed_Features_Study.Rds** is at pixel-level, we need to aggregate it into region-level. The Feature of a region will be a summary (sum, mean, ...) of Feature of all pixels belong to that Study region.

2. **Assign new FOI data** to the Summaried Feature dataframe. Infact, since Quan produced new FOI estimation from Catalytic Model and also removed some regions, hence we need to perform this step to match new FOI estimation and find out which regions were removed (Quan has changed the names of regions also) 

3. **Run the regression** on the Summarized Feature with new FOI dataframe. We also divided into 3 subset: Train - Validate - Test subsets. Note that if the result of the regression is negative, we will make it to 0.


#### Libraries
Need to install rgdal, rgeos, sp, ggplot2, gridExtra
<br/>Optional: neuralnet

## Core Functions
### Step 1: Summary feature for Study Regions

**Input**

**Output**

**Function**

### Step 2: Assign new FOI data

**Input**

**Output**

**Function**

### Step 3: Run the regression

**Input**

**Output**

**Function**
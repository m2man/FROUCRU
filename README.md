# FROUCRU INSTRUCTION

## Summary
This project (**F**OI **R**egression **OUCRU**) is about using a simple regression algorithm to estimate FOI at regions where we do not have age-stratified cases data. Regarding the regions we have data, we perform Catalytic model to find the FOI distribution at these regions, then use them as training data to estimate FOI. The project is in R programming language.

The main workflow is as followed:
1. **Summary feature for each Study region** (Study region is a region where we have age-stratified case data and run Catalytic Model to estimate FOI for that region). Since the dataframe **Imputed_Features_Study.Rds** is at pixel-level, we need to aggregate it into region-level. The Feature of a region will be a summary (sum, mean, ...) of Feature of all pixels belong to that Study region. ([Go to Step 1](#step-1-summary-feature-for-study-regions))

2. **Assign new FOI data** to the Summaried Feature dataframe. Infact, since Quan produced new FOI estimation from Catalytic Model and also removed some regions, hence we need to perform this step to match new FOI estimation and find out which regions were removed (Quan has changed the names of regions also).([Go to Step 2](#step-2-assign-new-foi-data)) 

3. **Run the regression** on the Summarized Feature with new FOI dataframe. We also divided into 3 subset: Train - Validate - Test subsets. Note that if the result of the regression is negative, we will make it to 0. ([Go to Step 3](#step-3-run-the-regression))


#### Libraries
Need to install rgdal, rgeos, sp, ggplot2, gridExtra
<br/>Optional: neuralnet

## Core Functions
### Step 1: Summary feature for Study Regions
Since the idea of this regression is to run regression at entire catchment (Study) area level, we need to find features for each study region. We can use the **Imputed_Features_Study.Rds** dataframe from **_Step 4_** of **_JERFOUCRU project_**. Because the dataframe is at pixel level, we need to aggregate it to get the feature values at study region level. Some basic methods are applied. For instance Population feature, we take the sum of all values in pixels that are inside a study region to get the total population of that region and make it become one feature for the study region. We also applied Mean, or majority vote for other features. The output will be generated in **_Generate/_** folder.

**Input**
- **Imputed_Features_Study.Rds** and **Coordinates_Index_Study.Rds** from **_JERFOUCRU project_** to know which pixels belong to which Studies.
- India and Nepal SHP file: since 2 countries have complicated overlay issues, we need their geographical shapefiles to solve
- FOI shapefile: to get the FOI data for Taiwan and Nepal. Original FOI data has 53 studies, but 2 of them (Taiwan and Nepal) are totally overlaied. Therefore the dataframe only consisted of 51 studies. But for this study-level regression, we also need these 2 countries.

**Output**
- **DataRegression.Rds**: The summarized features at each study.

**Function**
- **Summary_Feature_Regions**: Run to create the summarized Study Feature dataframe.

### Step 2: Assign new FOI data
Because of the new FOI estimation issue, the regions' names of Random Forest data are now different to the new estimation (although they are the same studies). **Besides, Quan also removed some regions (Seoul, China, Chitwan, 7.up.dist.assam).** This step include 2 parts: firstly the script will find the regions appearing in both old and new data, then it assign new FOI estimation to these regions and to the summarized study feature dataframe **DataRegression.Rds**. The output will be generated in **_Generate/_** folder.

**Input**
- **DataRegression.Rds**: Summarized study feature dataframe created from [Step 1](#step-1-summary-feature-for-study-regions)
- FOI shapefile: old FOI estimation
- **shapefiles_FOI_data_merged_region.rds**: New FOI estimation (stored in **_Data/_** folder)

**Output**
- **match_region_foi_dist.Rds**: result of the 1st part. It is a dataframe with 3 columns: Regions (new data but in the old names), FOI_dist (new FOI distribution estimation), FOI_mean (mean of FOI_dist)
- **DataRegression_NewFOI.Rds**: result of the 2nd part. Matched New FOI estimation with Summarized Study Feature dataframe. We will use this to run the regression in [Step 3](#step-3-run-the-regression).

**Function**
- **Match_Old_New_FOI_Data_Region**: run this script to match the regions in both old and new estimation and match new FOI to the summarized study feature dataframe.

### Step 3: Run the regression
The data is now ready. We can run the linear regression to train the model. The script also provide 2 other options: logistic regression and neural networks. The output will be generated in **_Generate/_** folder.

**Input**
- **DataRegression_NewFOI.Rds**: The dataframe including features and FOI values for the model (train-validate-test)
- **match_region_foi_dist.Rds**: the dataframe including name of regions (new data but in the old names) and FOI distribution. We only use this dataframe for visualizing (ploting the comparison between the result of regression and the data)

**Output**
- **Model_Linear_Regression.Rds**: the training linear regression model
- **FOI_Regression_[Regions].png**: figures illustrating the predicted FOI and the training/validating FOI values.

**Function**
- **Run_Regression**: Perform the regression, calculate the R-square, and plot the result compared with the FOI data used for train/validate.
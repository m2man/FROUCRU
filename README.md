# FROUCRU INSTRUCTION

## Summary
This project (Foi Regression OUCRU) is about using a simple regression algorithm to estimate FOI at regions where we do not have age-stratified cases data. Regarding the regions we have data, we perform Catalytic model to find the FOI distribution at these regions, then use them as training data to estimate FOI. The project is in R programming language.

This project will need the dataframe **Imputed_Features_Study.Rds** (from JERFOUCRU project). The main workflow is as followed:
1. Summary feature for each Study region (Study region is a region where we have age-stratified case data and run Catalytic Model to estimate FOI for that region). Since the dataframe **Imputed_Features_Study.Rds** is at pixel-level, we need to aggregate it into region-level. The Feature of a region will be a summary (sum, mean, ...) of Feature of all pixels belong to that Study region.

#### Libraries
Need to install rgdal, rgeos, sp

## Core Functions

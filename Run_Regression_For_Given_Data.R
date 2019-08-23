# --- NOTE ---
# This script is used to run the trained model to predict FOI to the given dataset
# Usually use this after you run the Summary_Feature_Given_Shapefile.R
# ---------- #

cat('===== START [Run_Regression_For_Given_Data.R] =====\n')

# ===== DEFINE FUNCTIONS =====
Predict_Linear_Model <- function(model, data){
    # data contains only ft, not including outcome
    predict <- predict(model, data)
    predict[predict < 0] <- 0
    return(as.numeric(predict))
}

Standardize_DF <- function(df, mean_vec, std_vec){
    # Standardize df based on mean_vec and std_vec
    for (i in 1 : length(mean_vec)){
        df[[i]] <- (df[[i]] - mean_vec[[i]])/std_vec[[i]]
    }
    return(df)
}

# ===== READ DATA =====
data_test <- readRDS('Generate/Feature_VNM.Rds')
model <- readRDS('Generate/Model_Linear_Regression.Rds')
paras <- readRDS('Generate/Parameter_Model.Rds')

# ===== PROCESSING =====
# Which features have been used to train the model
features_name <- names(model$coefficients)
features_name <- features_name[-1] # remove "Intercept"

# Extract features (have been used in the model) in data_test --> since may be data_test include other features
idx_feature_data_test <- which(colnames(data_test) %in% features_name)
data_test <- data_test[ , idx_feature_data_test]

# Standardize
data_test_standardized <- Standardize_DF(data_test, paras$mean_train, paras$std_train)

# Run prediction
prediction <- Predict_Linear_Model(model, data_test_standardized)

cat('Estimated FOI:', prediction, '\n')

cat('===== FINISH [Run_Regression_For_Given_Data.R] =====\n')
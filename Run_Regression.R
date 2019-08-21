# --- NOTE --- #
# Read entire datasets (DataRegression_NewFOI.Rds)
# Divide into train test validate
# run simple regession and check
# ------------ #

library(neuralnet)
library(ggplot2)
library(gridExtra)

cat('===== START [Run_Regression.R] =====\n')

## Get directory of the script (this part only work if source the code, wont work if run directly in the console)
## This can be set manually !!! -->setwd('bla bla bla')
script.dir <- dirname(sys.frame(1)$ofile)
script.dir <- paste0(script.dir, '/')
setwd(script.dir)

## Create folder to store the result (will show warnings if the folder already exists --> but just warning, no problem)
dir.create(file.path('Generate/'), showWarnings = TRUE)

Savepath <- 'Generate/' # Savepath here also used for read the generated file from Step 1, 2
Datapath <- 'Data/'

# ===== FUNCTIONS =====
sigmoid_function <- function(x){ # Sigmoid function --> Used in Neural Network
    1 / (1 + exp(-x)) 
} 

RSQ <- function(p, a){ # Function to calculate R-squared
    mse <- mean((p - a)^2)
    rsq <- 1 - mse / var(a)
    return (rsq)
}

Predict_Linear_Model <- function(model, data){
    # data contains only ft, not including outcome
    predict <- predict(model, data)
    predict[predict < 0] <- 0
    return(predict)
}

Standardize_Train <- function(df){
    # Standardize training data and result is standardized df, parameter of standardization
    # Standardize: (x - mean) / std
    mean_vec <- numeric()
    std_vec <- numeric()
    for (i in 1 : (ncol(df) - 1)){ # except label (last column)
        mean_vec <- c(mean_vec, mean(df[[i]]))
        std_vec <- c(std_vec, sd(df[[i]]))
        df[[i]] <- (df[[i]] - mean_vec[i]) / std_vec[[i]]
    }
    output <- list(df, mean_vec, std_vec)
    return(output)
}

Standardize_DF <- function(df, mean_vec, std_vec){
    # Standardize df based on mean_vec and std_vec
    for (i in 1 : length(mean_vec)){
        df[[i]] <- (df[[i]] - mean_vec[[i]])/std_vec[[i]]
    }
    return(df)
}

set.seed(5)

# ===== Read dataset =====
dataset <- readRDS(paste0(Savepath, 'DataRegression_NewFOI.Rds')) # Read Study Feature with New FOI data

########## if only bioclimatic 
# dataset <- dataset[,c(1:19, 27)]
########## if only relevant ft (eg: exclude demorgraphy, Urban/Rural, Population)
# dataset <- dataset[,-c(20, 25, 26)]

# ===== Divide into 3 subsets as Train 80% - Validate 10% - Test 10% =====
train_portion <- 0.8
validate_portion <- 0.1

ntotal <- nrow(dataset) 
ntrain <- round(ntotal * train_portion)
nvalidate <- round(ntotal * validate_portion)
ntest <- ntotal - ntrain - nvalidate

# Shuffle
idx_shuffle <- sample(1:ntotal, ntotal)
dataset_shuffle <- dataset[idx_shuffle,]

# 3 Subsets
data_train <- dataset_shuffle[1:ntrain, ]
data_validate <- dataset_shuffle[(ntrain + 1):(ntrain + nvalidate), ]
data_test <- dataset_shuffle[(ntrain + nvalidate + 1) : ntotal, ]

# ===== Standardize data =====
# We need to standardize the training data --> then use this Training standard information to apply for Validate and Testing
# Standardize helps to reduce the significant different within a feature (like Population) --> better result

temp <- Standardize_Train(data_train)
data_train_standardized <- temp[[1]]
mean_train <- temp[[2]]
std_train <- temp[[3]]
rm(temp)

# Use mean and std in Training standardize to standardize validate and test set
data_validate_standardized <- Standardize_DF(data_validate, mean_train, std_train)
data_test_standardized <- Standardize_DF(data_test, mean_train, std_train)

##### VISUALIZE RELATIONSHIP (Optional) #####
# p <- vector('list', ncol(data_train_standardized) - 1)
# for (i in 1 : (ncol(data_train_standardized) - 1)){
#     p[[i]] <- local({
#         i <- i
#         t <- ggplot() + geom_point(aes(x = data_train_standardized[[i]], y = data_train_standardized$FOI)) +
#             labs(x = colnames(data_train_standardized)[i], y = 'FOI')
#         print(t)
#     })
# }
# 
# t1 <- grid.arrange(p[[1]], p[[2]], p[[3]],
#                    p[[4]], p[[5]], p[[6]],
#                    p[[7]], p[[8]], p[[9]], nrow = 3)
# 
# t2 <- grid.arrange(p[[10]], p[[11]], p[[12]],
#                    p[[13]], p[[14]], p[[15]],
#                    p[[16]], p[[17]], p[[18]], nrow = 3)
# 
# t3 <- grid.arrange(p[[19]], p[[20]], p[[21]],
#                    p[[22]], p[[23]], p[[24]],
#                    p[[25]], p[[26]], nrow = 3)

##### TRAINING #####
fmla <- as.formula(paste("FOI ~ ", paste(colnames(data_train_standardized)[-ncol(data_train_standardized)], collapse= "+")))

# linear regression
lmMod <- lm(fmla, data = data_train_standardized)
predict_validate <- Predict_Linear_Model(lmMod, data_validate_standardized[-ncol(data_validate_standardized)])
predict_train <- Predict_Linear_Model(lmMod, data_train_standardized[-ncol(data_train_standardized)])

# Calculate Rsquare
RSQ_validate <- RSQ(predict_validate, data_validate_standardized$FOI)
RSQ_train <- RSQ(predict_train, data_train_standardized$FOI)

# ===== Compare with Rstan Distribution =====
idx_validate <- idx_shuffle[(ntrain + 1):(ntrain + nvalidate)]
idx_train <- idx_shuffle[1 : ntrain]
idx_test <- idx_shuffle[(ntrain + nvalidate + 1) : ntotal]

foi_dist <- readRDS(paste0(Savepath, 'match_region_foi_dist.Rds'))
foi_dist$region <- as.character(foi_dist$region)

Subset_compare <- 'Validate'
# Subset_compare <- 'Train'
# Subset_compare <- 'Test'

if (Subset_compare == 'Validate'){
    idx_compare <- idx_validate
    predict_compare <- predict_validate
}

if (Subset_compare == 'Train'){
    idx_compare <- idx_train
    predict_compare <- predict_train
}

if (Subset_compare == 'Test'){
    # Need to run the predict on Test set
    predict_test <- Predict_Linear_Model(lmMod, data_test_standardized[-ncol(data_test_standardized)])
    RSQ_test <- RSQ(predict_test, data_test_standardized$FOI)
    idx_compare <- idx_test
    predict_compare <- predict_test
}

for (i in 1 : length(idx_compare)){
    idx_temp <- idx_compare[i]
    idx_region <- which(foi_dist$FOI_mean %in% dataset$FOI[idx_temp])
    cat('Processing', foi_dist$region[idx_region], '...\n')
    data_plot <- data.frame(Region = foi_dist$region[idx_region], 
                            Dist = as.numeric(foi_dist$FOI_dist[[idx_region]]))
    data_reg <- data.frame(FOI = c(predict_compare[i], mean(data_plot$Dist)), 
                           Method = c('Regression', 'Mean-Rstan'))
    
    color <- c("#e41a1c", "#377eb8")
    names(color) <- c('Regression', 'Mean-Rstan')
    colmeanscale <- scale_color_manual(name = 'Method', values = color)
    
    p <- ggplot(data = data_plot, aes(x = Dist, fill = Region)) + geom_density(alpha=0.3, position="identity") + 
        scale_fill_manual(values = "#56B4E9") + 
        geom_vline(aes(xintercept = FOI, color = Method), data = data_reg, linetype = 'twodash', size = 0.65) + colmeanscale +
        labs(title = paste0('[', Subset_compare, '] FOI Rstan vs Regression Comparison - ', foi_dist$region[idx_region]), y = 'Density', x = 'FOI') + 
        theme(axis.text.y = element_blank(),
              axis.ticks.y = element_blank(),
              axis.title.x = element_text(size = 14),
              axis.title.y = element_text(size = 14),
              legend.direction = 'horizontal',
              legend.justification = c(1,1), legend.position=c(1,1),
              legend.background = element_rect(fill = 'transparent'),
              plot.title = element_text(size = 16, face = 'bold'))
    ggsave(filename = paste0(Savepath, 'FOI_Regression_', foi_dist$region[idx_region], '.png'), 
           width = 108*2.5, height = 72*2.5, units = 'mm', plot = p)
}

## Try logistic regression
# glmMod <- glm(fmla, data = data_train_standardized, family = binomial)
# predict <- predict(glmMod, data_validate_standardized[-ncol(data_validate_standardized)], type = 'response')
# RSQ(predict, data_validate_standardized$FOI)
# 
## Try neural net ~ sigmoid function
# nn=neuralnet(fmla,data=data_train_standardized, hidden= c(50), threshold = 0.001, stepmax = 1000000,
#              algorithm = 'backprop',
#              learningrate = 0.01,
#              act.fct = sigmoid_function,
#              linear.output = FALSE)
# predict_nn = compute(nn, data_validate_standardized)
# predict_nn = c(predict_nn$net.result)
# RSQ(predict_nn, data_validate_standardized$FOI)
# 
## Try to predict FOI at pixel-level
# AllDF_WP_Land <- readRDS("~/DuyNguyen/RProjects/OUCRU JE/Data JE/Data_RF/AllDF_WP_Land.Rds")
# entire <- AllDF_WP_Land[,c(-1, -2, -30)]
# entire$UR <- as.numeric(entire$UR)
# entire_standardized <- Standardize_DF(entire, mean_train, std_train)
# predict_nn = compute(nn, entire_standardized)
# predict_nn = c(predict_nn$net.result)
# df <- AllDF_WP_Land[,c(1, 2)]
# df <- cbind(df, predict_nn)
# 
# Endemic_DF_WP_Imputed_Land <- readRDS("~/DuyNguyen/RProjects/OUCRU JE/Data JE/Data_RF/Endemic_DF_WP_Full_Cov_Imputed_Land.Rds")
# entire <- Endemic_DF_WP_Imputed_Land[,c(-1, -2, -30)]
# entire$UR <- as.numeric(entire$UR)
# entire_standardized <- Standardize_DF(entire, mean_train, std_train)
# predict_nn = compute(nn, entire_standardized)
# predict_nn = c(predict_nn$net.result)
# df <- Endemic_DF_WP_Imputed_Land[,c(1, 2)]
# df <- cbind(df, predict_nn)
# 
# 
# predict <- predict(glmMod, entire_standardized, type = 'response')
# df <- Endemic_DF_WP_Imputed_Land[,c(1, 2)]
# df <- cbind(df, predict)


cat('===== FINISH [Run_Regression.R] =====\n')

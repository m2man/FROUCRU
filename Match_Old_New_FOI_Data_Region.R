### NOTE ###
# Since Quan New data Regions does not match with Old data Regions (old data = data used for random forest) --> Quan remove some regions due to the data limitation
# This file will find the regions appearing in both data frame (Quan new data region's names is different to old, although they are the same region)
# Then match the New FOI data to the old regions --> also remove regions that do not appear in new data
# Finally assign new FOI data to the Study Feature Dataframe
### ---- ###

library(rgdal)

cat('===== START [Match_Old_New_FOI_Data_Region.R] =====\n')

## Get directory of the script (this part only work if source the code, wont work if run directly in the console)
## This can be set manually !!! -->setwd('bla bla bla')
script.dir <- dirname(sys.frame(1)$ofile)
script.dir <- paste0(script.dir, '/')
setwd(script.dir)

## Create folder to store the result (will show warnings if the folder already exists --> but just warning, no problem)
dir.create(file.path('Generate/'), showWarnings = TRUE)

Savepath <- 'Generate/'
Datapath <- 'Data/'
Datapath_SHP_FOI <- 'Data/Shapefile_FOI/'

# ===== DEFINE OWN FUNCTIONS =====
Find_Distance <- function(ptA, ptB){
    # ptA, ptB is coordinates of points --> as vector form
    d <- sqrt(sum((ptA - ptB)**2))
    return(d)
}

Match_Near_Point <- function(dfA, dfB){
    # For each row in dfA, find the nearest row in B
    # dfA, dfB is nrow x 2 dataframe
    Near <- data.frame(idxA = 1 : nrow(dfA), idxB = 0)
    for (i in 1 : nrow(dfA)){
        ptA <- as.numeric(dfA[i, ])
        min <- 10000
        for (j in 1 : nrow(dfB)){
            ptB <- as.numeric(dfB[j, ])
            d <- Find_Distance(ptA, ptB)
            if (d <= min){
                min <- d
                Near$idxB[i] <- j
            }
        }
    }
    return(Near)
}

Match_Near_Point_Vec <- function(vecA, vecB){
    # For each value in vecA, find the nearest value in vecB
    # vecA, vecB is 1D vector
    Near <- data.frame(idxA = 1 : length(vecA), idxB = 0)
    for (i in 1 : length(vecA)){
        dif_abs <- abs(vecA[i] - vecB)
        Near$idxB[i] <- which(dif_abs == min(dif_abs))
    }
    return(Near)
}



# # ----- DUY MAP -----
foi_shp <- readOGR(paste0(Datapath_SHP_FOI, 'FOI_Full.shp')) # FOI use for Random Forest
foi_data_d <- foi_shp@data

if(!file.exists(paste0(Savepath, 'match_region_foi_dist.Rds'))){ # If have not run the matching regions part --> RUN it and save the result
    cat('Matching Regions ...\n')
    # # ----- QUAN MAP -----
    foi_data_q <- readRDS(paste0(Datapath, "shapefiles_FOI_data_merged_region.rds")) # Quan's New data (SpatialPolygonDataframe)
    foi_data_q <- foi_data_q@data
    
    # Take the coordinates of the regions
    coord_d <- foi_data_d[, c(3, 4)]
    coord_q <- foi_data_q[, c(6, 7)]
    
    # For each region name in Quan new data, find the mathcing name of the region in Duy data (Quan old data)
    near_idx <- Match_Near_Point(coord_q, coord_d)
    near_region <- data.frame(regA = foi_data_q$region, regB = foi_data_d$Region[near_idx$idxB])
    # Extract new FOI distribution (Quan new data)
    match_region <- data.frame(region = foi_data_d$Region[near_idx$idxB],
                               FOI_mean = foi_data_q$FOI_value,
                               FOI_dist = foi_data_q$FOI_dist)
    foi_d_q <- match_region[-c(48), ] # remove 1 duplicate 
    
    # This dataframe include 3 column: regions (old name in old data), FOI_mean (mean FOI of new distribution), FOI_dist (New FOI distribution)
    saveRDS(foi_d_q, paste0(Savepath, 'match_region_foi_dist.Rds'))
}else{ # If already run it --> Load the result
    ('Loading Matched Regions ...\n')
    foi_d_q <- readRDS(Savepath, 'match_region_foi_dist.Rds') # Both foi_mean and dist is from new quan data (no ideal where and how to get these)    
}

# ===== MATCH NEW FOI DATA TO THE STUDY FEATURE DATAFRAME =====
cat('Assigning New FOI values to Study Feature Dataframe\n')

DataRegression <- readRDS(paste0(Savepath, "DataRegression.Rds")) # Study Feature Dataframe

# Match the FOI old to the dataframe created above --> New column FOI_Old is the FOI from old data (old data = data use for Random Forest)
idx_match <- sapply(foi_d_q$region, function(x) which(foi_data_d$Region %in% x))
foi_d_q$FOI_Old <- foi_data_d$FOI_val[idx_match]

# Assign New FOI distribution and mean value to the Study Feature dataframe
near_point <- Match_Near_Point_Vec(foi_d_q$FOI_Old, DataRegression$FOI)
idx_remove <- setdiff(1:nrow(DataRegression), near_point$idxB) # setdiff(vecA, vecB): Find elements that appear in vecA, but do not appear in vecB

DataRegression$FOI[near_point$idxB] <- foi_d_q$FOI_mean
DataRegression <- DataRegression[-idx_remove, ]

saveRDS(DataRegression, paste0(Savepath, 'DataRegression_NewFOI.Rds'))


# ===== PLOT New FOI Distribution in IDN (OPTIONAL) =====
# library(ggplot2)
# library(grid)
# library(gridExtra)
# 
# idn1 <- data.frame(idx = 1 : length(foi_d_q$FOI_dist[[which(foi_d_q$region == '6provinces')]]), foi = foi_d_q$FOI_dist[[which(foi_d_q$region == '6provinces')]])
# idn2 <- data.frame(idx = 1 : length(foi_d_q$FOI_dist[[which(foi_d_q$region == 'bali')]]), foi = foi_d_q$FOI_dist[[which(foi_d_q$region == 'bali')]])
# 
# # 6PROVINCES
# p1 <- ggplot(idn1, aes(x = foi)) + geom_density(fill = '#009E73', alpha = 0.45)
# p1 <- p1 + theme(axis.text.x = element_blank(),
#                  axis.text.y = element_blank(),
#                  axis.ticks = element_blank(),
#                  axis.title.x = element_blank(),
#                  axis.title.y = element_text(size = 23),
#                  legend.direction = 'horizontal',
#                  legend.justification = c(1,1), legend.position=c(1,1),
#                  legend.background = element_rect(fill = 'transparent'),
#                  plot.title = element_text(size = 23, face = 'bold')) + 
#     labs(y = 'Density')
# 
# p2 <- ggplot(idn1, aes(y = foi)) + geom_boxplot(fill = '#009E73', alpha = 0.45) + coord_flip() 
# p2 <- p2 + theme(axis.text.y = element_blank(), 
#                  axis.ticks.y = element_blank(),
#                  legend.position = 'none',
#                  axis.title.y = element_text(size = 23),
#                  axis.title.x = element_text(size = 23),
#                  axis.text.x = element_text(size = 20)) + 
#     labs(x = '6 Provinces', y = 'FOI')
# 
# p3 <- grid.arrange(p1, p2, ncol = 1, heights = c(3, 2))
# 
# 
# # BALI
# p1 <- ggplot(idn2, aes(x = foi)) + geom_density(fill = '#009E73', alpha = 0.45)
# p1 <- p1 + theme(axis.text.x = element_blank(),
#                  axis.text.y = element_blank(),
#                  axis.ticks = element_blank(),
#                  axis.title.x = element_blank(),
#                  axis.title.y = element_text(size = 23),
#                  legend.direction = 'horizontal',
#                  legend.justification = c(1,1), legend.position=c(1,1),
#                  legend.background = element_rect(fill = 'transparent'),
#                  plot.title = element_text(size = 23, face = 'bold')) + 
#     labs(y = 'Density')
# 
# p2 <- ggplot(idn2, aes(y = foi)) + geom_boxplot(fill = '#009E73', alpha = 0.45) + coord_flip() 
# p2 <- p2 + theme(axis.text.y = element_blank(), 
#                  axis.ticks.y = element_blank(),
#                  legend.position = 'none',
#                  axis.title.y = element_text(size = 23),
#                  axis.title.x = element_text(size = 23),
#                  axis.text.x = element_text(size = 20)) + 
#     labs(x = 'Bali', y = 'FOI')
# 
# p3 <- grid.arrange(p1, p2, ncol = 1, heights = c(3, 2))

cat('===== FINISH [Match_Old_New_FOI_Data_Region.R] =====\n')
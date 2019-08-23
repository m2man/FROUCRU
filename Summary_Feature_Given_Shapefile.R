# --- NOTE ---
# Extract pixels in a dataframe that are insides a given shapefile SHP
# Then summarize feature
# Use this script to summarize features for regions that you want the regression model to predict FOI at
# ---------- #

library(raster)
library(rgdal)

cat('===== START [Summary_Feature_Given_Shapefile.R] =====\n')

## Get directory of the script (this part only work if source the code, wont work if run directly in the console)
## This can be set manually !!! -->setwd('bla bla bla')
script.dir <- dirname(sys.frame(1)$ofile)
script.dir <- paste0(script.dir, '/')
setwd(script.dir)

## Create folder to store the result (will show warnings if the folder already exists --> but just warning, no problem)
dir.create(file.path('Generate/'), showWarnings = TRUE)

Savepath <- 'Generate/'

# ===== DEFINE FUNCTIONS =====
Find_idx_point_in_SHP <- function(point, shp, 
                                  crs = "+proj=eqc +lat_ts=0 +lat_0=0 +lon_0=0 +x_0=0 +y_0=0 +ellps=WGS84 +datum=WGS84 +units=km +no_defs"){
    # Function to check which index (row) in point dataframe that are inside the shapefile shp
    # Input
    #   - point: dataframe with 2 column x, y which are coordinates of points
    #   - shp: shapefile that you want to check whether which points are inside
    #   - crs: CRS that we want to match both point and shp to (in our case, it is the crs we applied for all map)
    # Output: result is the index of row in point dataframe indicating which points are inside the shp
    
    # convert crs from string to the real crs format
    mycrs <- crs(crs)
    
    # Convert shp to selected crs
    shp <- spTransform(shp, mycrs)
    
    # Convert dataframe to spatial point with selected CRS
    if (class(point) == 'data.frame'){
        coordinates(point) <- ~ x + y
        proj4string(point) <- mycrs    
    }

    # If the point is NOT inside region.shp 
    # --> NA in all columns (maybe there are some columns already had NA values) 
    # --> is.na will be true for all column
    # --> rowsum = number of columns of the dataframe from region.shp
    # --> If rowsum != ncols --> the point is INSIDE region.shp
    point.check <- over(point, shp)
    point.check.na <- is.na(point.check)
    point.rowsum <- as.numeric(rowSums(point.check.na))
    ncoldata <- ncol(region.shp@data)
    idx.point.inside <- which(point.rowsum != ncoldata)
    
    return(idx.point.inside)
}

# crs_string <- "+proj=eqc +lat_ts=0 +lat_0=0 +lon_0=0 +x_0=0 +y_0=0 +ellps=WGS84 +datum=WGS84 +units=km +no_defs"

Summary_Feature <- function(df.region){
    # Summary features for the selected region with its original features dataframe df.region
    # Input: df.region is the dataframe consisted of all features of all pixels belong to the region
    # Output: result is a 1 row dataframe including feature at region-level, aggregating by mean, sum, majority vote, ...
    
    npixel <- nrow(df.region)
    group.region <- df.region[1, ]
    for (idx.col in 1 : ncol(df.region)){
        colname <- colnames(df.region)[idx.col]
        # cat('Colname:', colname, '===== idx.col:', idx.col, '\n')
        if (colname == 'UR'){
            group.region[[idx.col]] <- mean(as.numeric(df.region[[idx.col]]) - 1) # mean of "2" of all
        }else{
            if (colname == 'Rice' || colname == 'Adjusted_Pop_Count_2015'){ # Need to check the name of the column here
                group.region[[idx.col]] <- sum(df.region[[idx.col]]) / npixel # look likes it is the mean
            }else{
                group.region[[idx.col]] <- mean(df.region[[idx.col]])
            }
        }
    }
    
    return(group.region)
}

# ===== READ DATA =====
Region_SHP <- 'Data/Shapefile_Country/gadm36_VNM_0_sp.rds' # Link to the shapefile of the country of interest
region.shp <- readRDS(Region_SHP) # change to readOGR if the file is shapefile SHP

Imputed_Features_Study <- readRDS("Data/Imputed_Features_Study.Rds")
Coordinates_Index_Study <- readRDS("Data/Coordinates_Index_Study.Rds")

# Take the coordinates column
point <- Coordinates_Index_Study[, c(1,2)]

# ===== SUMMARIZE FEATURE =====
cat('Processing ...\n')
# Find points inside selected region.shp
idx.point.inside <- Find_idx_point_in_SHP(point, region.shp)

# Summarize feature of pixels that are inside the selected shapefile
result <- Summary_Feature(Imputed_Features_Study[idx.point.inside,])

result$x <- NULL # Remove coordinates
result$y <- NULL # Remove coordinates
result$FOI <- NULL # Remove FOI since this FOI might not be correct, and the purpose of this script is to just summarize feature and to predict FOI --> FOI is not important here

cat('Saving ...\n')
savename <- 'Feature_VNM.Rds' # Name of the file will be saved
saveRDS(result, paste0(Savepath, savename))

cat('===== FINISH [Summary_Feature_Given_Shapefile.R] =====\n')
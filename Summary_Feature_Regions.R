### NOTE ###
# Used to group pixels to their geographical places
# Summary the features values for each Rstan endemic regions
# First step for simple regression model
# HOW TO PROCESS: 
# Basically, it reverses to the Perform Overlay adjustment in JERFOUCRU
# For example: region 1 is overlay-ed by regions 2 and 3 --> the real feature value for region 1 is the pixel in region 1 + 2 + 3
# For complicated situation (Nepal, India) --> Use SHP file to detect pixel in regions
# For other and non complicated situation (China, ...) --> read Adjust_Overlay.R to have solutions
# IMPORTANT: Taiwan and Nepal is totally overlaid --> total data is 53 but dataframe is 51 --> need to extract 2 hidden regions
## ------ ##

library(rgdal)
library(rgeos)
library(sp)


cat('===== START [Summary_Feature_Regions.R] =====\n')

## Get directory of the script (this part only work if source the code, wont work if run directly in the console)
## This can be set manually !!! -->setwd('bla bla bla')
script.dir <- dirname(sys.frame(1)$ofile)
script.dir <- paste0(script.dir, '/')
setwd(script.dir)

## Create folder to store the result (will show warnings if the folder already exists --> but just warning, no problem)
dir.create(file.path('Generate/'), showWarnings = TRUE)

Savepath <- 'Generate/'
Datapath <- 'Data/'
Datapath_SHP_overlay <- 'Data/Shapefile_Overlay/'
Datapath_SHP_FOI <- 'Data/Shapefile_FOI/'

Create_Region_DF <- function(OriginalDF, idx_region, foi_region){
    # Summary all idx_region indexed rows of OriginalDF into 1 row (by mean or sum or ...)
    df.region <- OriginalDF[idx_region, ]
    npixel <- nrow(df.region)
    group.region <- OriginalDF[1, ]
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
    group.region$FOI <- foi_region
    return(group.region)
}

SHPPath_India <- paste0(Datapath_SHP_overlay, 'India_Map/')
SHPPath_Nepal <- paste0(Datapath_SHP_overlay, 'Nepal_Map/')
mycrs <- CRS("+proj=eqc +lat_ts=0 +lat_0=0 +lon_0=0 +x_0=0 +y_0=0 +ellps=WGS84 +datum=WGS84 +units=km +no_defs")

DataFrame <- readRDS(paste0(Datapath, 'Imputed_Features_Study.Rds')) # FOI here is original from Rstan
DataRegion <- readRDS(paste0(Datapath, 'Coordinates_Index_Study.Rds')) # Study Regions index of every pixel

check <- all(identical(DataFrame$x, DataRegion$x), identical(DataFrame$y, DataRegion$y))
if (!check){
    cat('Coordinates between Feature dataframe and Index dataframe do not match --> NEED TO STOP!\n')
    return()
}

DataFrame$Region <- DataRegion$Region # Extract Study region index
rm(DataRegion) # we do not need it anymore
    
countries <- list(c(1, 2, 4, 7, 9, 10, 11, 12, 16, 34), # CHINA --> Adjust
                  c(29, 31, 32, 33, 35, 36), # Taiwan
                  c(43), # Cambodia
                  c(37, 40), # Vietnam
                  c(3), # Japan
                  c(39), # Laos
                  c(5, 6), # SKOREA --> Adjust
                  c(38), # Philippines
                  c(44), # Thaiand
                  c(49), # Malaysia
                  c(14, 17, 18, 20, 22, 24), # NEPAL --> Adjust
                  c(50, 51), # Indonesia
                  c(8, 13, 15, 19, 21, 23, 25, 26, 27, 28, 41, 42, 45, 46, 47), # INDIA --> Adjust
                  c(30), # Bangladesh
                  c(48)) # SriLanka

names(countries) <- c('China', 'Taiwan', 'Cambodia', 'Vietnam', 'Japan', 'Laos', 'SKorea', 
                      'Philippines', 'Thailand', 'Malaysia', 'Nepal', 'Indonesia',
                      'India', 'Bangladesh', 'SriLanka')
needadjust <- c('China', 'SKorea', 'Nepal', 'India')

# Initialize the final result (0 rows and number-of-features columns) 
Group <- DataFrame[1, ]
Group <- Group[-1, ]

for (country in names(countries)){
    cat('===== Processing:', country, '=====\n')
    regions.country <- countries[[country]] # Take group information of the selected country
    if (country %in% needadjust){ # Adjust groupping
        if (country == 'China'){
            for (region in regions.country){
                if (region %in% c(4, 7, 9, 10, 11, 12, 16, 34)){ # independently (not be overlay-ed) --> easy
                    idx.region <- which(DataFrame$Region == region)
                }else{
                    if (region == 1){ # 1 --> 4, 7, 9, 10, 11, 16, 34 (region 1 is overlay-ed by region 4, 7, 9, ... --> original region 1 = current region 1 + 4 + 7 + ...)
                        idx.region <- which(DataFrame$Region %in% c(1, 4, 7, 9, 10, 11, 16, 34))
                    }else{ # region = 2 --> entire China
                        idx.region <- which(DataFrame$Region %in% c(1, 2, 4, 7, 9, 10, 11, 12, 16, 34))
                    }
                }
                foi.region <- DataFrame$FOI[which(DataFrame$Region == region)][1] # Take the modelled FOI (Rstan) of the selected region
                group.region <- Create_Region_DF(DataFrame, idx.region, foi.region) # Summary feature (by mean, sum, ...)
                group.region$Region <- region
                Group <- rbind(Group, group.region)
            }
        }
        if (country == 'SKorea'){
            for (region in regions.country){
                if (region == 6){ # independently --> easy
                    idx.region <- which(DataFrame$Region == region)
                }else{ # 5 --> 6
                    idx.region <- which(DataFrame$Region %in% c(5, 6))
                }
                foi.region <- DataFrame$FOI[which(DataFrame$Region == region)][1]
                group.region <- Create_Region_DF(DataFrame, idx.region, foi.region)
                group.region$Region <- region
                Group <- rbind(Group, group.region)
            }
        }
        if (country == 'Nepal'){
            df.country <- DataFrame[which(DataFrame$Region %in% countries[[country]]), ]
            point <- df.country[, c(1,2)]
            coordinates(point) <- ~ x + y
            proj4string(point) <- mycrs
            for (region in regions.country){
                if (region %in% c(18, 20, 22, 24)){ # independently --> easy
                    idx.region <- which(DataFrame$Region == region)
                }else{
                    if (region == 17){ # non.W.Terai geographic
                        region.shp <- readOGR(paste0(SHPPath_Nepal, 'non.W.Terai', '.shp'))
                    }else{ # region = 18 # non.kathmandu geographic
                        region.shp <- readOGR(paste0(SHPPath_Nepal, 'non.kathmandu', '.shp'))
                    }
                    region.shp <- spTransform(region.shp, mycrs)
                    point.in.geography <- over(point, region.shp)
                    idx.region <- which(!is.na(point.in.geography$FOI_val))
                }
                foi.region <- DataFrame$FOI[which(DataFrame$Region == region)][1]
                group.region <- Create_Region_DF(DataFrame, idx.region, foi.region)
                group.region$Region <- region
                Group <- rbind(Group, group.region)
            }
        }
        if (country == 'India'){
            df.country <- DataFrame[which(DataFrame$Region %in% countries[[country]]), ]
            point <- df.country[, c(1,2)]
            coordinates(point) <- ~ x + y
            proj4string(point) <- mycrs
            for (region in regions.country){
                if (region == 8){ # 8 --> Entire India
                    idx.region <- which(DataFrame$Region %in% countries[[country]])
                }else{
                    if (region %in% c(23, 26, 27, 28, 42, 46, 47)){ # independently --> easy
                        idx.region <- which(DataFrame$Region == region)
                    }else{
                        if (region == 21){ # 21 --> 23 (assam --> dhemaji)
                            idx.region <- which(DataFrame$Region %in% c(21, 23))
                        }else{
                            if (region == 25){ # 25 --> 26, 28
                                idx.region <- which(DataFrame$Region %in% c(25, 26, 28))
                            }else{
                                if (region == 19){ # 19 --> 28
                                    idx.region <- which(DataFrame$Region %in% c(19, 28))
                                }else{
                                    if (region == 13){ # 13 --> 19, 25, 26, 28
                                        idx.region <- which(DataFrame$Region %in% c(13, 19, 25, 26, 28))
                                    }else{
                                        if (region == 45){ # 45 --> 47
                                            idx.region <- which(DataFrame$Region %in% c(45, 47))
                                        }else{
                                            if (region == 41){ # 41 --> 42
                                                idx.region <- which(DataFrame$Region %in% c(41, 42))
                                            }else{ # region 15 (complicated)
                                                region.shp <- readOGR(paste0(SHPPath_India, '7up.dist.assam', '.shp'))
                                                region.shp <- spTransform(region.shp, mycrs)
                                                point.in.geography <- over(point, region.shp)
                                                idx.region <- which(!is.na(point.in.geography$FOI_val))
                                            }
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
                foi.region <- DataFrame$FOI[which(DataFrame$Region == region)][1]
                group.region <- Create_Region_DF(DataFrame, idx.region, foi.region)
                group.region$Region <- region
                Group <- rbind(Group, group.region)
            }
        }
    }else{ # Normal groupping --> no overlay
        for (region in regions.country){
            idx.region <- which(DataFrame$Region == region)
            foi.region <- DataFrame$FOI[which(DataFrame$Region == region)][1]
            group.region <- Create_Region_DF(DataFrame, idx.region, foi.region)
            group.region$Region <- region
            Group <- rbind(Group, group.region)
        }
    }    
}

# FINDING 2 HIDDEN REGIONS (NEPAL and TAIWAN)
# These 2 countries are totally overlay-ed by other regions --> they are not in the dataframe of Mapping Random Forest --> do it by manually
countries_extra <- c('Nepal', 'Taiwan')
foi_shp <- readOGR(paste0(Datapath_SHP_FOI, 'FOI_Full.shp'))
foi_shp_data <- foi_shp@data
foi_shp_data_2_countries <- foi_shp_data[which(foi_shp_data$Region %in% countries_extra),]
rm(foi_shp)
cat('~~~~~~~~~~\nProcessing extra regions\n~~~~~~~~~~\n')
for (country in countries_extra){
    cat('===== Processing:', country, '=====\n')
    regions.country <- countries[[country]]
    idx.region <- which(DataFrame$Region %in% regions.country)
    foi.region <- foi_shp_data_2_countries$FOI_val[which(foi_shp_data_2_countries$Region == country)]
    group.region <- Create_Region_DF(DataFrame, idx.region, foi.region)
    # group.region$Region <- region
    Group <- rbind(Group, group.region)
}

Group$WM <- NULL # Remove WM feature (useless since all are 0)
Group$x <- NULL # same as aboved
Group$y <- NULL # same as aboved
Group$Region <- NULL

saveRDS(Group, paste0(Savepath, 'DataRegression.Rds'))

cat('===== FINISH [Summary_Feature_Regions.R] =====\n')

library(targets)

options(tidyverse.quiet = TRUE)
tar_option_set(packages = c('tidyverse', 'lubridate', 'dataRetrieval',
                            'sf', 'xml2', 'units', 'retry', 'MESS'))

source("1_inventory.R")
source("1_added_cols.R")
source("2_download.R")
source("3_harmonize.R")
source("4_export.R")

# The temporal extent of our data pull for Saline Lakes project
# Note - can set start_date or end_date to "" to query the earliest or latest available date
start_date <- "2000-01-01"
end_date <- "2022-11-27" 

# Parameter groups (and CharacteristicNames) to return from WQP. 
# Parameter groups were outlined in the 1_inventory/cfg/wqp_codes.yml. 
# This list should match the high level groups of the WQP characteristic Names.
param_groups_select <- c('temperature',
                         'conductivity',
                         'salinity',
                         'DO',
                         'pH',
                         'nitrate',
                         'nitrogen',
                         'phosphorus')

# Specify arguments to WQP queries
# see https://www.waterqualitydata.us/webservices_documentation for more information 
wqp_args <- list(sampleMedia = c("Water","water"),
                 siteType = c("Stream",'Lake, Reservoir, Impoundment', 'Well'),
                 # return sites with at least one data record
                 minresults = 1, 
                 startDateLo = start_date,
                 startDateHi = end_date)

# Return the complete list of targets
c(p1_targets_list,
  p1_added_cols_list,
  p2_targets_list,
  p3_targets_list,
  p4_targets_list)



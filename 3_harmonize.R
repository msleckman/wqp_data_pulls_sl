# Source the functions that will be used to build the targets in p3_targets_list
source("3_harmonize/src/format_columns.R")
source("3_harmonize/src/clean_wqp_data.R")
# specific harmonized functions for temp and conductivity0
source("3_harmonize/src/clean_conductivity_data.R")
source("3_harmonize/src/clean_temperature_data.R")
# Note - the functions below are template functions and are identical. Added to ensure we can process targets `p3_wqp_param_cleaning_info` with same links. 
# These functions can be expanded we find that it is needed
source('3_harmonize/src/clean_DO_data.R')
source('3_harmonize/src/clean_nitrate_data.R')
source('3_harmonize/src/clean_nitrogen_data.R')
source('3_harmonize/src/clean_ph_data.R')
source('3_harmonize/src/clean_phosphorus_data.R')
source('3_harmonize/src/clean_salinity_data.R')
source('3_harmonize/src/clean_tds_data.R')
source('3_harmonize/src/clean_density_data.R')
source('3_harmonize/src/clean_spec_grav_data.R')



p3_targets_list <- list(
  
  # All columns in p2_wqp_data_aoi are of class character. Coerce select 
  # columns back to numeric, but first retain original entries in new columns
  # ending in "_original". The default option is to format "ResultMeasureValue"
  # and "DetectionQuantitationLimitMeasure.MeasureValue" to numeric, but 
  # additional variables can be added using the `vars_to_numeric` argument in 
  # format_columns(). By default, format_columns() will retain all columns, but
  # undesired variables can also be dropped from the WQP dataset using the 
  # optional `drop_vars` argument. 
  tar_target(
    p3_wqp_data_aoi_formatted,
    format_columns(p2_wqp_data_aoi)
  ),
  
  # Harmonize WQP data by uniting diverse characteristic names under more
  # commonly-used water quality parameter names, flagging missing records,
  # and flagging duplicate records. Duplicated rows are identified using 
  # the argument `duplicate_definition`. By default, a record will be 
  # considered duplicated if it shares the same organization, site id, date,
  # time, characteristic name and sample fraction, although a different 
  # vector of column names can be passed to `clean_wqp_data()` below. By 
  # default, duplicated rows are flagged and omitted from the dataset. To 
  # retain duplicate rows, set the argument `remove_duplicated_rows` to FALSE. 
  tar_target(
    p3_wqp_data_aoi_clean,
    clean_wqp_data(p3_wqp_data_aoi_formatted, p1_char_names_crosswalk, remove_duplicated_rows = TRUE)
  ),
  
  # Create a table that defines parameter-specific data cleaning functions.
  # Cleaning functions should be defined within a named list where the name
  # of each list element is the function name.
  # For Saline Lakes Proj, added the additional characteristic Names of interest (beyond template) and created repeat functions for each of those params. 
  tar_target(
    p3_wqp_param_cleaning_info,
    tibble(
      parameter = c('conductivity',
                    'temperature',
                    'salinity',
                    'DO',
                    'pH',
                    'nitrate',
                    'nitrogen',
                    'phosphorus',
                    'total dissolved solids',
                    'density',
                    'specific gravity'),
      cleaning_fxn = c(clean_conductivity_data,
                       clean_temperature_data,
                       clean_salinity_data,
                       clean_DO_data,
                       clean_ph_data,
                       clean_nitrate_data,
                       clean_N_data,
                       clean_phos_data,
                       clean_tds_data,
                       clean_density_data,
                       clean_spec_grav_data)
      )
  ),
  
  # Group the WQP data by parameter group in preparation for parameter-specific
  # data cleaning steps.
  tar_target(
    p3_wqp_data_aoi_clean_grp,
    p3_wqp_data_aoi_clean %>%
      group_by(parameter) %>%
      tar_group(),
    iteration = "group"
  ),
  
  # Harmonize WQP data by applying parameter-specific data cleaning steps,
  # including harmonizing units where possible. `p3_wqp_param_cleaning_info` 
  # is a {targets} dependency, so changes to any of the parameter-specific 
  # cleaning functions will trigger a rebuild of only those branches that 
  # correspond to the group of data impacted by the change.
  tar_target(
    p3_wqp_data_aoi_clean_param,
    {
      # Decide which function to use
      fxn_to_use <- p3_wqp_param_cleaning_info %>%
        filter(parameter == unique(p3_wqp_data_aoi_clean_grp$parameter)) %>%
        pull(cleaning_fxn) %>%
        {.[[1]]}
      
      # If applicable, apply parameter-specific cleaning function
      if(length(fxn_to_use) > 0){
        do.call(fxn_to_use, list(wqp_data = p3_wqp_data_aoi_clean_grp))
      } else {.}
    },
    map(p3_wqp_data_aoi_clean_grp)
  ),
  
  ## add MonitoringLocationSiteType and Stream order param to the final wqp_data. This vrsn is named with `added_cols` 
  tar_target(p3_wqp_data_aoi_clean_param_added_cols,
    p3_wqp_data_aoi_clean_param %>%
      filter(flag_missing_result == FALSE) %>% 
      left_join(.,y = p1_site_stream_order, by = 'MonitoringLocationIdentifier') %>% 
      left_join(., y = p1_site_lakes_sf_dict %>% st_drop_geometry(), by = 'MonitoringLocationIdentifier')
  )
)


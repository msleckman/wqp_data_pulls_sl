source("3_harmonize/src/summarize_wqp_records.R")

p4_targets_list <- list(
  
  
  # Summarize the number of records associated with each parameter,
  # characteristic name, and harmonized units. The harmonized dataset
  # can be summarized using any combination of columns by passing a
  # different vector of column names in `grouping_cols`.
  tar_target(
    p4_wqp_records_summary_csv,
    summarize_wqp_records(p3_wqp_data_aoi_clean_param, 
                          grouping_cols = c('parameter', 
                                            'CharacteristicName',
                                            'ResultMeasure.MeasureUnitCode'),
                          "3_harmonize/log/wqp_records_summary.csv"),
    format = "file"
  ),
  
  # Save output file containing the harmonized data. The code below can be edited
  # to save the output data to a different file format, but note that a "file"
  # target expects a character string to be returned when the target is built. 
  # This target currently represents the output of the pipeline although more 
  # steps can be added using `p3_wqp_data_aoi_clean_param` as a dependency to 
  # downstream targets.
  tar_target(
    p4_wqp_data_aoi_clean_param_rds,{
      outfile <- "4_export/out/harmonized_wqp_data.rds"
      saveRDS(p3_wqp_data_aoi_clean_param, outfile)
      outfile
    }, format = "file"
  ),
  
  # Save output file containing the harmonized data with stream order category and monitoring site type
  tar_target(
    p4_wqp_data_aoi_clean_param_added_cols_rds,{
      outfile <- "4_export/out/harmonized_wqp_data_added_cols.rds"
      saveRDS(p3_wqp_data_aoi_clean_param_added_cols, outfile)
      outfile
    }, format = "file"
  ),
  
  # save harmonized inventory of sites and CharacteristicName with stream order category and monitoring site type
  # sites are for the msot part duplicated because this tbl is unique by Monitoring site & characteristicName (many sites measure more than 1 characteristicName)
  tar_target(
    p4_wqp_inventory_aoi_added_cols,
    {outfile <- "4_export/out/harmonized_wqp_sites.rds"
    saveRDS(p1_wqp_inventory_aoi_added_cols, outfile)
    outfile
    }, format = 'file'
  )
  
)
source('1_inventory/src/sites_along_waterbody.R')

p1_added_cols_list <- list(
  

  ## Create simple sf dict of unique MonitoringLocationIdentifier sites and point geom
  tar_target(
    p1_wqp_inventory_aoi_sf_dict,
    p1_wqp_inventory_aoi_sf %>%
      ## selected both Monitoring Location Id and Monitoring Location Type to keep track of site type
      select(MonitoringLocationIdentifier, ResolvedMonitoringLocationTypeName) %>%
      distinct() %>% 
      ## renaming the site Typc col to a more standard name
      rename(MonitoringLocationType == ResolvedMonitoringLocationTypeName)
  ),
  
  ## Create simple sf obj of sites Identifier and associated lake 
  tar_target(
    p1_site_lakes_sf_dict,
    p1_wqp_inventory_aoi_sf_dict %>%
      st_join(p1_lake_watersheds) %>% 
      ## renaming col because it gets shorten with st_join()
      rename('lake_w_state' = 'lk_w_st')
  ),
  
  
  # Read lakes spatial file to mutate col with stream order info
  tar_target(p1_lake_tributaries_sf,
             sf::st_read('1_inventory/cfg/p2_lake_tributaries.shp', quiet = TRUE)
  ),
  
  # Read in lakes spatial file to mutate col with stream order info
  tar_target(p1_saline_lakes_sf,
             sf::st_read('1_inventory/cfg/saline_lakes.shp', quiet = TRUE)
  ),
  
  # Get list of sites along SO3
  tar_target(p1_sites_along_SO3,
             sites_along_waterbody(site_sf = p1_wqp_inventory_aoi_sf,
                                   site_id_col = 'MonitoringLocationIdentifier',
                                   waterbody_sf = p1_lake_tributaries_sf,
                                   lake_waterbody = FALSE)
  ),
  
  # Get list of sites along lakes
  # Read tributaries to mutate col with stream order info
  tar_target(p1_sites_along_lake,
             sites_along_waterbody(site_sf = p1_wqp_inventory_aoi_sf,
                                   site_id_col = 'MonitoringLocationIdentifier',
                                   waterbody_sf = p1_saline_lakes_sf,
                                   lake_waterbody = TRUE)
  ),
  
  
  # Pull out just site id and create stream order category column
  tar_target(p1_site_stream_order,
             p1_wqp_inventory_aoi_sf %>%
               st_drop_geometry() %>%
               select(MonitoringLocationIdentifier) %>%
               distinct() %>% 
               mutate(stream_order_category = 
                        case_when(.data[['MonitoringLocationIdentifier']] %in% p1_sites_along_SO3 ~ 'along SO 3+',
                                  .data[['MonitoringLocationIdentifier']] %in% p1_sites_along_lake ~ 'along saline lake',
                                  TRUE ~ 'Not along SO 3+ or saline lake')
               )
  ),
  
  ## create inventory df with added columns
  tar_target(p1_wqp_inventory_aoi_added_cols,
             left_join(x = p1_wqp_inventory_aoi,
                       y = p1_site_stream_order,
                       by = 'MonitoringLocationIdentifier') 
  )
  
)
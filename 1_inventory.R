# Source the functions that will be used to build the targets in p1_targets_list
source("1_inventory/src/check_characteristics.R")
source("1_inventory/src/create_grids.R")
source("1_inventory/src/get_wqp_inventory.R")
source("1_inventory/src/summarize_wqp_inventory.R")
source('1_inventory/src/sites_along_waterbody.R')


p1_targets_list <- list(
  
  # Track yml file containing common parameter groups and WQP characteristic names
  # If {targets} detects a change in the yml file, it will re-build all downstream
  # targets that depend on p1_wqp_params_yml.
  tar_target(
    p1_wqp_params_yml,
    '1_inventory/cfg/wqp_codes.yml',
    format = "file"
  ),
  
  # Load yml file containing common parameter groups and WQP characteristic names
  tar_target(
    p1_wqp_params,
    yaml::read_yaml(p1_wqp_params_yml) 
  ),
  
  # Format a table that indicates how various WQP characteristic names map onto 
  # more commonly-used parameter names
  tar_target(
    p1_char_names_crosswalk,
    crosswalk_characteristics(p1_wqp_params)
  ),
  
  # Get a vector of WQP characteristic names to match parameter groups of interest
  tar_target(
    p1_char_names,
    filter_characteristics(p1_char_names_crosswalk, param_groups_select)
  ),
  
  # Save output file(s) containing WQP characteristic names that are similar to the
  # parameter groups of interest.
  tar_target(
    p1_similar_char_names_txt,
    find_similar_characteristics(p1_char_names, param_groups_select, "1_inventory/out"),
    format = "file"
  ),
  
  # Define the spatial area of interest (AOI) for the WQP data pull
  # For the Saline Lakes proj, this is the aoi of the lake watersheds
  tar_target(
    p1_lake_watersheds,
    sf::st_read('1_inventory/cfg/p2_lake_watersheds_dissolved.shp', quiet = TRUE)
  ),
  
  ## Create AOI for saline lakes extent
  tar_target(
    p1_AOI_sf,
    p1_lake_watersheds %>% 
      sf::st_cast(., 'POLYGON')
  ),
  
  # Create a big grid of boxes to set up chunked data queries.
  # The resulting grid, which covers the globe, allows for queries
  # outside of CONUS, including AK, HI, and US territories. 
  tar_target(
    p1_global_grid,
    create_global_grid()
  ),
  
  # Use spatial subsetting to find boxes that overlap the area of interest
  # These boxes will be used to query the WQP.
  tar_target(
    p1_global_grid_aoi,
    subset_grids_to_aoi(p1_global_grid, p1_AOI_sf)
  ),
  
  # Inventory data available from the WQP within each of the boxes that overlap
  # the Saline Lakes area of interest in the Great Basin.
  # To prevent timeout issues that result from large data requests,
  # using {targets} dynamic branching capabilities to map the function 
  # inventory_wqp() over each grid within p1_global_grid_aoi. {targets} will then
  # combine all of the grid-scale inventories into one table. See comments above
  # target p2_wqp_data_aoi (in 2_download.R) regarding the use of error = 'continue'.
  tar_target(
    p1_wqp_inventory,
    {
    # inventory_wqp() requires grid and char_names as inputs, but users can 
    # also pass additional arguments to WQP, e.g. sampleMedia or siteType, using 
    # wqp_args. Below, wqp_args is defined in _targets.R. See documentation
    # in 1_fetch/src/get_wqp_inventory.R for further details.
    inventory_wqp(grid = p1_global_grid_aoi,
                  char_names = p1_char_names,
                  wqp_args = wqp_args)
    },
    pattern = cross(p1_global_grid_aoi, p1_char_names),
    error = "continue"
  ),
  
  # Subset the WQP inventory to only retain sites within lake watershed
  tar_target(
    p1_wqp_inventory_aoi,
    subset_inventory(p1_wqp_inventory, p1_AOI_sf)
  ),
  
  ## Create spatial version of Saline Lakes sites inventory  
  tar_target(
    p1_wqp_inventory_aoi_sf,
    p1_wqp_inventory_aoi %>%
      sf::st_as_sf(coords = c('lon','lat')) %>%
      sf::st_set_crs(st_crs(p1_AOI_sf))
  ),
  

  
  # Summarize the data that comes back from the WQP
  tar_target(
    p1_wqp_inventory_summary_csv,
    summarize_wqp_inventory(p1_wqp_inventory_aoi,
                            "1_inventory/log/summary_wqp_inventory_saline_lakes2.csv"),
    format = "file"
  )

)

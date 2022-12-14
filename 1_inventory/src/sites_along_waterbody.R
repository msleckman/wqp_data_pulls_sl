
  #' @param site_sf sf object of wqp sites and measurements
  #' @param site_id_col selected sf object id col
  #' @param waterbody_sf sf object of water bosy that will be buffered 
  #' @param lake_waterbody whether waterbody sf obj is lake or not. Matter for method of buffer. 
  
sites_along_waterbody <- function(site_sf, waterbody_sf, site_id_col, lake_waterbody = FALSE){
  
    ## running st_union for the tributary shp because it smooths the buffer and polygons are overlap less. 
    ## Not feasible for lakes due to specific selection of columns
    if(lake_waterbody == TRUE){  
      ## simple buffer of waterbody if lakes 
      waterbody_buffered <- waterbody_sf %>% sf::st_buffer(dist = units::set_units(250, m))
    }else{
      ## run st_union before buffer to smooth out edges and create buffer 
      waterbody_buffered <- waterbody_sf %>%
        group_by(comid, stremrd) %>%
        summarize(geometry = sf::st_union(geometry)) %>%
        sf::st_buffer(dist = units::set_units(250, m))
    }
    ## Join sites to waterbody buffer to get the sites intersect with buffer segments   
    filtered_sites <- st_join(site_sf, waterbody_buffered, left = FALSE) %>%
      pull(.data[[site_id_col]]) %>%
      unique()
    
    return(filtered_sites)
    
  }

#' @description add_stream_order() adds stream order col based list of valid sites (in this case, whether in stream order 3 reaches)
#' @param sites_sf sf df obj with sites location info
#' @param site_id_col selected sf object id col - e.g. site_no 
#' @param lakes_sf lake sf obj
#' @param flines_sf flowlines sf obj.  

add_stream_order <-function(sites_sf,
                            site_id_col,
                            lakes_sf,
                            flines_sf){
  
  sites <- sites_sf %>%
    select(.data[[site_id_col]]) %>%
    ## getting only ind sits, most sites collect different measurements.
    dplyr::distinct()

  ## Get sites within lakes
 lake_sites <- sites_along_waterbody(site_sf = sites,
                                     site_id_col = site_id_col,
                                     waterbody_sf = lakes_sf,
                                     lake_waterbody = TRUE)
  
  ## Get sites within stream segments
 flines_sites <- sites_along_waterbody(site_sf = sites,
                                       site_id_col = site_id_col,
                                       waterbody_sf = flines_sf,
                                       lake_waterbody = TRUE)
  
  ## Create df of sites with col for stream order
 final_inventory_sf <- inventory_sf %>% 
   mutate(stream_order_category = 
            case_when(.data[[site_id_col]] %in% flines_sites ~ 'along SO 3+',
                      .data[[site_id_col]] %in% lake_sites ~ 'along saline lake',
                      TRUE ~ 'Not along SO 3+ or saline lake')
          )
 
 return(final_inventory_sf)
 
}

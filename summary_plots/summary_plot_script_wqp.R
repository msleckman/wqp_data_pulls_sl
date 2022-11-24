### REVIEW OUTPUT WQP Data

# libs --------------------------------------------------------------------


library(dplyr)
library(targets)
library(mapview)
library(sf)
library(ggplot2)
library(lubridate)


# load targets -----------------------------------------------------------------

## final data set
tar_load(p3_wqp_data_aoi_clean_param_rds)
## Watersheds sf obj
tar_load(p1_lake_watersheds)
## wqp discrete sites sf obj 
tar_load(p1_wqp_inventory_aoi_sf)

## sites description
tar_load(p1_wqp_inventory_aoi)



# Scan output -----------------------------------------------------------------

## sites
nmbr_unique_meas_per_sites <- p1_wqp_inventory_aoi %>%
  group_by(MonitoringLocationIdentifier, ProviderName, OrganizationFormalName) %>%
  summarise(n()) %>%
  arrange(desc(`n()`))

## Pulls sites that collect 3 diff measurements
monitoring_location_3 <- p1_wqp_inventory_aoi %>%
  group_by(MonitoringLocationIdentifier,ProviderName, OrganizationFormalName) %>%
  summarise(n()) %>% 
  filter(`n()`== 3) %>%
  pull(MonitoringLocationIdentifier)

## Unique measurement type for sites with 3 different ones 
p1_wqp_inventory_aoi %>%
  filter(MonitoringLocationIdentifier %in% monitoring_location_3)
  pull(CharacteristicName) %>%
  unique()
  
# -->  generally sites collecting multiple items are collecting Temp water, Conductivity, and Specific Conductance 

## Pulls sites that collect 2 diff measurements
monitoring_location_2 <- p1_wqp_inventory_aoi %>% group_by(MonitoringLocationIdentifier,
                                                           ProviderName,
                                                           OrganizationFormalName) %>%
  summarise(n()) %>%
  arrange(desc(`n()`)) %>% 
  filter(`n()`== 2) %>% pull(MonitoringLocationIdentifier) 

p1_wqp_inventory_aoi %>%
  filter(MonitoringLocationIdentifier %in% monitoring_location_2) %>% 
  pull(CharacteristicName) %>%
  unique()

# -->  generally sites collecting 2 items are collecting 1) Temp water, 2) conductivity : Conductivity or Specific Conductance 
  

## Map overall wqp sites 

us_sf <- st_as_sf(maps::map('state', plot=F, fill=T)) %>% st_transform(4326)

bbox <- st_bbox(p1_wqp_inventory_aoi_sf)

map_wq_sites <- ggplot()+
  geom_sf(data = us_sf, fill = 'white')+
  geom_sf(data = p1_lake_watersheds, fill = 'transparent', color = 'firebrick', size = 0.01, linetype = 'dotted')+
  geom_sf(data = p1_wqp_inventory_aoi_sf,
          aes(geometry = geometry, color = CharacteristicName, shape = ProviderName), size = 0.8)+
  lims(x = c(bbox[1],bbox[3]),y = c(bbox[2],bbox[4]))+
  theme_bw()

map_wq_sites

ggsave(filename = 'map_wq_sites',
       device= 'png',
       plot =map_wq_sites,
       path = 'summary_plots')

# Evaluate wqp data -------------------------------------------------------

p3_wqp_data_aoi_clean_param <- readRDS(p3_wqp_data_aoi_clean_param_rds)


summarized_wqp_data <- p3_wqp_data_aoi_clean_param %>% 
  select(MonitoringLocationIdentifier, ActivityStartDate, CharacteristicName, ResultMeasureValue) %>%
  ## Create new Year col and month col to then gather different year and month coverage 
  mutate(ActivityStartDate = as.Date(ActivityStartDate),
         Year = year(ActivityStartDate),
         Month = month(ActivityStartDate)) %>% 
         group_by(MonitoringLocationIdentifier, CharacteristicName) %>% 
  ## Summarizations related to date range, obr of obs,  
  summarize(min_date = min(ActivityStartDate),
            # mean_date = median(ActivityStartDate),
            max_date = max(ActivityStartDate),
            nbr_observations = n(),
            years_converage = paste0(unique(Year), collapse = ', '), 
            months_coverage = paste0(unique(Month), collapse = ', '),
            mean_value = mean(ResultMeasureValue)
            ) %>% 
  arrange(desc(nbr_observations)) %>% 
  ## Create new col with categories of observations 
  mutate(nbr_obs_classes = ifelse(nbr_observations <= 10,'<10',
                                  ifelse(nbr_observations > 10 & nbr_observations <= 100,'10-100',
                                         ifelse(nbr_observations > 100 & nbr_observations <= 1000,'100-1,000','>1,000'))))

## Join to spatial file
summarized_wqp_data_sf <- summarized_wqp_data %>% 
  left_join(p1_wqp_inventory_aoi_sf[,c('MonitoringLocationIdentifier','geometry')], by = 'MonitoringLocationIdentifier') %>%
  st_as_sf() 

## View
mapview(summarized_wqp_data_sf %>% filter(!nbr_obs_classes %in% c('<10','10-100','100-1,000')),
        zcol = 'nbr_obs_classes')

## Generate Map 

map_wq_data_availability <- ggplot()+
  geom_sf(data = us_sf, fill = 'white')+
  geom_sf(data = p1_lake_watersheds, fill = 'transparent', color = 'firebrick', size = 0.01, linetype = 'dotted')+
  geom_sf(data = summarized_wqp_data_sf,
          aes(geometry = geometry, color = CharacteristicName, shape = nbr_obs_classes), size =0.4)+
  lims(x = c(bbox[1],bbox[3]),y = c(bbox[2],bbox[4]))+
  theme_bw()+
  labs(title = 'WQP Data Collection sites in the Great Basin Desert')

map_wq_data_availability

## save ggplot map 
ggsave(filename = 'map_wq_data_availability',
       device= 'png',
       plot =map_wq_data_availability,
       path = 'summary_plots')

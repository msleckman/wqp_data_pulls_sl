### REVIEW OUTPUT WQP Data

# libs -------------------------------------------------------------------------

library(dplyr)
library(targets)
library(mapview)
library(sf)
library(ggplot2)
library(lubridate)


# load targets -----------------------------------------------------------------

## final data set
tar_load(p4_wqp_data_aoi_clean_param_rds)
tar_load(p3_wqp_data_aoi_clean_param_added_cols)
tar_load(p4_wqp_data_aoi_clean_param_added_cols_rds)
## Watersheds sf obj
tar_load(p1_lake_watersheds)
tar_load(p1_saline_lakes_sf)
## sites description
tar_load(p1_wqp_inventory_aoi)

# Scan output -----------------------------------------------------------------

## STORET EPA vs USGS NWIS
p1_wqp_inventory_aoi %>%
1q  group_by(ProviderName) %>%
  summarise(percent_share_of_unique_parameter_site = (n()/nrow(p1_wqp_inventory_aoi))*100)

# # A tibble: 2 × 2
# ProviderName percent_share_of_unique_parameter_site
# <chr>                                         <dbl>
#   1 NWIS                                           16.0
# 2 STORET                                         84.0

## > 84% of parameters at sites are an EPA STORET site

unique_sites_len <- p1_wqp_inventory_aoi$MonitoringLocationIdentifier %>% unique() %>% length()

p1_wqp_inventory_aoi %>%
  select(MonitoringLocationIdentifier,CharacteristicName) %>%
  group_by(MonitoringLocationIdentifier) %>% summarise(n()) %>%
  left_join(., (p1_wqp_inventory_aoi %>% select(MonitoringLocationIdentifier,ProviderName)), by ='MonitoringLocationIdentifier') %>%
  distinct() %>% 
  group_by(ProviderName) %>% 
  summarise(percent_share_of_unique_sites = (n()/unique_sites_len)*100)

# # A tibble: 2 × 2
# ProviderName     n
# <chr>        <dbl>
#   1 NWIS          17.5
# 2 STORET        82.5

## > 82.5% of sites are an EPA STORET sites



## sites
nmbr_unique_meas_per_sites <- p1_wqp_inventory_aoi %>%
  group_by(MonitoringLocationIdentifier, ProviderName, OrganizationFormalName) %>%
  summarise(n = n()) %>%
  arrange(desc(n))

nmbr_unique_meas_per_sites %>% head()

# # A tibble: 6 × 4
# # Groups:   MonitoringLocationIdentifier, ProviderName [6]
# MonitoringLocationIdentifier ProviderName OrganizationFormalName                               n
# <chr>                        <chr>        <chr>                                            <int>
#   1 USGS-10141000                NWIS         USGS Utah Water Science Center                      13
# 2 USGS-10172630                NWIS         USGS Utah Water Science Center                      13
# 3 USGS-10350340                NWIS         USGS Nevada Water Science Center                    13
# 4 SIR_WQX-SW-WBC-LR2           STORET       Susanville Indian Rancheria, California (Tribal)    12
# 5 USGS-10168000                NWIS         USGS Utah Water Science Center                      12
# 6 USGS-10171000                NWIS         USGS Utah Water Science Center                      12

## who collects the most
nmbr_unique_meas_per_sites_provider <- p1_wqp_inventory_aoi %>%
  group_by(MonitoringLocationIdentifier,ProviderName) %>%
  summarise(n()) %>% arrange(desc(`n()`))

nmbr_unique_meas_per_sites_provider %>% head()

## What does the top wqp identifier collect? 
p1_wqp_inventory_aoi %>%
  filter(MonitoringLocationIdentifier == I(nmbr_unique_meas_per_sites_provider$MonitoringLocationIdentifier[1]))



# # A tibble: 6 × 3
# # Groups:   MonitoringLocationIdentifier [6]
# MonitoringLocationIdentifier ProviderName `n()`
# <chr>                        <chr>        <int>
#   1 USGS-10141000                NWIS            13
# 2 USGS-10172630                NWIS            13
# 3 USGS-10350340                NWIS            13
# 4 SIR_WQX-SW-WBC-LR2           STORET          12
# 5 USGS-10168000                NWIS            12
# 6 USGS-10171000                NWIS            12

## Pulls sites that collect 13 diff measurements
monitoring_location_13 <- p1_wqp_inventory_aoi %>%
  group_by(MonitoringLocationIdentifier,ProviderName, OrganizationFormalName) %>%
  summarise(n()) %>% 
  filter(`n()`== 13) %>%
  pull(MonitoringLocationIdentifier)

## Unique vector of measurement type for sites with 13 different ones 
p1_wqp_inventory_aoi %>%
  filter(MonitoringLocationIdentifier %in% monitoring_location_13) %>% 
  pull(CharacteristicName) %>%
  unique()
  
# -->  generally sites collecting multiple items are collecting Temp water, Conductivity, and Specific Conductance 


## Map overall wqp sites 

us_sf <- st_as_sf(maps::map('state', plot=F, fill=T)) %>% st_transform(4326)

bbox <- st_bbox(p1_wqp_inventory_aoi_sf)

p1_wqp_inventory_aoi_w_SO_sf$stream_order_category %>% unique()

tmp <- grepl('temp|Temp',p1_wqp_inventory_aoi_sf$CharacteristicName)

map_wq_sites <- ggplot()+
  geom_sf(data = us_sf, fill = 'white')+
  geom_sf(data = p1_lake_watersheds, fill = 'transparent', color = 'firebrick', size = 0.01, linetype = 'dotted')+
  geom_sf(data = p1_saline_lakes_sf, fill = ' light blue', color = 'grey', alpha = 0.5)+ 
  geom_sf(data = p1_wqp_inventory_aoi_w_SO_sf %>% filter(stream_order_category != "Not along SO 3+ or saline lake"),
          aes(geometry = geometry, shape = ProviderName), color = 'darkblue',size = 1)+
  lims(x = c(bbox[1],bbox[3]),y = c(bbox[2],bbox[4]))+
  theme_bw()+
  labs(title = 'NWIS and STORET Data Collection sites in the\n GBD saline lake  watersheds by WQ Parameter')

map_wq_sites

ggsave(filename = 'map_wq_sites_nwis_storet',
       device= 'png',
       plot =map_wq_sites,
       path = 'summary_plots')

# Evaluate wqp data -------------------------------------------------------

## read output rds wqp data file
p3_wqp_data_aoi_clean_param <- readRDS(p3_wqp_data_aoi_clean_param_rds)

#p3_wqp_data_aoi_clean_param <- p3_wqp_data_aoi_clean_param_w_SO

p3_wqp_data_aoi_clean_param_w_SO %>% select(ResultMeasureValue) %>% nrow()


summarized_wqp_data <- p3_wqp_data_aoi_clean_param %>% 
  select(MonitoringLocationIdentifier, ActivityStartDate,
         CharacteristicName, ResultMeasureValue) %>%
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

summarized_wqp_data$max_date %>% max()

## Join to spatial file
summarized_wqp_data_sf <- summarized_wqp_data %>% 
  left_join(p1_wqp_inventory_aoi_sf[,c('MonitoringLocationIdentifier','geometry')] %>% distinct(), by = 'MonitoringLocationIdentifier') %>%
  st_as_sf() 

## View - number fo sites with more than 1000 data points
mapview(summarized_wqp_data_sf %>% filter(!nbr_obs_classes %in% c('<10','10-100','100-1,000')),
        zcol = 'nbr_obs_classes')

## Generate Map 

map_wq_data_availability <- ggplot()+
  geom_sf(data = us_sf, fill = 'white')+
  geom_sf(data = p1_lake_watersheds, fill = 'transparent', color = 'firebrick', size = 0.01, linetype = 'dotted')+
  geom_sf(data = summarized_wqp_data_sf,
          aes(geometry = geometry, color = CharacteristicName, shape = nbr_obs_classes), size =0.4)+
  lims(x = c(bbox[1],bbox[3]),y = c(bbox[2],bbox[4]))+
  theme_bw()
# +
#   labs(title = 'WQP Data Collection sites in the Great Basin Desert')

map_wq_data_availability

## save ggplot map 
ggsave(filename = 'map_wq_data_availability',
       device= 'png',
       plot =map_wq_data_availability,
       path = 'summary_plots')


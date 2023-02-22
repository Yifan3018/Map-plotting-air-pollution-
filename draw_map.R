#20230111
#draw average pollution map

rm(list = ls())
setwd("~/Documents/椰林大學/資料/淳芳/財資中心/EPA_DATA")

library(readr)
library(sf)
library(janitor)
library(tmap)
library(dplyr)
library(ggplot2)
library(classInt)
library(ggpubr)
library(colorspace)

pollutants <- read_csv("processed_pm25_2018.csv")
severity <- read_csv("processed_severity_aqi.csv")

shp_name <- "district_map/TOWN_MOI_1111118.shp"
district_map <- st_read(shp_name)
pollut_district <- left_join(district_map, pollutants
                             , by=c("COUNTYNAME"="county", "TOWNNAME"="district"))
severity_district <- left_join(district_map, severity
                             , by=c("COUNTYNAME"="county", "TOWNNAME"="district"))

breaks_qt <- classIntervals(c(min(pollut_district$pm25_avg_summer)-0.001
                              , pollut_district$pm25_avg_summer
                              , pollut_district$pm25_avg_winter
                              , pollut_district$pm25_avg_overall),
                            , n=7, style="equal")
breaks_qt
pollut_district <- mutate(pollut_district, cut_summer = cut(pm25_avg_summer, breaks_qt$brks))
pollut_district <- mutate(pollut_district, cut_winter = cut(pm25_avg_winter, breaks_qt$brks))
pollut_district <- mutate(pollut_district, cut_overall = cut(pm25_avg_overall, breaks_qt$brks))

map_theme <- theme(axis.text.x = element_blank(), axis.text.y = element_blank(),
                   legend.text = element_text(size=7),
                   legend.title = element_text(size=7),
                   legend.key.size = unit(10, 'points'),
                   legend.position = c(0.7, 0.15),
                   legend.background = element_rect(linewidth = 0.1),
                   plot.margin = unit(c(3,3,3,3), 'mm'),)
coord_adjust_t <- 1
coord_adjust_b <- 2
coord_adjust_x <- 0.3
map_coord <- coord_sf(
  xlim = c(119+coord_adjust_x,122.5-coord_adjust_x),#調整緯度範圍
  ylim = c(21.5-coord_adjust_b,25.5+coord_adjust_t),#調整經度範圍
  datum = sf::st_crs(4326) 
)

#pm2.5 average
map_overall <- ggplot(pollut_district, aes(fill=cut_overall)) + 
  geom_sf() +
  scale_fill_discrete_sequential(palette="YlGn", nmax=7,
                                 name=expression(paste("pm2.5 (", mu*g, "/", m^3, ")"))) +
  theme_bw() +
  map_coord +
  map_theme;
map_overall
ggsave("pm25_2018_overall.png", width=2.5)

map_summer <- ggplot(pollut_district, aes(fill=cut_summer)) + 
  geom_sf() +
  scale_fill_discrete_sequential(palette="OrRd", nmax=7,
                                 name=expression(paste("pm2.5 (", mu*g, "/", m^3, ")"))) +
  theme_bw() +
  map_coord +
  map_theme;
map_summer
ggsave("pm25_2018_summer.png", width=2.5)

map_winter <- ggplot(pollut_district, aes(fill=cut_winter)) + 
  geom_sf() +
  scale_fill_discrete_sequential(palette="PuBu", nmax=7,
                                 name=expression(paste("pm2.5 (", mu*g, "/", m^3, ")"))) +
  theme_bw() +
  map_coord +
  map_theme;
map_winter
ggsave("pm25_2018_winter.png", width=2.5)

#severe days or proportion
#let 0 include in the partition
pollut_district$severe_prop[pollut_district$severe_prop==0] <- 10^(-10)
breaks_prop <- classIntervals(c(0,
                              pollut_district$severe_prop)
                            , n=5, style="equal")
pollut_district <- mutate(pollut_district, 
                          cut_severe_prop = cut(severe_prop, breaks_prop$brks))

map_severe_prop <- ggplot(pollut_district, aes(fill=cut_severe_prop)) + 
  geom_sf() +
  scale_fill_discrete_sequential(palette="Reds", name="Prop. of pm2.5 >= 54") +
  theme_bw() +
  map_coord +
  map_theme;
map_severe_prop
ggsave("pm25_severe_prop.png", width=2.5)

#AQI
severity_district$prop_senses[severity_district$prop_senses==0] <- 10^(-10)
breaks_senses <- classIntervals(c(0,
                                  severity_district$prop_senses)
                              , n=5, style="equal")
severity_district <- mutate(severity_district, 
                          cut_prop_senses = cut(prop_senses, breaks_senses$brks))

map_aqi_senses <- ggplot(severity_district, aes(fill=cut_prop_senses)) + 
  geom_sf() +
  scale_fill_discrete_sequential(palette="YlOrRd", name="Prop. of AQI >= 100") +
  theme_bw() +
  map_coord +
  map_theme;
map_aqi_senses
ggsave("aqi_senses_prop.png", width=2.5)

severity_district$prop_normal[severity_district$prop_normal==0] <- 10^(-10)
breaks_normal <- classIntervals(c(0,
                                  severity_district$prop_normal)
                                , n=5, style="equal")
severity_district <- mutate(severity_district, 
                            cut_prop_normal = cut(prop_normal, breaks_normal$brks))

map_aqi_normal <- ggplot(severity_district, aes(fill=cut_prop_normal)) + 
  geom_sf() +
  scale_fill_discrete_sequential(palette="PurpOr", name="Prop. of AQI >= 150") +
  theme_bw() +
  map_coord +
  map_theme;
map_aqi_normal
ggsave("aqi_normal_prop.png", width=2.5)

# ggarrange(map_overall, map_summer, map_winter, ncol=3, common.legend=FALSE,
#           heights=c(3, 3, 3), widths=c(1,1,1))
# ggsave("test.png")


# tw_bbox <- st_bbox(district_map)
# tw_bbox.new <- st_bbox(c(xmin=119, xmax=122, ymin=20, ymax=26.38528), crs=4326)
# 
# pollut_district <- left_join(district_map, pollutants
#                              , by=c("COUNTYNAME"="county", "TOWNNAME"="district"))
# 
# avg_overall <- tm_shape(pollut_district, bbox=tw_bbox.new) + 
#   tm_fill("pm25_avg_overall", style="quantile", palette= "Blues", title = "pm25 avg.") +
#   tm_layout(panel.labels = "Overall", legend.position = c("right", "bottom"),
#             legend.title.size = 0.8, legend.text.size = 0.5) +
#   tm_borders()
# 
# avg_summer <- tm_shape(pollut_district, bbox=tw_bbox.new) + 
#   tm_fill("pm25_avg_summer", style="quantile", palette= "Greens", title = "pm25 avg.") +
#   tm_layout(panel.labels = "Summer", legend.position = c("right", "bottom"),
#             legend.title.size = 0.8, legend.text.size = 0.5) +
#   tm_borders()
# 
# avg_winter <- tm_shape(pollut_district, bbox=tw_bbox.new) + 
#   tm_fill("pm25_avg_winter", style="quantile", palette= "Reds", title = "pm25 avg.") +
#   tm_layout(panel.labels = "Winter", legend.position = c("right", "bottom"),
#             legend.title.size = 0.8, legend.text.size = 0.5) +
#   tm_borders()
# 
# pollut_quantile <- tmap_arrange(avg_overall, avg_summer, avg_winter)
# tmap_save(pollut_quantile, filename = "pollut_quantile.png")

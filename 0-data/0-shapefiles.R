# Relevant shapefiles for identifying location of counties

library("tidyverse")

# Create a directory for the data
local_dir   <- "0-data/shapefiles"
data_source <- paste0(local_dir, "/raw")
if (!file.exists(local_dir)) dir.create(local_dir)
if (!file.exists(data_source)) dir.create(data_source)

shp_url  <- paste0("https://www2.census.gov/geo/docs/maps-data/data/",
                   "gazetteer/2015_Gazetteer/2015_Gaz_counties_national.zip")
shp_file <- paste0(data_source, "/", basename(shp_url))

if (!file.exists(shp_file)) download.file(shp_url, shp_file)


# ---- hex ----------------------------------------------------------------

# https://rud.is/b/2015/05/15/
#  u-s-drought-monitoring-with-hexbin-state-maps-in-r/
download.file(paste0("https://gist.githubusercontent.com/hrbrmstr/",
                     "51f961198f65509ad863/raw/",
                     "219173f69979f663aa9192fbe3e115ebd357ca9f/",
                     "us_states_hexgrid.geojson"),
              paste0(data_source, "/us_states_hexgrid.geojson"))

download.file(paste0("https://raw.githubusercontent.com/rdinter/",
                     "rdinter.github.io/master/_drafts/hexbins/",
                     "usa_hex.geojson"),
              paste0(data_source, "/usa_hex.geojson"))

library("maptools")
library("rgdal")
library("rgeos")

# us      <- readOGR(paste0(data_source, "/us_states_hexgrid.geojson"),
#                    "OGRGeoJSON")
# centers <- cbind.data.frame(data.frame(gCentroid(us, byid = T),
#                                        id = us@data$iso3166_2))
# us_map  <- fortify(us, region = "iso3166_2")
# us_map$ST_ABRV <- us_map$id
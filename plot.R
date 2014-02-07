library(ggplot2)
library(maps)

# Load map data
world<-map_data('world')

# Generates plot of the locations on a world map.
plotworld <- function(df, point_size = 0.1, point_alpha = 0.1) {
    # Set theme.
    theme_opts <- list(theme(panel.background = element_blank(),
                             panel.grid.major = element_blank(),
                             panel.grid.minor = element_blank(),
                             axis.text.x = element_blank(),
                             axis.text.y = element_blank(),
                             axis.ticks = element_blank(),
                             plot.background = element_rect(fill="gray6"),
                             legend.position = "none"))
    # Plot
    p <- ggplot(legend=FALSE) +
        geom_polygon(data=world, aes(x=long, y=lat,group=group), fill="gray12") +
        theme_opts +
        xlab("") + ylab("") + 
        geom_point(data=df, aes(lat,long),
            size=point_size, alpha=point_alpha, colour="white")
    return(p)
}

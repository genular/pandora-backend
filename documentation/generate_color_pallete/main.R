library(RColorBrewer)
library(ggplot2)
library(jsonlite)

# Two variables
df <- read.table(header=TRUE, text='
 cond yval
    A 2
    B 3.5
    C 2
    D 3
')

colors <- brewer.pal.info
themes <- c("theme_gray","theme_bw","theme_linedraw","theme_light","theme_dark","theme_minimal","theme_classic","theme_void")


colorList = list()
for (row in 1:nrow(colors)) {
  
    color <- colors[row,]
    paletteID = row.names(color)

    colorList[[paletteID]] = list(
        id = paletteID,
        value = paletteID,
        category = color$category,
        maxcolors = color$maxcolors,
        colorblind = color$colorblind
    )

    for(i in themes){
        theme_set(eval(parse(text=paste0(i, "()"))))

        g_plot <- ggplot(df, aes(x=cond, y=yval, fill=cond)) + 
        geom_bar(stat="identity") +
        scale_fill_brewer(palette=paletteID) + 

        theme(aspect.ratio=1, axis.title.x = element_blank(), axis.text.x = element_blank(), axis.ticks.x = element_blank()) + 
        ylab("Value")

        ggsave(file=paste0("./plots/", i, "_", paletteID,".svg"), plot=g_plot, width=4, height=4)
    }
}
## jsontest = toJSON(colorList, pretty = TRUE, auto_unbox = TRUE)
## print(jsontest)
## svgo --disable={minifyStyles,convertStyleToAttrs} -f .

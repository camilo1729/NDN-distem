library(ggplot2)


data = read.csv("results_merged.txt")
library(ggplot2)
fig <- ggplot(data, aes(node,time,colour = factor(size),group =size))+geom_point()+geom_line()

fig <- fig + xlab("Node")
fig <- fig + ylab("Time [secs]")
fig <- fig + guides(colour=guide_legend(title="Size [MB]"))
fig <- fig + theme_bw()+ theme(
    text = element_text(size = 18),
    legend.text = element_text(size = 20),
    axis.title.y = element_text(size = 18),
    legend.position = c(0.85,0.75),
    axis.text.x = element_text(size=10,angle = 90, hjust = 1)
)

ggsave("cache_leaf.pdf",plot = fig)

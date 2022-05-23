rm(list=ls())

library(ggplot2)
library(ggthemes)
library(forcats)
# library(extrafont)

# font_import()

# Colors
red = "#e33d5e"
green = "#18de92"
blue = "#1f87d1"
darkblue = "#0e4266"
lightgrey = "#999999"
colors = c("#2085ec", "#0a417a", "#72b4eb", "#e67710", "#db7360", "#323232")
custom_theme = theme(legend.position = "bottom",
                     legend.justification = 1,
                     legend.title = element_text(face = "bold", hjust = 0, margin = margin(b=5)),
                     legend.background = element_rect(colour="#999999", size=0.2, fill="#FFFFFF", linetype=1),
                     legend.key.size = unit(0.3, "cm"),
                     legend.key = element_rect(size=NA, color=NA, fill=NA),
                     panel.grid.major = element_line(colour = "#dadada", linetype = 1, size = 0.2, lineend = "square"),
                     panel.grid.minor = element_line(colour = "#eeeeee", linetype = 1, size = 0, lineend = "square"),
                     panel.background = element_rect(fill="#FFFFFF", colour="#999999", size=0.5, linetype=1),
                     plot.background = element_rect(fill="#FFFFFF"),
                     plot.margin = unit(c(0.00,0.00,0.00,0.00), "npc"),
                     axis.title.x = element_text(margin = margin(t = 0, r = 0, b = 0, l = 0)),
                     axis.title.x.bottom = element_text(margin = margin(t = 10, r = 0, b = 0, l = 0)),
                     axis.title.x.top = element_text(margin = margin(t = 0, r = 0, b = 10, l = 0)),
                     axis.title.y.left = element_text(margin = margin(t = 0, r = 10, b = 0, l = 0)),
                     axis.title.y.right = element_text(margin = margin(t = 0, r = 0, b = 0, l = 10)),
                     )

# Minimum Maximum chart
data = read.csv("statistics/max_min_tone_per_year.csv")

plot = ggplot() + 
  geom_bar(data=data, aes(x=year, y=maximum, fill="Positiver Ton"), stat="identity") +
  geom_bar(data=data, aes(x=year, y=minimum, fill="Negativer Ton"), stat="identity") +
  geom_vline(xintercept=2004.5, color=lightgrey, size=1, alpha=0.5) + 
  geom_text(aes(x=2004.5, y=100, label="Keine negativen Stimmungswerte\nvor dem Jahr 2005", hjust=1, vjust=1), nudge_x = -0.5, nudge_y = -10, size=2.5) + 
  labs(x="Jahr", y="Maximum und Minimum\nAvgTon pro Jahr") +
  scale_y_continuous(breaks=c(seq(-100, 100, 50)), limit=c(-100, 100), expand=c(0.05,0.05)) +
  scale_x_continuous(limit=c(1978, 2023), breaks=c(seq(1980, 2020, 10), 2022), expand=c(0.05,0.05)) +
  scale_fill_manual(values = c(red, green), name = NULL, 
                    guide = guide_legend(reverse = TRUE)) + 
  theme_fivethirtyeight(base_size = 8) +
  custom_theme + 
  theme(legend.position = c(0.05, 0.05),
        legend.justification = c(0,0))  
  
plot

ggsave(filename=paste0("max_min_per_year.png"),
       plot=plot,
       device = "png",
       path="figures/",
       dpi = 600,
       width=21,
       height = 7,
       units = "cm")


# Time distribution of data

data = read.csv("statistics/data_per_year.csv")

plot = ggplot() + 
  geom_bar(data=subset(data, year >= 1979), aes(x=year, y=number), fill=colors[1], stat="identity") +
  geom_vline(xintercept=2006.5, color=lightgrey, size=1, alpha=0.5) + 
  geom_text(aes(x=2006.5, y=max(data$number), label="Drastische Zunahme\nab dem Jahr 2007", hjust=1, vjust=1), nudge_x = -0.5, nudge_y = -800000, size=2.5) + 
  labs(x="Jahr", y="Anzahl Ereignisse in Mio.") +
  scale_y_continuous(breaks=c(seq(0, max(data$number), 5*1000000), max(data$number)), 
                     labels = round(c(seq(0, max(data$number)/1000000, 5), max(data$number)/1000000), 2), 
                     limit=c(0, max(data$number)+10),
                     expand=c(0.05,0.05)) +
  scale_x_continuous(limit=c(1978, 2023), breaks=c(seq(1980, 2020, 10), 2022), expand=c(0.05,0.05)) +
  theme_fivethirtyeight(base_size = 8) +
  custom_theme

plot

ggsave(filename=paste0("data_per_year.png"),
       plot=plot,
       device = "png",
       path="figures/",
       dpi = 600,
       width=21,
       height = 7,
       units = "cm")


# Geographic distribution of data

data = read.csv("statistics/data_per_relationship.csv")
data$index = seq(1, nrow(data), 1)
data=data[c(1:15),]
data$name = paste0(data$country_name, " <> ", gsub("United States of America", "USA", data$partner_name))
data$usa = ifelse(data$partner_iso == "USA", "Ja", "Nein")

plot = ggplot() + 
  geom_bar(data=data[c(1:15),], aes(x=rev(index), y=number, fill=usa), stat="identity") +
  labs(x=NULL, y="Anzahl Ereignisse in Mio.") +
  geom_text(data=data, aes(x=rev(index), y=0, label=name, hjust=0), color="#FFFFFF", size=2.2, nudge_y = 50000) +
  scale_y_continuous(breaks=c(seq(0, max(data$number), 1*1000000), max(data$number)), 
                     labels = round(c(seq(0, max(data$number)/1000000, 1), max(data$number)/1000000), 2), 
                     limit=c(0, max(data$number)+10),
                     expand=c(0.05,0.05)) +
  scale_x_continuous(labels=NULL, breaks=data$index, expand=c(0.05,0.05)) +
  coord_flip() +
  scale_fill_manual(values = colors[1:2], name = "USA beteiligt", 
                    guide = guide_legend(reverse = TRUE)) + 
  theme_fivethirtyeight(base_size = 8) +
  custom_theme + 
  theme(panel.grid.major.y = element_blank(),
        legend.position = c(0.95, 0.05),
        legend.justification = c(1,0)) 

plot

ggsave(filename=paste0("data_per_relationship.png"),
       plot=plot,
       device = "png",
       path="figures/",
       dpi = 600,
       width=21,
       height = 10,
       units = "cm")


# Russia Ukraine in detail

data = read.csv("statistics/ukr_rus_detail.csv")
dataAll = read.csv("statistics/avg_tone_per_relation.csv")
dataAll = aggregate(tone ~ year, dataAll, mean)
data$id = "Ukraine <> Russland"
dataAll$id = "Weltweit"
data = rbind(data, dataAll)

plot = ggplot() + 
  geom_line(data=subset(data, year >= 1979), aes(x=year, y=tone, color=id), size=1.5, lineend="round") +
  labs(x="Jahr", y="Durchschnittlicher Ton") +
  geom_vline(xintercept=2013, color=lightgrey, size=1, alpha=0.5) + 
  geom_hline(yintercept=0, color=lightgrey, size=0.5, alpha=1) +  
  geom_text(aes(x=2013, y=min(data$tone), label="Verhandlungen Assoziierungsabkommen\nzwischen EU und Ukraine (2013)", hjust=1, vjust=0), size=2.2, nudge_x=-0.5, nudge_y = 0.05) +
  scale_y_continuous(breaks=c(seq(floor(min(data$tone)), ceiling(max(data$tone)), 2)),
                     labels = c(seq(floor(min(data$tone)), ceiling(max(data$tone)), 2)), 
                     limit=c(min(data$tone), max(data$tone)),
                     expand=c(0.05,0.05)) +
  scale_x_continuous(limit=c(1978, 2023), breaks=c(seq(1980, 2020, 5), 2022), expand=c(0.05,0.05)) +
  scale_color_manual(name=NULL, values=colors[1:2])+
  theme_fivethirtyeight(base_size = 8) +
  custom_theme + 
  theme(legend.position = c(0.05, 0.05),
        legend.justification = c(0,0))

plot

ggsave(filename=paste0("ukr_rus_detail.png"),
       plot=plot,
       device = "png",
       path="figures/",
       dpi = 600,
       width=21,
       height = 7,
       units = "cm")


# USA GER CHE im detail

data = read.csv("statistics/avg_tone_usa_ger_che.csv")
data$name = paste0(data$country_name, " <> ", data$partner_name)

plot = ggplot() + 
  geom_line(data=subset(data, year >= 1979), aes(x=year, y=tone, color=name), size=1.5, lineend="round") +
  labs(x="Jahr", y="Durchschnittlicher Ton") +
  geom_vline(xintercept=2013, color=lightgrey, size=1, alpha=0.5) + 
  geom_hline(yintercept=0, color=lightgrey, size=0.5, alpha=1) +  
  scale_y_continuous(breaks=c(seq(floor(min(data$tone)), ceiling(max(data$tone)), 2)),
                     labels = c(seq(floor(min(data$tone)), ceiling(max(data$tone)), 2)), 
                     limit=c(min(data$tone), max(data$tone)),
                     expand=c(0.05,0.05)) +
  scale_x_continuous(limit=c(1978, 2023), breaks=c(seq(1980, 2020, 5), 2022), expand=c(0.05,0.05)) +
  scale_color_manual(name=NULL, values=rev(colors[1:3]))+
  theme_fivethirtyeight(base_size = 8) +
  custom_theme + 
  theme(legend.position = c(0.05, 0.05),
        legend.justification = c(0,0),
        legend.direction = "vertical")

plot

ggsave(filename=paste0("avg_tone_usa_ger_che.png"),
       plot=plot,
       device = "png",
       path="figures/",
       dpi = 600,
       width=21,
       height = 7,
       units = "cm")


# USA GER CHE UKR corrected in detail

data = read.csv("statistics/avg_tone_usa_ger_che_ukr_rus_corrected.csv")
data$name = paste0(data$country_name, " <> ", data$partner_name)
data$order[data$country_iso=="DEU" & data$partner_iso=="USA"] = 1
data$order[data$country_iso=="DEU" & data$partner_iso=="CHE"] = 2
data$order[data$country_iso=="CHE" & data$partner_iso=="USA"] = 3
data$order[data$country_iso=="RUS" & data$partner_iso=="UKR"] = 4
data = data[with(data, order(order, year)),]
row.names(data) = NULL

plot = ggplot() + 
  geom_line(data=subset(data, year >= 1979), aes(x=year, y=tone, color=fct_reorder(name, order)), size=1.5, lineend="round") +
  labs(x="Jahr", y="Durchschnittlicher Ton") +
  geom_text(aes(x=2014, y=min(data$tone), label="Annexion der\nKrim Halbinsel (2014)", hjust=1, vjust=0), size=2.2, nudge_x=-0.5, nudge_y = 0.05) +
  geom_vline(xintercept=2014, color=lightgrey, size=1, alpha=0.5) + 
  geom_hline(yintercept=0, color=lightgrey, size=0.5, alpha=1) +  
  scale_y_continuous(breaks=c(seq(floor(min(data$tone)), ceiling(max(data$tone)), 2)),
                     labels = c(seq(floor(min(data$tone)), ceiling(max(data$tone)), 2)), 
                     limit=c(min(data$tone), max(data$tone)),
                     expand=c(0.05,0.05)) +
  scale_x_continuous(limit=c(1978, 2023), breaks=c(seq(1980, 2020, 5), 2022), expand=c(0.05,0.05)) +
  scale_color_manual(name=NULL, values=c(rev(colors[1:3]), colors[4]))+
  theme_fivethirtyeight(base_size = 8) +
  custom_theme + 
  theme(legend.position = c(0.05, 0.05),
        legend.justification = c(0,0),
        legend.direction = "vertical")

plot

ggsave(filename=paste0("avg_tone_usa_ger_che_ukr_rus_corrected.png"),
       plot=plot,
       device = "png",
       path="figures/",
       dpi = 600,
       width=21,
       height = 7,
       units = "cm")


# USA regression graphs

data = read.csv("statistics/usa_regression_set.csv")
dataAvg = aggregate(tone ~ gov_period, data, mean)
dataMin = aggregate(tone ~ gov_period, data, min)
colnames(dataMin) = c("gov_period", "min_tone")
dataAvg$x = seq(1, nrow(dataAvg))
dataAvg = merge(dataAvg, dataMin, by="gov_period")

plot = ggplot() + 
  geom_violin(data=data, aes(x=gov_period, y=tone), fill=colors[1]) +
  geom_line(data=dataAvg, aes(x=x, y=tone), color=colors[4], size=1, lineend="round") + 
  geom_label(data=dataAvg, aes(x=x, y=min(min_tone)+0.5, label=round(tone, 2)), color=colors[4], size=2.5 ) + 
  labs(x="Amtszeit", y="Verteilung der durchschnittlichen\nStimmungen pro Periode") +
  scale_y_continuous(breaks=c(min(data$tone), seq(ceiling(min(data$tone)), max(data$tone), 3), max(data$tone)),
                     labels = round(c(min(data$tone), seq(ceiling(min(data$tone)), max(data$tone), 3), max(data$tone)), 2), 
                     limit=c(min(data$tone), max(data$tone)),
                     expand=c(0.05,0.05)) +
  theme_fivethirtyeight(base_size = 8) +
  custom_theme + 
  theme(legend.position = c(0.05, 0.05),
        legend.justification = c(0,0),
        legend.direction = "vertical")

plot

ggsave(filename=paste0("usa_violin_plot.png"),
       plot=plot,
       device = "png",
       path="figures/",
       dpi = 600,
       width=21,
       height = 6,
       units = "cm")


# Distribution of R-Squared values

data = read.csv("statistics/all_regression_result_rsquared.csv")
dataGov = read.csv("statistics/gov_regression_result_rsquared.csv")

plot = ggplot() + 
  geom_violin(data=dataGov, aes(x=type, y=value, fill="Regierungs-Daten"), alpha=0.4, color="transparent") +
  geom_violin(data=data, aes(x=type, y=value, fill="Alle Daten"), alpha=0.4, color="transparent") +
  labs(x=NULL, y="Verteilung") +
  scale_y_continuous(breaks=c(seq(0, max(c(data$value, dataGov$value)), 0.05), 0.25),
                     labels = c(seq(0, max(c(data$value, dataGov$value)), 0.05), 0.25), 
                     limit=c(min(c(data$value, dataGov$value)), max(c(data$value, dataGov$value))),
                     expand=c(0.05,0.05)) +
  scale_fill_manual(values = c(colors[1], colors[4]), name = NULL, 
                    guide = guide_legend(reverse = FALSE)) + 
  theme_fivethirtyeight(base_size = 8) +
  custom_theme + 
  theme(legend.position = c(0.5, 0.95),
        legend.justification = c(0.5,1),
        legend.direction = "horizontal")

plot

ggsave(filename=paste0("global_regression_result_rsquared_violin.png"),
       plot=plot,
       device = "png",
       path="figures/",
       dpi = 600,
       width=21,
       height = 9,
       units = "cm")


# USA IRQ in detail

data = read.csv("statistics/usa_irq_detail.csv")
data$name = paste0(data$country_name, " <> ", data$partner_name)
data$type[data$data_type==1] = "Alle Daten"
data$type[data$data_type==2] = "Regierungs-Set"
data$type[data$data_type==3] = "Multi-Source-Set"
data = data[with(data, order(data_type, year)),]
row.names(data) = NULL
data = subset(data, data_type != 3)


plot = ggplot() + 
  geom_line(data=subset(data, year >= 1979), aes(x=year, y=tone, color=type, alpha=type, size=type), lineend="round") +
  labs(x="Jahr", y="Durchschnittlicher Ton") +
  geom_text(aes(x=2003, y=min(data$tone), label="Anfang Irak-Krieg", hjust=0, vjust=0), size=2.2, nudge_x=0.5, nudge_y = 0.05) +
  geom_vline(xintercept=2003, color=lightgrey, size=1, alpha=0.5) + 
  geom_hline(yintercept=0, color=lightgrey, size=0.5, alpha=1) +  
  scale_y_continuous(breaks=c( seq(ceiling(min(data$tone)), max(data$tone), 1)),
                     labels = round(c( seq(ceiling(min(data$tone)), max(data$tone), 1)), 2), 
                     limit=c(min(data$tone), max(data$tone)),
                     expand=c(0.05,0.05)) +
  scale_x_continuous(limit=c(1978, 2023), breaks=c(seq(1980, 2020, 5), 2022), expand=c(0.05,0.05)) +
  theme_fivethirtyeight(base_size = 8) +
  scale_color_manual(name = NULL, values=c(colors[1], colors[4])) +
  scale_alpha_manual(values=c(0.3,1)) + 
  scale_size_manual(values=c(1,1.5)) + 
  custom_theme + 
  guides(size=FALSE, alpha=FALSE) +
  theme(legend.position = c(0.05, 0.05),
        legend.justification = c(0,0),
        legend.direction = "vertical")

plot

ggsave(filename=paste0("usa_irq_detail.png"),
       plot=plot,
       device = "png",
       path="figures/",
       dpi = 600,
       width=21,
       height = 8,
       units = "cm")


# NLD RUS in detail

data = read.csv("statistics/nld_rus_detail.csv")
data$name = paste0(data$country_name, " <> ", data$partner_name)
data$type[data$data_type==1] = "Alle Daten"
data$type[data$data_type==2] = "Regierungs-Set"
data$type[data$data_type==3] = "Multi-Source-Set"
data = data[with(data, order(data_type, year)),]
row.names(data) = NULL
data = subset(data, data_type != 3)

plot = ggplot() + 
  geom_line(data=subset(data, year >= 1979), aes(x=year, y=tone, color=type, alpha=type, size=type), lineend="round") +
  labs(x="Jahr", y="Durchschnittlicher Ton") +
  geom_text(aes(x=2014, y=min(data$tone), label="Abschuss des\nPassagierflugzeugs MH17", hjust=1, vjust=0), size=2.2, nudge_x=-0.5, nudge_y = 0.05) +
  geom_vline(xintercept=2014, color=lightgrey, size=1, alpha=0.5) + 
  geom_hline(yintercept=0, color=lightgrey, size=0.5, alpha=1) +  
  scale_y_continuous(breaks=c( seq(ceiling(min(data$tone)), max(data$tone), 1)),
                     labels = round(c( seq(ceiling(min(data$tone)), max(data$tone), 1)), 2), 
                     limit=c(min(data$tone), max(data$tone)),
                     expand=c(0.05,0.05)) +
  scale_x_continuous(limit=c(1978, 2023), breaks=c(seq(1980, 2020, 5), 2022), expand=c(0.05,0.05)) +
  theme_fivethirtyeight(base_size = 8) +
  scale_color_manual(name = NULL, values=c(colors[1], colors[4])) +
  scale_alpha_manual(values=c(0.3,1)) + 
  scale_size_manual(values=c(1,1.5)) + 
  guides(size=FALSE, alpha=FALSE) +
  custom_theme + 
  theme(legend.position = c(0.05, 0.05),
        legend.justification = c(0,0),
        legend.direction = "vertical")

plot

ggsave(filename=paste0("nld_rus_detail.png"),
       plot=plot,
       device = "png",
       path="figures/",
       dpi = 600,
       width=21,
       height = 8,
       units = "cm")


# AFG USA in detail
data = read.csv("statistics/afg_usa_detail.csv")
data$name = paste0(data$country_name, " <> ", data$partner_name)
data$type[data$data_type==1] = "Alle Daten"
data$type[data$data_type==2] = "Regierungs-Set"
data$type[data$data_type==3] = "Multi-Source-Set"
data = data[with(data, order(data_type, year)),]
row.names(data) = NULL
data = subset(data, data_type != 3)

plot = ggplot() + 
  geom_line(data=subset(data, year >= 1979), aes(x=year, y=tone, color=type, alpha=type, size=type), lineend="round") +
  labs(x="Jahr", y="Durchschnittlicher Ton") +
  geom_text(aes(x=2001, y=min(data$tone), label="9/11 Terror-Anschlag", hjust=0, vjust=0), size=2.2, nudge_x=0.5, nudge_y = 0.05) +
  geom_vline(xintercept=2001, color=lightgrey, size=1, alpha=0.5) + 
  geom_hline(yintercept=0, color=lightgrey, size=0.5, alpha=1) +  
  scale_y_continuous(breaks=c( seq(ceiling(min(data$tone)), max(data$tone), 1)),
                     labels = round(c( seq(ceiling(min(data$tone)), max(data$tone), 1)), 2), 
                     limit=c(min(data$tone), max(data$tone)),
                     expand=c(0.05,0.05)) +
  scale_x_continuous(limit=c(1978, 2023), breaks=c(seq(1980, 2020, 5), 2022), expand=c(0.05,0.05)) +
  theme_fivethirtyeight(base_size = 8) +
  scale_color_manual(name = NULL, values=c(colors[1], colors[4])) +
  scale_alpha_manual(values=c(0.3,1)) + 
  scale_size_manual(values=c(1,1.5)) + 
  guides(size=FALSE, alpha=FALSE) +
  custom_theme + 
  theme(legend.position = c(0.05, 0.05),
        legend.justification = c(0,0),
        legend.direction = "vertical")

plot

ggsave(filename=paste0("afg_usa_detail.png"),
       plot=plot,
       device = "png",
       path="figures/",
       dpi = 600,
       width=21,
       height = 8,
       units = "cm")

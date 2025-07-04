################################################################################
# AnoBac | Plot meningotype summary
#
# Author: Vladimir Bajić
# Date: June 2025
#
# Outputs:
#
#   - meningotype.png
#     meningotype bar plots
#     MLST vs Serogroup table
#     MLST vs BLAST table
#
# Usage:
#
# To see help message
#   Rscript --vanilla anobac_plot_summary_meningotype.R --help
#
# To plot
#   Rscript --vanilla anobac_plot_summary_meningotype.R -i meningotype_out -o out_dir
#
################################################################################

# Libraries --------------------------------------------------------------------
suppressMessages(library(tidyverse))
library(optparse)
library(ggnewscale)
library(ggpubr)
library(patchwork)

# Making option list -----------------------------------------------------------
option_list <- list(
    make_option(c("-i", "--input"), type = "character", help = "Path to the meningotype summary output file [csv]", metavar = "character"),
    make_option(c("-o", "--output"), type = "character", help = "Path to the output directory", metavar = "character")
)

# Parsing options
opt_parser <- OptionParser(option_list = option_list)
opt <- parse_args(opt_parser)

# Check the provided option and execute the corresponding code -----------------
if (is.null(opt$i)) {
    print_help(opt_parser)
    stop("Path to the meningotype summary output file [csv] must be provided.\n")
}

# Check if output is specified and if not use input to define it
if (is.null(opt$o)) {
    opt$o <- tools::file_path_sans_ext(opt$i)
    cat("Output not specified.\nOutput will be saved as: ", opt$o, "\n", sep = "")
}

# Create out dir if it doesn't exist -------------------------------------------
if (!dir.exists(opt$o)) {
    cat("Creating output directory.\n")
    dir.create(opt$o)
}

# Load the data ------------------------------------------------------------
meningotype <- read_csv(opt$i, col_types = cols(.default = col_character()))
order4plot <- c("MLST", "SEROGROUP", "ctrA", "PorA", "FetA", "PorB", "fHbp", "NHBA", "NadA", "BAST")

# Plot table meningotype ---------------------------------------------------
p_meningotype_table_1 <-
    meningotype %>%
    select(MLST, SEROGROUP) %>%
    mutate(MLST = fct_infreq(MLST)) %>%
    mutate(SEROGROUP = fct_infreq(SEROGROUP)) %>%
    group_by(MLST, SEROGROUP) %>%
    summarise(n = n(), .groups = "drop") %>%
    ggplot(aes(MLST, SEROGROUP)) +
    geom_point(aes(size = n, alpha = n), color = "orange") +
    geom_text(aes(label = n)) +
    theme_bw() +
    theme(
        panel.grid.minor = element_blank(),
        legend.position = "none",
        axis.text.x = element_text(angle = 90, vjust = 0.5, hjust = 1)
    ) +
    labs(title = paste("MLST and SEROGROUP | N =", nrow(meningotype)))

p_meningotype_table_2 <-
    meningotype %>%
    select(MLST, BAST) %>%
    mutate(MLST = fct_infreq(MLST)) %>%
    mutate(BAST = fct_infreq(BAST)) %>%
    group_by(MLST, BAST) %>%
    summarise(n = n(), .groups = "drop") %>%
    ggplot(aes(MLST, BAST)) +
    geom_point(aes(size = n, alpha = n), color = "orange") +
    geom_text(aes(label = n)) +
    theme_bw() +
    theme(
        panel.grid.minor = element_blank(),
        legend.position = "none",
        axis.text.x = element_text(angle = 90, vjust = 0.5, hjust = 1)
    ) +
    labs(title = paste("MLST and BAST | N =", nrow(meningotype)))

# Transform data for plotting ----------------------------------------------
meningotype_long <-
    meningotype %>%
    mutate(across(
        .cols = where(is.character),
        .fns = as.factor
    )) %>%
    mutate(across(
        .cols = -1,
        .fns = ~ fct_lump_n(.x, n = 8, other_level = NA, ties.method = "first")
    )) %>%
    mutate(across(
        .cols = -1,
        .fns = ~ fct_infreq(.x)
    )) %>%
    pivot_longer(cols = -1) %>%
    arrange(name, value) %>%
    mutate(
        name = as.factor(name),
        name = fct_relevel(name, !!!order4plot),
        value = as.factor(value)
    )

# Plot bars Species, Serotype, and QC --------------------------------------
p_meningotype_bar <-
    meningotype_long %>%
    ggplot() +
    geom_bar(aes(y = name, fill = fct_infreq(value)), filter(meningotype_long, name == "MLST")) +
    scale_fill_brewer(
        palette = "Dark2",
        labels = function(breaks) {
            breaks[is.na(breaks)] <- "Others"
            breaks
        },
        na.value = "black",
        guide = guide_legend(order = 10, ncol = 3, direction = "vertical")
    ) +
    labs(fill = "MLST") +
    new_scale_fill() +
    geom_bar(aes(y = name, fill = fct_infreq(value)), filter(meningotype_long, name == "SEROGROUP")) +
    scale_fill_brewer(
        palette = "Dark2",
        labels = function(breaks) {
            breaks[is.na(breaks)] <- "Others"
            breaks
        },
        na.value = "black",
        guide = guide_legend(order = 9, ncol = 3, direction = "vertical")
    ) +
    labs(fill = "SEROGROUP") +
    new_scale_fill() +
    geom_bar(aes(y = name, fill = fct_infreq(value)), filter(meningotype_long, name == "ctrA")) +
    scale_fill_brewer(
        palette = "Pastel2",
        labels = function(breaks) {
            breaks[is.na(breaks)] <- "Others"
            breaks
        },
        na.value = "black",
        guide = guide_legend(order = 8, ncol = 3, direction = "vertical")
    ) +
    labs(fill = "ctrA") +
    new_scale_fill() +
    geom_bar(aes(y = name, fill = fct_infreq(value)), filter(meningotype_long, name == "PorA")) +
    scale_fill_brewer(
        palette = "Pastel2",
        labels = function(breaks) {
            breaks[is.na(breaks)] <- "Others"
            breaks
        },
        na.value = "black",
        guide = guide_legend(order = 7, ncol = 3, direction = "vertical")
    ) +
    labs(fill = "PorA") +
    new_scale_fill() +
    geom_bar(aes(y = name, fill = fct_infreq(value)), filter(meningotype_long, name == "FetA")) +
    scale_fill_brewer(
        palette = "Pastel2",
        labels = function(breaks) {
            breaks[is.na(breaks)] <- "Others"
            breaks
        },
        na.value = "black",
        guide = guide_legend(order = 6, ncol = 3, direction = "vertical")
    ) +
    labs(fill = "FetA") +
    new_scale_fill() +
    geom_bar(aes(y = name, fill = fct_infreq(value)), filter(meningotype_long, name == "PorB")) +
    scale_fill_brewer(
        palette = "Pastel2",
        labels = function(breaks) {
            breaks[is.na(breaks)] <- "Others"
            breaks
        },
        na.value = "black",
        guide = guide_legend(order = 5, ncol = 3, direction = "vertical")
    ) +
    labs(fill = "PorB") +
    new_scale_fill() +
    geom_bar(aes(y = name, fill = fct_infreq(value)), filter(meningotype_long, name == "fHbp")) +
    scale_fill_brewer(
        palette = "Pastel2",
        labels = function(breaks) {
            breaks[is.na(breaks)] <- "Others"
            breaks
        },
        na.value = "black",
        guide = guide_legend(order = 4, ncol = 3, direction = "vertical")
    ) +
    labs(fill = "fHbp") +
    new_scale_fill() +
    geom_bar(aes(y = name, fill = fct_infreq(value)), filter(meningotype_long, name == "NHBA")) +
    scale_fill_brewer(
        palette = "Pastel2",
        labels = function(breaks) {
            breaks[is.na(breaks)] <- "Others"
            breaks
        },
        na.value = "black",
        guide = guide_legend(order = 3, ncol = 3, direction = "vertical")
    ) +
    labs(fill = "NHBA") +
    new_scale_fill() +
    geom_bar(aes(y = name, fill = fct_infreq(value)), filter(meningotype_long, name == "NadA")) +
    scale_fill_brewer(
        palette = "Pastel2",
        labels = function(breaks) {
            breaks[is.na(breaks)] <- "Others"
            breaks
        },
        na.value = "black",
        guide = guide_legend(order = 2, ncol = 3, direction = "vertical")
    ) +
    labs(fill = "NadA") +
    theme_bw() +
    ylab("") +
    labs(title = "meningotype") +
    new_scale_fill() +
    geom_bar(aes(y = name, fill = fct_infreq(value)), filter(meningotype_long, name == "BAST")) +
    scale_fill_brewer(
        palette = "Dark2",
        labels = function(breaks) {
            breaks[is.na(breaks)] <- "Others"
            breaks
        },
        na.value = "black",
        guide = guide_legend(order = 1, ncol = 3, direction = "vertical")
    ) +
    labs(fill = "BAST") +
    theme(
        legend.position = "right",
        legend.box = "vertical",
        plot.title = element_text(size = 12, face = "bold"),
        legend.title = element_text(size = 5),
        legend.text = element_text(size = 5),
        legend.key.size = unit(0.5, "lines")
    )

# Combine plots in one -----------------------------------------------------
p_meningotype <- ggarrange(p_meningotype_bar, p_meningotype_table_1, p_meningotype_table_2, ncol = 1, nrow = 3, heights = c(30, 10, 10), widths = c(10, 10, 10))

# Save plot ----------------------------------------------------------------
ggsave(paste0(opt$o, "/", "meningotype.png"), p_meningotype, dpi = 600, width = 30, height = 40, units = "cm", device = "png")

################################################################################
# AnoBac | Plot ngmaster summary
#
# Author: Vladimir Bajić
# Date: June 2025
#
# Outputs:
#
#   - ngmaster.png
#     ngmaster bar plots
#     NG-MAST vs MG-STAR table
#
# Usage:
#
# To see help message
#   Rscript --vanilla anobac_plot_summary_ngmaster.R --help
#
# To plot
#   Rscript --vanilla anobac_plot_summary_ngmaster.R -i ngmaster_out -o out_dir
#
################################################################################

# Libraries --------------------------------------------------------------------
suppressMessages(library(tidyverse))
library(optparse)
library(ggnewscale)
library(ggpubr)

# Making option list -----------------------------------------------------------
option_list <- list(
    make_option(c("-i", "--input"), type = "character", help = "Path to the ngmaster summary output file [csv]", metavar = "character"),
    make_option(c("-o", "--output"), type = "character", help = "Path to the output directory", metavar = "character")
)

# Parsing options
opt_parser <- OptionParser(option_list = option_list)
opt <- parse_args(opt_parser)

# Check the provided option and execute the corresponding code -----------------
if (is.null(opt$i)) {
    print_help(opt_parser)
    stop("Path to the ngmaster summary output file [csv] must be provided.\n")
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
ngmaster <- read_csv(opt$i, col_types = cols(.default = col_character()))
order4plot <- names(ngmaster)[-c(1:3)]

# Plot table ngmaster NG-MAST and NG-STAR ----------------------------------
p_ngmaster_table <-
    ngmaster %>%
    select(`NG-MAST/NG-STAR`) %>%
    separate(col = `NG-MAST/NG-STAR`, into = c("NG-MAST", "NG-STAR"), sep = "/") %>%
    mutate(`NG-MAST` = fct_infreq(`NG-MAST`)) %>%
    mutate(`NG-STAR` = fct_infreq(`NG-STAR`)) %>%
    group_by(`NG-MAST`, `NG-STAR`) %>%
    summarise(n = n(), .groups = "drop") %>%
    ggplot(aes(`NG-MAST`, `NG-STAR`)) +
    geom_point(aes(size = n, alpha = n), color = "orange") +
    geom_text(aes(label = n)) +
    theme_bw() +
    theme(
        panel.grid.minor = element_blank(),
        legend.position = "none",
        axis.text.x = element_text(angle = 90, vjust = 0.5, hjust = 1)
    ) +
    labs(title = paste("NG-MAST and NG-STAR | N =", nrow(ngmaster)))

# Transform data for plotting ----------------------------------------------
ngmaster_long <-
    ngmaster %>%
    select(-c(2, 3)) %>%
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
p_ngmaster_bar <-
    ngmaster_long %>%
    ggplot() +
    geom_bar(aes(y = name, fill = fct_infreq(value)), filter(ngmaster_long, name == "porB_NG-MAST")) +
    scale_fill_brewer(
        palette = "Dark2",
        labels = function(breaks) {
            breaks[is.na(breaks)] <- "Others"
            breaks
        },
        na.value = "black",
        guide = guide_legend(order = 9, ncol = 3, direction = "vertical")
    ) +
    labs(fill = "porB_NG-MAST") +
    new_scale_fill() +
    geom_bar(aes(y = name, fill = fct_infreq(value)), filter(ngmaster_long, name == "tbpB")) +
    scale_fill_brewer(
        palette = "Dark2",
        labels = function(breaks) {
            breaks[is.na(breaks)] <- "Others"
            breaks
        },
        na.value = "black",
        guide = guide_legend(order = 8, ncol = 3, direction = "vertical")
    ) +
    labs(fill = "tbpB") +
    new_scale_fill() +
    geom_bar(aes(y = name, fill = fct_infreq(value)), filter(ngmaster_long, name == "penA")) +
    scale_fill_brewer(
        palette = "Dark2",
        labels = function(breaks) {
            breaks[is.na(breaks)] <- "Others"
            breaks
        },
        na.value = "black",
        guide = guide_legend(order = 7, ncol = 3, direction = "vertical")
    ) +
    labs(fill = "penA") +
    new_scale_fill() +
    geom_bar(aes(y = name, fill = fct_infreq(value)), filter(ngmaster_long, name == "mtrR")) +
    scale_fill_brewer(
        palette = "Dark2",
        labels = function(breaks) {
            breaks[is.na(breaks)] <- "Others"
            breaks
        },
        na.value = "black",
        guide = guide_legend(order = 6, ncol = 3, direction = "vertical")
    ) +
    labs(fill = "mtrR") +
    new_scale_fill() +
    geom_bar(aes(y = name, fill = fct_infreq(value)), filter(ngmaster_long, name == "porB_NG-STAR")) +
    scale_fill_brewer(
        palette = "Dark2",
        labels = function(breaks) {
            breaks[is.na(breaks)] <- "Others"
            breaks
        },
        na.value = "black",
        guide = guide_legend(order = 5, ncol = 3, direction = "vertical")
    ) +
    labs(fill = "porB_NG-STAR") +
    new_scale_fill() +
    geom_bar(aes(y = name, fill = fct_infreq(value)), filter(ngmaster_long, name == "ponA")) +
    scale_fill_brewer(
        palette = "Dark2",
        labels = function(breaks) {
            breaks[is.na(breaks)] <- "Others"
            breaks
        },
        na.value = "black",
        guide = guide_legend(order = 4, ncol = 3, direction = "vertical")
    ) +
    labs(fill = "ponA") +
    new_scale_fill() +
    geom_bar(aes(y = name, fill = fct_infreq(value)), filter(ngmaster_long, name == "gyrA")) +
    scale_fill_brewer(
        palette = "Dark2",
        labels = function(breaks) {
            breaks[is.na(breaks)] <- "Others"
            breaks
        },
        na.value = "black",
        guide = guide_legend(order = 3, ncol = 3, direction = "vertical")
    ) +
    labs(fill = "gyrA") +
    new_scale_fill() +
    geom_bar(aes(y = name, fill = fct_infreq(value)), filter(ngmaster_long, name == "parC")) +
    scale_fill_brewer(
        palette = "Dark2",
        labels = function(breaks) {
            breaks[is.na(breaks)] <- "Others"
            breaks
        },
        na.value = "black",
        guide = guide_legend(order = 2, ncol = 3, direction = "vertical")
    ) +
    labs(fill = "parC") +
    new_scale_fill() +
    geom_bar(aes(y = name, fill = fct_infreq(value)), filter(ngmaster_long, name == "23S")) +
    scale_fill_brewer(
        palette = "Dark2",
        labels = function(breaks) {
            breaks[is.na(breaks)] <- "Others"
            breaks
        },
        na.value = "black",
        guide = guide_legend(order = 1, ncol = 3, direction = "vertical")
    ) +
    labs(fill = "23S") +
    theme_bw() +
    ylab("") +
    labs(title = "ngmaster") +
    theme(
        legend.position = "right",
        legend.box = "vertical",
        plot.title = element_text(size = 12, face = "bold"),
        legend.title = element_text(size = 5),
        legend.text = element_text(size = 5),
        legend.key.size = unit(0.5, "lines")
    )

# Combine plots in one -----------------------------------------------------
p_ngmaster <- ggarrange(p_ngmaster_bar, p_ngmaster_table, ncol = 1, nrow = 2, heights = c(20, 10), widths = c(10, 10))

# Save plot ----------------------------------------------------------------
ggsave(paste0(opt$o, "/", "ngmaster.png"), p_ngmaster, dpi = 600, width = 30, height = 30, units = "cm", device = "png")

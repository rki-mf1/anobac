################################################################################
# AnoBac | Plot Kleborate summary
#
# Author: Vladimir Bajić
# Date: June 2025
#
# Outputs:
#
#   - Kleborate.png
#     Resistance vs Virulence table
#     Resistance and Virulence scores across STs
#     O-locus vs H-locus table
#
# Usage:
#
# To see help message
#   Rscript --vanilla anobac_plot_summary_kleborate.R --help
#
# To plot
#   Rscript --vanilla anobac_plot_summary_kleborate.R -i kleborate_out -o out_dir
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
    make_option(c("-i", "--input"), type = "character", help = "Path to the Kleborate summary output file [csv]", metavar = "character"),
    make_option(c("-o", "--output"), type = "character", help = "Path to the output directory", metavar = "character")
)

# Parsing options
opt_parser <- OptionParser(option_list = option_list)
opt <- parse_args(opt_parser)

# Check the provided option and execute the corresponding code -----------------

if (is.null(opt$i)) {
    print_help(opt_parser)
    stop("Path to the Kleborate summary output file [csv] must be provided.\n")
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

# Load the data ----------------------------------------------------------------
kleborate <- read_csv(opt$i, show_col_types = FALSE)

# Define colors for plots
colors4res <- c(
    "0" = "gray85",
    "1" = "#fcbba1",
    "2" = "#fc9272",
    "3" = "#fb6a4a",
    "4" = "#de2d26",
    "5" = "#a50f15"
)

colors4vir <- c(
    "0" = "gray85",
    "1" = "#c6dbef",
    "2" = "#9ecae1",
    "3" = "#6baed6",
    "4" = "#3182bd",
    "5" = "#08519c"
)

# Plot table kleborate virulence_score and resistance_score --------------------
p_kleborate_table <-
    kleborate %>%
    group_by(virulence_score, resistance_score) %>%
    summarise(n = n(), .groups = "drop") %>%
    ggplot(aes(virulence_score, resistance_score)) +
    geom_point(aes(size = n, alpha = n), color = "orange") +
    geom_text(aes(label = n)) +
    theme_bw() +
    xlim(0, 5) +
    ylim(0, 3) +
    xlab("Virulence Score") +
    ylab("Resistance Score") +
    theme(
        panel.grid.minor = element_blank(),
        legend.position = "none"
    ) +
    labs(title = paste("Kleborate | Virulence vs Resistance | N =", nrow(kleborate)))

# Plot table kleborate K and O -------------------------------------------------
p_kleborate_table_KO <-
    kleborate %>%
    mutate(K_locus = fct_infreq(K_locus), O_locus = fct_infreq(O_locus)) %>%
    group_by(K_locus, O_locus) %>%
    summarise(n = n(), .groups = "drop") %>%
    ggplot(aes(K_locus, O_locus)) +
    geom_point(aes(size = n, alpha = n), color = "orange") +
    geom_text(aes(label = n)) +
    theme_bw() +
    xlab("K-locus") +
    ylab("O-locus") +
    theme(
        panel.grid.minor = element_blank(),
        legend.position = "none",
        axis.text.x = element_text(angle = 90, vjust = 0.5, hjust = 1)
    ) +
    labs(title = paste("Kleborate | K and O loci | N =", nrow(kleborate)))

# Plot bars --------------------------------------------------------------------
# Compute total counts per ST
kleborate_totals <- kleborate %>%
    mutate(ST = fct_infreq(ST)) %>%
    count(ST)

# Plot res
p_kleborate_res <-
    kleborate %>%
    mutate(ST = fct_infreq(ST)) %>%
    mutate(resistance_score = as.factor(resistance_score)) %>%
    ggplot(aes(y = ST, fill = resistance_score)) +
    geom_bar() +
    geom_text(
        data = kleborate_totals,
        aes(x = n, y = ST, label = n),
        inherit.aes = FALSE,
        hjust = -0.1,
        size = 2.5
    ) +
    theme_bw() +
    labs(title = "Resistance Scores") +
    scale_fill_manual(values = colors4res) +
    theme(
        legend.title = element_text(size = 6),
        legend.text = element_text(size = 6),
        legend.key.size = unit(0.6, "lines"),
        axis.title.y = element_blank()
    )

# Plot vir
p_kleborate_vir <-
    kleborate %>%
    mutate(ST = fct_infreq(ST)) %>%
    mutate(virulence_score = as.factor(virulence_score)) %>%
    ggplot(aes(y = ST, fill = virulence_score)) +
    geom_bar() +
    theme_bw() +
    geom_text(
        data = kleborate_totals,
        aes(x = n, y = ST, label = n),
        inherit.aes = FALSE,
        hjust = -0.1,
        size = 2.5
    ) +
    labs(title = "Virulence Scores") +
    scale_fill_manual(values = colors4vir) +
    theme(
        legend.title = element_text(size = 6),
        legend.text = element_text(size = 6),
        legend.key.size = unit(0.6, "lines"),
        axis.title.y = element_blank()
    )

# Combine Res and Vir in one plot
p_kleborate_ResVir <- (p_kleborate_res + p_kleborate_vir) +
    plot_layout(guides = "collect") &
    theme(legend.position = "right")

# Combine ResVir with table plot
p_kleborate_ResVir_table <- (p_kleborate_table + p_kleborate_ResVir + p_kleborate_table_KO) +
    plot_layout(ncol = 1, heights = c(10, 20, 10))

# Save plot --------------------------------------------------------------------
ggsave(paste0(opt$o, "/", "kleborate.png"), p_kleborate_ResVir_table, dpi = 600, width = 20, height = 30, units = "cm", device = "png")

################################################################################
# AnoBac | Plot ECTyper summary
#
# Author: Vladimir Bajić
# Date: June 2025
#
# Outputs:
#
#   - ectyper.png
#     Bar plots summarizing Species, Serotype, and QC
#     O-type vs H-type table
#
# Usage:
#
# To see help message
#   Rscript --vanilla anobac_plot_summary_ectyper.R --help
#
# To plot
#   Rscript --vanilla anobac_plot_summary_ectyper.R -i ectyper_out -o out_dir
#
################################################################################

# Libraries --------------------------------------------------------------------
suppressMessages(library(tidyverse))
library(optparse)
library(ggnewscale)
library(ggpubr)

# Making option list -----------------------------------------------------------
option_list <- list(
    make_option(c("-i", "--input"), type = "character", help = "Path to the ECTyper summary output file [csv]", metavar = "character"),
    make_option(c("-o", "--output"), type = "character", help = "Path to the output directory", metavar = "character")
)
# Parsing options
opt_parser <- OptionParser(option_list = option_list)
opt <- parse_args(opt_parser)

# TEST-ONLY: Define variables -------------------------------------------------------------
# opt$i <- "/scratch/Projekte/MF1_GE/Research_Projects/AnoBac/1_analysis/IGS_BIG_dataset_ectyper2/summarize/ectyper.csv"
# opt$o <- "/scratch/Projekte/MF1_GE/Research_Projects/AnoBac/2_results/1_AnoBac_IGS_BIG_dataset_Rout"

# Check the provided option and execute the corresponding code -----------------

if (is.null(opt$i)) {
    print_help(opt_parser)
    stop("Path to the ECTyper summary output file [csv] must be provided.\n")
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
ectyper <- read_csv(opt$i, col_types = cols(.default = col_character()))

# Define colors for QC -----------------------------------------------------
colors4qc <- c(
    "PASS (REPORTABLE)" = "#4daf4a",
    "FAIL (-:- TYPING)" = "#e41a1c",
    "WARNING MIXED O-TYPE" = "#ffffe5",
    "WARNING (WRONG SPECIES)" = "#fff7bc",
    "WARNING (-:H TYPING)" = "#fee391",
    "WARNING (O:- TYPING)" = "#fec44f",
    "WARNING (O NON-REPORT)" = "#fe9929",
    "WARNING (H NON-REPORT)" = "#ec7014",
    "WARNING (O and H NON-REPORT)" = "#cc4c02"
)

# Plot table ectyper O-type and H-type -------------------------------------
p_ectyper_table <-
    ectyper %>%
    group_by(`O-type`, `H-type`) %>%
    summarise(n = n(), .groups = "drop") %>%
    ggplot(aes(`O-type`, `H-type`)) +
    geom_point(aes(size = n, alpha = n), color = "orange") +
    geom_text(aes(label = n)) +
    theme_bw() +
    theme(
        panel.grid.minor = element_blank(),
        legend.position = "none",
        axis.text.x = element_text(angle = 90, vjust = 0.5, hjust = 1)
    ) +
    labs(title = paste("O-type and H-type | N =", nrow(ectyper)))

# Transform data for plotting ----------------------------------------------
ectyper_long <-
    ectyper %>%
    select(Name, Species, Serotype, QC) %>%
    mutate(
        Species = fct_lump_n(as.factor(Species), n = 8, other_level = NA, ties.method = "first"),
        Species = fct_infreq(Species),
        Serotype = fct_lump_n(as.factor(Serotype), n = 8, other_level = NA, ties.method = "first"),
        Serotype = fct_infreq(Serotype)
    ) %>%
    pivot_longer(cols = -1) %>%
    mutate(
        name = as.factor(name),
        value = as.factor(value),
        value = fct_infreq(value)
    )

# Plot bars Species, Serotype, and QC --------------------------------------
p_ectyper_bar <-
    ectyper_long %>%
    ggplot() +
    geom_bar(aes(y = name, fill = value), filter(ectyper_long, name == "QC")) +
    scale_fill_manual(values = colors4qc, guide = guide_legend(order = 3)) +
    labs(fill = "QC") +
    new_scale_fill() +
    geom_bar(aes(y = name, fill = value), filter(ectyper_long, name == "Serotype")) +
    scale_fill_brewer(
        palette = "Pastel2",
        labels = function(breaks) {
            breaks[is.na(breaks)] <- "Others"
            breaks
        },
        na.value = "black",
        guide = guide_legend(order = 2)
    ) +
    labs(fill = "Serotype") +
    new_scale_fill() +
    geom_bar(aes(y = name, fill = value), filter(ectyper_long, name == "Species")) +
    scale_fill_brewer(
        palette = "Dark2",
        labels = function(breaks) {
            breaks[is.na(breaks)] <- "Others"
            breaks
        },
        na.value = "black",
        guide = guide_legend(order = 1)
    ) +
    labs(fill = "Species") +
    theme_bw() +
    ylab("") +
    labs(title = "ECTyper") +
    theme(
        plot.title = element_text(size = 12, face = "bold"),
        legend.title = element_text(size = 5),
        legend.text = element_text(size = 5),
        legend.key.size = unit(0.5, "lines")
    )

# Combine plots in one -----------------------------------------------------
p_ectyper <- ggarrange(p_ectyper_bar, p_ectyper_table, ncol = 1, nrow = 2, heights = c(10, 10), widths = c(10, 10))

# Save plot ----------------------------------------------------------------
ggsave(paste0(opt$o, "/", "ectyper.png"), p_ectyper, dpi = 600, width = 20, height = 20, units = "cm", device = "png")

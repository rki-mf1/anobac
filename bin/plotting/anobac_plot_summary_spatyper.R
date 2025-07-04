################################################################################
# AnoBac | Plot spaTyper summary
#
# Author: Vladimir Bajić
# Date: June 2025
#
# Outputs:
#
#   - spatyper.png
#     spaTyper bar plots
#
# Usage:
#
# To see help message
#   Rscript --vanilla anobac_plot_summary_spatyper.R --help
#
# To plot
#   Rscript --vanilla anobac_plot_summary_spatyper.R -i spatyper_out -o out_dir
#
################################################################################

# Libraries --------------------------------------------------------------------
suppressMessages(library(tidyverse))
library(optparse)

# Making option list -----------------------------------------------------------
option_list <- list(
    make_option(c("-i", "--input"), type = "character", help = "Path to the spaTyper summary output file [csv]", metavar = "character"),
    make_option(c("-o", "--output"), type = "character", help = "Path to the output directory", metavar = "character")
)

# Parsing options
opt_parser <- OptionParser(option_list = option_list)
opt <- parse_args(opt_parser)

# Check the provided option and execute the corresponding code -----------------
if (is.null(opt$i)) {
    print_help(opt_parser)
    stop("Path to the spaTyper summary output file [csv] must be provided.\n")
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
spatyper <- read_csv(opt$i, col_types = cols(.default = col_character()))

# Plot bars Species, Serotype, and QC --------------------------------------
p_spatyper <-
    spatyper %>%
    ggplot() +
    geom_bar(aes(y = fct_rev(fct_infreq(Type)))) +
    theme_bw() +
    labs(title = "spaTyper") +
    theme(
        plot.title = element_text(size = 12, face = "bold"),
        legend.title = element_text(size = 5),
        legend.text = element_text(size = 5),
        legend.key.size = unit(0.5, "lines"),
        axis.title.y = element_blank()
    )
# Save plot ----------------------------------------------------------------
ggsave(paste0(opt$o, "/", "spatyper.png"), p_spatyper, dpi = 600, width = 20, height = 20, units = "cm", device = "png")

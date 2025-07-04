################################################################################
# AnoBac | Plot AMRFinderPlus summary for all files in input dir
#
# Author: Vladimir Bajić
# Date: June 2025
#
# Outputs:
#
#   - amrfinderplus_summary_class.png
#     Violin plots per class grouped by species
#
#   - amrfinderplus_summary_subtype.png
#     Violin plots per subtype grouped by species
#
#   - amrfinderplus_summary_type.png
#     Violin plots per type grouped by species
#
# Usage:
#
# To see help message
#   Rscript --vanilla anobac_plot_amrfinderplus.R --help
#
# To plot
#   Rscript --vanilla anobac_plot_amrfinderplus.R -i amrfinderplus_out_dir -s anobac_samplesheet -o out_dir
#
################################################################################

# Libraries --------------------------------------------------------------------
suppressMessages(library(tidyverse))
library(optparse)

# Making option list -----------------------------------------------------------
option_list <- list(
    make_option(c("-i", "--input"), type = "character", help = "Path to the input directory with AMRFinderPlus output files", metavar = "character"),
    make_option(c("-s", "--samplesheet"), type = "character", help = "Path to the AnoBac samplesheet file [csv]", metavar = "character"),
    make_option(c("-o", "--output"), type = "character", help = "Path to the output directory", metavar = "character")
)
# Parsing options
opt_parser <- OptionParser(option_list = option_list)
opt <- parse_args(opt_parser)

# TEST-ONLY: Define variables -------------------------------------------------------------
# opt$i <- "/scratch/Projekte/MF1_GE/Research_Projects/AnoBac/1_analysis/IGS_BIG_dataset_ectyper2/amrfinderplus"
# opt$s <- "/scratch/projekte/MF1_GE/Research_Projects/AnoBac/x_scripts/IGS_BIG_dataset_samplesheet.csv"
# opt$o <- "/scratch/Projekte/MF1_GE/Research_Projects/AnoBac/2_results/1_AnoBac_IGS_BIG_dataset_Rout"

# Check the provided option and execute the corresponding code -----------------

if (is.null(opt$i)) {
    print_help(opt_parser)
    stop("Path to the input directory with AMRFinderPlus output files must be provided.\n")
}

if (is.null(opt$s)) {
    print_help(opt_parser)
    stop("Path to the AnoBac samplesheet must be provided.\n")
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

# Read in species info from AnoBac samplesheet ---------------------------------
annobac_samplesheet <- read_csv(opt$s, col_types = cols(.default = col_character())) %>%
    mutate(file = basename(tools::file_path_sans_ext(fasta)), sp = paste0(genus, "_", species)) %>%
    select(-c(sample, fasta, genus, species)) %>%
    mutate(file = str_remove(file, "_T1$"))

# List of file paths
file_list_full <- list.files(path = opt$i, pattern = "\\.tsv$", full.names = TRUE)
file_list_mutations <- file_list_full[str_detect(file_list_full, "-mutations.tsv$")]
file_list <- file_list_full[!str_detect(file_list_full, "-mutations.tsv$")]

# Read and bind with filename column -------------------------------------------
cat("Loading all AMRFinderPlus files...\n")
df <- map_dfr(file_list, ~ read_tsv(.x, show_col_types = FALSE) %>% mutate(file = basename(tools::file_path_sans_ext(.x)))) %>%
    mutate(file = str_remove(file, "_T1$")) %>%
    left_join(annobac_samplesheet, by = join_by(file))

# Species per sample -----------------------------------------------------------
sp_info <- df %>%
    select(file, sp) %>%
    distinct()

# Summarize per sample ---------------------------------------------------------
cat("Summarizing AMRFinderPlus data.\n")
df_class <- df %>%
    count(file, Class) %>%
    complete(file, Class, fill = list(n = 0)) %>%
    left_join(., sp_info, by = join_by(file))

df_type <- df %>%
    count(file, Type) %>%
    complete(file, Type, fill = list(n = 0)) %>%
    left_join(., sp_info, by = join_by(file))

df_subtype <- df %>%
    count(file, Subtype) %>%
    complete(file, Subtype, fill = list(n = 0)) %>%
    left_join(., sp_info, by = join_by(file))

# Plot -------------------------------------------------------------------------
cat("Plotting violin plots with Class.\n")
p_amrfinderplus_class <-
    df_class %>%
    ggplot(aes(x = n, y = Class, fill = Class)) +
    geom_violin(drop = FALSE) +
    facet_wrap(~sp, scales = "free") +
    theme_bw() +
    ylab("") +
    xlab("") +
    ggtitle(paste("AMRFinderPlus summary | Class")) +
    theme(legend.position = "none")

# Save plot --------------------------------------------------------------------
ggsave(paste0(opt$o, "/", "amrfinderplus_summary_class.png"), p_amrfinderplus_class, dpi = 600, width = 40, height = 40, units = "cm", device = "png")

cat("Plotting violin plots with Type.\n")
p_amrfinderplus_type <-
    df_type %>%
    ggplot(aes(x = n, y = Type, fill = Type)) +
    geom_violin(drop = FALSE) +
    facet_wrap(~sp, scales = "free") +
    theme_bw() +
    ylab("") +
    xlab("") +
    ggtitle(paste("AMRFinderPlus summary | Type")) +
    theme(legend.position = "none")

# Save plot --------------------------------------------------------------------
ggsave(paste0(opt$o, "/", "amrfinderplus_summary_type.png"), p_amrfinderplus_type, dpi = 600, width = 40, height = 40, units = "cm", device = "png")


cat("Plotting violin plots with Subtype.\n")
p_amrfinderplus_subtype <-
    df_subtype %>%
    ggplot(aes(x = n, y = Subtype, fill = Subtype)) +
    geom_violin(drop = FALSE) +
    facet_wrap(~sp, scales = "free") +
    theme_bw() +
    ylab("") +
    xlab("") +
    ggtitle(paste("AMRFinderPlus summary | Subtype")) +
    theme(legend.position = "none")

# Save plot --------------------------------------------------------------------
ggsave(paste0(opt$o, "/", "amrfinderplus_summary_subtype.png"), p_amrfinderplus_subtype, dpi = 600, width = 40, height = 40, units = "cm", device = "png")

cat("Done.\n\n")

################################################################################

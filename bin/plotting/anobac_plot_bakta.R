################################################################################
# AnoBac | Plot Bakta summary for all files in input dir
#
# Author: Vladimir Bajić
# Date: June 2025
#
# Outputs:
#
#   - bakta_summary.png
#     Violin plots summarizing Bakta statistics for all samples
#
#   - bakta_summary_[species].png
#     Separate png plots per species
#
# Usage:
#
# To see help message
#   Rscript --vanilla anobac_plot_bakta.R --help
#
# To plot
#   Rscript --vanilla anobac_plot_bakta.R -i bakta_out_dir -s anobac_samplesheet -o out_dir
#
################################################################################

# Libraries --------------------------------------------------------------------
suppressMessages(library(tidyverse))
library(optparse)

# Making option list -----------------------------------------------------------
option_list <- list(
    make_option(c("-i", "--input"), type = "character", help = "Path to the input directory with Bakta output files", metavar = "character"),
    make_option(c("-s", "--samplesheet"), type = "character", help = "Path to the AnoBac samplesheet file [csv]", metavar = "character"),
    make_option(c("-o", "--output"), type = "character", help = "Path to the output directory", metavar = "character")
)
# Parsing options
opt_parser <- OptionParser(option_list = option_list)
opt <- parse_args(opt_parser)

# TEST-ONLY: Define variables -------------------------------------------------------------
# opt$i <- "/scratch/Projekte/MF1_GE/Research_Projects/AnoBac/1_analysis/IGS_BIG_dataset_ectyper2/bakta"
# opt$s <- "/scratch/projekte/MF1_GE/Research_Projects/AnoBac/x_scripts/IGS_BIG_dataset_samplesheet.csv"
# opt$o <- "/scratch/Projekte/MF1_GE/Research_Projects/AnoBac/2_results/1_AnoBac_IGS_BIG_dataset_Rout"

# Check the provided option and execute the corresponding code -----------------

if (is.null(opt$i)) {
    print_help(opt_parser)
    stop("Path to the input directory with Bakta output files must be provided.\n")
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
file_list <- list.files(path = opt$i, pattern = "\\.txt$", full.names = TRUE)

# Function to parse each file --------------------------------------------------
parse_bakta_file <- function(file) {
    lines <- read_lines(file)

    lines_with_colon <- lines[str_detect(lines, ":")]

    kv_matrix <- str_split_fixed(lines_with_colon, ":", 2)

    kv <- tibble(
        file = basename(tools::file_path_sans_ext(file)),
        key = str_trim(kv_matrix[, 1]),
        value = str_trim(kv_matrix[, 2])
    )

    return(kv)
}


# Read all files and combine into one tibble -----------------------------------
cat("Loading all Bakta files...\n")
bakta_full <- map_dfr(file_list, parse_bakta_file)

# Columns classification -------------------------------------------------------
exclude_columns <- c("Sequence(s)", "Annotation", "Bakta", "Software", "Database", "DOI", "URL")
sequence_columns <- c("Length", "Count", "GC", "N50", "N90", "N ratio", "coding density")
annotation_columns <- c("tRNAs", "tmRNAs", "rRNAs", "ncRNAs", "ncRNA regions", "CRISPR arrays", "CDSs", "pseudogenes", "hypotheticals", "sORFs", "gaps", "oriCs", "oriVs", "oriTs")

# Extract infor for plot title -------------------------------------------------
software_info <- bakta_full %>%
    select(key, value) %>%
    filter(key == "Software") %>%
    distinct() %>%
    pull()
db_info <- bakta_full %>%
    select(key, value) %>%
    filter(key == "Database") %>%
    distinct() %>%
    pull()

# Exclude entries that are not important ---------------------------------------
bakta <-
    bakta_full %>%
    filter(!key %in% exclude_columns) %>%
    mutate(value = as.numeric(value)) %>%
    mutate(class = case_when(
        key %in% sequence_columns ~ "Sequence",
        key %in% annotation_columns ~ "Annotation"
    )) %>%
    mutate(key = factor(key, levels = c(sequence_columns, annotation_columns))) %>% # custom order
    mutate(file = str_remove(file, "_T1$")) %>%
    left_join(., annobac_samplesheet, by = join_by(file))


# Pivot to wider format --------------------------------------------------------
bakta_wide <- bakta %>%
    select(-class) %>%
    pivot_wider(names_from = key, values_from = value)

# Save merged table ------------------------------------------------------------
cat("Saving Bakta summary table.\n")
write_csv(bakta_wide, paste0(opt$o, "/", "bakta_summary_table.csv"))

# Plot violins with all species together ---------------------------------------
cat("Plotting full Bakta summary.\n")
p_bakta_full <-
    bakta %>%
    mutate(key = factor(key, levels = c(sequence_columns, annotation_columns))) %>% # custom order
    ggplot(aes(x = sp, y = value, fill = class)) +
    geom_violin() +
    facet_wrap(~key, scales = "free", ncol = 7) +
    theme_bw() +
    ylab("") +
    xlab("") +
    ggtitle(paste("Bakta", software_info, "| Database:", db_info, "| Number of samples:", nrow(bakta_wide))) +
    theme(
        legend.position = "none",
        axis.text.x = element_text(angle = 90, vjust = 0.5, hjust = 1),
        strip.text = element_text(face = "bold") # optional: make facet labels bold
    ) +
    scale_fill_manual(values = c("#E1BE6A", "#40B0A6"))

# Save plot --------------------------------------------------------------------
ggsave(paste0(opt$o, "/", "bakta_summary.png"), p_bakta_full, dpi = 600, width = 40, height = 40, units = "cm", device = "png")

# Create plot for each species -------------------------------------------------
for (species in unique(bakta$sp)) {
    cat("Plotting Bakta summary for ", species, ".\n", sep = "")

    # Calculate number of samples in species -----------------------------------
    n_samples <- bakta_wide %>%
        filter(sp == species) %>%
        nrow()

    # Plot violins per species -------------------------------------------------
    p_bakta <-
        bakta %>%
        filter(sp == species) %>%
        mutate(key = factor(key, levels = c(sequence_columns, annotation_columns))) %>% # custom order
        ggplot(aes(x = key, y = value, fill = class)) +
        geom_violin() +
        facet_wrap(~key, scales = "free", ncol = 7) +
        theme_bw() +
        xlab("") +
        ylab("") +
        ggtitle(paste("Bakta", software_info, "| Database:", db_info, "| Number of", species, "samples:", n_samples)) +
        theme(
            legend.position = "none",
            axis.text.x = element_blank(), # remove x-axis text
            axis.ticks.x = element_blank(), # remove x-axis ticks
            strip.text = element_text(face = "bold") # optional: make facet labels bold
        ) +
        scale_fill_manual(values = c("#E1BE6A", "#40B0A6"))

    # Save plot ----------------------------------------------------------------
    ggsave(paste0(opt$o, "/", "bakta_summary_", species, ".png"), p_bakta, dpi = 600, width = 40, height = 20, units = "cm", device = "png")
}

cat("Done.\n\n")

################################################################################

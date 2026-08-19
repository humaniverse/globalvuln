# Prepare the package datasets from the validated humanitarian-intensity
# pipeline outputs. Run this script from the globalvuln package root.

source_dir <- Sys.getenv(
  "HUMANITARIAN_INTENSITY_DIR",
  unset = file.path("..", "ad-hoc-analysis", "analysis", "humanitarian-intensity")
)

long_path <- file.path(
  source_dir, "data", "processed", "humanitarian_indices_long.rds"
)
manifest_path <- file.path(source_dir, "artifacts", "source_manifest.csv")

required_files <- c(long_path, manifest_path)
missing_files <- required_files[!file.exists(required_files)]
if (length(missing_files)) {
  stop(
    "Missing required humanitarian-intensity output(s):\n",
    paste0("- ", missing_files, collapse = "\n"),
    call. = FALSE
  )
}

humanitarian_indices_long <- as.data.frame(readRDS(long_path))
humanitarian_index_sources <- read.csv(
  manifest_path,
  stringsAsFactors = FALSE,
  na.strings = ""
)
humanitarian_index_sources$retrieval_date <- as.Date(
  humanitarian_index_sources$retrieval_date
)

index_ids <- c(
  "inform_risk", "inform_severity", "underfunded_crisis",
  "oecd_fragility", "worldrisk", "nd_gain", "hdi", "mpi", "ghi", "ghs",
  "wps", "un_mvi", "debt_distress", "searo", "disaster_displacement",
  "internal_displacement"
)

observed_index_ids <- unique(humanitarian_indices_long$index_id)
if (!identical(observed_index_ids, index_ids)) {
  stop(
    "Unexpected index identifiers or order in humanitarian_indices_long.",
    call. = FALSE
  )
}
if (nrow(humanitarian_indices_long) != 195L * length(index_ids) ||
    anyDuplicated(humanitarian_indices_long[c("iso3", "index_id")])) {
  stop("The long dataset is not a complete country-index grid.", call. = FALSE)
}
if (length(unique(humanitarian_indices_long$iso3)) != 195L ||
    anyNA(humanitarian_indices_long$iso3)) {
  stop("The long dataset does not contain 195 unique ISO3 codes.", call. = FALSE)
}

included <- humanitarian_indices_long$eligible_for_counts %in% TRUE &
  !is.na(humanitarian_indices_long$rank)
humanitarian_indices_long$top_10 <- rep(NA, nrow(humanitarian_indices_long))
humanitarian_indices_long$top_20 <- rep(NA, nrow(humanitarian_indices_long))
humanitarian_indices_long$top_10[included] <-
  humanitarian_indices_long$rank[included] <= 10L
humanitarian_indices_long$top_20[included] <-
  humanitarian_indices_long$rank[included] <= 20L

individual_indices <- split(
  humanitarian_indices_long,
  factor(humanitarian_indices_long$index_id, levels = index_ids),
  drop = TRUE
)
individual_indices <- lapply(individual_indices, function(x) {
  rownames(x) <- NULL
  x
})
list2env(individual_indices, envir = environment())

dir.create("data", showWarnings = FALSE)

save(
  humanitarian_index_sources,
  file = file.path("data", "humanitarian_index_sources.rda"),
  version = 3,
  compress = "xz"
)

for (index_id in index_ids) {
  save(
    list = index_id,
    file = file.path("data", paste0(index_id, ".rda")),
    version = 3,
    compress = "xz"
  )
}

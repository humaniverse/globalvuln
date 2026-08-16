# Prepare the package datasets from the validated humanitarian-intensity
# pipeline outputs. Run this script from the globalvuln package root.

source_dir <- Sys.getenv(
  "HUMANITARIAN_INTENSITY_DIR",
  unset = file.path("..", "ad-hoc-analysis", "analysis", "humanitarian-intensity")
)

long_path <- file.path(
  source_dir, "data", "processed", "humanitarian_indices_long.rds"
)
country_path <- file.path(
  source_dir, "data", "processed", "humanitarian_indices_country.rds"
)
manifest_path <- file.path(source_dir, "artifacts", "source_manifest.csv")

required_files <- c(long_path, country_path, manifest_path)
missing_files <- required_files[!file.exists(required_files)]
if (length(missing_files)) {
  stop(
    "Missing required humanitarian-intensity output(s):\n",
    paste0("- ", missing_files, collapse = "\n"),
    call. = FALSE
  )
}

humanitarian_indices_long <- as.data.frame(readRDS(long_path))
humanitarian_indices_country <- as.data.frame(readRDS(country_path))
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
if (nrow(humanitarian_indices_country) != 195L ||
    anyDuplicated(humanitarian_indices_country$iso3)) {
  stop("The country dataset does not contain 195 unique ISO3 rows.", call. = FALSE)
}
if (nrow(humanitarian_indices_long) != 195L * length(index_ids) ||
    anyDuplicated(humanitarian_indices_long[c("iso3", "index_id")])) {
  stop("The long dataset is not a complete country-index grid.", call. = FALSE)
}

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
  humanitarian_indices_country,
  file = file.path("data", "humanitarian_indices_country.rda"),
  version = 3,
  compress = "xz"
)
save(
  humanitarian_indices_long,
  file = file.path("data", "humanitarian_indices_long.rda"),
  version = 3,
  compress = "xz"
)
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

# globalvuln

`globalvuln` is an R data package containing country-level data from
published global vulnerability, fragility, development, hunger, health,
gender, debt, safeguarding, and displacement indices.

Publisher scores remain on their original scales. The package
standardises only rank and decile direction, so rank 1 and decile 1
always mean **most vulnerable** within the countries scored by that
index.

> **Interactive explorer:** [Compare the structure, coverage, concepts,
> and sources of all 16
> indices](https://matthewgthomas.co.uk/globalvuln/indices-explorer.html).

## Installation

Install the development version from GitHub:

``` r

# install.packages("pak")
pak::pak("matthewgthomas/globalvuln")
```

## Data

The main analysis-ready dataset is `humanitarian_indices_country`: one
row for each of 195 United Nations member or observer states, with
score, vulnerability rank, and vulnerability decile columns for all 16
indices.

``` r

library(globalvuln)

humanitarian_indices_country[
  humanitarian_indices_country$iso3 == "AFG",
  c("country", "inform_risk_score", "inform_risk_rank", "top_10_count")
]
```

`humanitarian_indices_long` contains the same collection as a complete
country-index audit table. Individual index datasets share that table’s
schema and use the source identifiers as their object names:

``` r

data(inform_risk)

head(inform_risk[!is.na(inform_risk$score),
                 c("country", "score", "rank", "decile")])

data(package = "globalvuln")
```

The individual objects are `inform_risk`, `inform_severity`,
`underfunded_crisis`, `oecd_fragility`, `worldrisk`, `nd_gain`, `hdi`,
`mpi`, `ghi`, `ghs`, `wps`, `un_mvi`, `debt_distress`, `searo`,
`disaster_displacement`, and `internal_displacement`.

### Index catalogue

| Dataset | Index and official documentation | What it measures |
|----|----|----|
| `inform_risk` | [INFORM Risk](https://drmkc.jrc.ec.europa.eu/inform-index/INFORM-Risk/Methodology) | Risk of humanitarian crises and disasters, combining hazard and exposure, vulnerability, and lack of coping capacity. |
| `inform_severity` | [INFORM Severity](https://drmkc.jrc.ec.europa.eu/inform-index/INFORM-Severity/Methodology) | Current humanitarian-crisis severity on a common scale, combining crisis impact, conditions of affected people, and crisis complexity. |
| `underfunded_crisis` | [Underfunded Crisis Index](https://humanitarianfundingforecast.org/index-underfunded-crisis/) | Persistent underfunding of recurring humanitarian appeals, expressed as the cumulative share of funding requirements met over the preceding five years. |
| `oecd_fragility` | [OECD Multidimensional Fragility](https://www.oecd.org/en/publications/states-of-fragility-2025_81982370-en.html) | Exposure to risk and insufficient resilience across economic, environmental, human, political, security, and societal dimensions. |
| `worldrisk` | [WorldRiskIndex](https://weltrisikobericht.de/worldriskreport/) | Disaster risk from extreme natural events and climate impacts, combining population exposure with societal vulnerability, coping, and adaptive capacities. |
| `nd_gain` | [ND-GAIN Country Index](https://gain.nd.edu/our-work/country-index/methodology/) | A country’s vulnerability to climate change and its readiness to convert public and private investment into adaptation action. |
| `hdi` | [Human Development Index](https://hdr.undp.org/data-center/human-development-index) | Average achievement in health, education, and standard of living. |
| `mpi` | [Global Multidimensional Poverty Index](https://hdr.undp.org/content/2025-global-multidimensional-poverty-index-mpi) | The incidence and intensity of overlapping household deprivations in health, education, and living standards. |
| `ghi` | [Global Hunger Index](https://www.globalhungerindex.org/methodology.html) | Hunger using undernourishment, child stunting, child wasting, and child mortality. |
| `ghs` | [Global Health Security Index](https://ghsindex.org/about/) | National capacity to prevent, detect, and respond to epidemics and pandemics, alongside health-system, international-norm, and risk-environment factors. |
| `wps` | [Women, Peace and Security Index](https://giwps.georgetown.edu/wps-index-methodology/) | Women’s wellbeing and status across inclusion, justice, and security. |
| `un_mvi` | [UN Multidimensional Vulnerability Index](https://www.un.org/ohrlls/mvi/documents) | Structural vulnerability and lack of structural resilience to external shocks, especially among developing countries. |
| `debt_distress` | [IMF–World Bank Debt Sustainability Framework](https://www.imf.org/external/pubs/ft/dsa/lic.htm) | Low-income countries’ risk of debt distress, classified as low, moderate, high, or in debt distress using baseline projections, thresholds, and stress tests. |
| `searo` | [Sexual Exploitation and Abuse Risk Overview](https://psea.interagencystandingcommittee.org/sites/default/files/2025-02/SEARO%202025%20Methodology%20%26%20Concept.pdf) | Contextual risk of sexual exploitation and abuse in humanitarian operations across enabling, situational, operational, and protective environments. |
| `disaster_displacement` | [IDMC Global Displacement Risk Model](https://www.internal-displacement.org/displacement-risk/) | Modelled risk of future disaster displacement, including expected annual displacement under current-climate hazard scenarios. |
| `internal_displacement` | [IDMC Internal Displacement Index](https://www.internal-displacement.org/25-years-of-progress-on-internal-displacement-1998-2023/) | National policies and capacity, contextual drivers, and current impacts associated with internal displacement. |

Use `humanitarian_index_sources` for publisher URLs, editions, reference
years, retrieval dates, source-file checksums, coverage, and licensing
notes.

## Interpretation

- Rankings and deciles are calculated within each index’s published
  exact numeric coverage, not across all 195 countries.
- Ties use minimum rank. Deciles are
  `min(10, floor(10 * (rank - 1) / n_scored) + 1)`, so tied groups can
  make a decile contain more than exactly 10% of scored countries.
- `top_10_count` counts decile 1 appearances; `top_20_count` counts
  decile 1 or 2 appearances; and `indices_ranked_count` is the available
  denominator for each country.
- Debt distress is a published classification with a derived ordinal
  value. It is not ranked or included in summary counts.
- Global Hunger Index censored values and ranges are retained as score
  labels and are not assigned invented numeric scores.
- Disaster Displacement Risk Model fields are present but missing
  because no stable downloadable country table was available at the 4
  August 2026 data snapshot.
- No scores are imputed and no cross-index meta-score is produced.

## Sources and reuse

The package distributes harmonised country-level data and provenance
metadata, not the publishers’ raw files. Source data remain the property
of their publishers and are subject to their applicable terms. Cite the
relevant publisher or index edition when using an individual series;
details are in `humanitarian_index_sources`.

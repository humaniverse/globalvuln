# Retrieve bundled or latest approved globalvuln data

`globalvuln_data()` makes data freshness explicit. Package data are the
immutable snapshot installed with `globalvuln`; latest data are read
from the approved, versioned static board published with the package
website.

## Usage

``` r
globalvuln_data(
  source = c("latest", "package"),
  version = NULL,
  indices = NULL,
  format = c("long", "wide")
)
```

## Arguments

- source:

  Data source. `"latest"` reads the approved online board and
  `"package"` reads the installed package snapshot offline.

- version:

  Optional version of the `humanitarian_indices` pin. Versions are only
  supported for `source = "latest"`.

- indices:

  Optional character vector of index identifiers. The default selects
  all supported indices.

- format:

  Output layout: `"long"` (the default) or `"wide"`.

## Value

A data frame with provenance in the `globalvuln_source`,
`globalvuln_version`, and `globalvuln_manifest` attributes.

## See also

[`collate_indices()`](https://humaniverse.github.io/globalvuln/reference/collate_indices.md),
[`source_status()`](https://humaniverse.github.io/globalvuln/reference/source_status.md)

## Examples

``` r
package_data <- globalvuln_data(
  source = "package",
  indices = c("inform_risk", "hdi")
)
```

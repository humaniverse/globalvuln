# globalvuln: Global Humanitarian Vulnerability Indices

Country-level data from 16 published global vulnerability, fragility,
development, hunger, health, gender, debt, safeguarding, and
displacement indices.

## Details

The package provides three complementary interfaces:

- [`collate_indices()`](https://humaniverse.github.io/globalvuln/reference/collate_indices.md)
  combines a user-selected set of indices in wide or long form.

- The 16 datasets documented in
  [individual_indices](https://humaniverse.github.io/globalvuln/reference/individual_indices.md)
  expose one index at a time on the same 195-country geography.

- [humanitarian_index_sources](https://humaniverse.github.io/globalvuln/reference/humanitarian_index_sources.md)
  records source and provenance metadata.

Publisher scores retain their original scales. Computed ranks and
deciles have a common direction: rank 1 and decile 1 always identify the
most vulnerable observations within an index's published numeric
coverage. Top-10 and top-20 summaries use ranks, not deciles.

## See also

Useful links:

- <https://humaniverse.github.io/globalvuln/>

## Author

**Maintainer**: Matthew Gwynfryn Thomas <matthewgthomas@gmail.com>

Authors:

- Matthew Gwynfryn Thomas <matthewgthomas@gmail.com>

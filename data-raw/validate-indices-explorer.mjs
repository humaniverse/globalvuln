#!/usr/bin/env node

import { readFile } from "node:fs/promises";
import path from "node:path";
import process from "node:process";
import { fileURLToPath } from "node:url";

const CANONICAL_INDEX_IDS = [
  "inform_risk",
  "inform_severity",
  "underfunded_crisis",
  "oecd_fragility",
  "worldrisk",
  "nd_gain",
  "hdi",
  "mpi",
  "ghi",
  "ghs",
  "wps",
  "un_mvi",
  "debt_distress",
  "searo",
  "disaster_displacement",
  "internal_displacement",
];

const ALLOWED_SOURCE_TYPES = new Set(["provider", "dataset", "series"]);
const ALLOWED_RELATION_TYPES = new Set([
  "direct_input",
  "nested_composite",
  "shared_series",
  "shared_provider",
  "conceptual_overlap",
  "legacy_replacement",
]);
const ALLOWED_NETWORK_INPUT_KINDS = new Set(["indicator", "series"]);
const ALLOWED_NETWORK_DEPENDENCY_TYPES = new Set(["direct_input", "nested_composite"]);
const ALLOWED_COVERAGE_STATUSES = new Set([
  "ranked_numeric",
  "numeric_unranked",
  "label_only",
  "no_record",
]);
const ALLOWED_SCORE_DIRECTIONS = new Set(["higher_worse", "lower_worse"]);
const COVERED_STATUSES = new Set([
  "ranked_numeric",
  "numeric_unranked",
  "label_only",
]);

const KEY_COVERAGE_EDGES = [
  ["worldrisk", "ghs", 193],
  ["hdi", "worldrisk", 191],
  ["ghs", "hdi", 191],
  ["nd_gain", "worldrisk", 190],
  ["debt_distress", "underfunded_crisis", 18],
];

const EXPECTED_EDITION_COUNTS = new Map([
  ["inform_risk", { analyticalLeafCount: 90, rawInputCount: 80 }],
  ["inform_severity", { analyticalLeafCount: 42, rawInputCount: 31 }],
  ["underfunded_crisis", { analyticalLeafCount: 1, rawInputCount: null }],
  ["oecd_fragility", { analyticalLeafCount: 56, rawInputCount: 56 }],
  ["worldrisk", { analyticalLeafCount: 100, rawInputCount: 100 }],
  ["nd_gain", { analyticalLeafCount: 45, rawInputCount: 74 }],
  ["hdi", { analyticalLeafCount: 4, rawInputCount: 4 }],
  ["mpi", { analyticalLeafCount: 10, rawInputCount: 10 }],
  ["ghi", { analyticalLeafCount: 4, rawInputCount: 4 }],
  ["ghs", { analyticalLeafCount: 171, rawInputCount: 171 }],
  ["wps", { analyticalLeafCount: 13, rawInputCount: 13 }],
  ["un_mvi", { analyticalLeafCount: 26, rawInputCount: 26 }],
  ["debt_distress", { analyticalLeafCount: null, rawInputCount: null }],
  ["searo", { analyticalLeafCount: 30, rawInputCount: 30 }],
  ["disaster_displacement", { analyticalLeafCount: null, rawInputCount: null }],
  ["internal_displacement", { analyticalLeafCount: 18, rawInputCount: 43 }],
]);

const EXPECTED_CONCEPTS = new Map([
  ["hazards_exposure", "Hazards / exposure"],
  ["climate_environment", "Climate / environment"],
  ["conflict_security", "Conflict / security"],
  ["humanitarian_need", "Humanitarian need / access / funding"],
  ["displacement", "Displacement"],
  ["poverty_livelihoods", "Poverty / inequality / livelihoods"],
  ["economy_debt_finance", "Economy / debt / external finance"],
  ["food_nutrition", "Food / nutrition"],
  ["health_disease", "Health / disease"],
  ["education_development", "Education / human development"],
  ["gender_inclusion_safeguarding", "Gender / inclusion / safeguarding"],
  ["governance_rights", "Governance / institutions / rights"],
  ["infrastructure_services", "Infrastructure / services"],
  ["demography_social_cohesion", "Demography / social cohesion"],
  ["coping_preparedness_adaptation", "Coping / preparedness / adaptation"],
]);

const MINIMUM_NORMALIZED_SOURCE_USAGE = new Map([
  ["provider_transparency_international", 3],
  ["dataset_v_dem", 2],
  ["provider_idmc", 3],
  ["dataset_ocha_fts", 3],
  ["dataset_worldwide_governance_indicators", 3],
  ["dataset_undp_human_development_report", 3],
]);

const scriptPath = fileURLToPath(import.meta.url);
const repositoryRoot = path.resolve(path.dirname(scriptPath), "..");
const explorerPath = path.resolve(
  repositoryRoot,
  process.argv[2] ?? "pkgdown/assets/indices-explorer.html",
);

const issues = [];

function check(condition, message) {
  if (!condition) issues.push(message);
}

function requireArray(value, name) {
  check(Array.isArray(value), `${name} must be an array`);
  return Array.isArray(value) ? value : [];
}

function requireObject(value, name) {
  const valid = value !== null && typeof value === "object" && !Array.isArray(value);
  check(valid, `${name} must be an object`);
  return valid ? value : {};
}

function requireString(value, name) {
  const valid = typeof value === "string" && value.trim() !== "";
  check(valid, `${name} must be a non-empty string`);
  return valid ? value : "";
}

function checkOptionalHttpUrl(value, name) {
  if (value === null || value === undefined) return null;

  const url = requireString(value, name);
  if (!url) return "";

  let parsed;
  try {
    parsed = new URL(url);
  } catch {
    check(false, `${name} is not a valid URL`);
    return url;
  }
  check(
    parsed.protocol === "https:" || parsed.protocol === "http:",
    `${name} must use HTTP or HTTPS`,
  );
  return url;
}

function collectIds(items, name) {
  const seen = new Set();

  items.forEach((item, index) => {
    const id = requireString(item?.id, `${name}[${index}].id`);
    if (!id) return;
    check(!seen.has(id), `${name} contains duplicate id ${JSON.stringify(id)}`);
    seen.add(id);
  });

  return seen;
}

function checkCanonicalIndexIds(indices) {
  const actual = indices.map((index) => index?.id).filter(Boolean);
  const expected = new Set(CANONICAL_INDEX_IDS);
  const actualSet = new Set(actual);

  check(indices.length === CANONICAL_INDEX_IDS.length, "indices must contain exactly 16 records");
  for (const id of CANONICAL_INDEX_IDS) {
    check(actualSet.has(id), `indices is missing canonical id ${JSON.stringify(id)}`);
  }
  for (const id of actualSet) {
    check(expected.has(id), `indices contains non-canonical id ${JSON.stringify(id)}`);
  }
}

function checkReferenceList(values, validIds, fieldName) {
  const references = requireArray(values, fieldName);
  const seen = new Set();

  references.forEach((reference, index) => {
    const id = requireString(reference, `${fieldName}[${index}]`);
    if (!id) return;
    check(!seen.has(id), `${fieldName} contains duplicate reference ${JSON.stringify(id)}`);
    check(validIds.has(id), `${fieldName} references unknown id ${JSON.stringify(id)}`);
    seen.add(id);
  });

  return references;
}

function checkEvidence(evidence, fieldName) {
  const records = requireArray(evidence, fieldName);
  check(records.length > 0, `${fieldName} must contain at least one citation`);

  records.forEach((record, index) => {
    const item = requireObject(record, `${fieldName}[${index}]`);
    requireString(item.label, `${fieldName}[${index}].label`);
    const url = requireString(item.url, `${fieldName}[${index}].url`);
    if (url) checkOptionalHttpUrl(url, `${fieldName}[${index}].url`);
  });
}

function intersectionSize(left, right) {
  let count = 0;
  for (const value of left) {
    if (right.has(value)) count += 1;
  }
  return count;
}

let html;
try {
  html = await readFile(explorerPath, "utf8");
} catch (error) {
  console.error(`Unable to read explorer HTML at ${explorerPath}: ${error.message}`);
  process.exit(1);
}

check(!/<script\b[^>]*\bsrc\s*=/i.test(html), "explorer must not load external scripts");
check(
  !/<link\b(?=[^>]*\brel\s*=\s*["']stylesheet["'])[^>]*>/i.test(html),
  "explorer must not load external stylesheets",
);
check(!/\bfetch\s*\(/.test(html), "explorer must not make runtime fetch requests");
check(!/\bXMLHttpRequest\b/.test(html), "explorer must not use XMLHttpRequest");
check(!/\bWebSocket\s*\(/.test(html), "explorer must not open WebSockets");
check(!/\bdocument\.cookie\b/.test(html), "explorer must not access cookies");

const noscript = html.match(/<noscript\b[^>]*>([\s\S]*?)<\/noscript\s*>/i);
check(Boolean(noscript), "explorer must include a no-JavaScript catalogue");
if (noscript) {
  const catalogueItems = noscript[1].match(/<li\b/g) ?? [];
  check(catalogueItems.length === 16, `no-JavaScript catalogue must list 16 indices; found ${catalogueItems.length}`);
}

const blankTargetLinks = html.match(/<a\b(?=[^>]*\btarget\s*=\s*["']_blank["'])[^>]*>/gi) ?? [];
for (const link of blankTargetLinks) {
  check(
    /\brel\s*=\s*["'][^"']*\bnoopener\b[^"']*\bnoreferrer\b[^"']*["']/i.test(link),
    `external-link safety attributes are missing on ${link.slice(0, 120)}`,
  );
}

const dataScript = html.match(
  /<script\b(?=[^>]*\bid\s*=\s*["']explorer-data["'])(?=[^>]*\btype\s*=\s*["']application\/json["'])[^>]*>([\s\S]*?)<\/script\s*>/i,
);

if (!dataScript) {
  console.error(
    `No <script id="explorer-data" type="application/json"> block found in ${explorerPath}`,
  );
  process.exit(1);
}

let data;
try {
  data = JSON.parse(dataScript[1]);
} catch (error) {
  console.error(`Explorer data is not valid JSON: ${error.message}`);
  process.exit(1);
}

const networkDataScript = html.match(
  /<script\b(?=[^>]*\bid\s*=\s*["']network-data["'])(?=[^>]*\btype\s*=\s*["']application\/json["'])[^>]*>([\s\S]*?)<\/script\s*>/i,
);

if (!networkDataScript) {
  console.error(
    `No <script id="network-data" type="application/json"> block found in ${explorerPath}`,
  );
  process.exit(1);
}

let networkData;
try {
  networkData = JSON.parse(networkDataScript[1]);
} catch (error) {
  console.error(`Network data is not valid JSON: ${error.message}`);
  process.exit(1);
}

requireObject(data, "explorer-data");
const version = requireString(data.version, "version");
const snapshotDate = requireString(data.snapshotDate, "snapshotDate");
check(version !== "pending", "version must not be the pending placeholder");
check(/^\d{4}-\d{2}-\d{2}$/.test(snapshotDate), "snapshotDate must use YYYY-MM-DD format");

const concepts = requireArray(data.concepts, "concepts");
const indices = requireArray(data.indices, "indices");
const providers = requireArray(data.providers, "providers");
const sources = requireArray(data.sources, "sources");
const nodes = requireArray(data.nodes, "nodes");
const relations = requireArray(data.relations, "relations");
const countries = requireArray(data.countries, "countries");
const coverage = requireArray(data.coverage, "coverage");
const map = requireObject(data.map, "map");
requireObject(networkData, "network-data");
const networkVersion = requireString(networkData?.version, "network-data.version");
const networkCuratedDate = requireString(networkData?.curatedDate, "network-data.curatedDate");
check(networkVersion !== "pending", "network-data.version must not be the pending placeholder");
check(/^\d{4}-\d{2}-\d{2}$/.test(networkCuratedDate), "network-data.curatedDate must use YYYY-MM-DD format");
const sharedInputs = requireArray(networkData?.sharedInputs, "network-data.sharedInputs");
const networkDependencies = requireArray(networkData?.dependencies, "network-data.dependencies");

const conceptIds = collectIds(concepts, "concepts");
const indexIds = collectIds(indices, "indices");
const providerIds = collectIds(providers, "providers");
const sourceIds = collectIds(sources, "sources");
const nodeIds = collectIds(nodes, "nodes");
const nodesById = new Map(nodes.map((node) => [node.id, node]));
const indicesById = new Map(indices.map((index) => [index.id, index]));
const relationsById = new Map(relations.map((relation) => [relation.id, relation]));
checkCanonicalIndexIds(indices);

check(providers.length > 0, "providers must contain normalized provider records");
const providerLabels = new Set();
providers.forEach((provider, index) => {
  const fieldName = `providers[${index}]`;
  const label = requireString(provider?.label, `${fieldName}.label`);
  const labelKey = label.toLocaleLowerCase();
  check(!providerLabels.has(labelKey), `${fieldName}.label duplicates ${JSON.stringify(label)}`);
  providerLabels.add(labelKey);
  requireString(provider?.url, `${fieldName}.url`);
  checkOptionalHttpUrl(provider?.url, `${fieldName}.url`);
});

check(concepts.length === EXPECTED_CONCEPTS.size, "concepts must contain the fixed 15-item vocabulary");
for (const [id, label] of EXPECTED_CONCEPTS) {
  const concept = concepts.find((item) => item?.id === id);
  check(Boolean(concept), `concepts is missing fixed vocabulary id ${JSON.stringify(id)}`);
  if (!concept) continue;
  check(concept.label === label, `${id}.label must be ${JSON.stringify(label)}`);
  requireString(concept.shortLabel, `${id}.shortLabel`);
  requireString(concept.description, `${id}.description`);
}

indices.forEach((index, position) => {
  const fieldName = `indices[${position}]`;
  requireString(index?.name, `${fieldName}.name`);
  requireString(index?.shortName, `${fieldName}.shortName`);
  requireString(index?.publisher, `${fieldName}.publisher`);
  requireString(index?.edition, `${fieldName}.edition`);
  requireString(index?.referenceYear, `${fieldName}.referenceYear`);
  requireString(index?.purpose, `${fieldName}.purpose`);
  requireString(index?.measurementType, `${fieldName}.measurementType`);
  requireString(index?.scoreDirectionLabel, `${fieldName}.scoreDirectionLabel`);
  requireString(index?.countScope, `${fieldName}.countScope`);
  requireString(index?.sourceStatus, `${fieldName}.sourceStatus`);
  requireString(index?.licenseNotes, `${fieldName}.licenseNotes`);
  check(
    ALLOWED_SCORE_DIRECTIONS.has(index?.scoreDirection),
    `${fieldName}.scoreDirection must be one of ${[...ALLOWED_SCORE_DIRECTIONS].join(", ")}`,
  );
  check(typeof index?.rankable === "boolean", `${fieldName}.rankable must be a boolean`);
  check(
    typeof index?.eligibleForCounts === "boolean",
    `${fieldName}.eligibleForCounts must be a boolean`,
  );
  checkReferenceList(index?.conceptIds, conceptIds, `${fieldName}.conceptIds`);
  checkReferenceList(index?.sourceIds, sourceIds, `${fieldName}.sourceIds`);
  const links = requireObject(index?.links, `${fieldName}.links`);
  requireString(links.methodology, `${fieldName}.links.methodology`);
  requireString(links.landing, `${fieldName}.links.landing`);
  checkOptionalHttpUrl(links.methodology, `${fieldName}.links.methodology`);
  checkOptionalHttpUrl(links.landing, `${fieldName}.links.landing`);
  checkOptionalHttpUrl(links.download, `${fieldName}.links.download`);
  const caveats = requireArray(index?.caveats, `${fieldName}.caveats`);
  check(caveats.length > 0, `${fieldName}.caveats must contain at least one limitation`);
  caveats.forEach((caveat, index) => requireString(caveat, `${fieldName}.caveats[${index}]`));
});

for (const [indexId, expected] of EXPECTED_EDITION_COUNTS) {
  const index = indicesById.get(indexId) ?? {};
  for (const [field, expectedValue] of Object.entries(expected)) {
    check(
      Object.is(index[field], expectedValue),
      `${indexId}.${field} must be ${JSON.stringify(expectedValue)}; found ${JSON.stringify(index[field])}`,
    );
  }
}

check(
  indicesById.get("mpi")?.referenceYear === "country-specific survey year",
  "mpi.referenceYear must explicitly retain the country-specific survey year",
);
check(
  indicesById.get("debt_distress")?.referenceYear === "latest DSA as of 2026-03-31",
  "debt_distress.referenceYear must retain the latest-DSA snapshot as of 2026-03-31",
);

const normalizedSources = new Map();
const normalizedSourceLabels = new Map();
sources.forEach((source, index) => {
  const fieldName = `sources[${index}]`;
  requireString(source?.label, `${fieldName}.label`);
  checkOptionalHttpUrl(source?.url, `${fieldName}.url`);
  check(
    ALLOWED_SOURCE_TYPES.has(source?.type),
    `${fieldName}.type must be one of ${[...ALLOWED_SOURCE_TYPES].join(", ")}`,
  );

  const normalizedId = requireString(source?.normalizedId, `${fieldName}.normalizedId`);
  const normalizedLabel = requireString(
    source?.normalizedLabel,
    `${fieldName}.normalizedLabel`,
  );
  const normalizedType = requireString(source?.normalizedType, `${fieldName}.normalizedType`);
  check(
    ALLOWED_SOURCE_TYPES.has(normalizedType),
    `${fieldName}.normalizedType must be one of ${[...ALLOWED_SOURCE_TYPES].join(", ")}`,
  );
  const normalizedUrl = checkOptionalHttpUrl(
    source?.normalizedUrl,
    `${fieldName}.normalizedUrl`,
  );
  const sourceProviders = checkReferenceList(
    source?.providerIds,
    providerIds,
    `${fieldName}.providerIds`,
  );
  check(sourceProviders.length > 0, `${fieldName}.providerIds must identify at least one provider`);

  if (!normalizedId) return;
  const normalizedLabelKey = normalizedLabel.toLocaleLowerCase();
  const existingLabelId = normalizedSourceLabels.get(normalizedLabelKey);
  check(
    !existingLabelId || existingLabelId === normalizedId,
    `${fieldName}.normalizedLabel duplicates the label for ${JSON.stringify(existingLabelId)}`,
  );
  normalizedSourceLabels.set(normalizedLabelKey, normalizedId);
  const normalizedRecord = {
    label: normalizedLabel,
    type: normalizedType,
    url: normalizedUrl,
  };
  const previous = normalizedSources.get(normalizedId);
  if (previous) {
    check(
      previous.label === normalizedRecord.label &&
        previous.type === normalizedRecord.type &&
        previous.url === normalizedRecord.url,
      `${fieldName} conflicts with the normalized label/type/URL for ${JSON.stringify(normalizedId)}`,
    );
  } else {
    normalizedSources.set(normalizedId, normalizedRecord);
  }
});

const undpoProviders = sources.find((source) => source.id === "source_undpo")?.providerIds ?? [];
check(
  undpoProviders.length === 1 && undpoProviders[0] === "provider_un_dpo",
  "source_undpo must map only to provider_un_dpo (not UNDP)",
);

const childCounts = new Map(nodes.map((node) => [node.id, 0]));

nodes.forEach((node, index) => {
  const fieldName = `nodes[${index}]`;
  check(indexIds.has(node?.indexId), `${fieldName}.indexId references an unknown index`);
  requireString(node?.kind, `${fieldName}.kind`);
  requireString(node?.officialLabel, `${fieldName}.officialLabel`);
  requireString(node?.displayLabel, `${fieldName}.displayLabel`);
  check(typeof node?.isLeaf === "boolean", `${fieldName}.isLeaf must be a boolean`);
  if (node?.weight !== null && node?.weight !== undefined) {
    check(Number.isFinite(node.weight) && node.weight >= 0, `${fieldName}.weight must be a non-negative number`);
  }
  if (node?.normalizationNote !== null && node?.normalizationNote !== undefined) {
    requireString(node.normalizationNote, `${fieldName}.normalizationNote`);
  }

  const parents = checkReferenceList(node?.parentIds, nodeIds, `${fieldName}.parentIds`);
  const nodeSources = checkReferenceList(node?.sourceIds, sourceIds, `${fieldName}.sourceIds`);
  const nodeConcepts = checkReferenceList(node?.conceptIds, conceptIds, `${fieldName}.conceptIds`);

  for (const parentId of parents) {
    check(parentId !== node.id, `${fieldName}.parentIds must not contain its own id`);
    const parent = nodesById.get(parentId);
    if (parent) {
      check(
        parent.indexId === node.indexId,
        `${fieldName}.parentIds contains a node from a different index`,
      );
      childCounts.set(parentId, (childCounts.get(parentId) ?? 0) + 1);
    }
  }

  if (node?.isLeaf === true) {
    check(nodeSources.length > 0, `${fieldName}.sourceIds must identify leaf lineage`);
    check(nodeConcepts.length > 0, `${fieldName}.conceptIds must map the leaf vocabulary`);
    requireString(node?.description, `${fieldName}.description`);
    checkEvidence(node?.evidence, `${fieldName}.evidence`);
  }
});

nodes.forEach((node, index) => {
  const actualLeaf = (childCounts.get(node.id) ?? 0) === 0;
  check(
    node.isLeaf === actualLeaf,
    `nodes[${index}].isLeaf disagrees with its parent/child references`,
  );
});

check(
  nodes.some((node) => (node.parentIds ?? []).length > 1),
  "methodology graph must include at least one multiple-parent node for a published lattice",
);

for (const indexId of indexIds) {
  const indexNodes = nodes.filter((node) => node.indexId === indexId);
  const roots = indexNodes.filter((node) => (node.parentIds ?? []).length === 0);
  check(roots.length === 1, `${indexId} must have exactly one methodology root; found ${roots.length}`);
}

const visitedNodes = new Set();
const visitingNodes = new Set();
function visitParents(nodeId) {
  if (visitedNodes.has(nodeId)) return;
  if (visitingNodes.has(nodeId)) {
    check(false, `methodology parent graph contains a cycle at ${JSON.stringify(nodeId)}`);
    return;
  }
  visitingNodes.add(nodeId);
  const node = nodesById.get(nodeId);
  for (const parentId of node?.parentIds ?? []) visitParents(parentId);
  visitingNodes.delete(nodeId);
  visitedNodes.add(nodeId);
}
for (const node of nodes) visitParents(node.id);

const normalizedSourceUsage = new Map(
  [...normalizedSources].map(([id]) => [id, new Set()]),
);
const normalizedIdBySourceId = new Map(
  sources.map((source) => [source.id, source.normalizedId]),
);
const sourceProviderIds = new Map(
  sources.map((source) => [source.id, source.providerIds ?? []]),
);
const sourceUsage = new Map(sources.map((source) => [source.id, new Set()]));
const providerUsage = new Map(providers.map((provider) => [provider.id, new Set()]));
function recordSourceUsage(sourceId, indexId) {
  normalizedSourceUsage.get(normalizedIdBySourceId.get(sourceId))?.add(indexId);
  sourceUsage.get(sourceId)?.add(indexId);
  for (const providerId of sourceProviderIds.get(sourceId) ?? []) {
    providerUsage.get(providerId)?.add(indexId);
  }
}
for (const index of indices) {
  for (const sourceId of index.sourceIds ?? []) {
    recordSourceUsage(sourceId, index.id);
  }
}
for (const node of nodes) {
  for (const sourceId of node.sourceIds ?? []) {
    recordSourceUsage(sourceId, node.indexId);
  }
}
for (const [sourceId, usage] of sourceUsage) {
  check(usage.size > 0, `${sourceId} is not used by any index or methodology node`);
}
for (const [providerId, usage] of providerUsage) {
  check(usage.size > 0, `${providerId} is not connected to any used source record`);
}
for (const [sourceId, expectedMinimum] of MINIMUM_NORMALIZED_SOURCE_USAGE) {
  const actual = normalizedSourceUsage.get(sourceId)?.size ?? 0;
  check(
    actual >= expectedMinimum,
    `${sourceId} must be reconciled across at least ${expectedMinimum} indices; found ${actual}`,
  );
}

const relationIds = new Set();
relations.forEach((relation, index) => {
  const id = requireString(relation.id, `relations[${index}].id`);
  if (!id) return;
  check(!relationIds.has(id), `relations contains duplicate id ${JSON.stringify(id)}`);
  relationIds.add(id);
});

const relationTypesPresent = new Set();
relations.forEach((relation, index) => {
  const fieldName = `relations[${index}]`;
  check(
    ALLOWED_RELATION_TYPES.has(relation?.type),
    `${fieldName}.type must be one of ${[...ALLOWED_RELATION_TYPES].join(", ")}`,
  );
  const fromIndexId = requireString(relation?.fromIndexId, `${fieldName}.fromIndexId`);
  const toIndexId = requireString(relation?.toIndexId, `${fieldName}.toIndexId`);
  check(indexIds.has(fromIndexId), `${fieldName}.fromIndexId references an unknown index`);
  check(indexIds.has(toIndexId), `${fieldName}.toIndexId references an unknown index`);
  check(
    fromIndexId !== toIndexId || relation?.type === "legacy_replacement",
    `${fieldName} may connect an index to itself only for a legacy replacement`,
  );
  requireString(relation?.label, `${fieldName}.label`);
  requireString(relation?.evidenceUrl, `${fieldName}.evidenceUrl`);
  checkOptionalHttpUrl(relation?.evidenceUrl, `${fieldName}.evidenceUrl`);
  if (relation?.editionNote !== null && relation?.editionNote !== undefined) {
    requireString(relation.editionNote, `${fieldName}.editionNote`);
  }
  if (ALLOWED_RELATION_TYPES.has(relation?.type)) relationTypesPresent.add(relation.type);
});

for (const type of ALLOWED_RELATION_TYPES) {
  check(relationTypesPresent.has(type), `relations must exercise typed relationship ${JSON.stringify(type)}`);
}

const normalizedDatasetIds = new Set(
  [...normalizedSources]
    .filter(([, source]) => source.type === "dataset" || source.type === "series")
    .map(([id]) => id),
);
const sharedInputIds = collectIds(sharedInputs, "network-data.sharedInputs");
sharedInputs.forEach((input, inputIndex) => {
  const fieldName = `network-data.sharedInputs[${inputIndex}]`;
  requireString(input?.label, `${fieldName}.label`);
  check(
    ALLOWED_NETWORK_INPUT_KINDS.has(input?.kind),
    `${fieldName}.kind must be one of ${[...ALLOWED_NETWORK_INPUT_KINDS].join(", ")}`,
  );
  const members = requireArray(input?.members, `${fieldName}.members`);
  check(members.length >= 2, `${fieldName}.members must connect at least two indices`);
  const memberIndexIds = new Set();
  const memberNodeIds = new Set();
  members.forEach((member, memberIndex) => {
    const memberField = `${fieldName}.members[${memberIndex}]`;
    const indexId = requireString(member?.indexId, `${memberField}.indexId`);
    check(indexIds.has(indexId), `${memberField}.indexId references an unknown index`);
    check(!memberIndexIds.has(indexId), `${fieldName}.members duplicates index ${JSON.stringify(indexId)}`);
    memberIndexIds.add(indexId);
    const leafIds = checkReferenceList(member?.nodeIds, nodeIds, `${memberField}.nodeIds`);
    check(leafIds.length > 0, `${memberField}.nodeIds must identify at least one analytical leaf`);
    leafIds.forEach((nodeId) => {
      const node = nodesById.get(nodeId);
      check(node?.indexId === indexId, `${memberField}.nodeIds contains a node from another index`);
      check(node?.isLeaf === true, `${memberField}.nodeIds must reference analytical leaves`);
      check(!memberNodeIds.has(nodeId), `${fieldName}.members reuses node ${JSON.stringify(nodeId)}`);
      memberNodeIds.add(nodeId);
    });
  });
  const normalizedIds = requireArray(input?.normalizedSourceIds, `${fieldName}.normalizedSourceIds`);
  check(normalizedIds.length > 0, `${fieldName}.normalizedSourceIds must identify direct dataset or series provenance`);
  const seenNormalizedIds = new Set();
  normalizedIds.forEach((sourceId, sourceIndex) => {
    const sourceField = `${fieldName}.normalizedSourceIds[${sourceIndex}]`;
    const id = requireString(sourceId, sourceField);
    check(normalizedDatasetIds.has(id), `${sourceField} must reference a normalized dataset or series`);
    check(!seenNormalizedIds.has(id), `${fieldName}.normalizedSourceIds duplicates ${JSON.stringify(id)}`);
    seenNormalizedIds.add(id);
  });
  checkEvidence(input?.evidence, `${fieldName}.evidence`);
  requireString(input?.editionNote, `${fieldName}.editionNote`);
});

check(sharedInputIds.has("input_wgi_rule_of_law"), "network must include the curated WGI rule-of-law input group");
const wgiRuleOfLawMembers = new Set(
  sharedInputs.find((input) => input.id === "input_wgi_rule_of_law")?.members?.map((member) => member.indexId) ?? [],
);
for (const indexId of ["inform_severity", "oecd_fragility", "worldrisk", "nd_gain"]) {
  check(wgiRuleOfLawMembers.has(indexId), `WGI rule-of-law input must include ${indexId}`);
}
check(
  !wgiRuleOfLawMembers.has("searo"),
  "WGI rule-of-law input must exclude SEARO's World Justice Project measure",
);

const networkDependencyIds = new Set();
networkDependencies.forEach((dependency, dependencyIndex) => {
  const fieldName = `network-data.dependencies[${dependencyIndex}]`;
  const relationId = requireString(dependency?.relationId, `${fieldName}.relationId`);
  check(!networkDependencyIds.has(relationId), `${fieldName}.relationId duplicates ${JSON.stringify(relationId)}`);
  networkDependencyIds.add(relationId);
  const relation = relationsById.get(relationId);
  check(Boolean(relation), `${fieldName}.relationId references an unknown relation`);
  check(
    ALLOWED_NETWORK_DEPENDENCY_TYPES.has(relation?.type),
    `${fieldName}.relationId must reference only direct_input or nested_composite relations`,
  );
  for (const [nodeField, expectedIndexId] of [
    ["fromNodeIds", relation?.fromIndexId],
    ["toNodeIds", relation?.toIndexId],
  ]) {
    const references = checkReferenceList(dependency?.[nodeField], nodeIds, `${fieldName}.${nodeField}`);
    if (nodeField === "toNodeIds") {
      check(references.length > 0, `${fieldName}.toNodeIds must identify the consuming analytical leaf`);
    }
    references.forEach((nodeId) => {
      const node = nodesById.get(nodeId);
      check(node?.indexId === expectedIndexId, `${fieldName}.${nodeField} contains a node from the wrong index`);
      check(node?.isLeaf === true, `${fieldName}.${nodeField} must reference analytical leaves`);
    });
  }
});

const directRelationIds = new Set(
  relations
    .filter((relation) => ALLOWED_NETWORK_DEPENDENCY_TYPES.has(relation.type))
    .map((relation) => relation.id),
);
for (const relationId of directRelationIds) {
  check(networkDependencyIds.has(relationId), `network dependencies is missing direct relation ${JSON.stringify(relationId)}`);
}
for (const relationId of networkDependencyIds) {
  check(directRelationIds.has(relationId), `network dependencies contains non-direct relation ${JSON.stringify(relationId)}`);
}
check(networkDependencyIds.has("rel_mpi_inform_risk"), "network must include Global MPI feeding INFORM Risk");

const networkDependencyPairs = new Set(
  networkDependencies.flatMap((dependency) => {
    const relation = relationsById.get(dependency.relationId);
    return relation ? [`${relation.fromIndexId}->${relation.toIndexId}`] : [];
  }),
);
for (const [leftIndexId, rightIndexId, label] of [
  ["inform_risk", "inform_severity", "INFORM Risk and INFORM Severity"],
  ["ghi", "mpi", "Global Hunger Index and Global MPI"],
  ["debt_distress", "oecd_fragility", "Debt distress and OECD Fragility"],
]) {
  check(
    !networkDependencyPairs.has(`${leftIndexId}->${rightIndexId}`)
      && !networkDependencyPairs.has(`${rightIndexId}->${leftIndexId}`),
    `network must not infer a dependency between ${label}`,
  );
}

check(countries.length === 195, "countries must contain exactly 195 records");
const countryIds = new Set();
const countryNames = new Set();
countries.forEach((country, index) => {
  const iso3 = requireString(country?.iso3, `countries[${index}].iso3`);
  const countryName = requireString(country?.country, `countries[${index}].country`);
  requireString(country?.region, `countries[${index}].region`);
  requireString(country?.subregion, `countries[${index}].subregion`);
  if (!iso3) return;
  check(/^[A-Z]{3}$/.test(iso3), `countries[${index}].iso3 must be three uppercase letters`);
  check(!countryIds.has(iso3), `countries contains duplicate iso3 ${JSON.stringify(iso3)}`);
  check(!countryNames.has(countryName), `countries contains duplicate country ${JSON.stringify(countryName)}`);
  countryIds.add(iso3);
  countryNames.add(countryName);
});

requireString(map.viewBox, "map.viewBox");
const mapPaths = requireArray(map.paths, "map.paths");
const mapMarkers = requireArray(map.markers, "map.markers");
const mapCountryIds = new Set();

mapPaths.forEach((record, index) => {
  const fieldName = `map.paths[${index}]`;
  const iso3 = requireString(record?.iso3, `${fieldName}.iso3`);
  check(countryIds.has(iso3), `${fieldName}.iso3 references an unknown country`);
  check(!mapCountryIds.has(iso3), `${fieldName}.iso3 duplicates ${JSON.stringify(iso3)} geometry`);
  requireString(record?.d, `${fieldName}.d`);
  mapCountryIds.add(iso3);
});

mapMarkers.forEach((record, index) => {
  const fieldName = `map.markers[${index}]`;
  const iso3 = requireString(record?.iso3, `${fieldName}.iso3`);
  check(countryIds.has(iso3), `${fieldName}.iso3 references an unknown country`);
  check(!mapCountryIds.has(iso3), `${fieldName}.iso3 duplicates ${JSON.stringify(iso3)} geometry or marker`);
  check(Number.isFinite(record?.x), `${fieldName}.x must be numeric`);
  check(Number.isFinite(record?.y), `${fieldName}.y must be numeric`);
  mapCountryIds.add(iso3);
});

check(mapCountryIds.size === 195, `map must cover all 195 countries; found ${mapCountryIds.size}`);
for (const iso3 of countryIds) {
  check(mapCountryIds.has(iso3), `map is missing country ${JSON.stringify(iso3)}`);
}
const mapSource = requireObject(map.source, "map.source");
requireString(mapSource.label, "map.source.label");
checkOptionalHttpUrl(mapSource.url, "map.source.url");

check(coverage.length === 3120, "coverage must contain exactly 3,120 records");
const coverageKeys = new Set();
const coverageByIndex = new Map(CANONICAL_INDEX_IDS.map((id) => [id, new Set()]));
const coverageCountByIndex = new Map(CANONICAL_INDEX_IDS.map((id) => [id, 0]));
const coverageCountByCountry = new Map([...countryIds].map((id) => [id, 0]));
const coverageStatusCounts = new Map(
  CANONICAL_INDEX_IDS.map((id) => [
    id,
    new Map([...ALLOWED_COVERAGE_STATUSES].map((status) => [status, 0])),
  ]),
);

coverage.forEach((record, index) => {
  const fieldName = `coverage[${index}]`;
  const indexId = requireString(record?.indexId, `${fieldName}.indexId`);
  const iso3 = requireString(record?.iso3, `${fieldName}.iso3`);
  const status = requireString(record?.status, `${fieldName}.status`);

  check(indexIds.has(indexId), `${fieldName}.indexId references an unknown index`);
  check(countryIds.has(iso3), `${fieldName}.iso3 references an unknown country`);
  check(
    ALLOWED_COVERAGE_STATUSES.has(status),
    `${fieldName}.status must be one of ${[...ALLOWED_COVERAGE_STATUSES].join(", ")}`,
  );

  const key = `${indexId}\u0000${iso3}`;
  check(!coverageKeys.has(key), `${fieldName} duplicates the ${indexId}/${iso3} record`);
  coverageKeys.add(key);

  if (coverageCountByIndex.has(indexId)) {
    coverageCountByIndex.set(indexId, coverageCountByIndex.get(indexId) + 1);
  }
  if (coverageCountByCountry.has(iso3)) {
    coverageCountByCountry.set(iso3, coverageCountByCountry.get(iso3) + 1);
  }
  if (COVERED_STATUSES.has(status) && coverageByIndex.has(indexId)) {
    coverageByIndex.get(indexId).add(iso3);
  }
  if (coverageStatusCounts.has(indexId) && ALLOWED_COVERAGE_STATUSES.has(status)) {
    const counts = coverageStatusCounts.get(indexId);
    counts.set(status, counts.get(status) + 1);
  }
});

for (const [indexId, count] of coverageCountByIndex) {
  check(count === 195, `coverage must contain 195 records for ${indexId}; found ${count}`);
}
for (const [iso3, count] of coverageCountByCountry) {
  check(count === 16, `coverage must contain 16 records for ${iso3}; found ${count}`);
}

for (const [leftId, rightId, expected] of KEY_COVERAGE_EDGES) {
  const actual = intersectionSize(coverageByIndex.get(leftId), coverageByIndex.get(rightId));
  check(
    actual === expected,
    `coverage overlap ${leftId}/${rightId} must be ${expected}; found ${actual}`,
  );
}

function statusCount(indexId, status) {
  return coverageStatusCounts.get(indexId)?.get(status) ?? 0;
}

function publishedCount(indexId) {
  return [...COVERED_STATUSES].reduce(
    (total, status) => total + statusCount(indexId, status),
    0,
  );
}

const COVERAGE_SUMMARY_FIELDS = new Map([
  ["ranked", "ranked_numeric"],
  ["numericUnranked", "numeric_unranked"],
  ["labelOnly", "label_only"],
  ["missing", "no_record"],
]);

for (const index of indices) {
  const summary = requireObject(index?.coverage, `${index?.id}.coverage`);
  for (const [field, status] of COVERAGE_SUMMARY_FIELDS) {
    const expected = statusCount(index.id, status);
    check(
      summary[field] === expected,
      `${index.id}.coverage.${field} must be ${expected}; found ${JSON.stringify(summary[field])}`,
    );
  }
  const expectedPublished = publishedCount(index.id);
  check(
    summary.published === expectedPublished,
    `${index.id}.coverage.published must be ${expectedPublished}; found ${JSON.stringify(summary.published)}`,
  );
}

check(statusCount("ghi", "ranked_numeric") === 98, "GHI must have 98 ranked records");
check(statusCount("ghi", "label_only") === 32, "GHI must have 32 label-only records");
check(publishedCount("ghi") === 130, "GHI must have 130 published records");

check(
  statusCount("debt_distress", "numeric_unranked") === 67,
  "debt distress must have 67 numeric-unranked records",
);
check(
  statusCount("debt_distress", "label_only") === 1,
  "debt distress must have one label-only record",
);
check(
  statusCount("debt_distress", "ranked_numeric") === 0,
  "debt distress must have zero ranked records",
);
check(publishedCount("debt_distress") === 68, "debt distress must have 68 published records");

check(
  statusCount("disaster_displacement", "no_record") === 195,
  "disaster displacement must have 195 no-record entries",
);
check(
  publishedCount("disaster_displacement") === 0,
  "disaster displacement must have zero published records",
);

if (issues.length > 0) {
  console.error(`Explorer validation failed with ${issues.length} issue(s):`);
  for (const issue of issues) console.error(`- ${issue}`);
  process.exit(1);
}

console.log(
  `Validated ${indices.length} indices, ${nodes.length} hierarchy nodes, ` +
    `${sources.length} sources, ${providers.length} providers, ${concepts.length} concepts, ` +
    `${coverage.length} coverage records, ${sharedInputs.length} shared network inputs, ` +
    `and ${networkDependencies.length} direct network dependencies.`,
);

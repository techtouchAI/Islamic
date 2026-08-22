import fs from "node:fs";

const filePath = "/home/ubuntu/Islamic/assets/data/content.json";
const content = JSON.parse(fs.readFileSync(filePath, "utf8"));

const summary = Object.entries(content).map(([key, value]) => {
  if (Array.isArray(value)) {
    const first = value[0] ?? null;
    return {
      key,
      kind: "array",
      count: value.length,
      sampleKeys: first && typeof first === "object" ? Object.keys(first).slice(0, 12) : [],
      sampleTitle: first && typeof first === "object" ? (first.title ?? first.name ?? first.id ?? null) : first,
    };
  }
  if (value && typeof value === "object") {
    return { key, kind: "object", count: Object.keys(value).length, sampleKeys: Object.keys(value).slice(0, 12) };
  }
  return { key, kind: typeof value, count: 1, sample: value };
});

const nestedContent = Object.entries(content.content ?? {}).map(([key, value]) => {
  if (Array.isArray(value)) {
    const first = value[0] ?? null;
    return {
      key,
      kind: "array",
      count: value.length,
      sampleKeys: first && typeof first === "object" ? Object.keys(first).slice(0, 10) : [],
      sampleTitle: first && typeof first === "object" ? (first.title ?? first.name ?? first.id ?? null) : first,
    };
  }
  if (value && typeof value === "object") {
    return {
      key,
      kind: "object",
      count: Object.keys(value).length,
      children: Object.entries(value).slice(0, 30).map(([childKey, childValue]) => ({
        key: childKey,
        kind: Array.isArray(childValue) ? "array" : typeof childValue,
        count: Array.isArray(childValue) ? childValue.length : childValue && typeof childValue === "object" ? Object.keys(childValue).length : 1,
      })),
    };
  }
  return { key, kind: typeof value, count: 1 };
});

console.log(JSON.stringify({ summary, sections: content.sections, nestedContent }, null, 2));

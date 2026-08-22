import fs from "node:fs";
import path from "node:path";

const sourcePath = "/home/ubuntu/Islamic/assets/data/content.json";
const outputDir = "/home/ubuntu/webdev-static-assets/aldhakereen-library";
const source = JSON.parse(fs.readFileSync(sourcePath, "utf8"));

const titleOverrides = {
  duas_days: "أدعية الأيام",
  duas_taqeebat: "تعقيبات الصلوات",
  duas_salawat: "الصلوات على النبي وآله",
  duas_general: "الأدعية العامة",
  visits_days: "زيارات الأيام",
  visits_general: "الزيارات العامة",
  adhkar_munajat: "المناجيات",
  adhkar_tasbihs: "التسابيح",
  daily_duas: "مناجاة اليوم",
  owraths: "الأوراد",
  "fatawa.m": "الاستفتاءات — الشهيدين الصدرين",
  Mafatih_alJinan: "مقتطفات مفاتيح الجنان",
  fatawa_categories: "تصنيفات الاستفتاءات",
  dreams_categories: "تصنيفات تفسير الأحلام",
  prophets_stories: "قصص الأنبياء",
  hijri_calendar: "التقويم الهجري",
};

const slugify = (key) => key.replaceAll(".", "-").replaceAll("_", "-").toLowerCase();
const collectionTitle = (key) => titleOverrides[key] ?? source.sections?.[key]?.title ?? key;
const fileName = (id, index) => `${id}-${String(index + 1).padStart(3, "0")}.json`;
const isLargeCollection = (key) => key === "fatawa.m" || key === "visits";
const entryTitle = (entry, fallback) => {
  if (typeof entry === "string") return entry;
  if (!entry || typeof entry !== "object") return `عنصر ${fallback + 1}`;
  for (const key of ["title", "name", "question", "id"]) {
    if (typeof entry[key] === "string" || typeof entry[key] === "number") return String(entry[key]);
  }
  return `عنصر ${fallback + 1}`;
};

fs.rmSync(outputDir, { recursive: true, force: true });
fs.mkdirSync(outputDir, { recursive: true });

const allCollections = [
  ...Object.entries(source.content ?? {}).map(([key, items]) => ({ key, items, origin: "content" })),
  ...["fatawa_categories", "dreams_categories", "prophets_stories", "hijri_calendar"].map((key) => ({ key, items: source[key], origin: "root" })),
].filter(({ items }) => Array.isArray(items));

const catalog = allCollections.map(({ key, items, origin }) => {
  const id = slugify(key);
  const chunkSize = isLargeCollection(key) ? 250 : 5000;
  const chunks = [];

  for (let offset = 0; offset < items.length; offset += chunkSize) {
    const index = chunks.length;
    const name = fileName(id, index);
    const payload = {
      collection: id,
      sourceKey: key,
      title: collectionTitle(key),
      offset,
      total: items.length,
      items: items.slice(offset, offset + chunkSize),
    };
    fs.writeFileSync(path.join(outputDir, name), JSON.stringify(payload));
    chunks.push({ file: name, count: payload.items.length, offset });
  }

  const indexFile = `${id}-index.json`;
  fs.writeFileSync(path.join(outputDir, indexFile), JSON.stringify({
    collection: id,
    sourceKey: key,
    total: items.length,
    entries: items.map((item, index) => ({ index, title: entryTitle(item, index) })),
  }));

  return {
    id,
    sourceKey: key,
    title: collectionTitle(key),
    origin,
    count: items.length,
    indexFile,
    chunks,
  };
});

const appProfile = {
  about: source.about ?? {},
  settings: source.settings ?? {},
  sections: source.sections ?? {},
};

fs.writeFileSync(path.join(outputDir, "catalog.json"), JSON.stringify({
  source: "assets/data/content.json",
  collectionCount: catalog.length,
  itemCount: catalog.reduce((sum, collection) => sum + collection.count, 0),
  collections: catalog,
}));
fs.writeFileSync(path.join(outputDir, "app-profile.json"), JSON.stringify(appProfile));

console.log(JSON.stringify({
  outputDir,
  collectionCount: catalog.length,
  itemCount: catalog.reduce((sum, collection) => sum + collection.count, 0),
  fileCount: fs.readdirSync(outputDir).length,
}, null, 2));

/** Design: «واجهة التطبيق الممتدة» — المكتبة تقرأ المصدر الحقيقي وتعرضه على دفعات قابلة للبحث. */
import { appAssets } from "./app-assets";

export type CatalogChunk = { file: string; count: number; offset: number };
export type LibraryCollection = {
  id: string;
  sourceKey: string;
  title: string;
  origin: "content" | "root";
  count: number;
  indexFile: string;
  chunks: CatalogChunk[];
};

export type LibraryCatalog = {
  source: string;
  collectionCount: number;
  itemCount: number;
  collections: LibraryCollection[];
};

export type LibraryIndexEntry = { index: number; title: string };
export type LibraryIndex = { collection: string; sourceKey: string; total: number; entries: LibraryIndexEntry[] };
export type LibraryChunk = { collection: string; sourceKey: string; offset: number; total: number; items: unknown[] };

export async function loadCatalog(): Promise<LibraryCatalog> {
  const response = await fetch(appAssets.catalog);
  if (!response.ok) throw new Error("تعذر تحميل فهرس المحتوى.");
  return response.json() as Promise<LibraryCatalog>;
}

export async function loadApplicationContent(): Promise<Record<string, unknown>> {
  const response = await fetch(appAssets.content);
  if (!response.ok) throw new Error("تعذر تحميل محتوى التطبيق.");
  return response.json() as Promise<Record<string, unknown>>;
}

export async function loadCollectionIndex(file: string): Promise<LibraryIndex> {
  const response = await fetch(appAssets.libraryFile(file));
  if (!response.ok) throw new Error("تعذر تحميل فهرس المجموعة.");
  return response.json() as Promise<LibraryIndex>;
}

export async function loadCollectionChunk(file: string): Promise<LibraryChunk> {
  const response = await fetch(appAssets.libraryFile(file));
  if (!response.ok) throw new Error("تعذر تحميل النص المطلوب.");
  return response.json() as Promise<LibraryChunk>;
}

export function readCollection(source: Record<string, unknown>, collection: LibraryCollection): unknown[] {
  const contentRoot = source.content as Record<string, unknown> | undefined;
  const entries = collection.origin === "content" ? contentRoot?.[collection.sourceKey] : source[collection.sourceKey];
  return Array.isArray(entries) ? entries : [];
}

export function entryTitle(entry: unknown, fallback: number): string {
  if (typeof entry === "string") return entry;
  if (!entry || typeof entry !== "object") return `عنصر ${fallback + 1}`;
  const data = entry as Record<string, unknown>;
  for (const key of ["title", "name", "question", "id"]) {
    const value = data[key];
    if (typeof value === "string" || typeof value === "number") return String(value);
  }
  return `عنصر ${fallback + 1}`;
}

function nestedText(value: unknown): string {
  if (typeof value === "string" || typeof value === "number") return String(value);
  if (Array.isArray(value)) return value.map(nestedText).filter(Boolean).join("\n\n");
  if (value && typeof value === "object") {
    return Object.entries(value as Record<string, unknown>)
      .filter(([key]) => !["id", "title", "name"].includes(key))
      .map(([key, child]) => `${key}: ${nestedText(child)}`)
      .filter(Boolean)
      .join("\n\n");
  }
  return "";
}

export function entryBody(entry: unknown): string {
  if (typeof entry === "string") return entry;
  if (!entry || typeof entry !== "object") return "لا يتوفر نص قابل للعرض لهذا العنصر.";
  const data = entry as Record<string, unknown>;
  if (typeof data.content === "string") return data.content;
  if (typeof data.answer === "string") return data.answer;
  if (data.items) return nestedText(data.items);
  if (data.days) return nestedText(data.days);
  return nestedText(data);
}

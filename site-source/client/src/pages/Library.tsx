/** Design: «واجهة التطبيق الممتدة» — فهرس الحواف يقود إلى النص الأصلي، لا إلى بطاقات تسويقية. */
import { useEffect, useMemo, useState } from "react";
import { BookOpen, ChevronLeft, ExternalLink, LoaderCircle, Search, X } from "lucide-react";
import { Link } from "wouter";
import { SiteShell } from "@/components/SiteShell";
import { appAssets, isGitHubPagesBuild } from "@/lib/app-assets";
import { entryBody, entryTitle, loadApplicationContent, loadCatalog, loadCollectionChunk, loadCollectionIndex, readCollection, type LibraryCatalog, type LibraryCollection, type LibraryIndexEntry } from "@/lib/library";

const PAGE_SIZE = 24;

export default function Library() {
  const [catalog, setCatalog] = useState<LibraryCatalog | null>(null);
  const [source, setSource] = useState<Record<string, unknown> | null>(null);
  const [indexEntries, setIndexEntries] = useState<LibraryIndexEntry[]>([]);
  const [selectedId, setSelectedId] = useState<string>("");
  const [activeReading, setActiveReading] = useState<{ title: string; body: string } | null>(null);
  const [query, setQuery] = useState("");
  const [page, setPage] = useState(0);
  const [error, setError] = useState("");

  useEffect(() => {
    loadCatalog().then((data) => {
      setCatalog(data);
      setSelectedId(data.collections.find((collection) => collection.count > 0)?.id ?? "");
    }).catch(() => setError("تعذر قراءة فهرس المحتوى حاليًا."));
  }, []);

  const selectedCollection = useMemo(() => catalog?.collections.find((collection) => collection.id === selectedId) ?? null, [catalog, selectedId]);

  useEffect(() => {
    if (!selectedCollection) return;
    setActiveReading(null);
    if (isGitHubPagesBuild) {
      loadCollectionIndex(selectedCollection.indexFile).then((data) => setIndexEntries(data.entries)).catch(() => setError("تعذر تحميل فهرس المجموعة."));
      return;
    }
    if (!source) loadApplicationContent().then(setSource).catch(() => setError("تعذر تحميل النصوص الأصلية للتطبيق."));
  }, [selectedCollection, source]);

  const allEntries = useMemo(() => source && selectedCollection ? readCollection(source, selectedCollection) : [], [source, selectedCollection]);
  const entryRecords = useMemo(() => isGitHubPagesBuild ? indexEntries : allEntries.map((entry, index) => ({ index, title: entryTitle(entry, index) })), [allEntries, indexEntries]);
  const filteredEntries = useMemo(() => {
    const normalized = query.trim();
    if (!normalized) return entryRecords;
    return entryRecords.filter((entry) => entry.title.includes(normalized));
  }, [entryRecords, query]);
  const visibleEntries = useMemo(() => filteredEntries.slice(page * PAGE_SIZE, (page + 1) * PAGE_SIZE), [filteredEntries, page]);
  const pageCount = Math.max(1, Math.ceil(filteredEntries.length / PAGE_SIZE));
  const entriesReady = isGitHubPagesBuild ? Boolean(selectedCollection && (selectedCollection.count === 0 || indexEntries.length > 0)) : Boolean(source);

  function selectCollection(collection: LibraryCollection) {
    setSelectedId(collection.id);
    setActiveReading(null);
    setQuery("");
    setPage(0);
  }

  async function openEntry(record: LibraryIndexEntry) {
    if (!selectedCollection) return;
    if (!isGitHubPagesBuild) {
      setActiveReading({ title: record.title, body: entryBody(allEntries[record.index]) });
      return;
    }
    try {
      const chunk = selectedCollection.chunks.find((candidate) => record.index >= candidate.offset && record.index < candidate.offset + candidate.count);
      if (!chunk) throw new Error("missing chunk");
      const data = await loadCollectionChunk(chunk.file);
      setActiveReading({ title: record.title, body: entryBody(data.items[record.index - chunk.offset]) });
    } catch {
      setError("تعذر تحميل نص العنصر المختار.");
    }
  }

  return <SiteShell>
    <main className="library-page">
      <section className="library-intro section-wrap">
        <p className="section-kicker">مكتبة التطبيق</p>
        <div className="library-intro-grid">
          <div><h1>كل ما يحفظه<br />الذاكرين، في موضع واحد.</h1><p>فهرس مباشر لمجموعات <span dir="ltr">content.json</span> الأصلية. اختر مجموعة، ثم افتح النص من المصدر الذي يقرأه التطبيق نفسه.</p></div>
          <div className="library-total"><span>مادة مفهرسة</span><strong>{catalog ? catalog.itemCount.toLocaleString("ar-IQ") : "…"}</strong><small>{catalog ? `${catalog.collectionCount} مجموعة محتوى` : "جارٍ قراءة الفهرس"}</small></div>
        </div>
      </section>

      {error ? <section className="section-wrap"><div className="notice-box">{error}</div></section> : null}
      {!catalog ? <section className="section-wrap loading-state"><LoaderCircle className="h-5 w-5 animate-spin" /> جارٍ تجهيز فهرس المكتبة…</section> : <section className="library-workspace section-wrap">
        <aside className="collection-rail" aria-label="مجموعات المحتوى">
          <p className="rail-label">المجموعات</p>
          {catalog.collections.map((collection, index) => <button type="button" key={collection.id} onClick={() => selectCollection(collection)} className={`collection-link ${collection.id === selectedId ? "is-active" : ""}`}><span>{String(index + 1).padStart(2, "0")}</span><b>{collection.title}</b><small>{collection.count.toLocaleString("ar-IQ")}</small></button>)}
        </aside>

        <div className="library-main">
          <div className="library-toolbar"><div><p className="section-kicker">{selectedCollection?.sourceKey ?? "CONTENT"}</p><h2>{selectedCollection?.title ?? "اختر مجموعة"}</h2><span>{selectedCollection ? `${selectedCollection.count.toLocaleString("ar-IQ")} عنصر من بيانات التطبيق` : ""}</span></div><a href={appAssets.content} target="_blank" rel="noreferrer" className="raw-source-link">الملف الأصلي <ExternalLink className="h-4 w-4" /></a></div>
          {!entriesReady ? <div className="library-loading"><LoaderCircle className="h-5 w-5 animate-spin" /> جارٍ تحميل فهرس النصوص الأصلية…</div> : <>
            <label className="search-field"><Search className="h-4 w-4" /><input value={query} onChange={(event) => { setQuery(event.target.value); setPage(0); setActiveReading(null); }} placeholder={`ابحث في ${selectedCollection?.title ?? "المجموعة"}`} /><button type="button" onClick={() => setQuery("")} aria-label="مسح البحث">{query ? <X className="h-4 w-4" /> : null}</button></label>
            <div className="entry-list" aria-live="polite">{visibleEntries.map((entry) => <button type="button" key={`${entry.index}-${entry.title}`} onClick={() => openEntry(entry)}><span>{String(entry.index + 1).padStart(3, "0")}</span><b>{entry.title}</b><ChevronLeft className="h-4 w-4" /></button>)}</div>
            <div className="pager"><button type="button" onClick={() => setPage((current) => Math.max(0, current - 1))} disabled={page === 0}>السابق</button><span>صفحة {page + 1} من {pageCount}</span><button type="button" onClick={() => setPage((current) => Math.min(pageCount - 1, current + 1))} disabled={page + 1 >= pageCount}>التالي</button></div>
          </>}
        </div>
      </section>}

      {activeReading ? <div className="reading-overlay" role="dialog" aria-modal="true" aria-label="قراءة المحتوى"><button type="button" className="overlay-dismiss" onClick={() => setActiveReading(null)} aria-label="إغلاق" /><article className="reading-sheet"><button type="button" onClick={() => setActiveReading(null)} className="reading-close"><X className="h-4 w-4" /> إغلاق</button><p className="section-kicker">{selectedCollection?.title}</p><h2>{activeReading.title}</h2><div className="reading-content">{activeReading.body}</div></article></div> : null}

      <section className="library-footer section-wrap"><BookOpen className="h-5 w-5" /><p>هذه المكتبة تعرض المحتوى الذي يستخدمه التطبيق من ملفه المركزي؛ للحصول على أدوات اليوم والتنبيهات، استخدم تطبيق Android.</p><Link href="/download">اذهب إلى التنزيل</Link></section>
    </main>
  </SiteShell>;
}

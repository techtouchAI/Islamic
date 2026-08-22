/** Design: «محراب رقمي» — صفحة محتوى تشبه فهرس مخطوطة رقمية، مع تعليمات قابلة للمسح البصري. */
import { Braces, FileCheck2, FolderTree, PenLine, ShieldAlert } from "lucide-react";
import { PageHero, SectionHeading, SiteShell } from "@/components/SiteShell";

const groups = [
  ["sections", "تعريف الأقسام التي تظهر في واجهة التطبيق، مثل القرآن والأدعية والزيارات."],
  ["duas_days", "أعمال وأدعية اليوم التي يمكن للتطبيق إظهارها وفق اليوم الحالي."],
  ["duas_taqeebat", "تعقيبات منظمة لتمكين الوصول السريع بعد الصلوات."],
  ["duas_general", "الأدعية العامة؛ يضاف إليها دعاء جديد بكائن مستقل ومعرّف غير مكرر."],
  ["ziyara", "الزيارات والمحتوى المرتبط بالمناسبات أو الاختيارات المخصصة."],
];

const snippet = `{
  "id": 100,
  "title": "عنوان الدعاء الجديد",
  "content": "نص الدعاء بالكامل هنا..."
}`;

export default function Content() {
  return <SiteShell><PageHero eyebrow="CONTENT / 05" title="المحتوى جزء من التطبيق، وله مسار إدارة واضح." description="يحفظ الذاكرين المحتوى في ملف JSON مركزي. هذه الصفحة تشرح البنية، ما الذي يحرره كل قسم، وكيف تضيف نصًا دون كسر التنسيق." />
    <main className="px-5 py-16 sm:py-24 lg:px-10"><div className="mx-auto max-w-[1240px]"><section className="grid gap-10 lg:grid-cols-[1fr_.9fr] lg:items-center"><div><SectionHeading title="ملف واحد يربط الأقسام بالمحتوى." copy="يُدار المحتوى من assets/data/content.json. حافظ على صيغة JSON الدقيقة وعلى المعرفات غير المتكررة، ثم راجع التغيير قبل نشره." /></div><div className="arch-visual h-[330px] shadow-[0_20px_50px_rgba(23,58,60,0.14)]"><div className="relative z-10 max-w-[220px] rounded-2xl border border-[#d7b97f]/25 bg-[#f6f1e7]/95 p-5"><p className="font-plex text-[9px] tracking-[.18em] text-[#b7833f]">JSON / ARCHIVE</p><p className="mt-3 font-kufi text-lg leading-8 text-[#173a3c]">نصوص مفهرسة، في ملف واحد.</p><div className="copper-rule mt-4" /></div></div></section>
      <section className="mt-16 grid gap-6 lg:grid-cols-[.9fr_1.1fr]"><aside className="rounded-[26px] bg-[#173a3c] p-7 text-[#f6f1e7]"><FolderTree className="h-7 w-7 text-[#d7b97f]" /><h2 className="mt-5 font-kufi text-xl leading-9">بنية المحتوى</h2><p className="mt-3 font-naskh text-xl leading-8 text-[#f6f1e7]/72">تعامل مع الملف كمصدر منظم لا كمساحة ملاحظات. الاسم الدقيق للمفتاح مهم بقدر أهمية النص الذي تضيفه.</p><a href="https://raw.githubusercontent.com/techtouchAI/Islamic/main/assets/data/content.json" target="_blank" rel="noreferrer" className="mt-7 inline-flex items-center gap-2 font-kufi text-[11px] text-[#d7b97f] hover:text-white"><Braces className="h-4 w-4" /> فتح content.json</a></aside><div className="divide-y divide-[#173a3c]/12 border-y border-[#173a3c]/12">{groups.map(([name, copy]) => <article key={name} className="grid gap-3 py-5 sm:grid-cols-[180px_1fr]"><code className="self-start rounded-lg bg-[#e9dfcd] px-3 py-1.5 font-plex text-xs text-[#8b5b25]">{name}</code><p className="font-naskh text-xl leading-8 text-[#496869]">{copy}</p></article>)}</div></section>
      <section className="mt-16 grid gap-6 lg:grid-cols-[.9fr_1.1fr]"><div className="rounded-[26px] border border-[#173a3c]/12 bg-[#fffaf2] p-7"><PenLine className="h-6 w-6 text-[#b7833f]" /><h2 className="mt-4 font-kufi text-xl leading-9 text-[#173a3c]">إضافة دعاء جديد</h2><p className="mt-3 font-naskh text-xl leading-8 text-[#496869]">ابحث عن <code className="font-plex text-sm text-[#8b5b25]">duas_general</code> وأضف كائنًا جديدًا في نهاية القائمة. استخدم <code className="font-plex text-sm text-[#8b5b25]">\\n</code> عندما تحتاج سطرًا جديدًا داخل النص.</p></div><pre dir="ltr" className="overflow-x-auto rounded-[26px] bg-[#102e31] p-7 text-left font-plex text-sm leading-7 text-[#e7c68d] shadow-[0_20px_40px_rgba(16,46,49,0.18)]">{snippet}</pre></section>
      <section className="mt-6 flex gap-4 rounded-2xl border border-[#b7833f]/25 bg-[#f0e4cf] p-6"><ShieldAlert className="mt-1 h-5 w-5 shrink-0 text-[#b7833f]" /><p className="font-naskh text-xl leading-8 text-[#496869]"><strong className="font-kufi text-sm text-[#173a3c]">فحص أخير:</strong> تأكد من الفواصل والأقواس واقتباسات JSON. التغيير غير الصالح قد يمنع التطبيق من قراءة قسم كامل، وليس العنصر الجديد فقط.</p></section>
    </div></main>
  </SiteShell>;
}

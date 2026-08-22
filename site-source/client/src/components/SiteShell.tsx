/**
 * Design: «محراب رقمي» — حبر أزرق-أخضر، عاج دافئ، ونحاس مطفأ؛ الملاحة هادئة وواضحة.
 */
import {
  ArrowUpLeft,
  BookOpenText,
  ChevronLeft,
  Download,
  Menu,
  MoonStar,
  X,
} from "lucide-react";
import { useState } from "react";
import { Link, useLocation } from "wouter";
import { appMarkSrc } from "@/lib/site-assets";

const navItems = [
  { href: "/", label: "الرئيسية" },
  { href: "/features", label: "المزايا" },
  { href: "/guide", label: "دليل الاستخدام" },
  { href: "/content", label: "المحتوى" },
  { href: "/downloads", label: "التنزيلات" },
  { href: "/about", label: "عن التطبيق" },
];

export function SiteShell({ children }: { children: React.ReactNode }) {
  const [location] = useLocation();
  const [open, setOpen] = useState(false);

  const isCurrent = (href: string) =>
    href === "/" ? location === "/" : location.startsWith(href);

  return (
    <div dir="rtl" className="min-h-screen overflow-x-hidden bg-[#f6f1e7] text-[#173a3c]">
      <header className="sticky top-0 z-50 border-b border-[#173a3c]/10 bg-[#f6f1e7]/92 backdrop-blur-xl">
        <div className="mx-auto flex h-[76px] max-w-[1440px] items-center justify-between px-5 lg:px-10">
          <Link href="/" className="group flex items-center gap-3">
            <img
              src={appMarkSrc}
              alt="رمز تطبيق الذاكرين"
              className="h-11 w-11 rounded-[14px] object-cover shadow-[0_9px_20px_rgba(23,58,60,0.12)] transition-transform duration-200 group-hover:-rotate-3"
            />
            <span>
              <strong className="block font-kufi text-[18px] font-bold leading-none tracking-[-0.07em] text-[#173a3c]">الذاكرين</strong>
              <small className="mt-1.5 block font-plex text-[8px] uppercase tracking-[0.22em] text-[#b7833f]">AL-DHAKEREEN</small>
            </span>
          </Link>

          <nav className="hidden items-center gap-1 lg:flex" aria-label="التنقل الرئيسي">
            {navItems.map((item) => (
              <Link
                key={item.href}
                href={item.href}
                className={`rounded-full px-3 py-2 font-kufi text-[12px] transition-colors ${
                  isCurrent(item.href)
                    ? "bg-[#173a3c] text-[#f6f1e7]"
                    : "text-[#3d5c5d] hover:bg-[#173a3c]/7 hover:text-[#173a3c]"
                }`}
              >
                {item.label}
              </Link>
            ))}
          </nav>

          <a
            href="https://github.com/techtouchAI/Islamic/releases/tag/v1.0.51-801"
            target="_blank"
            rel="noreferrer"
            className="hidden items-center gap-2 rounded-full bg-[#b7833f] px-4 py-2.5 font-kufi text-[11px] text-[#fffaf1] shadow-[0_8px_18px_rgba(183,131,63,0.22)] transition hover:-translate-y-0.5 hover:bg-[#9d6a2f] lg:flex"
          >
            <Download className="h-3.5 w-3.5" />
            تنزيل التطبيق
          </a>

          <button
            type="button"
            aria-label={open ? "إغلاق القائمة" : "فتح القائمة"}
            aria-expanded={open}
            onClick={() => setOpen((current) => !current)}
            className="grid h-10 w-10 place-items-center rounded-full border border-[#173a3c]/14 text-[#173a3c] lg:hidden"
          >
            {open ? <X className="h-5 w-5" /> : <Menu className="h-5 w-5" />}
          </button>
        </div>
        {open && (
          <div className="border-t border-[#173a3c]/10 bg-[#f6f1e7] px-5 py-5 lg:hidden">
            <nav className="mx-auto grid max-w-md gap-1" aria-label="التنقل المحمول">
              {navItems.map((item) => (
                <Link
                  key={item.href}
                  href={item.href}
                  onClick={() => setOpen(false)}
                  className={`flex items-center justify-between rounded-xl px-4 py-3 font-kufi text-sm ${
                    isCurrent(item.href) ? "bg-[#173a3c] text-[#f6f1e7]" : "text-[#173a3c]"
                  }`}
                >
                  {item.label}
                  <ChevronLeft className="h-4 w-4" />
                </Link>
              ))}
              <a
                href="https://github.com/techtouchAI/Islamic/releases/tag/v1.0.51-801"
                target="_blank"
                rel="noreferrer"
                className="mt-2 flex items-center justify-between rounded-xl bg-[#b7833f] px-4 py-3 font-kufi text-sm text-white"
              >
                تنزيل التطبيق
                <ArrowUpLeft className="h-4 w-4" />
              </a>
            </nav>
          </div>
        )}
      </header>

      {children}

      <footer className="relative overflow-hidden bg-[#102e31] text-[#f6f1e7]">
        <div className="absolute inset-0 opacity-[0.09] pattern-grid" />
        <div className="relative mx-auto grid max-w-[1440px] gap-10 px-5 py-14 lg:grid-cols-[1.2fr_.7fr_.7fr] lg:px-10">
          <div>
            <div className="mb-5 flex items-center gap-3">
              <img src={appMarkSrc} alt="" className="h-11 w-11 rounded-xl" />
              <div>
                <p className="font-kufi text-base">الذاكرين</p>
                <p className="mt-1 font-plex text-[10px] tracking-[0.18em] text-[#d7b97f]">TIME · QURAN · DHIKR</p>
              </div>
            </div>
            <p className="max-w-md font-naskh text-lg leading-8 text-[#f6f1e7]/75">
              رفيق عربي هادئ يجمع وقت الصلاة، القرآن، الأدعية، الذكر وإدارة المحتوى في موضع واحد.
            </p>
          </div>
          <div>
            <p className="mb-4 font-kufi text-[12px] text-[#d7b97f]">استكشف</p>
            <div className="grid gap-3 font-naskh text-lg text-[#f6f1e7]/75">
              <Link href="/features" className="hover:text-white">المزايا</Link>
              <Link href="/guide" className="hover:text-white">دليل الاستخدام</Link>
              <Link href="/content" className="hover:text-white">إدارة المحتوى</Link>
            </div>
          </div>
          <div>
            <p className="mb-4 font-kufi text-[12px] text-[#d7b97f]">المشروع</p>
            <div className="grid gap-3 font-naskh text-lg text-[#f6f1e7]/75">
              <a href="https://github.com/techtouchAI/Islamic" target="_blank" rel="noreferrer" className="hover:text-white">مستودع GitHub</a>
              <Link href="/downloads" className="hover:text-white">الملفات والتنزيلات</Link>
              <Link href="/about" className="hover:text-white">عن التطبيق</Link>
            </div>
          </div>
        </div>
        <div className="relative mx-auto flex max-w-[1440px] flex-col gap-3 border-t border-white/10 px-5 py-5 font-naskh text-sm text-[#f6f1e7]/50 sm:flex-row sm:items-center sm:justify-between lg:px-10">
          <span>© {new Date().getFullYear()} تطبيق الذاكرين.</span>
          <span className="flex items-center gap-2"><MoonStar className="h-3.5 w-3.5 text-[#d7b97f]" /> صُمم لرحلة يومية أكثر ترتيبًا وطمأنينة.</span>
        </div>
      </footer>
    </div>
  );
}

export function Eyebrow({ children }: { children: React.ReactNode }) {
  return <p className="mb-4 flex items-center gap-2 font-plex text-[11px] font-medium tracking-[0.18em] text-[#b7833f]"><span className="h-px w-8 bg-[#b7833f]" />{children}</p>;
}

export function SectionHeading({ title, copy }: { title: string; copy: string }) {
  return (
    <div className="max-w-2xl">
      <h2 className="font-kufi text-2xl leading-[1.6] tracking-[-0.055em] text-[#173a3c] sm:text-3xl">{title}</h2>
      <p className="mt-4 font-naskh text-xl leading-8 text-[#496869]">{copy}</p>
    </div>
  );
}

export function PageHero({ eyebrow, title, description }: { eyebrow: string; title: string; description: string }) {
  return (
    <section className="relative overflow-hidden bg-[#102e31] px-5 pb-20 pt-16 text-[#f6f1e7] sm:pb-24 sm:pt-20 lg:px-10">
      <div className="absolute inset-0 opacity-[0.12] pattern-grid" />
      <div className="relative mx-auto grid max-w-[1240px] gap-8 lg:grid-cols-[150px_1fr] lg:gap-12">
        <aside className="hidden border-l border-[#d7b97f]/45 pl-5 lg:block"><p className="font-plex text-[10px] tracking-[.22em] text-[#d7b97f]">SECTION</p><p className="mt-12 font-plex text-xs text-[#f6f1e7]/45">01 — 06</p><div className="mt-5 h-24 w-px bg-[#b7833f]" /></aside>
        <div className="max-w-3xl"><Eyebrow>{eyebrow}</Eyebrow><h1 className="font-kufi text-3xl font-semibold leading-[1.72] tracking-[-0.075em] sm:text-5xl">{title}</h1><p className="mt-5 max-w-2xl font-naskh text-xl leading-9 text-[#f6f1e7]/76">{description}</p></div>
      </div>
    </section>
  );
}

export function ExternalLink({ href, children }: { href: string; children: React.ReactNode }) {
  if (href.startsWith("/")) {
    return <Link href={href} className="inline-flex items-center gap-2 font-kufi text-[12px] text-[#b7833f] hover:text-[#9d6a2f]">{children}<ArrowUpLeft className="h-3.5 w-3.5" /></Link>;
  }
  return <a href={href} target="_blank" rel="noreferrer" className="inline-flex items-center gap-2 font-kufi text-[12px] text-[#b7833f] hover:text-[#9d6a2f]">{children}<ArrowUpLeft className="h-3.5 w-3.5" /></a>;
}

export function InfoBadge({ children }: { children: React.ReactNode }) {
  return <span className="rounded-full border border-[#b7833f]/30 bg-[#fffaf2] px-3 py-1 font-kufi text-[10px] text-[#8b5b25]">{children}</span>;
}

export { BookOpenText };

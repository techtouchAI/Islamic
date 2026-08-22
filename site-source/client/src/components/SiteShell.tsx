/** Design: «واجهة التطبيق الممتدة» — رأس بسيط بأيقونة التطبيق الأصلية ومسارات قليلة واضحة. */
import { Menu, X } from "lucide-react";
import { useState } from "react";
import { Link, useLocation } from "wouter";
import { appAssets } from "@/lib/app-assets";

const nav = [{ href: "/", label: "الرئيسية" }, { href: "/library", label: "المكتبة" }, { href: "/download", label: "التنزيل" }, { href: "/about", label: "عن التطبيق" }];

export function SiteShell({ children }: { children: React.ReactNode }) {
  const [location] = useLocation();
  const [open, setOpen] = useState(false);
  const active = (href: string) => href === "/" ? location === "/" : location.startsWith(href);
  return <div dir="rtl" className="site-shell"><header className="site-header"><div className="site-nav section-wrap"><Link href="/" className="brand"><span className="brand-symbol"><img src={appAssets.logo} alt="شعار الذاكرين" /></span><span className="brand-wordmark"><b>الذاكرين</b><i /><small>AL-DHAKEREEN</small></span></Link><nav className="desktop-nav" aria-label="التنقل الرئيسي">{nav.map((item) => <Link key={item.href} href={item.href} className={active(item.href) ? "active" : ""}>{item.label}</Link>)}</nav><button type="button" onClick={() => setOpen((value) => !value)} className="mobile-menu" aria-label={open ? "إغلاق القائمة" : "فتح القائمة"}>{open ? <X className="h-5 w-5" /> : <Menu className="h-5 w-5" />}</button></div>{open ? <nav className="mobile-nav" aria-label="التنقل المحمول">{nav.map((item) => <Link key={item.href} href={item.href} onClick={() => setOpen(false)} className={active(item.href) ? "active" : ""}>{item.label}</Link>)}</nav> : null}</header>{children}<footer className="site-footer"><div className="section-wrap"><div><img src={appAssets.logo} alt="" /><p>الذاكرين — وقت، قراءة، ذكر ومكتبة في تجربة عربية واحدة.</p></div><div><Link href="/library">المكتبة</Link><Link href="/download">التنزيل</Link><a href="https://github.com/techtouchAI/Islamic" target="_blank" rel="noreferrer">GitHub</a></div><small>© {new Date().getFullYear()} الذاكرين</small></div></footer></div>;
}

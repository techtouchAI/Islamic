/** Design: «واجهة التطبيق الممتدة» — الأيقونة الرسمية والمحتوى الفعلي يقودان الصفحة، لا الزخرفة العامة. */
import { ArrowUpLeft, BookOpen, Download, MoonStar, Sparkles } from "lucide-react";
import { Link } from "wouter";
import { OfficialAppFrame } from "@/components/OfficialAppFrame";
import { SiteShell } from "@/components/SiteShell";

const libraryDoors = [
  ["القرآن الكريم", "114 سورة"], ["الأدعية", "230 نصًا"], ["الزيارات", "2,264 نصًا"], ["الصحيفة السجادية", "111 دعاء"], ["الأحاديث", "102 حديث"], ["أسماء الله الحسنى", "99 اسمًا"],
];

export default function Home() {
  return <SiteShell>
    <main>
      <section className="home-hero"><div className="section-wrap hero-grid"><div className="hero-copy"><p className="hero-eyebrow"><MoonStar className="h-4 w-4" /> تطبيق عربي إسلامي</p><h1>كل ما تحتاجه<br /><em>في يومك.</em></h1><p>وقت الصلاة، القرآن، الأدعية، الزيارات، الذكر والمكتبة — في تجربة واحدة هادئة وواضحة.</p><div className="hero-actions"><Link href="/library" className="primary-action"><BookOpen className="h-4 w-4" /> افتح المكتبة <ArrowUpLeft className="h-4 w-4" /></Link><Link href="/download" className="text-action"><Download className="h-4 w-4" /> تنزيل التطبيق</Link></div></div><OfficialAppFrame label="APP / 01" /></div></section>
      <section className="product-register section-wrap"><p><Sparkles className="h-4 w-4" /> سجل التطبيق</p><span><b>01</b> Android App</span><span><b>02</b> <i dir="ltr">content.json</i></span><span><b>03</b> 17,657 مادة مفهرسة</span></section>
      <section className="app-intro section-wrap"><div><p className="section-kicker">الذاكرين</p><h2>واجهة بسيطة،<br />لكنها لا تختصر المحتوى.</h2></div><p>هذا الموقع هو مساحة للقراءة واكتشاف ما يقدمه التطبيق. ابدأ بمجموعات المكتبة، ثم انتقل إلى التطبيق لتجربة الوقت والتنبيه والذكر من مكان واحد.</p></section>
      <section className="library-preview section-wrap"><div className="library-preview-heading"><div><p className="section-kicker">أبواب المكتبة</p><h2>اختر بابًا، واقرأ من موضع واضح.</h2></div><Link href="/library" className="text-action">عرض كل المحتوى <ArrowUpLeft className="h-4 w-4" /></Link></div><div className="door-list">{libraryDoors.map(([title, count], index) => <Link key={title} href="/library" className="door"><span>{String(index + 1).padStart(2, "0")}</span><b>{title}</b><small>{count}</small><ArrowUpLeft className="h-4 w-4" /></Link>)}</div></section>
      <section className="tools-row section-wrap"><article><span>01</span><h3>وقت الصلاة</h3><p>مصدر موقع واضح، حساب موحد، وجدولة يمكن فهمها.</p></article><article><span>02</span><h3>الأذان والتنبيهات</h3><p>تنبيه مسبق، صوت موحد، واستعادة بعد الإقلاع.</p></article><article><span>03</span><h3>الذكر</h3><p>مسبحة تحفظ التقدم وتسبيحة الزهراء 34/33/33.</p></article></section>
      <section className="home-download section-wrap"><div><p className="section-kicker">ANDROID</p><h2>التطبيق جاهز<br />حين تكون أنت جاهزًا.</h2></div><Link href="/download" className="primary-action"><Download className="h-4 w-4" /> التنزيل والإصدار <ArrowUpLeft className="h-4 w-4" /></Link></section>
    </main>
  </SiteShell>;
}

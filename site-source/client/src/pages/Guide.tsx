/** Design: «محراب رقمي» — الدليل يتبع خط وقت نحاسي ويحوّل الإعداد إلى خطوات مطمئنة. */
import { Bell, CheckCircle2, MapPin, ShieldCheck, SlidersHorizontal } from "lucide-react";
import { ExternalLink, PageHero, SectionHeading, SiteShell } from "@/components/SiteShell";

const steps = [
  { icon: MapPin, number: "01", title: "حدّد مصدر موقعك", copy: "اختر المحافظة/المدينة إن أردت وقتًا ثابتًا للمكان الذي تقيم فيه، أو اسمح بالموقع الحي عند رغبتك في استخدام GPS. يعرض التطبيق المصدر المستخدم بدل التخمين." },
  { icon: Bell, number: "02", title: "فعّل ما تحتاجه من تنبيهات", copy: "اختر الصلوات المراد تنبيهك بها، واضبط التنبيه المسبق والصوت. سيطلب التطبيق صلاحيات الإشعار والتنبيه الدقيق عندما يحتاج إليها." },
  { icon: ShieldCheck, number: "03", title: "راجع أذونات Android", copy: "في بعض إصدارات Android، تتطلب التنبيهات الدقيقة أو إظهار تنبيه ملء الشاشة موافقة من إعدادات النظام. اتبع رابط الإعداد الذي يظهر داخل التطبيق." },
  { icon: SlidersHorizontal, number: "04", title: "خصّص روتينك", copy: "اضبط الواجهة التي تقرأ بها، واختر مظهر التطبيق، ثم استخدم المسبحة أو الأدعية كمساحات قصيرة متاحة من الصفحة الرئيسية." },
];

export default function Guide() {
  return <SiteShell><PageHero eyebrow="GUIDE / 02" title="ابدأ بهدوء. أربع خطوات تكفي لتجهيز يومك." description="هذا الدليل يشرح المسار الأساسي للتطبيق: موقع واضح، تنبيهات مفهومة، محتوى جاهز، وإعدادات لا تخفي أثرها." />
    <main className="px-5 py-16 sm:py-24 lg:px-10"><div className="mx-auto max-w-[1240px]"><SectionHeading title="الإعداد ليس مهمة تقنية؛ هو ترتيب لوقت اليوم." copy="ابدأ بالموقع، ثم التنبيهات، ثم خصص ما تحتاجه. لا يلزم تفعيل كل شيء دفعة واحدة." />
      <div className="relative mt-16 grid gap-0 before:absolute before:right-[27px] before:top-7 before:h-[calc(100%-56px)] before:w-px before:bg-[#b7833f]/45 md:mr-8 md:max-w-4xl">
        {steps.map(({ icon: Icon, number, title, copy }) => <article key={number} className="relative grid gap-5 pb-11 pr-16 sm:grid-cols-[80px_1fr] sm:pr-20"><div className="absolute right-0 top-0 grid h-14 w-14 place-items-center rounded-full border border-[#b7833f] bg-[#f6f1e7] text-[#b7833f]"><Icon className="h-5 w-5" /></div><span className="font-plex text-xs tracking-[0.16em] text-[#b7833f]">STEP {number}</span><div><h2 className="font-kufi text-xl leading-8 text-[#173a3c]">{title}</h2><p className="mt-3 max-w-2xl font-naskh text-xl leading-8 text-[#496869]">{copy}</p></div></article>)}
      </div>
      <section className="mt-10 grid gap-6 rounded-[28px] bg-[#173a3c] p-7 text-[#f6f1e7] lg:grid-cols-[1.15fr_.85fr] lg:p-10"><div><p className="font-plex text-[10px] tracking-[0.18em] text-[#d7b97f]">ملاحظة مهمة</p><h2 className="mt-3 font-kufi text-2xl leading-[1.7]">لا تخلط بين موقع GPS والمدينة المختارة.</h2><p className="mt-4 font-naskh text-xl leading-8 text-[#f6f1e7]/72">إذا اخترت مدينة يدويًا، يبقى الحساب مرتبطًا بها. وعند استخدام GPS، يعرض التطبيق أن المصدر حي أو محفوظ حتى لا تُفهم النتيجة بصورة خاطئة.</p></div><div className="flex flex-col justify-center gap-4 rounded-2xl bg-white/7 p-6 font-naskh text-lg text-[#f6f1e7]/78"><p className="flex gap-3"><CheckCircle2 className="mt-1 h-4 w-4 shrink-0 text-[#d7b97f]" />راجع صلاحيات الإشعار بعد تحديث Android.</p><p className="flex gap-3"><CheckCircle2 className="mt-1 h-4 w-4 shrink-0 text-[#d7b97f]" />شغّل اختبارًا قريبًا للأذان بعد الإعداد.</p><p className="flex gap-3"><CheckCircle2 className="mt-1 h-4 w-4 shrink-0 text-[#d7b97f]" />أعد المراجعة إن بدّلت المدينة أو timezone.</p></div></section>
      <div className="mt-8"><ExternalLink href="/downloads">انتقل إلى ملفات التطبيق والتنزيل</ExternalLink></div>
    </div></main>
  </SiteShell>;
}

/** Design: «محراب رقمي» — عرض المزايا كأبواب معرفة متتابعة، لا شبكة بطاقات متشابهة. */
import { ArrowUpLeft, BellRing, BookMarked, Clock3, HeartHandshake, Settings2, Sparkles } from "lucide-react";
import { Link } from "wouter";
import { Eyebrow, ExternalLink, PageHero, SectionHeading, SiteShell } from "@/components/SiteShell";

const features = [
  { icon: Clock3, href: "/prayer-times", label: "أوقات الصلاة", title: "الوقت الذي يظهر هو الوقت الذي يُجدول.", copy: "يُبنى العرض والتنبيه من نتيجة موحدة تجمع الموقع، المنطقة الزمنية، التعديلات اليدوية ووقت UTC المرسل إلى المنبه.", note: "GPS · المدن العراقية · الإزاحات اليدوية" },
  { icon: BellRing, href: "/adhan", label: "الأذان", title: "تنبيه واضح، مع مسار صلاحيات مفهوم.", copy: "يدعم التطبيق جدولة الأذان، التنبيه المسبق، الاستعادة بعد إعادة التشغيل، وإظهار حالة صلاحية التنبيه الدقيق بوضوح.", note: "Exact alarm · pre-alert · استعادة بعد الإقلاع" },
  { icon: BookMarked, href: "/quran", label: "القرآن", title: "قراءة منظمة تحفظ سياقك.", copy: "استكشف السور في واجهة قراءة هادئة مع بحث وفهرسة ومحتوى مهيأ للعودة إلى موضع القراءة بسهولة.", note: "سور · بحث · قارئ مخصص" },
  { icon: HeartHandshake, href: "/duas", label: "الأدعية والزيارات", title: "محتوى مصنف ليخدم اليوم والمناسبة.", copy: "الأدعية والتعقيبات والزيارات تنظّم في أقسام قابلة للتوسعة، مع مسار واضح لإضافة النصوص وإدارتها من ملف المحتوى المركزي.", note: "أيام · مناسبات · أدعية عامة" },
  { icon: Sparkles, href: "/tasbih", label: "المسبحة", title: "ذكر بتسلسل محفوظ، لا مجرد عدّاد.", copy: "تدعم المسبحة تسبيحة الزهراء بتسلسل 34/33/33، مع انتقال واضح بين المراحل، اهتزاز عند الإكمال وحفظ للتقدم والدورات.", note: "34/33/33 · اهتزاز · حفظ تلقائي" },
  { icon: Settings2, href: "/customize", label: "التخصيص", title: "التطبيق يراعي إيقاع المستخدم.", copy: "اضبط مظهر التطبيق، الألوان، الخطوط والخلفيات بما يلائم بيئة الاستخدام، مع مراعاة الوضع النهاري والليلي.", note: "ألوان · خطوط · سمة" },
];

export default function Features() {
  return <SiteShell><PageHero eyebrow="FEATURES / 01" title="ميزات متصلة بيوم المستخدم، لا قائمة أدوات متجاورة." description="كل مساحة في الذاكرين تؤدي دورًا محددًا: تعرف وقتك، اقرأ، اذكر، ثم عد إلى ما يهمك دون تشتيت." />
    <main className="px-5 py-16 sm:py-24 lg:px-10">
      <div className="mx-auto max-w-[1240px]">
        <SectionHeading title="من التوقيت إلى الذكر، في مسار واحد." copy="صُممت الخصائص لتتشارك نفس اللغة: تفاصيل هادئة، خيارات مفهومة، ومحتوى يبقى قريبًا حين تحتاجه." />
        <div className="mt-14 divide-y divide-[#173a3c]/12 border-y border-[#173a3c]/12">
          {features.map(({ icon: Icon, href, label, title, copy, note }, index) => <article key={label} className="grid gap-6 py-9 md:grid-cols-[92px_1fr_250px] md:items-start">
            <div className="flex items-center gap-3 text-[#b7833f]"><span className="font-plex text-xs">0{index + 1}</span><Icon className="h-6 w-6" /></div>
            <div><p className="font-plex text-[10px] tracking-[0.18em] text-[#b7833f]">{label}</p><h2 className="mt-2 font-kufi text-xl leading-8 text-[#173a3c]">{title}</h2><p className="mt-3 max-w-2xl font-naskh text-xl leading-8 text-[#496869]">{copy}</p></div>
            <div className="border-r-2 border-[#b7833f]/50 pr-4"><p className="font-naskh text-lg leading-7 text-[#577475]">{note}</p><Link href={href} className="mt-4 inline-flex items-center gap-1 font-kufi text-[10px] text-[#b7833f] hover:text-[#9d6a2f]">صفحة الميزة <ArrowUpLeft className="h-3.5 w-3.5" /></Link></div>
          </article>)}
        </div>
      </div>
    </main>
    <section className="bg-[#e9dfcd] px-5 py-14 lg:px-10"><div className="mx-auto grid max-w-[1240px] gap-8 lg:grid-cols-[1fr_.86fr] lg:items-center"><div className="time-visual h-[370px] shadow-[0_24px_50px_rgba(23,58,60,0.14)]"><span className="time-dot" /><p className="font-plex text-[10px] tracking-[.2em] text-[#d7b97f]">PRAYER TIME / SOURCE</p><div className="mt-auto flex items-end justify-between"><div><p className="font-kufi text-xl text-white">وقت واضح</p><p className="mt-2 font-naskh text-lg text-white/65">مصدر الموقع · وقت مدني · تنبيه</p></div><span className="font-plex text-3xl text-[#d7b97f]">01</span></div></div><div><Eyebrow>صورة الوقت</Eyebrow><h2 className="font-kufi text-2xl font-semibold leading-[1.7] text-[#173a3c]">دقة الحساب تحتاج لغة واجهة صريحة.</h2><p className="mt-4 font-naskh text-xl leading-8 text-[#496869]">يوضح التطبيق مصدر الموقع، ويعرض وقتًا مدنيًا مناسبًا للمكان المختار، ويجعل إعدادات التنبيه جزءًا مفهومًا من التجربة.</p><div className="mt-6"><ExternalLink href="/guide">اقرأ دليل إعداد الأذان</ExternalLink></div></div></div></section>
  </SiteShell>;
}

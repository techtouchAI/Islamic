/** Design: «محراب رقمي» — كل ميزة باب مستقل بنبرة تحريرية هادئة، مع مسار رجوع واضح إلى فهرس المزايا. */
import type { LucideIcon } from "lucide-react";
import { BellRing, BookMarked, ChevronLeft, Clock3, HeartHandshake, Settings2, Sparkles } from "lucide-react";
import { Link } from "wouter";
import { Eyebrow, PageHero, SiteShell } from "@/components/SiteShell";

type Detail = {
  icon: LucideIcon;
  label: string;
  title: string;
  description: string;
  lead: string;
  points: string[];
  calloutTitle: string;
  callout: string;
};

const details: Record<string, Detail> = {
  prayer: {
    icon: Clock3,
    label: "PRAYER TIMES / 01",
    title: "أوقات الصلاة: نتيجة واحدة للعرض والتنبيه.",
    description: "عندما تتغير المدينة أو طريقة تحديد الموقع، يحتاج المستخدم إلى معرفة المصدر الذي بُني عليه الوقت. لذلك يضع التطبيق المصدر في الصورة بدل أن يخفيه.",
    lead: "يعتمد الذاكرين مسارًا واحدًا للحساب والعرض والجدولة، بحيث لا تظهر بطاقة وقت لا يطابقها التنبيه الذي حُجز في النظام.",
    points: ["تمييز واضح بين GPS الحي، آخر موقع محفوظ، المدينة المختارة، والافتراضي.", "استخدام سياسة timezone مناسبة للموقع: المدن العراقية ثابتة، وموقع GPS يتبع منطقة الجهاز.", "دعم تعديلات الوقت اليدوية ضمن النتيجة النهائية نفسها دون مسار عرض منفصل."],
    calloutTitle: "نقطة عملية", callout: "بعد اختيار موقع جديد، راجع وقت الصلاة التالي ثم نفّذ اختبارًا قريبًا للتنبيه للتأكد من أن إعداد Android مكتمل." },
  adhan: {
    icon: BellRing,
    label: "ADHAN / 02",
    title: "تنبيهات الأذان: صلاحيات مفهومة واستعادة مدروسة.",
    description: "الأذان في الخلفية يحتاج أكثر من شاشة تبديل. يتعامل التطبيق مع التنبيه الدقيق، التنبيه المسبق، الصوت، والاستعادة بعد أحداث النظام.",
    lead: "يُفصل التنبيه المسبق عن الأذان الفعلي كي لا يُشغّل الصوت في توقيت تحضيري، وتُحفظ سجلات التنبيهات لإعادة بنائها بعد الإقلاع أو تغير التاريخ.",
    points: ["إظهار حالة Exact Alarm وإرشاد المستخدم إلى إعداد النظام إن احتاج ذلك.", "فصل pre-alert عن تشغيل الصوت الفعلي في طبقة Android Native.", "استعادة الجداول بعد boot وتحديث التطبيق وتغير اليوم أو timezone وفق مصدر الموقع."],
    calloutTitle: "ملاحظة Android", callout: "قد تضع بعض الشركات المصنعة قيودًا إضافية على الخلفية. اختبار جهازك وهو مقفل وفي وضع توفير البطارية يظل خطوة مهمة بعد الإعداد." },
  quran: {
    icon: BookMarked,
    label: "QURAN / 03",
    title: "القرآن: قراءة أقرب إلى المقصود، لا مجرد قائمة سور.",
    description: "يعرض التطبيق السور في تجربة قراءة منظمة، مع أدوات وصول إلى النص وخيارات تساعد المستخدم على العودة إلى ما كان يقرأه.",
    lead: "تُحافظ واجهة القرآن على هدوء القراءة وتبقي البحث والتنقل في موضع داعم بدل أن يتحول إلى طبقات تحكم مزاحمة للنص.",
    points: ["فهرسة السور في مسار قراءة مخصص.", "بحث يخدم الوصول إلى المواضع دون تغيير سياق القراءة.", "تصميم محتوى قابل للتوسع ضمن الهيكل العام للتطبيق."],
    calloutTitle: "استخدام مقترح", callout: "اجعل صفحة القرآن نقطة العودة الأساسية من الصفحة الرئيسية، ثم استخدم المفضلة أو البحث للوصول إلى السورة بدل حفظ المسارات ذهنيًا." },
  duas: {
    icon: HeartHandshake,
    label: "DUAS & ZIYARAT / 04",
    title: "الأدعية والزيارات: محتوى مصنف كي يصل في وقته.",
    description: "يضم التطبيق أقسامًا للأدعية العامة وتعقيبات الصلاة وأعمال الأيام والزيارات. يظل كل ذلك قابلًا للإدارة من ملف محتوى مركزي.",
    lead: "القيمة هنا ليست في تخزين النصوص فقط، بل في ترتيبها ليصبح محتوى اليوم أو المناسبة متاحًا من دون تصفح متكرر.",
    points: ["تقسيمات للمحتوى العام وتعقيبات ما بعد الصلاة وأعمال الأيام.", "مسار واضح لإضافة عناصر من content.json ومراجعة بنيتها.", "عناوين مناسبة للفهرسة حتى يظهر دعاء اليوم في سياق متوقع."],
    calloutTitle: "للمحررين", callout: "احرص على معرفات غير متكررة وصيغة JSON سليمة، واستخدم الأسطر الجديدة داخل النص بحذر حتى لا تتضرر القراءة في التطبيق." },
  tasbih: {
    icon: Sparkles,
    label: "TASBIH / 05",
    title: "المسبحة: الذكر محفوظ كرحلة قصيرة.",
    description: "لا تتعامل المسبحة مع كل نقرة كرقم منفصل فقط؛ تحفظ المرحلة والتقدم والدورات المكتملة، وتعرض انتقالات تسبيحة الزهراء بوضوح.",
    lead: "في تسبيحة الزهراء يبدأ التسلسل بـ34 من الله أكبر، ثم 33 من الحمد لله، ثم 33 من سبحان الله؛ يتصفّر عداد المرحلة عند كل انتقال ويبدأ العد الجديد.",
    points: ["state machine مستقلة تمنع زيادة النقرة مرتين أو تضارب الحفظ.", "اهتزاز وتنبيه انتقال عند نهاية كل مرحلة مع حفظ التقدم.", "عداد للدورات المكتملة والذكر التراكمي دون حذف التاريخ عند إعادة ضبط المرحلة."],
    calloutTitle: "كيف تستخدمها", callout: "اختر تسبيحة الزهراء من داخل المسبحة، ثم تابع اسم الذكر والعدد المتبقي؛ لا تحتاج إلى حفظ مكانك يدويًا عند مغادرة التطبيق." },
  customize: {
    icon: Settings2,
    label: "CUSTOMIZATION / 06",
    title: "التخصيص: مظهر يتبع روتينك لا العكس.",
    description: "يتيح التطبيق تغيير السمة والألوان والخطوط والخلفيات، مع مراعاة الوضع النهاري والليلي لتبقى القراءة مريحة في ظروف مختلفة.",
    lead: "التخصيص الجيد يمنح المستخدم إحساسًا بالملكية دون أن يجعل الوظائف الأساسية أصعب في الوصول أو الفهم.",
    points: ["تعديل السمات والخلفيات ضمن واجهة إعدادات منظمة.", "خيارات مظهر تدعم القراءة النهارية والليلية.", "حفظ التفضيلات لتبقى التجربة متسقة عند العودة للتطبيق."],
    calloutTitle: "اقتراح بسيط", callout: "ابدأ بسمة مريحة للقراءة ثم غيّر عنصرًا واحدًا في كل مرة؛ التخصيص الهادئ يحافظ على وضوح شاشات الوقت والمحتوى." },
};

function FeatureDetail({ detail }: { detail: Detail }) {
  const Icon = detail.icon;
  return <SiteShell><PageHero eyebrow={detail.label} title={detail.title} description={detail.description} />
    <main className="px-5 py-16 sm:py-24 lg:px-10"><div className="mx-auto max-w-[1120px]"><Link href="/features" className="inline-flex items-center gap-2 font-kufi text-[11px] text-[#b7833f] hover:text-[#9d6a2f]"><ChevronLeft className="h-4 w-4" /> العودة إلى فهرس المزايا</Link>
      <section className="mt-10 grid gap-9 lg:grid-cols-[150px_1fr]"><div className="grid h-24 w-24 place-items-center rounded-[28px] bg-[#e9dfcd] text-[#b7833f]"><Icon className="h-10 w-10" /></div><div><Eyebrow>كيف تعمل الميزة</Eyebrow><p className="font-naskh text-2xl leading-10 text-[#496869]">{detail.lead}</p></div></section>
      <section className="mt-14 divide-y divide-[#173a3c]/12 border-y border-[#173a3c]/12">{detail.points.map((point, index) => <div key={point} className="grid gap-4 py-6 sm:grid-cols-[75px_1fr]"><span className="font-plex text-xs tracking-[.16em] text-[#b7833f]">0{index + 1}</span><p className="font-naskh text-xl leading-8 text-[#173a3c]">{point}</p></div>)}</section>
      <aside className="mt-12 rounded-[26px] bg-[#173a3c] p-7 text-[#f6f1e7] lg:p-9"><p className="font-plex text-[10px] tracking-[.18em] text-[#d7b97f]">{detail.calloutTitle}</p><p className="mt-4 max-w-3xl font-naskh text-2xl leading-10 text-[#f6f1e7]/83">{detail.callout}</p></aside>
    </div></main>
  </SiteShell>;
}

export const PrayerFeature = () => <FeatureDetail detail={details.prayer} />;
export const AdhanFeature = () => <FeatureDetail detail={details.adhan} />;
export const QuranFeature = () => <FeatureDetail detail={details.quran} />;
export const DuasFeature = () => <FeatureDetail detail={details.duas} />;
export const TasbihFeature = () => <FeatureDetail detail={details.tasbih} />;
export const CustomizeFeature = () => <FeatureDetail detail={details.customize} />;

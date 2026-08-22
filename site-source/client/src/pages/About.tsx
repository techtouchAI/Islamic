/** Design: «محراب رقمي» — تعريف موجز ورصين يشرح الغرض دون ادعاءات تسويقية مبالغ بها. */
import { BookOpenText, Heart, Shield, Waypoints } from "lucide-react";
import { PageHero, SectionHeading, SiteShell } from "@/components/SiteShell";

const principles = [
  { icon: Waypoints, title: "وضوح الطريق", copy: "كل ميزة يجب أن توضح ماذا تفعل، وما المصدر الذي تعتمد عليه، وما الذي يحتاج موافقة المستخدم." },
  { icon: BookOpenText, title: "قرب المحتوى", copy: "القرآن والأدعية والزيارات ليست إضافات ثانوية؛ هي محتوى منظم له موضع وفهرس ومسار تحرير." },
  { icon: Heart, title: "إيقاع إنساني", copy: "الموقع والتطبيق يتركان مساحة للسكينة، ويقدمان المهمة التالية بلا ضغط أو إشعارات مبهمة." },
  { icon: Shield, title: "احترام الإعداد", copy: "الموقع لا يخفي روابط الملفات أو متطلبات التثبيت، والتطبيق يوضح الصلاحيات عندما يصبح وجودها ضروريًا." },
];

export default function About() {
  return <SiteShell><PageHero eyebrow="ABOUT / 06" title="الذاكرين: رفيق يومي منظم، لا واجهة مزدحمة." description="تطبيق عربي مبني بـFlutter يجمع مساحات العبادة الأساسية في تجربة موحدة قابلة للتخصيص." />
    <main className="px-5 py-16 sm:py-24 lg:px-10"><div className="mx-auto max-w-[1240px]"><section className="grid gap-10 border-b border-[#173a3c]/12 pb-16 lg:grid-cols-[1fr_.86fr]"><SectionHeading title="لماذا هذا التطبيق؟" copy="لأن وقت الصلاة والمحتوى والذكر لا يحتاجون إلى واجهات متنافسة. الذاكرين يجمعهم حول مسار واحد: ترى ما تحتاجه، تعدله بوضوح، ثم تعود إلى يومك." /><div className="rounded-[28px] bg-[#e9dfcd] p-7 lg:p-9"><p className="font-plex text-[10px] tracking-[0.18em] text-[#b7833f]">PRODUCT PRINCIPLE</p><p className="mt-5 font-naskh text-3xl leading-[1.65] text-[#173a3c]">«وقت الصلاة، واضح في موضعه الصحيح.»</p></div></section>
      <section className="mt-16"><p className="font-plex text-[10px] tracking-[0.18em] text-[#b7833f]">FOUR PRINCIPLES</p><div className="mt-6 grid gap-x-10 gap-y-0 border-t border-[#173a3c]/12 md:grid-cols-2">{principles.map(({ icon: Icon, title, copy }) => <article key={title} className="border-b border-[#173a3c]/12 py-8"><Icon className="h-6 w-6 text-[#b7833f]" /><h2 className="mt-4 font-kufi text-lg text-[#173a3c]">{title}</h2><p className="mt-3 font-naskh text-xl leading-8 text-[#496869]">{copy}</p></article>)}</div></section>
    </div></main>
  </SiteShell>;
}

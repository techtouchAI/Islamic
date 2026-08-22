/** Design: «واجهة التطبيق الممتدة» — صفحة تنزيل مختصرة، عملية، ومتصلة بالأصل الرسمي للتطبيق. */
import { ArrowUpLeft, Check, Download as DownloadIcon, Github, ShieldCheck } from "lucide-react";
import { OfficialAppFrame } from "@/components/OfficialAppFrame";
import { SiteShell } from "@/components/SiteShell";

const releaseUrl = "https://github.com/techtouchAI/Islamic/releases/tag/v1.0.51-801";

export default function Download() {
  return <SiteShell>
    <main className="download-page section-wrap"><section className="download-hero"><div><p className="section-kicker">ANDROID / RELEASE</p><h1>خذ الذاكرين<br />إلى يومك.</h1><p>النسخة المتاحة تُنشر من GitHub Releases. افتح صفحة الإصدار للحصول على ملف APK الرسمي وملاحظات البناء.</p><a href={releaseUrl} target="_blank" rel="noreferrer" className="primary-action"><DownloadIcon className="h-4 w-4" /> فتح صفحة التنزيل <ArrowUpLeft className="h-4 w-4" /></a></div><div className="download-app-art"><OfficialAppFrame label="RELEASE / 801" compact /></div></section>
      <section className="release-register"><span><b>01</b> SIGNED APK</span><span><b>02</b> VERSION 1.0.51</span><span><b>03</b> BUILD 801</span></section>
      <section className="download-notes"><article><span className="record-number">01 / SIGNATURE</span><ShieldCheck className="h-5 w-5" /><h2>تحديث فوق النسخة السابقة</h2><p>يتطلب التحديث بقاء توقيع التطبيق مطابقًا للنسخة المثبتة. إن اختلف التوقيع، يعامل Android الملف كتطبيق جديد.</p></article><article><span className="record-number">02 / RELEASE</span><Check className="h-5 w-5" /><h2>ملف واضح المصدر</h2><p>تصل صفحة التنزيل إلى الإصدار المنشور مباشرة، دون نسخ رابط APK ثابت قد ينتهي أو يصبح غير صحيح.</p></article><article><span className="record-number">03 / SOURCE</span><Github className="h-5 w-5" /><h2>المشروع والمصادر</h2><p>يمكن مراجعة الشفرة، المحتوى، وسجل التغييرات من المستودع العام في أي وقت.</p></article></section>
      <section className="source-row"><div><p className="section-kicker">SOURCE</p><h2>كل تفصيلة، في مستودع واحد.</h2></div><a href="https://github.com/techtouchAI/Islamic" target="_blank" rel="noreferrer">فتح المستودع <ArrowUpLeft className="h-4 w-4" /></a></section>
    </main>
  </SiteShell>;
}

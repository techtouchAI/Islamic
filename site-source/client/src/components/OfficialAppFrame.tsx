/** Design: «واجهة التطبيق الممتدة» — إطار التطبيق الرسمي هو الكائن البصري المتكرر عبر الموقع. */
import { appAssets } from "@/lib/app-assets";

export function OfficialAppFrame({ label, compact = false }: { label: string; compact?: boolean }) {
  return <div className={`official-app-frame ${compact ? "is-compact" : ""}`}>
    <img src={appAssets.home} alt="خلفية تطبيق الذاكرين الأصلية" className="official-app-background" />
    <div className="official-app-shade" />
    <span className="official-app-register">{label}</span>
    <img src={appAssets.icon} alt="أيقونة تطبيق الذاكرين الرسمية" className="official-app-icon" />
    <div className="official-app-footer"><small>AL-DHAKEREEN</small><b>الذاكرين</b></div>
  </div>;
}

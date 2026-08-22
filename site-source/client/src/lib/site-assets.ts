/** Design: «محراب رقمي» — تحافظ المعاينة على أصولها المؤقتة، بينما تستعمل نسخة GitHub Pages ملفات ثابتة قابلة للنشر. */
const staticBase = import.meta.env.BASE_URL;
const isGitHubPagesBuild = import.meta.env.VITE_GITHUB_PAGES === "true";

export const appMarkSrc = isGitHubPagesBuild
  ? `${staticBase}site-assets/aldhakereen-mark.webp`
  : "/manus-storage/aldhakereen-mark_f69a0f7a.png";

export const heroMihrabSrc = isGitHubPagesBuild
  ? `${staticBase}site-assets/aldhakereen-hero-mihrab.webp`
  : "/manus-storage/aldhakereen-hero-mihrab_595ae51a.jpg";

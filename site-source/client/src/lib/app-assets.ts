/** Design: «واجهة التطبيق الممتدة» — تَستخدم الواجهة أصول الذاكرين الأصلية في جميع البيئات. */
const base = import.meta.env.BASE_URL;
export const isGitHubPagesBuild = import.meta.env.VITE_GITHUB_PAGES === "true";
const staticAsset = (name: string) => `${base}site-assets/${name}`;
const previewAsset = (name: string) => `/manus-storage/${name}`;

export const appAssets = {
  icon: isGitHubPagesBuild ? staticAsset("app-icon.png") : previewAsset("app-icon_ac9c092d.png"),
  home: isGitHubPagesBuild ? staticAsset("app-home.png") : previewAsset("app-home_02aaed42.png"),
  logo: isGitHubPagesBuild ? staticAsset("app-logo.png") : previewAsset("app-logo_20925cfb.png"),
  content: isGitHubPagesBuild ? staticAsset("content.json") : previewAsset("content_275a7c57.json"),
  catalog: isGitHubPagesBuild ? staticAsset("library/catalog.json") : previewAsset("content-catalog_804529fc.json"),
  libraryFile: (file: string) => staticAsset(`library/${file}`),
};

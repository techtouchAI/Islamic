import { Toaster } from "@/components/ui/sonner";
import { TooltipProvider } from "@/components/ui/tooltip";
import { lazy, Suspense } from "react";
import { Route, Router as WouterRouter, Switch } from "wouter";
import ErrorBoundary from "./components/ErrorBoundary";
import { ThemeProvider } from "./contexts/ThemeContext";

/** Design: «محراب رقمي» — التحميل الأول يركز على صفحة المسار المطلوب؛ الصفحات الموسوعية تُحمّل عند زيارتها. */
const NotFound = lazy(() => import("@/pages/NotFound"));
const Home = lazy(() => import("./pages/Home"));
const Features = lazy(() => import("./pages/Features"));
const Guide = lazy(() => import("./pages/Guide"));
const Downloads = lazy(() => import("./pages/Downloads"));
const Content = lazy(() => import("./pages/Content"));
const About = lazy(() => import("./pages/About"));
const PrayerFeature = lazy(() => import("./pages/FeatureDetails").then((module) => ({ default: module.PrayerFeature })));
const AdhanFeature = lazy(() => import("./pages/FeatureDetails").then((module) => ({ default: module.AdhanFeature })));
const QuranFeature = lazy(() => import("./pages/FeatureDetails").then((module) => ({ default: module.QuranFeature })));
const DuasFeature = lazy(() => import("./pages/FeatureDetails").then((module) => ({ default: module.DuasFeature })));
const TasbihFeature = lazy(() => import("./pages/FeatureDetails").then((module) => ({ default: module.TasbihFeature })));
const CustomizeFeature = lazy(() => import("./pages/FeatureDetails").then((module) => ({ default: module.CustomizeFeature })));


function SiteRouter() {
  return (
    <WouterRouter base={import.meta.env.BASE_URL.replace(/\/$/, "")}>
      <Suspense fallback={<div dir="rtl" className="grid min-h-screen place-items-center bg-[#f6f1e7] font-kufi text-sm text-[#173a3c]">جارٍ تجهيز الصفحة…</div>}>
        <Switch>
          <Route path={"/"} component={Home} />
          <Route path={"/features"} component={Features} />
          <Route path={"/prayer-times"} component={PrayerFeature} />
          <Route path={"/adhan"} component={AdhanFeature} />
          <Route path={"/quran"} component={QuranFeature} />
          <Route path={"/duas"} component={DuasFeature} />
          <Route path={"/tasbih"} component={TasbihFeature} />
          <Route path={"/customize"} component={CustomizeFeature} />
          <Route path={"/guide"} component={Guide} />
          <Route path={"/downloads"} component={Downloads} />
          <Route path={"/content"} component={Content} />
          <Route path={"/about"} component={About} />
          <Route path={"/404"} component={NotFound} />
          <Route component={NotFound} />
        </Switch>
      </Suspense>
    </WouterRouter>
  );
}

// NOTE: About Theme
// - First choose a default theme according to your design style (dark or light bg), than change color palette in index.css
//   to keep consistent foreground/background color across components
// - If you want to make theme switchable, pass `switchable` ThemeProvider and use `useTheme` hook

function App() {
  return (
    <ErrorBoundary>
      <ThemeProvider
        defaultTheme="light"
        // switchable
      >
        <TooltipProvider>
          <Toaster />
          <SiteRouter />
        </TooltipProvider>
      </ThemeProvider>
    </ErrorBoundary>
  );
}

export default App;

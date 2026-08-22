import { Toaster } from "@/components/ui/sonner";
import { TooltipProvider } from "@/components/ui/tooltip";
import { lazy, Suspense } from "react";
import { Route, Router as WouterRouter, Switch } from "wouter";
import ErrorBoundary from "./components/ErrorBoundary";
import { ThemeProvider } from "./contexts/ThemeContext";

/** Design: «واجهة التطبيق الممتدة» — أربع وجهات واضحة، مع تحميل المكتبة عند الطلب. */
const Home = lazy(() => import("./pages/Home"));
const Library = lazy(() => import("./pages/Library"));
const Download = lazy(() => import("./pages/Download"));
const About = lazy(() => import("./pages/About"));
const NotFound = lazy(() => import("@/pages/NotFound"));

function SiteRouter() {
  return <WouterRouter base={import.meta.env.BASE_URL.replace(/\/$/, "")}><Suspense fallback={<div dir="rtl" className="app-loading">جارٍ تجهيز الصفحة…</div>}><Switch><Route path="/" component={Home} /><Route path="/library" component={Library} /><Route path="/download" component={Download} /><Route path="/about" component={About} /><Route component={NotFound} /></Switch></Suspense></WouterRouter>;
}

export default function App() {
  return <ErrorBoundary><ThemeProvider defaultTheme="light"><TooltipProvider><Toaster /><SiteRouter /></TooltipProvider></ThemeProvider></ErrorBoundary>;
}

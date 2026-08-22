import { createRoot } from "react-dom/client";
import App from "./App";
import "./index.css";

// GitHub Pages يعيد المسارات المباشرة إلى 404.html؛ نستعيد المسار داخل SPA بعد تحميل index.html.
const requestedRoute = new URLSearchParams(window.location.search).get("route");
if (requestedRoute) {
  const cleanRoute = requestedRoute.replace(/^\/+/, "");
  const base = import.meta.env.BASE_URL.replace(/\/$/, "");
  window.history.replaceState(null, "", `${base}/${cleanRoute}`);
}

createRoot(document.getElementById("root")!).render(<App />);

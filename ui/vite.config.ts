import { defineConfig } from "vite";
import react from "@vitejs/plugin-react";

// https://vitejs.dev/config/
export default defineConfig({
	plugins: [react()],
	css: {
		preprocessorOptions: {
			// Dart Sass のレガシー JS API 非推奨警告(legacy-js-api)を解消するためモダン API を使用
			scss: { api: "modern-compiler" },
		},
	},
	build: {
		// webpack 時代の target: ["web", "es2015"] に倣い ES2015 を維持
		target: "es2015",
		// 出力先は ui/dist（デプロイ時は ui/dist を document root として配信）
		outDir: "dist",
	},
});

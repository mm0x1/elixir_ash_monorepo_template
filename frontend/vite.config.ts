import { loadEnv, defineConfig } from "vite";
import react from "@vitejs/plugin-react";
import path from "path";

export default defineConfig(({ mode }) => {
  // Load .env from project root (parent directory)
  const env = loadEnv(mode, path.resolve(__dirname, '..'), '');

  return {
    plugins: [react()],
    build: {
      outDir: "../priv/static",
      target: ["es2022"],
      sourcemap: mode === 'development',
      rollupOptions: {
        input: "src/main.tsx",
        output: {
          assetFileNames: "assets/[name][extname]",
          chunkFileNames: "assets/[name].[hash].js",
          entryFileNames: "assets/[name].js",
          manualChunks: {
            'react-vendor': ['react', 'react-dom'],
            'react-query': ['@tanstack/react-query'],
            'inertia': ['@inertiajs/react'],
          },
        },
        // Exclude test files from production builds
        external: mode === 'production' ? [/\.test\.(ts|tsx|js|jsx)$/] : [],
      },
      commonjsOptions: {
        exclude: [],
      },
    },
    test: {
      globals: true,
      environment: 'jsdom',
    },
    resolve: {
      alias: {
        '@': path.resolve(__dirname, './src'),
      },
      conditions: mode === 'test' ? ['browser'] : [],
    },
    define: {
      __APP_ENV__: JSON.stringify(env.NODE_ENV || mode),
    },
  }
})
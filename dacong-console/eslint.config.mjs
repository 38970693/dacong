import { defineConfig, globalIgnores } from "eslint/config";
import nextVitals from "eslint-config-next/core-web-vitals";
import nextTs from "eslint-config-next/typescript";

const eslintConfig = defineConfig([
  ...nextVitals,
  ...nextTs,
  {
    rules: {
      // Disable strict type rules for rapid iteration
      "@typescript-eslint/no-explicit-any": "off",
      "@typescript-eslint/ban-ts-comment": "off",
      // Allow unescaped quotes in JSX (common pattern in Chinese text)
      "react/no-unescaped-entities": "off",
      // Allow setState in useEffect (common pattern in Next.js data fetching)
      "react-hooks/set-state-in-effect": "off",
      // Allow hoisted function calls in useEffect (common pattern)
      "no-use-before-define": "off",
    },
  },
  // Override default ignores of eslint-config-next.
  globalIgnores([
    // Default ignores of eslint-config-next:
    ".next/**",
    "out/**",
    "build/**",
    "next-env.d.ts",
  ]),
]);

export default eslintConfig;
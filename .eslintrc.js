module.exports = {
  env: {
    browser: false,
    es2021: true,
    mocha: true,
    node: true,
  },
  plugins: ["@typescript-eslint", "prettier"],
  extends: ["standard", "plugin:node/recommended", "plugin:prettier/recommended"],
  parser: "@typescript-eslint/parser",
  parserOptions: {
    ecmaVersion: 12,
  },
  rules: {
    "node/no-unsupported-features/es-syntax": ["error", { ignores: ["modules"] }],
    "prettier/prettier": ["error", {}],
    "arrow-body-style": "off",
    "prefer-arrow-callback": "off",
    "node/no-missing-import": [
      "error",
      {
        allowModules: [],
        resolvePaths: ["node_modules", "./test"],
        tryExtensions: [".ts", ".js"],
      },
    ],
    "no-unused-expressions": "off",
  },
};

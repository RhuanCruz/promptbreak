export const siteConfig = {
  name: "PromptBreak",
  downloadUrl: "https://github.com/RhuanCruz/promptbreak/releases/latest/download/PromptBreak.0.1.0.dmg",
  demoVideoUrl: "", // TODO: replace with real video URL
  checkout: {
    usd: "https://buy.stripe.com/8x2bJ12iMeGHh172874gg02",
    brl: "https://buy.stripe.com/00weVdbTm2XZ9yF6on4gg01",
  },
  priceByLocale: {
    en: { amount: "$9.99", currency: "USD", checkoutKey: "usd" as const },
    "pt-BR": { amount: "R$12,90", currency: "BRL", checkoutKey: "brl" as const },
  },
}

export type Locale = "en" | "pt-BR"

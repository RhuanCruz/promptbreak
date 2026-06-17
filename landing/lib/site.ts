export const siteConfig = {
  name: "PromptBreak",
  downloadUrl: "#", // TODO: replace with GitHub Releases / R2 URL
  demoVideoUrl: "", // TODO: replace with real video URL
  checkout: {
    usd: "https://buy.stripe.com/test_eVq6oH5uYgOPfX3fYX4gg00",
    brl: "https://buy.stripe.com/test_eVq6oH5uYgOPfX3fYX4gg00", // TODO: replace with BRL link
  },
  priceByLocale: {
    en: { amount: "$9.99", currency: "USD", checkoutKey: "usd" as const },
    "pt-BR": { amount: "R$12,90", currency: "BRL", checkoutKey: "brl" as const },
  },
}

export type Locale = "en" | "pt-BR"

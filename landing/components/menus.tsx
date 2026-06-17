"use client"

import { useTranslations } from "next-intl"

export function Menus() {
  const t = useTranslations("header")

  const links = [
    { label: t("nav_how"), href: "#how-it-works" },
    { label: t("nav_pricing"), href: "#pricing" },
    { label: t("nav_faq"), href: "#faq" },
  ]

  return (
    <nav className="flex items-center gap-6">
      {links.map((link) => (
        <a
          key={link.href}
          href={link.href}
          className="text-muted-foreground hover:text-foreground text-xs font-medium transition-colors"
        >
          {link.label}
        </a>
      ))}
    </nav>
  )
}

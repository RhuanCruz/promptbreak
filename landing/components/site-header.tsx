"use client"

import Link from "next/link"
import Image from "next/image"
import { useTranslations, useLocale } from "next-intl"
import { LocaleSwitcher } from "./locale-switcher"
import { siteConfig } from "@/lib/site"

export function SiteHeader() {
  const t = useTranslations("nav")
  const locale = useLocale()

  return (
    <header className="fixed top-0 left-0 right-0 z-50 bg-white/90 backdrop-blur-md border-b border-black/5">
      <div className="max-w-6xl mx-auto px-6 h-16 flex items-center justify-between">
        <Link href={`/${locale}`} className="flex items-center gap-2">
          <Image
            src="/logo.png"
            alt="PromptBreak"
            width={28}
            height={28}
            className="rounded-md"
          />
          <span className="font-bold text-[15px] text-[#141414]" style={{ fontFamily: "var(--font-nunito)" }}>
            PromptBreak
          </span>
        </Link>

        <nav className="hidden md:flex items-center gap-7">
          <a href="#pricing" className="text-sm font-medium text-[#5B5B5B] hover:text-[#141414] transition-colors">
            {t("pricing")}
          </a>
          <a href="#faq" className="text-sm font-medium text-[#5B5B5B] hover:text-[#141414] transition-colors">
            {t("faq")}
          </a>
          <LocaleSwitcher />
          <a
            href={siteConfig.downloadUrl}
            className="px-4 py-2 rounded-full text-sm font-semibold text-white transition-colors"
            style={{ backgroundColor: "var(--brand)" }}
            onMouseEnter={e => (e.currentTarget.style.backgroundColor = "var(--brand-hover)")}
            onMouseLeave={e => (e.currentTarget.style.backgroundColor = "var(--brand)")}
          >
            {t("download")}
          </a>
        </nav>

        <div className="md:hidden">
          <LocaleSwitcher />
        </div>
      </div>
    </header>
  )
}

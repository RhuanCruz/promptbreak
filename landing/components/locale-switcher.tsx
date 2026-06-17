"use client"

import { useLocale } from "next-intl"
import { useRouter, usePathname } from "next/navigation"

export function LocaleSwitcher() {
  const locale = useLocale()
  const router = useRouter()
  const pathname = usePathname()

  const toggle = () => {
    const next = locale === "en" ? "pt-BR" : "en"
    const segments = pathname.split("/")
    segments[1] = next
    router.push(segments.join("/"))
  }

  return (
    <button
      onClick={toggle}
      className="text-sm font-medium text-[#5B5B5B] hover:text-[#141414] transition-colors"
    >
      {locale === "en" ? "PT" : "EN"}
    </button>
  )
}

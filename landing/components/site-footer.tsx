import { getTranslations } from "next-intl/server"
import Image from "next/image"

export async function SiteFooter() {
  const t = await getTranslations("footer")

  return (
    <footer className="border-t border-black/5 py-12">
      <div className="max-w-6xl mx-auto px-6 flex flex-col md:flex-row items-center justify-between gap-6">
        <div className="flex items-center gap-2">
          <Image src="/logo.png" alt="PromptBreak" width={24} height={24} className="rounded" />
          <span className="text-sm font-semibold text-[#141414]" style={{ fontFamily: "var(--font-nunito)" }}>
            PromptBreak
          </span>
          <span className="text-sm text-[#5B5B5B] ml-2">— {t("tagline")}</span>
        </div>
        <p className="text-xs text-[#5B5B5B]">{t("copyright")}</p>
      </div>
    </footer>
  )
}

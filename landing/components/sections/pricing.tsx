"use client"

import { useTranslations, useLocale } from "next-intl"
import { Check, Zap } from "lucide-react"
import { siteConfig, type Locale } from "@/lib/site"

export function Pricing() {
  const t = useTranslations("pricing")
  const locale = useLocale() as Locale

  const priceInfo = siteConfig.priceByLocale[locale] ?? siteConfig.priceByLocale.en
  const checkoutUrl = siteConfig.checkout[priceInfo.checkoutKey]

  const features: string[] = t.raw("features") as string[]

  return (
    <section id="pricing" className="py-24 px-6 bg-[#FAFAFA]">
      <div className="max-w-6xl mx-auto text-center">
        <p className="text-xs font-bold tracking-widest text-[#5B5B5B] mb-3">{t("eyebrow")}</p>
        <h2
          className="text-4xl font-extrabold text-[#141414] mb-14"
          style={{ fontFamily: "var(--font-nunito)" }}
        >
          {t("title")}
        </h2>

        <div className="flex justify-center">
          <div className="w-full max-w-sm rounded-3xl border border-black/8 bg-white p-8 shadow-sm flex flex-col gap-6 text-left">
            {/* Plan header */}
            <div className="flex items-center justify-between">
              <div>
                <p className="text-xs font-bold tracking-widest text-[#5B5B5B] uppercase mb-1">
                  {t("plan_name")}
                </p>
                <p className="text-4xl font-extrabold text-[#141414]" style={{ fontFamily: "var(--font-nunito)" }}>
                  {priceInfo.amount}
                </p>
                <p className="text-sm text-[#5B5B5B] mt-1">{t("plan_label")}</p>
              </div>
              <div
                className="w-12 h-12 rounded-2xl flex items-center justify-center"
                style={{ backgroundColor: "rgba(255,117,38,0.12)" }}
              >
                <Zap className="w-6 h-6" style={{ color: "var(--brand)" }} />
              </div>
            </div>

            <div className="h-px bg-black/6" />

            {/* Features */}
            <ul className="flex flex-col gap-3">
              {features.map((f, i) => (
                <li key={i} className="flex items-start gap-3">
                  <div
                    className="w-5 h-5 rounded-full flex items-center justify-center shrink-0 mt-0.5"
                    style={{ backgroundColor: "rgba(255,117,38,0.12)" }}
                  >
                    <Check className="w-3 h-3" style={{ color: "var(--brand)" }} />
                  </div>
                  <span className="text-sm text-[#141414]">{f}</span>
                </li>
              ))}
            </ul>

            {/* CTA */}
            <a
              href={checkoutUrl}
              className="w-full py-3.5 rounded-2xl text-center text-sm font-bold text-white transition-colors mt-2"
              style={{ backgroundColor: "var(--brand)" }}
              onMouseEnter={e => (e.currentTarget.style.backgroundColor = "var(--brand-hover)")}
              onMouseLeave={e => (e.currentTarget.style.backgroundColor = "var(--brand)")}
            >
              {t("cta")}
            </a>
          </div>
        </div>
      </div>
    </section>
  )
}

"use client"

import Link from "next/link"
import { useTranslations, useLocale } from "next-intl"

import { Button } from "@/components/ui/button"
import { siteConfig } from "@/lib/site"

const Cta1 = () => {
  const t = useTranslations("cta")
  const locale = useLocale()
  const { checkoutKey } = siteConfig.priceByLocale[locale as "en" | "pt-BR"] ?? siteConfig.priceByLocale.en
  const checkoutUrl = siteConfig.checkout[checkoutKey]

  return (
    <section id="pricing" className="relative py-10">
      <div className="mx-auto max-w-5xl px-6">
        <div className="pointer-events-none absolute inset-0 overflow-hidden">
          <div className="absolute inset-0 border-x [mask-image:linear-gradient(black,transparent)]" />
          <div className="absolute inset-y-0 left-1/2 w-[1200px] -translate-x-1/2">
            <svg
              className="pointer-events-none absolute inset-0 [mask-image:linear-gradient(black,transparent),radial-gradient(black,transparent)] [mask-composite:intersect] text-black/20 dark:text-white/20"
              width="100%"
              height="100%"
            >
              <defs>
                <pattern
                  id="cta-grid"
                  x="-1"
                  y="-1"
                  width="60"
                  height="60"
                  patternUnits="userSpaceOnUse"
                >
                  <path
                    d="M 60 0 L 0 0 0 60"
                    fill="transparent"
                    stroke="currentColor"
                    strokeWidth="1"
                  />
                </pattern>
              </defs>
              <rect fill="url(#cta-grid)" width="100%" height="100%" />
            </svg>
          </div>
        </div>

        <div className="relative z-10 flex flex-col items-center px-4 pt-24 pb-32 text-center">
          <h2 className="font-display max-w-lg text-4xl font-semibold text-balance sm:text-5xl tracking-tight">
            {t("headline").split("\n").map((line, i) => (
              <span key={i} className="block">{line}</span>
            ))}
          </h2>
          <p className="text-muted-foreground mt-6 max-w-[480px] text-lg font-medium">
            {t("sub")}
          </p>

          <div className="mt-10 flex items-center justify-center">
            <Button
              size="lg"
              render={<Link href={checkoutUrl} target="_blank" />}
              nativeButton={false}
            >
              {t("cta_primary")}
            </Button>
          </div>
        </div>
      </div>
    </section>
  )
}

export default Cta1

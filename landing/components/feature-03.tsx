"use client"

import { useTranslations } from "next-intl"
import { DotPattern } from "@/components/dot-pattern"

export default function Feature03() {
  const t = useTranslations("feature")

  return (
    <div className="container flex w-full flex-col items-center justify-center py-24">
      <div className="border-primary relative flex flex-col items-center rounded-md border">
        <DotPattern dotSize={0.5} width={5} height={5} />

        <div className="bg-primary absolute -top-1.5 -left-1.5 h-3 w-3 rounded-md" />
        <div className="bg-primary absolute -bottom-1.5 -left-1.5 h-3 w-3 rounded-md" />
        <div className="bg-primary absolute -top-1.5 -right-1.5 h-3 w-3 rounded-md" />
        <div className="bg-primary absolute -right-1.5 -bottom-1.5 h-3 w-3 rounded-md" />

        <div className="relative p-10 md:py-20">
          <p className="md:text-md text-primary text-xs lg:text-lg xl:text-2xl">
            {t("label")}
          </p>
          <div className="text-2xl tracking-tighter md:text-5xl lg:text-7xl xl:text-8xl">
            <div className="flex gap-1 md:gap-2 lg:gap-3 xl:gap-4">
              <h1 className="font-semibold">{t("quote_line1")}</h1>
            </div>
            <div className="flex gap-1 md:gap-2 lg:gap-3 xl:gap-4">
              <p className="font-thin">{t("quote_line2")}</p>
            </div>
            <div className="flex gap-1 md:gap-2 lg:gap-3 xl:gap-4">
              <h1 className="font-semibold">{t("quote_line3")}</h1>
            </div>
          </div>
        </div>
      </div>
    </div>
  )
}

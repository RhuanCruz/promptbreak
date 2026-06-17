"use client"

import Image from "next/image"
import Link from "next/link"
import { ArrowRight } from "@aliimam/icons"
import { useTranslations } from "next-intl"

import { Button } from "@/components/ui/button"
import { siteConfig } from "@/lib/site"

export default function HeroDemo() {
  const t = useTranslations("hero")

  return (
    <div className="relative flex min-h-svh w-full flex-col items-center justify-center overflow-hidden">
      <div
        className="absolute inset-0 z-0"
        style={{
          background:
            "radial-gradient(ellipse at 50% 0%, var(--primary) 0%, var(--background) 70%), linear-gradient(to bottom, rgba(255,255,255,0) 50%, var(--background) 100%)",
          opacity: 0.8,
        }}
      >
        <div
          style={{
            WebkitMaskImage:
              "linear-gradient(to bottom, rgba(0,0,0,0.4) 0%, rgba(0,0,0,0) 75%)",
            backgroundImage:
              "repeating-linear-gradient(90deg, var(--primary) 0px, var(--primary) 1px, transparent 1px, transparent 24px)",
            height: "70%",
            left: "50%",
            maskImage:
              "linear-gradient(to bottom, rgba(0,0,0,0.4) 0%, rgba(0,0,0,0) 75%)",
            pointerEvents: "none",
            position: "absolute",
            top: "0",
            transform: "translateX(-50%)",
            width: "100%",
          }}
        />
      </div>
      <div className="z-30 h-screen pt-20">
        <div className="px-5 text-center sm:px-8 md:px-6 lg:px-0">
          {/* Pill */}
          <div>
            <Link
              href={t("pill_href")}
              className="hover:bg-background dark:hover:border-t-border bg-muted group mx-auto flex w-fit items-center gap-4 rounded-full border p-1 pl-4 shadow-md shadow-zinc-950/5 transition-colors duration-300 dark:border-t-white/5 dark:shadow-zinc-950"
            >
              <span className="text-foreground text-sm">{t("pill")}</span>
              <span className="dark:border-background block h-4 w-0.5 border-l bg-white dark:bg-zinc-700" />
              <div className="bg-background group-hover:bg-muted size-6 overflow-hidden rounded-full duration-500">
                <div className="flex w-12 -translate-x-1/2 duration-500 ease-in-out group-hover:translate-x-0">
                  <span className="flex size-6">
                    <ArrowRight className="m-auto size-3" />
                  </span>
                  <span className="flex size-6">
                    <ArrowRight className="m-auto size-3" />
                  </span>
                </div>
              </div>
            </Link>
          </div>

          {/* Headline */}
          <h1 className="mx-auto mt-6 max-w-3xl text-4xl font-semibold tracking-tighter uppercase sm:text-5xl md:text-6xl lg:mt-12 xl:text-[5.25rem]">
            {t("headline").split("\n").map((line, i) => (
              <span key={i} className="block">
                {line}
              </span>
            ))}
          </h1>

          {/* Sub */}
          <p className="mx-auto mt-5 max-w-xl px-2 text-base text-white/80 sm:text-lg sm:px-0">
            {t("sub")}
          </p>

          {/* CTAs */}
          <div className="mt-8 flex flex-col items-center justify-center gap-2 sm:flex-row">
            <Button
              size="lg"
              className="w-full px-5 text-base sm:w-auto"
              render={<Link href={siteConfig.downloadUrl} />}
              nativeButton={false}
            >
              <span className="text-nowrap">{t("cta_primary")}</span>
            </Button>
            <Button
              size="lg"
              variant="ghost"
              className="w-full px-5 sm:w-auto"
              render={<Link href={siteConfig.demoVideoUrl || "#demo"} />}
              nativeButton={false}
            >
              <span className="text-nowrap">{t("cta_secondary")}</span>
            </Button>
          </div>
        </div>

        {/* Demo video */}
        <div className="relative mt-8 overflow-hidden px-4 sm:mt-12 sm:px-6 md:mt-16 md:px-8 lg:px-0">
          <div
            aria-hidden
            className="to-background absolute inset-0 z-10 bg-linear-to-b from-transparent from-35%"
          />
          <div className="ring-background bg-background relative mx-auto w-full max-w-4xl overflow-hidden rounded-2xl border shadow-lg ring-1 shadow-zinc-950/15 dark:inset-shadow-white/20">
            <Image
              src="/app-screenshot.png"
              alt="PromptBreak app screenshot"
              width={1456}
              height={816}
              className="w-full h-auto"
              priority
            />
          </div>
        </div>
      </div>
    </div>
  )
}

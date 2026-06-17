"use client"

import { useState } from "react"
import { useTranslations } from "next-intl"
import { Badge } from "@/components/ui/badge"
import { Play, Download } from "lucide-react"
import { VideoDialog } from "@/components/video-dialog"
import { siteConfig } from "@/lib/site"

export function Hero() {
  const t = useTranslations("hero")
  const [videoOpen, setVideoOpen] = useState(false)

  const headline = t("headline").split("\n")

  return (
    <section className="pt-32 pb-24 px-6">
      <div className="max-w-6xl mx-auto">
        <div className="flex flex-col lg:flex-row items-center gap-16">
          {/* Left: copy */}
          <div className="flex-1 flex flex-col items-start gap-6 max-w-lg">
            <Badge
              variant="outline"
              className="rounded-full text-xs font-semibold px-3 py-1 border-black/10 text-[#5B5B5B]"
            >
              {t("badge")}
            </Badge>

            <h1
              className="text-5xl md:text-6xl font-extrabold leading-tight text-[#141414]"
              style={{ fontFamily: "var(--font-nunito)" }}
            >
              {headline.map((line, i) => (
                <span key={i}>
                  {line}
                  {i < headline.length - 1 && <br />}
                </span>
              ))}
            </h1>

            <p className="text-lg text-[#5B5B5B] leading-relaxed">{t("sub")}</p>

            <div className="flex flex-wrap items-center gap-3 mt-2">
              <a
                href={siteConfig.downloadUrl}
                className="inline-flex items-center gap-2 px-5 py-3 rounded-full text-sm font-semibold text-white transition-colors"
                style={{ backgroundColor: "var(--brand)" }}
                onMouseEnter={e => (e.currentTarget.style.backgroundColor = "var(--brand-hover)")}
                onMouseLeave={e => (e.currentTarget.style.backgroundColor = "var(--brand)")}
              >
                <Download className="w-4 h-4" />
                {t("cta_download")}
              </a>
              <button
                onClick={() => setVideoOpen(true)}
                className="inline-flex items-center gap-2 px-5 py-3 rounded-full text-sm font-semibold text-[#141414] border border-black/10 hover:border-black/20 transition-colors bg-white"
              >
                <Play className="w-4 h-4" />
                {t("cta_video")}
              </button>
            </div>
          </div>

          {/* Right: app screenshot placeholder */}
          <div className="flex-1 flex items-center justify-center w-full max-w-md lg:max-w-none">
            <div
              className="relative w-full max-w-sm aspect-[3/4] rounded-3xl overflow-hidden flex items-center justify-center"
              style={{ backgroundColor: "#16161A" }}
            >
              {/* Play overlay */}
              <button
                onClick={() => setVideoOpen(true)}
                className="absolute inset-0 flex items-center justify-center group"
              >
                <div className="w-16 h-16 rounded-full bg-white/10 backdrop-blur-sm flex items-center justify-center group-hover:bg-white/20 transition-colors">
                  <Play className="w-7 h-7 text-white fill-white ml-1" />
                </div>
              </button>
              <p className="text-white/20 text-xs text-center px-8 pointer-events-none select-none">
                App screenshot
              </p>
            </div>
          </div>
        </div>
      </div>

      <VideoDialog
        open={videoOpen}
        onOpenChange={setVideoOpen}
        videoUrl={siteConfig.demoVideoUrl}
      />
    </section>
  )
}

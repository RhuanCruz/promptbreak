import { getTranslations } from "next-intl/server"
import { ShieldCheck } from "lucide-react"

export async function CameraOverlay() {
  const t = await getTranslations("camera")

  return (
    <section className="py-24 px-6">
      <div className="max-w-6xl mx-auto">
        <div className="flex flex-col lg:flex-row-reverse items-center gap-16">
          {/* Right: copy */}
          <div className="flex-1 flex flex-col gap-6 max-w-md">
            <p className="text-xs font-bold tracking-widest text-[#5B5B5B]">{t("eyebrow")}</p>
            <h2
              className="text-4xl font-extrabold text-[#141414] leading-tight"
              style={{ fontFamily: "var(--font-nunito)" }}
            >
              {t("title")}
            </h2>
            <p className="text-base text-[#5B5B5B] leading-relaxed">{t("sub")}</p>

            <div className="flex items-center gap-2 mt-2">
              <ShieldCheck className="w-4 h-4 shrink-0" style={{ color: "var(--brand)" }} />
              <span className="text-sm text-[#5B5B5B]">All processing happens on-device via Apple Vision</span>
            </div>
          </div>

          {/* Left: camera overlay screenshot placeholder */}
          <div className="flex-1 flex justify-center lg:justify-start">
            <div
              className="w-full max-w-xs aspect-[3/4] rounded-3xl flex items-center justify-center"
              style={{ backgroundColor: "#16161A" }}
            >
              <p className="text-white/20 text-xs text-center px-8 select-none">
                Camera overlay screenshot
              </p>
            </div>
          </div>
        </div>
      </div>
    </section>
  )
}

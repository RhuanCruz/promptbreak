import { getTranslations } from "next-intl/server"
import { Clock, Shield, BarChart3 } from "lucide-react"

export async function TodayScreen() {
  const t = await getTranslations("today")

  const callouts = [
    { icon: Clock, label: t("callout1") },
    { icon: Shield, label: t("callout2") },
    { icon: BarChart3, label: t("callout3") },
  ]

  return (
    <section className="py-24 px-6">
      <div className="max-w-6xl mx-auto">
        <div className="flex flex-col lg:flex-row items-center gap-16">
          {/* Left: copy */}
          <div className="flex-1 flex flex-col gap-6 max-w-md">
            <p className="text-xs font-bold tracking-widest text-[#5B5B5B]">{t("eyebrow")}</p>
            <h2
              className="text-4xl font-extrabold text-[#141414] leading-tight"
              style={{ fontFamily: "var(--font-nunito)" }}
            >
              {t("title")}
            </h2>
            <p className="text-base text-[#5B5B5B] leading-relaxed">{t("sub")}</p>

            <ul className="flex flex-col gap-3 mt-2">
              {callouts.map(({ icon: Icon, label }) => (
                <li key={label} className="flex items-center gap-3">
                  <div
                    className="w-8 h-8 rounded-lg flex items-center justify-center shrink-0"
                    style={{ backgroundColor: "rgba(255,117,38,0.1)" }}
                  >
                    <Icon className="w-4 h-4" style={{ color: "var(--brand)" }} />
                  </div>
                  <span className="text-sm font-medium text-[#141414]">{label}</span>
                </li>
              ))}
            </ul>
          </div>

          {/* Right: app screenshot placeholder */}
          <div className="flex-1 flex justify-center lg:justify-end">
            <div
              className="w-full max-w-xs aspect-[3/4] rounded-3xl flex items-center justify-center"
              style={{ backgroundColor: "#16161A" }}
            >
              <p className="text-white/20 text-xs text-center px-8 select-none">
                Today screen screenshot
              </p>
            </div>
          </div>
        </div>
      </div>
    </section>
  )
}

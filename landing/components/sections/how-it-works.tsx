import { getTranslations } from "next-intl/server"
import { Timer, ShieldOff, Camera } from "lucide-react"

const icons = [Timer, ShieldOff, Camera]

export async function HowItWorks() {
  const t = await getTranslations("how")

  const steps = [
    { key: "step1", title: t("step1_title"), desc: t("step1_desc") },
    { key: "step2", title: t("step2_title"), desc: t("step2_desc") },
    { key: "step3", title: t("step3_title"), desc: t("step3_desc") },
  ]

  return (
    <section className="py-24 px-6 bg-[#FAFAFA]">
      <div className="max-w-6xl mx-auto">
        <p className="text-xs font-bold tracking-widest text-[#5B5B5B] mb-3">{t("eyebrow")}</p>
        <h2
          className="text-4xl font-extrabold text-[#141414] mb-14"
          style={{ fontFamily: "var(--font-nunito)" }}
        >
          {t("title")}
        </h2>

        <div className="grid md:grid-cols-3 gap-6">
          {steps.map((step, i) => {
            const Icon = icons[i]
            return (
              <div
                key={step.key}
                className="rounded-2xl p-8 flex flex-col gap-5"
                style={{ backgroundColor: "#16161A" }}
              >
                <div className="flex items-center gap-3">
                  <div
                    className="w-9 h-9 rounded-xl flex items-center justify-center shrink-0"
                    style={{ backgroundColor: "rgba(255,117,38,0.15)" }}
                  >
                    <Icon className="w-5 h-5" style={{ color: "var(--brand)" }} />
                  </div>
                  <span
                    className="text-4xl font-black leading-none"
                    style={{ color: "rgba(255,255,255,0.08)", fontFamily: "var(--font-nunito)" }}
                  >
                    {String(i + 1).padStart(2, "0")}
                  </span>
                </div>
                <div>
                  <h3 className="text-base font-bold text-white mb-2">{step.title}</h3>
                  <p className="text-sm text-white/50 leading-relaxed">{step.desc}</p>
                </div>
              </div>
            )
          })}
        </div>
      </div>
    </section>
  )
}

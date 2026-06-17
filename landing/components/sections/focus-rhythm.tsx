import { getTranslations } from "next-intl/server"
import { Terminal, MousePointer2, Code2, Sparkles } from "lucide-react"

const TOOLS = [
  { icon: Terminal, name: "Terminal" },
  { icon: MousePointer2, name: "Cursor" },
  { icon: Code2, name: "VS Code" },
  { icon: Sparkles, name: "Claude" },
]

const DAYS = ["Mon", "Tue", "Wed", "Thu", "Fri", "Sat", "Sun"]
const WEEKS = 18

const HEAT_SEED = [
  0, 0, 1, 2, 1, 0, 0,
  0, 2, 3, 4, 2, 0, 0,
  1, 3, 4, 4, 3, 1, 0,
  0, 1, 2, 3, 2, 1, 0,
  0, 0, 1, 2, 4, 0, 0,
  0, 1, 3, 4, 3, 2, 0,
  0, 2, 4, 4, 4, 1, 0,
  1, 3, 3, 4, 2, 0, 0,
  0, 0, 2, 3, 3, 1, 0,
  0, 1, 2, 4, 4, 2, 0,
  0, 0, 1, 3, 2, 0, 0,
  0, 2, 4, 4, 3, 1, 0,
  1, 3, 4, 4, 4, 2, 0,
  0, 1, 2, 3, 1, 0, 0,
  0, 0, 1, 4, 3, 1, 0,
  0, 2, 3, 4, 4, 2, 0,
  1, 2, 4, 4, 3, 0, 0,
  0, 0, 1, 2, 1, 0, 0,
]

function heatColor(v: number) {
  switch (v) {
    case 0: return "rgba(255,255,255,0.06)"
    case 1: return "rgba(255,117,38,0.25)"
    case 2: return "rgba(255,117,38,0.45)"
    case 3: return "rgba(255,117,38,0.7)"
    case 4: return "#FF7526"
    default: return "rgba(255,255,255,0.06)"
  }
}

export async function FocusRhythm() {
  const t = await getTranslations("rhythm")

  return (
    <section className="py-24 px-6" style={{ backgroundColor: "#FAFAFA" }}>
      <div className="max-w-6xl mx-auto">
        <p className="text-xs font-bold tracking-widest text-[#5B5B5B] mb-3">{t("eyebrow")}</p>
        <h2
          className="text-4xl font-extrabold text-[#141414] mb-4"
          style={{ fontFamily: "var(--font-nunito)" }}
        >
          {t("title")}
        </h2>
        <p className="text-base text-[#5B5B5B] mb-10 max-w-lg">{t("sub")}</p>

        {/* Dark heatmap card */}
        <div className="rounded-3xl p-8 md:p-10 mb-10" style={{ backgroundColor: "#16161A" }}>
          {/* Stats row */}
          <div className="flex gap-10 mb-8">
            <div>
              <p className="text-3xl font-extrabold text-white" style={{ fontFamily: "var(--font-nunito)" }}>
                {t("stat1_value")}
              </p>
              <p className="text-sm text-white/40 mt-1">{t("stat1_label")}</p>
            </div>
            <div>
              <p className="text-3xl font-extrabold text-white" style={{ fontFamily: "var(--font-nunito)" }}>
                {t("stat2_value")}
              </p>
              <p className="text-sm text-white/40 mt-1">{t("stat2_label")}</p>
            </div>
          </div>

          {/* Heatmap grid */}
          <div className="overflow-x-auto">
            <div className="flex gap-1 min-w-max">
              {/* Day labels */}
              <div className="flex flex-col gap-1 mr-2">
                {DAYS.map(d => (
                  <div key={d} className="h-3 w-7 flex items-center">
                    <span className="text-[9px] text-white/30">{d}</span>
                  </div>
                ))}
              </div>
              {/* Weeks */}
              {Array.from({ length: WEEKS }).map((_, wi) => (
                <div key={wi} className="flex flex-col gap-1">
                  {Array.from({ length: 7 }).map((_, di) => {
                    const idx = wi * 7 + di
                    const v = HEAT_SEED[idx % HEAT_SEED.length]
                    return (
                      <div
                        key={di}
                        className="w-3 h-3 rounded-[3px]"
                        style={{ backgroundColor: heatColor(v) }}
                      />
                    )
                  })}
                </div>
              ))}
            </div>
          </div>

          {/* Legend */}
          <div className="flex items-center gap-2 mt-5">
            <span className="text-[10px] text-white/30">{t("legend_none")}</span>
            {[0, 1, 2, 3, 4].map(v => (
              <div
                key={v}
                className="w-3 h-3 rounded-[3px]"
                style={{ backgroundColor: heatColor(v) }}
              />
            ))}
            <span className="text-[10px] text-white/30">{t("legend_max")}</span>
          </div>
        </div>

        {/* Protects tools row */}
        <div className="flex flex-col md:flex-row md:items-center gap-6">
          <div className="flex-1">
            <h3 className="text-xl font-bold text-[#141414] mb-2" style={{ fontFamily: "var(--font-nunito)" }}>
              {t("protects_title")}
            </h3>
            <p className="text-sm text-[#5B5B5B]">{t("protects_sub")}</p>
          </div>
          <div className="flex flex-wrap gap-2">
            {TOOLS.map(({ icon: Icon, name }) => (
              <div
                key={name}
                className="flex items-center gap-2 px-3 py-2 rounded-xl border border-black/8 bg-white text-sm font-medium text-[#141414]"
              >
                <Icon className="w-4 h-4 text-[#5B5B5B]" />
                {name}
              </div>
            ))}
          </div>
        </div>
      </div>
    </section>
  )
}

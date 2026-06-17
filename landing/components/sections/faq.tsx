import { getTranslations } from "next-intl/server"
import {
  Accordion,
  AccordionContent,
  AccordionItem,
  AccordionTrigger,
} from "@/components/ui/accordion"

export async function Faq() {
  const t = await getTranslations("faq")

  const items: { q: string; a: string }[] = t.raw("items") as { q: string; a: string }[]

  return (
    <section id="faq" className="py-24 px-6">
      <div className="max-w-2xl mx-auto">
        <p className="text-xs font-bold tracking-widest text-[#5B5B5B] mb-3">{t("eyebrow")}</p>
        <h2
          className="text-4xl font-extrabold text-[#141414] mb-12"
          style={{ fontFamily: "var(--font-nunito)" }}
        >
          {t("title")}
        </h2>

        <Accordion className="flex flex-col gap-2">
          {items.map((item, i) => (
            <AccordionItem
              key={i}
              value={`item-${i}`}
              className="border border-black/8 rounded-2xl px-6 bg-white overflow-hidden"
            >
              <AccordionTrigger className="text-sm font-semibold text-[#141414] hover:no-underline py-5">
                {item.q}
              </AccordionTrigger>
              <AccordionContent className="text-sm text-[#5B5B5B] leading-relaxed pb-5">
                {item.a}
              </AccordionContent>
            </AccordionItem>
          ))}
        </Accordion>
      </div>
    </section>
  )
}

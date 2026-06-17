"use client"

import { useTranslations } from "next-intl"
import {
  Accordion,
  AccordionContent,
  AccordionItem,
  AccordionTrigger,
} from "@/components/ui/accordion"

interface FAQItem {
  q: string
  a: string
}

export default function FAQs() {
  const t = useTranslations("faq")
  const items = t.raw("items") as FAQItem[]

  return (
    <div id="faq" className="mx-auto max-w-5xl px-6 py-20">
      <div className="flex max-w-5xl flex-1 flex-col gap-6 lg:flex-row">
        <div className="flex w-full flex-col gap-4 lg:flex-1 lg:py-5">
          <h2 className="text-4xl leading-tight font-semibold tracking-tight">
            {t("title")}
          </h2>
          <p className="text-muted-foreground text-base leading-7">
            {t("sub")}
          </p>
        </div>

        <div className="w-full lg:flex-1">
          <Accordion className="w-full">
            {items.map((item, index) => (
              <AccordionItem
                key={index}
                value={`item-${index}`}
                className="border-b"
              >
                <AccordionTrigger className="p-5 text-left text-base font-medium hover:no-underline">
                  {item.q}
                </AccordionTrigger>
                <AccordionContent className="p-5 text-sm leading-6">
                  {item.a}
                </AccordionContent>
              </AccordionItem>
            ))}
          </Accordion>
        </div>
      </div>
    </div>
  )
}

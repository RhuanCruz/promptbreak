"use client"

import React from "react"
import Link from "next/link"
import Image from "next/image"
import { Equal, X } from "@aliimam/icons"
import { useTranslations, useLocale } from "next-intl"
import { useRouter, usePathname } from "next/navigation"

import { Menus } from "@/components/menus"
import { cn } from "@/lib/utils"
import { Button } from "@/components/ui/button"
import { siteConfig } from "@/lib/site"

function LocaleSwitcher() {
  const locale = useLocale()
  const router = useRouter()
  const pathname = usePathname()

  const toggle = () => {
    const next = locale === "en" ? "pt-BR" : "en"
    const segments = pathname.split("/")
    segments[1] = next
    router.push(segments.join("/"))
  }

  return (
    <button
      onClick={toggle}
      className="text-muted-foreground hover:text-foreground text-xs font-medium transition-colors"
    >
      {locale === "en" ? "PT" : "EN"}
    </button>
  )
}

const Header = () => {
  const t = useTranslations("header")
  const locale = useLocale()
  const [menuState, setMenuState] = React.useState(false)
  const [isScrolled, setIsScrolled] = React.useState(false)

  const checkoutUrl =
    siteConfig.checkout[
      siteConfig.priceByLocale[locale as "en" | "pt-BR"]?.checkoutKey ?? "usd"
    ]

  React.useEffect(() => {
    const handleScroll = () => setIsScrolled(window.scrollY > 4)
    window.addEventListener("scroll", handleScroll)
    return () => window.removeEventListener("scroll", handleScroll)
  }, [])

  const navLinks = [
    { label: t("nav_how"), href: "#how-it-works" },
    { label: t("nav_pricing"), href: "#pricing" },
    { label: t("nav_faq"), href: "#faq" },
  ]

  return (
    <header>
      <nav
        data-state={menuState && "active"}
        className={cn(
          "fixed z-50 w-full px-3 transition-colors duration-300 md:px-4",
          isScrolled ? "border-transparent" : "border-b"
        )}
      >
        <div
          className={cn(
            "mx-auto mt-2 transition-all duration-300",
            isScrolled &&
              "bg-background/50 max-w-5xl rounded-2xl border px-3 backdrop-blur-xl"
          )}
        >
          <div className="relative flex flex-wrap items-center justify-between gap-3 py-3">
            {/* Logo */}
            <div className="flex w-full justify-between lg:w-auto">
              <a href="#" aria-label="home" className="flex items-center gap-2">
                <Image
                  src="/logo.png"
                  alt="PromptBreak"
                  width={28}
                  height={28}
                  className="rounded-md"
                />
                <span className="text-sm font-semibold">PromptBreak</span>
              </a>
              <div className="flex items-center gap-2 lg:hidden">
                <LocaleSwitcher />
                <button
                  onClick={() => setMenuState(!menuState)}
                  aria-label={menuState ? "Close Menu" : "Open Menu"}
                  className="relative z-20 block cursor-pointer p-2"
                >
                  <Equal className="m-auto scale-120 duration-200 in-data-[state=active]:scale-0 in-data-[state=active]:rotate-180 in-data-[state=active]:opacity-0" />
                  <X className="absolute inset-0 m-auto size-6 scale-0 -rotate-180 opacity-0 duration-200 in-data-[state=active]:scale-120 in-data-[state=active]:rotate-0 in-data-[state=active]:opacity-100" />
                </button>
              </div>
            </div>

            {/* Desktop nav */}
            <div className="absolute inset-0 m-auto hidden size-fit lg:block">
              <Menus />
            </div>

            {/* Right side */}
            <div className="shadow-3xl hidden w-full flex-wrap items-center justify-end space-y-8 rounded-sm border p-3 backdrop-blur-2xl in-data-[state=active]:block md:flex-nowrap lg:m-0 lg:flex lg:w-fit lg:gap-4 lg:space-y-0 lg:border-transparent lg:bg-transparent lg:p-0 lg:shadow-none lg:in-data-[state=active]:flex dark:shadow-none dark:lg:bg-transparent">
              {/* Mobile nav links */}
              <div className="block p-3 lg:hidden">
                <ul className="space-y-6 text-base">
                  {navLinks.map((item) => (
                    <li key={item.href}>
                      <a
                        href={item.href}
                        onClick={() => setMenuState(false)}
                        className="text-muted-foreground hover:text-foreground block text-sm duration-150"
                      >
                        {item.label}
                      </a>
                    </li>
                  ))}
                </ul>
              </div>

              <div className="flex w-full items-center gap-3 sm:flex-row sm:w-auto">
                <LocaleSwitcher />
                <Button
                  render={<Link href={checkoutUrl} target="_blank" />}
                  nativeButton={false}
                >
                  {t("cta")}
                </Button>
              </div>
            </div>
          </div>
        </div>
      </nav>
    </header>
  )
}

export { Header }

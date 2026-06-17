import type { Metadata } from "next"
import { Geist } from "next/font/google"
import "./globals.css"

const geist = Geist({
  subsets: ["latin"],
  variable: "--font-geist",
  display: "swap",
})

export const metadata: Metadata = {
  title: "PromptBreak — Your next prompt has a cooldown.",
  description:
    "PromptBreak blocks your AI tools at set intervals and unlocks them only after you complete real reps — detected by your camera.",
}

export default function RootLayout({ children }: { children: React.ReactNode }) {
  return (
    <html suppressHydrationWarning className={`dark ${geist.variable}`}>
      <body className="antialiased">
        {children}
      </body>
    </html>
  )
}

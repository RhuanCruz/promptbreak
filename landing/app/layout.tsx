import type { Metadata } from "next"
import { Geist } from "next/font/google"
import { Analytics } from "@vercel/analytics/next"
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
  openGraph: {
    title: "PromptBreak — Your next prompt has a cooldown.",
    description:
      "PromptBreak blocks Claude, Cursor and Codex until you stand up and move. Camera-verified. No cheating.",
    url: "https://promptbreak.com",
    siteName: "PromptBreak",
    images: [
      {
        url: "/app-screenshot.png",
        width: 1456,
        height: 816,
        alt: "PromptBreak app",
      },
    ],
    type: "website",
  },
  twitter: {
    card: "summary_large_image",
    title: "PromptBreak — Your next prompt has a cooldown.",
    description:
      "PromptBreak blocks Claude, Cursor and Codex until you stand up and move. Camera-verified. No cheating.",
    images: ["/app-screenshot.png"],
    creator: "@zzurcz",
  },
}

export default function RootLayout({ children }: { children: React.ReactNode }) {
  return (
    <html suppressHydrationWarning className={`dark ${geist.variable}`}>
      <body className="antialiased">
        {children}
        <Analytics />
      </body>
    </html>
  )
}

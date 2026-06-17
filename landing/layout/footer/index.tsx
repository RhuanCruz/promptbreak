import Link from "next/link"
import { X } from "@aliimam/logos"

export default function Footer() {
  return (
    <div className="flex w-full flex-col items-center justify-center">
      <div className="container flex h-auto flex-col items-stretch justify-between self-stretch md:flex-row">
        <div className="flex h-auto flex-col items-start justify-start gap-8 p-4 md:p-8">
          <div className="flex items-center justify-start gap-3 self-stretch">
            <div className="text-center text-xl leading-4 font-semibold">
              PromptBreak
            </div>
          </div>
          <div className="text-sm font-medium">
            <h1 className="text-lg font-medium">Your next prompt has a cooldown.</h1>
            <p className="text-muted-foreground max-w-md">
              PromptBreak blocks your AI tools at set intervals and unlocks them
              only after you complete real reps — detected by your camera.
            </p>
          </div>

          <div className="flex items-start justify-start gap-6">
            <Link href="https://x.com/zzurcz" target="_blank" rel="noopener noreferrer">
              <X className="w-6 hover:opacity-70 transition-opacity" />
            </Link>
          </div>
        </div>
      </div>

      <div className="relative h-12 self-stretch overflow-hidden border-t border-b">
        <div className="absolute inset-0 h-full w-full overflow-hidden">
          <div className="relative h-full w-full">
            {Array.from({ length: 300 }).map((_, i) => (
              <div
                key={i}
                className="outline-primary/40 absolute h-4 w-full origin-top-left -rotate-45 outline-[0.5px] outline-offset-[-0.25px]"
                style={{
                  top: `${i * 16 - 120}px`,
                  left: "-100%",
                  width: "300%",
                }}
              />
            ))}
          </div>
        </div>
      </div>
    </div>
  )
}

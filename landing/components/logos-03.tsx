import { Marquee } from "@/components/marquee"
import { ClaudeAiWordmarkIconDark } from "@/components/ui/svgs/claudeAiWordmarkIconDark"
import { CursorWordmarkDark } from "@/components/ui/svgs/cursorWordmarkDark"
import { CodexWordmarkDark } from "@/components/ui/svgs/codexWordmarkDark"
import { GhosttyWordmarkDark } from "@/components/ui/svgs/ghosttyWordmarkDark"
import { Vscode } from "@/components/ui/svgs/vscode"
import { AntigravityWordmark } from "@/components/ui/svgs/antigravityWordmark"

const logos = [
  { name: "Claude", el: <ClaudeAiWordmarkIconDark className="h-7 w-auto" /> },
  { name: "Cursor", el: <CursorWordmarkDark className="h-6 w-auto fill-white" /> },
  { name: "Codex", el: <CodexWordmarkDark className="h-6 w-auto" /> },
  { name: "Ghostty", el: <GhosttyWordmarkDark className="h-6 w-auto" /> },
  { name: "VS Code", el: <Vscode className="h-8 w-auto" /> },
  { name: "Antigravity", el: <AntigravityWordmark className="h-6 w-auto" /> },
]

export default function Logos03() {
  return (
    <div className="flex flex-col items-center justify-center gap-6 py-16">
      <p className="text-muted-foreground text-sm font-medium">
        Holds these hostage until you get up
      </p>
      <div className="mx-auto w-full max-w-4xl overflow-hidden [mask-image:linear-gradient(to_right,transparent,black_15%,black_85%,transparent)]">
        <Marquee gap="80px" speed="slow" pauseOnHover>
          {logos.map(({ name, el }) => (
            <div key={name} className="flex items-center opacity-70 hover:opacity-100 transition-opacity">
              {el}
            </div>
          ))}
        </Marquee>
      </div>
    </div>
  )
}

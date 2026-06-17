"use client"

import {
  Dialog,
  DialogContent,
  DialogTitle,
} from "@/components/ui/dialog"

interface VideoDialogProps {
  open: boolean
  onOpenChange: (open: boolean) => void
  videoUrl: string
}

export function VideoDialog({ open, onOpenChange, videoUrl }: VideoDialogProps) {
  return (
    <Dialog open={open} onOpenChange={onOpenChange}>
      <DialogContent className="max-w-3xl p-0 bg-black border-0 overflow-hidden rounded-2xl">
        <DialogTitle className="sr-only">Demo video</DialogTitle>
        {videoUrl ? (
          <iframe
            src={videoUrl}
            className="w-full aspect-video"
            allow="autoplay; fullscreen"
            allowFullScreen
          />
        ) : (
          <div className="w-full aspect-video flex items-center justify-center bg-[#16161A]">
            <p className="text-white/40 text-sm">Demo coming soon</p>
          </div>
        )}
      </DialogContent>
    </Dialog>
  )
}

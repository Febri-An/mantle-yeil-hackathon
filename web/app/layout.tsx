import type React from "react"
import type { Metadata } from "next"
import { GeistSans } from "geist/font/sans"
import { GeistMono } from "geist/font/mono"
import { Web3Provider } from "@/components/providers/web3-provider"
import "./globals.css"

export const metadata: Metadata = {
  title: "Yeil - Mantle Hackathon",
  description: "Yeil Application for Mantle Hackathon",
  generator: "v0.app",
}

export default function RootLayout({
  children,
}: Readonly<{
  children: React.ReactNode
}>) {
  return (
    <html lang="en" className="dark">
      <head>
        <style>{`
html {
  font-family: ${GeistSans.style.fontFamily};
  --font-sans: ${GeistSans.variable};
  --font-mono: ${GeistMono.variable};
}
        `}</style>
      </head>
      <body className="dark">
        <Web3Provider>
          {children}
        </Web3Provider>
      </body>
    </html>
  )
}

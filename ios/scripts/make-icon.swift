#!/usr/bin/env swift
// Renders the 1024×1024 App Store icon (cream spade on the app's dark green),
// matching public/icon.svg. Opaque — App Store Connect rejects icons with alpha.
//
//   swift ios/scripts/make-icon.swift ios/ScoringSpades/Assets.xcassets/AppIcon.appiconset/AppIcon.png

import AppKit

let out = CommandLine.arguments.dropFirst().first ?? "AppIcon.png"
let size = 1024

func rgb(_ hex: Int) -> NSColor {
  NSColor(srgbRed: CGFloat((hex >> 16) & 0xff) / 255,
          green: CGFloat((hex >> 8) & 0xff) / 255,
          blue: CGFloat(hex & 0xff) / 255, alpha: 1)
}

let ctx = CGContext(data: nil, width: size, height: size, bitsPerComponent: 8, bytesPerRow: 0,
                    space: CGColorSpace(name: CGColorSpace.sRGB)!,
                    bitmapInfo: CGImageAlphaInfo.noneSkipLast.rawValue)!
NSGraphicsContext.saveGraphicsState()
NSGraphicsContext.current = NSGraphicsContext(cgContext: ctx, flipped: false)

rgb(0x0f1f1a).setFill()
NSRect(x: 0, y: 0, width: size, height: size).fill()

let config = NSImage.SymbolConfiguration(pointSize: 560, weight: .regular)
  .applying(.init(paletteColors: [rgb(0xf5f0e6)]))
let spade = NSImage(systemSymbolName: "suit.spade.fill", accessibilityDescription: nil)!
  .withSymbolConfiguration(config)!
let s = spade.size
spade.draw(in: NSRect(x: (CGFloat(size) - s.width) / 2, y: (CGFloat(size) - s.height) / 2,
                      width: s.width, height: s.height))

NSGraphicsContext.restoreGraphicsState()
let rep = NSBitmapImageRep(cgImage: ctx.makeImage()!)
try! rep.representation(using: .png, properties: [:])!.write(to: URL(fileURLWithPath: out))
print("wrote \(out)")

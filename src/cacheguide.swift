// cacheguide: the floating "How to use" panel for cachewatch, opened from the menu-bar ring.
// usage: cacheguide [GROW_GB]
// built by install.sh: swiftc -O src/cacheguide.swift -o ~/.local/bin/cacheguide
import AppKit
import SwiftUI

let growGB = CommandLine.arguments.dropFirst().first ?? "10"

// MARK: building blocks

struct RingGlyph: View {
  let frac: Double, tint: Color, label: String
  var size: CGFloat = 30
  var body: some View {
    ZStack {
      Circle().stroke(tint.opacity(0.3), lineWidth: 2.5)
      Circle().trim(from: 0, to: frac).stroke(tint, style: .init(lineWidth: 2.5, lineCap: .round)).rotationEffect(.degrees(-90))
      Text(label).font(.system(size: size * 0.4, weight: .bold).monospacedDigit()).foregroundStyle(tint)
    }
    .frame(width: size, height: size)
  }
}

struct Card<Content: View>: View {
  @ViewBuilder var content: Content
  var body: some View {
    VStack(alignment: .leading, spacing: 6) { content }
      .padding(14)
      .frame(maxWidth: .infinity, alignment: .leading)
      .background(.white.opacity(0.06), in: RoundedRectangle(cornerRadius: 12))
      .overlay(RoundedRectangle(cornerRadius: 12).strokeBorder(.white.opacity(0.08)))
  }
}

/// A titled card with the reason and, optionally, the exact command to run (selectable, so it can be copied).
struct Item: View {
  let title: String, why: String
  var how: String? = nil
  var tint: Color = .primary
  var body: some View {
    Card {
      Text(title).font(.headline).foregroundStyle(tint)
      Text(LocalizedStringKey(why)).foregroundStyle(.secondary).fixedSize(horizontal: false, vertical: true)
      if let how {
        Text(how).font(.system(.callout, design: .monospaced)).textSelection(.enabled)
          .padding(8).frame(maxWidth: .infinity, alignment: .leading)
          .background(.black.opacity(0.35), in: RoundedRectangle(cornerRadius: 8))
      }
    }
  }
}

struct Step: View {
  let n: Int, title: String, why: String
  var body: some View {
    HStack(alignment: .top, spacing: 12) {
      Text("\(n)").font(.headline.monospacedDigit()).frame(width: 26, height: 26).background(.white.opacity(0.12), in: Circle())
      VStack(alignment: .leading, spacing: 4) {
        Text(LocalizedStringKey(title)).font(.headline)
        Text(LocalizedStringKey(why)).foregroundStyle(.secondary).fixedSize(horizontal: false, vertical: true)
      }
    }
  }
}

// MARK: tabs

struct RingTab: View {
  var body: some View {
    ForEach([(0.1, Color.secondary, "Grey, nearly empty", "Your caches have barely grown since the last sweep. **Nothing to do.**"),
             (0.6, Color.primary, "Filling up", "Growth is heading toward \(growGB) GB. **Still nothing to do.** Open the menu if you're curious where it went."),
             (1.0, Color.orange, "Orange, plus a notification", "Caches grew \(growGB) GB or more. **Time for the 2-minute sweep** (next tab).")], id: \.2) { frac, tint, title, text in
      Card {
        HStack(spacing: 14) {
          RingGlyph(frac: frac, tint: tint, label: "4")
          VStack(alignment: .leading, spacing: 3) {
            Text(title).font(.headline).foregroundStyle(tint == .secondary ? .primary : tint)
            Text(LocalizedStringKey(text)).foregroundStyle(.secondary).fixedSize(horizontal: false, vertical: true)
          }
        }
      }
    }
    Item(title: "The number in the middle",
         why: "How many GB the **biggest cache you can clear** is holding right now. It tells you where the space went. It's not a to-do: **Clean now…** only ever offers what's safe.")
    Item(title: "Why count growth, not total size?",
         why: "Some big folders are there on purpose: Docker's disk, your phone's debug files, a simulator you use. An alarm on total size would go off every week until you learned to ignore it. Growth is the thing that sneaks up on you.")
    Item(title: "When it updates",
         why: "The menu checks what's running every 5 minutes, which is quick and cheap. Cache sizes are slower to measure (about 30 seconds), so they're re-measured every 6 hours, or straight away with **Re-measure sizes**. A weekly check on Sundays at 10:00 sends the cache notification.")
  }
}

struct BackgroundTab: View {
  var body: some View {
    Text("Developer tools left running can drain your battery, slow your Mac down and even hold your speakers open. cachewatch tells you **once** when it spots one, and never stops anything by itself.")
      .foregroundStyle(.secondary).fixedSize(horizontal: false, vertical: true)
    Card {
      HStack(spacing: 14) {
        ZStack(alignment: .topTrailing) {
          RingGlyph(frac: 0.35, tint: .primary, label: "4")
          Text("⚠︎").font(.caption.bold()).foregroundStyle(.orange).offset(x: 10, y: -6)
        }
        VStack(alignment: .leading, spacing: 3) {
          Text("A ⚠︎ beside the ring, plus one notification").font(.headline)
          Text("Something heavy is running in the background. Click the ring: it's listed at the top in orange.")
            .foregroundStyle(.secondary).fixedSize(horizontal: false, vertical: true)
        }
      }
    }
    Item(title: "What it looks for",
         why: "**A simulator** left on for 30 minutes or more. **Docker Desktop** left on that long. **Any of your own programs** stuck above 50% CPU on two checks in a row. The app you're using right now is never flagged.")
    Item(title: "Deciding what to do",
         why: "Hover the item: it says what the program is and whether quitting it is safe. Then pick the quick fix (shut down the simulator, quit Docker, quit the program) or simply leave it. If you're using it, ignore the warning; you won't be notified about it again.")
    Item(title: "Is the quick fix safe?",
         why: "It only ever acts on the exact process it showed you. If that program has already closed and something else took its place, the fix does nothing.")
    Item(title: "Tune or turn it off",
         why: "In your settings file: `CPU_HOG` (the % line), `SIM_MIN` (minutes), `BG_IGNORE` (names never to flag) or `BG_CHECK=0` to switch it off.",
         how: "open ~/.config/cachewatch/config.zsh")
  }
}

struct SweepTab: View {
  var body: some View {
    Card {
      VStack(alignment: .leading, spacing: 16) {
        Step(n: 1, title: "Click the ring, then **Clean now…**",
             why: "Terminal opens and goes through each cache over 100 MB, one at a time, showing its size and the exact command. Type **y** to clear it, anything else to skip.")
        Step(n: 2, title: "Say **yes** freely to uv, pip, npm, pnpm, Yarn, Bun, Homebrew, CocoaPods and Go",
             why: "They're download caches. The worst that happens is one install later takes a little longer while it re-downloads.")
        Step(n: 3, title: "Xcode DerivedData: **yes, unless Xcode is building right now**",
             why: "It's Xcode's scratch space and goes to the Trash. Your next build is just slower. Clearing it mid-build makes that build fail.")
        Step(n: 4, title: "Simulators: **yes**",
             why: "The command only removes simulators whose iOS version is no longer installed, so the ones you use are safe.")
        Step(n: 5, title: "Wait a day, then **empty the Trash**",
             why: "Only DerivedData goes to the Trash, and that's your undo window. The space comes back once you empty it.")
      }
    }
    Item(title: "After the sweep", why: "The ring empties straight away and starts counting fresh growth from there.")
  }
}

struct ByHandTab: View {
  var body: some View {
    Text("Grey rows are never cleared for you, because a wrong guess there costs real data or a long re-download. Click any row in the menu to see it in Finder.")
      .foregroundStyle(.secondary).fixedSize(horizontal: false, vertical: true)
    Item(title: "Docker disk",
         why: "One big file (`Docker.raw`) that holds every image, container and **volume**. Volumes can hold real database data, and only Docker knows which is which. **Never delete `Docker.raw` in Finder.** Open Docker Desktop first, then:",
         how: "docker system df        # see what's inside\ndocker image prune -a   # images nothing uses\ndocker builder prune    # build cache")
    Item(title: "Docker, if you've stopped using it",
         why: "Docker Desktop → Troubleshoot → **Clean / Purge data** empties it in one go.")
    Item(title: "iOS DeviceSupport",
         why: "Debug files Xcode copies from every iPhone and iOS version you plug in, 5–7 GB each. **Keep the folder that matches your phone's iOS today**; the rest are leftovers. The model codes run a number ahead of the names: `iPhone16,1` is an iPhone 15 Pro.")
    Item(title: "Xcode Archives",
         why: "Every app build you've archived for the App Store. Keep the ones you might need to symbolicate a crash from; Xcode → Window → Organizer lets you delete the rest.")
    Item(title: "Local AI models (Ollama, LM Studio, Hugging Face)",
         why: "Big and slow to download again, and only you know which you still use.",
         how: "ollama rm NAME                 # remove an Ollama model\nhuggingface-cli delete-cache   # pick Hugging Face models to remove")
    Item(title: "Playwright browsers", why: "Test browsers. The next test run reinstalls whatever it needs.",
         how: "npx playwright uninstall --all")
    Item(title: "Project folders",
         why: "`node_modules` and `.venv` inside your projects. Only remove them for projects you're **not** working on (click the row, then move it to the Trash). Bring them back with:",
         how: "npm install   |   pnpm install   |   uv sync")
  }
}

struct DontsTab: View {
  var body: some View {
    Item(title: "Don't clear a cache while its tool is running",
         why: "An Xcode build or `npm install` in progress loses files mid-way and fails.", tint: .orange)
    Item(title: "Don't delete things in ~/Library/Containers or Application Support",
         why: "Those hold apps' live data, not caches.", tint: .orange)
    Item(title: "Don't empty the Trash right after cleaning",
         why: "Give it a day. It's your only undo if something you needed went with it.", tint: .orange)
    Item(title: "Don't read the number in the ring as \"delete this\"",
         why: "It shows where space is, not what's safe. **Clean now…** only offers what's safe.", tint: .orange)
    Item(title: "Change the settings",
         why: "Alert size, project folders and extra folders to watch all live in one small file:",
         how: "open ~/.config/cachewatch/config.zsh")
    Item(title: "From Terminal",
         why: "Everything in the menu also works as a command.",
         how: "cachewatch           # table of caches\ncachewatch --clean   # the sweep\ncachewatch --help")
  }
}

// MARK: panel

struct GuideView: View {
  @State private var tab = 0
  private let tabs = ["Ring", "Sweep", "Background", "By hand", "Don'ts"]
  var body: some View {
    VStack(alignment: .leading, spacing: 14) {
      HStack(spacing: 12) {
        RingGlyph(frac: 0.35, tint: .white, label: "4", size: 36)
        VStack(alignment: .leading, spacing: 2) {
          Text("cachewatch").font(.title2.weight(.semibold))
          Text("Keeps your caches and background tools in check").font(.callout).foregroundStyle(.secondary)
        }
      }
      Picker("", selection: $tab) { ForEach(tabs.indices, id: \.self) { Text(tabs[$0]).tag($0) } }
        .pickerStyle(.segmented).labelsHidden()
      ScrollView {
        VStack(alignment: .leading, spacing: 10) {
          switch tab {
          case 0: RingTab()
          case 1: SweepTab()
          case 2: BackgroundTab()
          case 3: ByHandTab()
          default: DontsTab()
          }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
      }
      .scrollIndicators(.never)
      HStack {
        Text("Esc to close").font(.caption).foregroundStyle(.tertiary)
        Spacer()
        Button("Done") { NSApp.terminate(nil) }.keyboardShortcut(.cancelAction)
      }
    }
    .padding(.horizontal, 22).padding(.top, 34).padding(.bottom, 16)
    .frame(width: 500, height: 640)
    .background(Color(white: 0.06).opacity(0.6))  // dark tint over the glass: stays dark whatever the wallpaper
  }
}

final class Delegate: NSObject, NSApplicationDelegate {
  func applicationShouldTerminateAfterLastWindowClosed(_ app: NSApplication) -> Bool { true }
}

let app = NSApplication.shared
app.setActivationPolicy(.accessory)  // no Dock icon; it's a panel, not an app
let delegate = Delegate()
app.delegate = delegate

let panel = NSPanel(contentRect: NSRect(x: 0, y: 0, width: 500, height: 640),
                    styleMask: [.titled, .closable, .fullSizeContentView], backing: .buffered, defer: false)
panel.titlebarAppearsTransparent = true
panel.titleVisibility = .hidden
panel.isMovableByWindowBackground = true
panel.level = .floating          // stays above other windows while you follow the steps
panel.hidesOnDeactivate = false
panel.appearance = NSAppearance(named: .darkAqua)

let glass = NSVisualEffectView()
glass.material = .hudWindow      // frosted glass: macOS blurs whatever is behind the panel
glass.blendingMode = .behindWindow
glass.state = .active
let host = NSHostingView(rootView: GuideView())
host.frame = glass.bounds
host.autoresizingMask = [.width, .height]
glass.addSubview(host)
panel.contentView = glass

panel.center()
panel.makeKeyAndOrderFront(nil)
app.activate(ignoringOtherApps: true)
app.run()

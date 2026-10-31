import AppKit
import SwiftUI

/// A compact native popover, independent from the menu bar's ticking title.
struct MenuBarContent: View {
    @ObservedObject var timer: PomodoroTimer

    var body: some View {
        VStack(alignment: .leading, spacing: 15) {
            VStack(alignment: .leading, spacing: 0) {
                header
                // Target roughly 45 px of optical spacing above and below the digits
                // at 2x Retina scale; macOS font metrics can affect the final pixels.
                countdown
                    .padding(.top, 10.5)
                    .padding(.bottom, 17.5)
                cycleProgress
            }

            Divider()
            controls
            Divider()
            settings
            Divider()
            footer
        }
        .padding(20)
        .frame(width: 354)
        .background(.regularMaterial)
    }

    private var header: some View {
        HStack {
            Label("OzDoro", systemImage: "timer")
                .font(.headline)
            Spacer()
            Label(L10n.phaseTitle(timer.phase), systemImage: timer.phase.symbol)
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
    }

    private var countdown: some View {
        Text(timer.formattedRemaining)
            .font(.system(size: 44, weight: .semibold, design: .rounded))
            .monospacedDigit()
            .accessibilityLabel(L10n.remainingTime(timer.formattedRemaining))
            .frame(maxWidth: .infinity)
    }

    private var cycleProgress: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(L10n.cycleTitle)
                .font(.caption.weight(.semibold))

            HStack(spacing: 7) {
                ForEach(0..<PomodoroCycle.roundsPerCycle, id: \.self) { index in
                    let isFinished = index < timer.completedFocusSessions
                    let isCurrentFocus = timer.phase == .focus && index == timer.completedFocusSessions

                    ZStack {
                        Circle()
                            .fill(isFinished ? Color.accentColor : Color.secondary.opacity(0.10))
                        if isFinished {
                            Image(systemName: "checkmark")
                                .font(.system(size: 10, weight: .bold))
                                .foregroundStyle(.white)
                        } else {
                            Text("\(index + 1)")
                                .font(.system(size: 11, weight: isCurrentFocus ? .semibold : .regular))
                                .foregroundStyle(isCurrentFocus ? Color.accentColor : Color.secondary)
                        }
                    }
                    .frame(width: 27, height: 27)
                    .overlay {
                        Circle()
                            .strokeBorder(isCurrentFocus ? Color.accentColor : .clear, lineWidth: 1.5)
                    }
                    .accessibilityLabel(
                        L10n.roundAccessibility(index + 1, completed: isFinished, current: isCurrentFocus))
                }
                Spacer(minLength: 0)
                Text("\(timer.completedFocusSessions)/\(PomodoroCycle.roundsPerCycle)")
                    .font(.caption.monospacedDigit())
                    .foregroundStyle(.secondary)
            }

            HStack(alignment: .firstTextBaseline) {
                Text(L10n.upNext)
                    .foregroundStyle(.secondary)
                Spacer()
                Text(timer.nextSessionDescription)
                    .fontWeight(.medium)
            }
            .font(.caption)

            VStack(alignment: .leading, spacing: 4) {
                Label(L10n.firstThreeRounds, systemImage: "arrow.turn.down.right")
                Label(
                    L10n.finalRound(longBreakMinutes: timer.longBreakMinutes),
                    systemImage: "arrow.turn.down.right")
            }
            .font(.caption2)
            .foregroundStyle(.secondary)

            Text(L10n.automaticBreaksHint)
                .font(.caption2)
                .foregroundStyle(.secondary)
        }
        .padding(12)
        .background(Color.secondary.opacity(0.06), in: RoundedRectangle(cornerRadius: 12))
    }

    private var controls: some View {
        VStack(spacing: 8) {
            HStack(spacing: 8) {
                Button {
                    timer.toggle()
                } label: {
                    Label(timer.primaryActionTitle, systemImage: timer.primaryActionSymbol)
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .keyboardShortcut(.space, modifiers: [])

                Button {
                    timer.resetCurrentSession()
                } label: {
                    Label(L10n.restart, systemImage: "arrow.counterclockwise")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.bordered)
                .help(L10n.restartHelp)
            }

            if timer.phase != .focus {
                Button {
                    timer.skipBreak()
                } label: {
                    Label(L10n.skipBreak, systemImage: "forward.end")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.bordered)
            }
        }
    }

    private var settings: some View {
        VStack(alignment: .leading, spacing: 11) {
            HStack {
                Text(L10n.longBreak)
                Spacer()
                Picker(L10n.longBreak, selection: $timer.longBreakMinutes) {
                    ForEach([15, 20, 25, 30], id: \.self) { minutes in
                        Text(L10n.minutes(minutes)).tag(minutes)
                    }
                }
                .labelsHidden()
                .frame(width: 119)
            }

            HStack(spacing: 8) {
                Text(L10n.alertSound)
                Spacer()
                Button {
                    timer.previewSound()
                } label: {
                    Image(systemName: "speaker.wave.2")
                }
                .buttonStyle(.borderless)
                .disabled(timer.selectedSound == SystemSounds.silent)
                .help(L10n.previewSoundHelp)

                Picker(L10n.alertSound, selection: $timer.selectedSound) {
                    Text(L10n.noSound).tag(SystemSounds.silent)
                    Divider()
                    ForEach(SystemSounds.availableNames, id: \.self) { sound in
                        Text(sound).tag(sound)
                    }
                }
                .labelsHidden()
                .frame(width: 119)
            }

        }
        .font(.subheadline)
    }

    private var footer: some View {
        HStack {
            Button(L10n.resetCycle) {
                timer.startNewCycle()
            }
            .buttonStyle(.plain)
            .help(L10n.resetCycleHelp)
            Spacer()
            Button(L10n.quit) {
                NSApp.terminate(nil)
            }
            .buttonStyle(.plain)
            .keyboardShortcut("q", modifiers: .command)
        }
        .font(.caption)
        .foregroundStyle(.secondary)
    }
}

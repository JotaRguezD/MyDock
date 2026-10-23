import AppKit
import EventKit
import SwiftUI

// MARK: Pomodoro

final class PomodoroModel: ObservableObject {
    enum Phase { case idle, work, rest }
    @Published private(set) var phase = Phase.idle
    @Published private(set) var remaining: TimeInterval = 0
    @Published private(set) var paused = false
    private var end: Date?
    private var timer: Timer?

    /// Clic: empezar, pausar o seguir.
    func toggle(work: Int, rest: Int) {
        switch (phase, paused) {
        case (.idle, _): start(.work, minutes: work, rest: rest)
        case (_, false): paused = true; end = nil
        case (_, true): paused = false; end = Date().addingTimeInterval(remaining)
        }
    }

    func reset() {
        phase = .idle
        paused = false
        end = nil
        remaining = 0
        timer?.invalidate()
    }

    private func start(_ phase: Phase, minutes: Int, rest: Int) {
        self.phase = phase
        paused = false
        remaining = TimeInterval(minutes * 60)
        end = Date().addingTimeInterval(remaining)
        timer?.invalidate()
        timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { [weak self] _ in self?.tick(rest: rest) }
    }

    private func tick(rest: Int) {
        guard let end else { return }  // en pausa
        remaining = max(end.timeIntervalSinceNow, 0)
        guard remaining == 0 else { return }
        NSSound(named: "Glass")?.play()
        if phase == .work { start(.rest, minutes: rest, rest: rest) } else { reset() }
    }
}

/// 1500 → "25:00".
func minutesSeconds(_ t: TimeInterval) -> String {
    let s = Int(t.rounded(.up))
    return String(format: "%d:%02d", s / 60, s % 60)
}

struct PomodoroWidget: View {
    let s: WidgetSettings
    let compact: Bool
    @StateObject private var model = PomodoroModel()

    var body: some View {
        let work = s.workMinutes ?? 25, rest = s.breakMinutes ?? 5
        let time = model.phase == .idle ? minutesSeconds(TimeInterval(work * 60)) : minutesSeconds(model.remaining)
        let label = [.idle: t("Pomodoro"), .work: t("Concentración"), .rest: t("Descanso")][model.phase]!
        HStack(spacing: 6) {
            WidgetLabel(symbol: model.phase == .rest ? "cup.and.saucer.fill" : "timer", title: time,
                        subtitle: model.paused ? t("En pausa") : label, compact: compact,
                        tint: model.phase == .work ? .red : model.phase == .rest ? .green : nil)
            if !compact && model.phase != .idle {
                Button { model.reset() } label: { Image(systemName: "arrow.counterclockwise") }
                    .buttonStyle(.plain)
                    .help(t("Reiniciar"))
                    .accessibilityLabel(t("Reiniciar"))
            }
        }
        .contentShape(Rectangle())
        .onTapGesture { model.toggle(work: work, rest: rest) }
        .help(model.phase == .idle ? t("Empezar %ld min de concentración", work) : model.paused ? t("Seguir") : t("Pausar"))
    }
}

// MARK: Nota rápida

struct NoteWidget: View {
    let id: UUID
    @ObservedObject var store: DockStore
    let compact: Bool
    @State private var open = false

    var body: some View {
        let text = store.settings(id).note ?? ""
        let firstLine = text.split(separator: "\n").first.map(String.init)
        WidgetLabel(symbol: "note.text", title: compact ? t("Nota") : (firstLine ?? t("Nota rápida")),
                    subtitle: firstLine == nil ? t("Clic para escribir") : nil, compact: compact, tint: .yellow)
            .contentShape(Rectangle())
            .onTapGesture {
                NSApp.activate(ignoringOtherApps: true)  // para poder escribir en el popover
                open.toggle()
            }
            .help(text.isEmpty ? t("Escribir una nota") : text)
            .popover(isPresented: $open, arrowEdge: store.popoverEdge) {
                TextEditor(text: Binding(get: { store.settings(id).note ?? "" },
                                         set: { new in store.updateSettings(id) { $0.note = new } }))
                    .font(.body)
                    .frame(width: 280, height: 160)
                    .padding(8)
            }
    }
}

// MARK: Calendario y Recordatorios (EventKit)

/// Un único almacén para eventos y recordatorios; macOS pide permiso la primera vez.
final class EventStore {
    static let shared = EKEventStore()

    static func openPrivacy(_ pane: String) {
        NSWorkspace.shared.open(URL(string: "x-apple.systempreferences:com.apple.preference.security?\(pane)")!)
    }
}

final class EventsModel: ObservableObject {
    @Published var next: EKEvent?
    @Published var denied = false
    private var timer: Timer?
    private var days = 1

    init() {
        EventStore.shared.requestFullAccessToEvents { [weak self] granted, _ in
            DispatchQueue.main.async {
                self?.denied = !granted
                self?.update()
            }
        }
        NotificationCenter.default.addObserver(forName: .EKEventStoreChanged, object: EventStore.shared, queue: .main) { [weak self] _ in self?.update() }
        timer = Timer.scheduledTimer(withTimeInterval: 60, repeats: true) { [weak self] _ in self?.update() }
    }

    func setDays(_ days: Int) {
        guard days != self.days else { return }
        self.days = days
        update()
    }

    func update() {
        guard EKEventStore.authorizationStatus(for: .event) == .fullAccess else { return }
        let now = Date()
        let end = Calendar.current.date(byAdding: .day, value: days, to: Calendar.current.startOfDay(for: now))!
        let predicate = EventStore.shared.predicateForEvents(withStart: now, end: end, calendars: nil)
        next = EventStore.shared.events(matching: predicate)
            .filter { !$0.isAllDay && $0.endDate > now }
            .min { $0.startDate < $1.startDate }
    }
}

/// "en 25 min", "ahora", o la hora si falta más de una hora (con el día si no es hoy).
func eventTimeText(_ start: Date, now: Date = Date()) -> String {
    let minutes = Int(start.timeIntervalSince(now) / 60)
    if minutes <= 0 { return t("Ahora") }
    if minutes < 60 { return t("En %ld min", minutes) }
    // Hora y día en el formato del idioma y la región (14:30, 2:30 PM, 14時30分…).
    return Calendar.current.isDate(start, inSameDayAs: now)
        ? start.formatted(.dateTime.hour().minute())
        : start.formatted(.dateTime.weekday(.abbreviated).hour().minute())
}

struct EventsWidget: View {
    let s: WidgetSettings
    let compact: Bool
    @StateObject private var model = EventsModel()

    var body: some View {
        Group {
            if model.denied {
                WidgetLabel(symbol: "calendar.badge.exclamationmark", title: t("Sin permiso"), subtitle: t("Clic para dárselo"), compact: compact)
            } else if let event = model.next {
                WidgetLabel(symbol: "calendar", title: compact ? eventTimeText(event.startDate) : event.title ?? t("Evento"),
                            subtitle: eventTimeText(event.startDate), compact: compact,
                            tint: event.calendar.map { Color(cgColor: $0.cgColor) })
            } else {
                WidgetLabel(symbol: "calendar", title: compact ? "—" : t("Sin eventos"), subtitle: s.daysAhead ?? 1 == 1 ? t("Hoy") : t("Próximos días"), compact: compact)
            }
        }
        .contentShape(Rectangle())
        .onTapGesture {
            if model.denied { EventStore.openPrivacy("Privacy_Calendars") } else { openPath("/System/Applications/Calendar.app") }
        }
        .help(model.next.map { "\($0.title ?? t("Evento")) · \(eventTimeText($0.startDate))" } ?? t("Abrir Calendario"))
        .onAppear { model.setDays(s.daysAhead ?? 1) }
        .onChange(of: s.daysAhead) { model.setDays($0 ?? 1) }
    }
}

final class RemindersModel: ObservableObject {
    @Published var pending: [EKReminder] = []
    @Published var denied = false
    private var timer: Timer?

    init() {
        EventStore.shared.requestFullAccessToReminders { [weak self] granted, _ in
            DispatchQueue.main.async {
                self?.denied = !granted
                self?.update()
            }
        }
        NotificationCenter.default.addObserver(forName: .EKEventStoreChanged, object: EventStore.shared, queue: .main) { [weak self] _ in self?.update() }
        timer = Timer.scheduledTimer(withTimeInterval: 120, repeats: true) { [weak self] _ in self?.update() }
    }

    func update() {
        guard EKEventStore.authorizationStatus(for: .reminder) == .fullAccess else { return }
        let predicate = EventStore.shared.predicateForIncompleteReminders(withDueDateStarting: nil, ending: nil, calendars: nil)
        EventStore.shared.fetchReminders(matching: predicate) { reminders in
            // Primero los que tienen fecha (la más cercana), luego el resto.
            let sorted = (reminders ?? []).sorted {
                ($0.dueDateComponents?.date ?? .distantFuture) < ($1.dueDateComponents?.date ?? .distantFuture)
            }
            DispatchQueue.main.async { self.pending = sorted }
        }
    }

    func complete(_ reminder: EKReminder) {
        reminder.isCompleted = true
        do {
            try EventStore.shared.save(reminder, commit: true)
        } catch {
            NSLog("MyDock: no se pudo completar el recordatorio: \(error)")
        }
        update()
    }
}

struct RemindersWidget: View {
    let s: WidgetSettings
    let compact: Bool
    let edge: Edge
    @StateObject private var model = RemindersModel()
    @State private var open = false

    var body: some View {
        Group {
            if model.denied {
                WidgetLabel(symbol: "checklist", title: t("Sin permiso"), subtitle: t("Clic para dárselo"), compact: compact)
            } else {
                WidgetLabel(symbol: "checklist", title: compact ? "\(model.pending.count)" : model.pending.first?.title ?? t("Todo hecho"),
                            subtitle: t("%ld pendientes", model.pending.count), compact: compact, tint: .orange)
            }
        }
        .contentShape(Rectangle())
        .onTapGesture { if model.denied { EventStore.openPrivacy("Privacy_Reminders") } else { open.toggle() } }
        .help(t("Recordatorios pendientes"))
        .popover(isPresented: $open, arrowEdge: edge) {
            VStack(alignment: .leading, spacing: 6) {
                HStack {
                    Text(t("Recordatorios")).font(.headline)
                    Spacer()
                    Button(t("Abrir")) { open = false; openPath("/System/Applications/Reminders.app") }
                }
                if model.pending.isEmpty { Text(t("No tienes nada pendiente.")).foregroundStyle(.secondary) }
                ForEach(model.pending.prefix(10), id: \.calendarItemIdentifier) { reminder in
                    HStack(spacing: 8) {
                        Button { model.complete(reminder) } label: { Image(systemName: "circle") }
                            .buttonStyle(.plain)
                            .help(t("Marcar como hecho"))
                            .accessibilityLabel(t("Marcar como hecho"))
                        Text(reminder.title ?? "").lineLimit(1)
                        Spacer()
                        if let due = reminder.dueDateComponents?.date {
                            Text(eventTimeText(due)).font(.caption).foregroundStyle(.secondary)
                        }
                    }
                }
            }
            .padding(12)
            .frame(width: 300)
        }
    }
}

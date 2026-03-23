import SwiftUI
import UIKit
import CoreHaptics
import AVFoundation

// MARK: - Основное приложение
@main
struct LiquidGlassCalculatorApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}

// MARK: - Главный вид
struct ContentView: View {
    @State private var display = "0"
    @State private var previousNumber: Double = 0
    @State private var currentOperation: Operation? = nil
    @State private var shouldResetDisplay = false
    @State private var history: [String] = []
    @State private var showHistory = false
    @State private var decimalPlaces = 6
    @State private var isLandscape = false
    @State private var hapticEngine: CHHapticEngine?
    
    enum Operation {
        case add, subtract, multiply, divide
    }
    
    var body: some View {
        GeometryReader { geometry in
            let isLandscape = geometry.size.width > geometry.size.height
            
            ZStack {
                // Liquid Glass Gradient Background
                LinearGradient(
                    colors: [
                        Color(red: 0.1, green: 0.1, blue: 0.15),
                        Color(red: 0.05, green: 0.05, blue: 0.08),
                        Color.black
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()
                
                VStack(spacing: 12) {
                    // Header с настройками
                    HStack {
                        Button(action: { showHistory.toggle() }) {
                            Image(systemName: "clock.arrow.circlepath")
                                .font(.title2)
                                .foregroundColor(.white.opacity(0.7))
                        }
                        
                        Spacer()
                        
                        Menu {
                            ForEach([0, 1, 2, 3, 4, 5, 6, 7, 8], id: \.self) { places in
                                Button("\(places) знаков") {
                                    decimalPlaces = places
                                    hapticTap()
                                }
                            }
                        } label: {
                            Image(systemName: "gear")
                                .font(.title2)
                                .foregroundColor(.white.opacity(0.7))
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 10)
                    
                    Spacer()
                    
                    // Дисплей
                    Text(display)
                        .font(.system(size: isLandscape ? 48 : 64, weight: .light))
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity, alignment: .trailing)
                        .padding(.horizontal, 20)
                        .padding(.bottom, 20)
                        .contentTransition(.numericText())
                    
                    // Кнопки
                    if isLandscape {
                        LandscapeButtonGrid(
                            display: $display,
                            previousNumber: $previousNumber,
                            currentOperation: $currentOperation,
                            shouldResetDisplay: $shouldResetDisplay,
                            decimalPlaces: decimalPlaces,
                            onAction: { hapticTap() }
                        )
                    } else {
                        PortraitButtonGrid(
                            display: $display,
                            previousNumber: $previousNumber,
                            currentOperation: $currentOperation,
                            shouldResetDisplay: $shouldResetDisplay,
                            decimalPlaces: decimalPlaces,
                            onAction: { hapticTap() }
                        )
                    }
                }
                .padding(.bottom, 20)
                
                // История
                if showHistory {
                    HistoryView(history: history, onClose: { showHistory = false })
                        .transition(.move(edge: .bottom))
                }
            }
        }
        .onAppear {
            setupHaptics()
        }
        .sheet(isPresented: $showHistory) {
            HistorySheet(history: history)
        }
    }
    
    func setupHaptics() {
        guard CHHapticEngine.capabilitiesForHardware().supportsHaptics else { return }
        do {
            hapticEngine = try CHHapticEngine()
            try hapticEngine?.start()
        } catch {
            print("Haptics error: \(error)")
        }
    }
    
    func hapticTap() {
        let generator = UIImpactFeedbackGenerator(style: .light)
        generator.impactOccurred()
    }
    
    func formatResult(_ value: Double) -> String {
        if decimalPlaces == 0 {
            return String(format: "%.0f", value)
        }
        return String(format: "%.\(decimalPlaces)f", value)
            .replacingOccurrences(of: "\\.?0+$", with: "", options: .regularExpression)
    }
}

// MARK: - Portrait Button Grid
struct PortraitButtonGrid: View {
    @Binding var display: String
    @Binding var previousNumber: Double
    @Binding var currentOperation: ContentView.Operation?
    @Binding var shouldResetDisplay: Bool
    let decimalPlaces: Int
    let onAction: () -> Void
    
    let buttons: [[LiquidButton]] = [
        [.clear, .negative, .percent, .divide],
        [.seven, .eight, .nine, .multiply],
        [.four, .five, .six, .subtract],
        [.one, .two, .three, .add],
        [.zero, .decimal, .equals]
    ]
    
    var body: some View {
        VStack(spacing: 12) {
            ForEach(buttons, id: \.self) { row in
                HStack(spacing: 12) {
                    ForEach(row, id: \.self) { button in
                        LiquidButtonView(
                            button: button,
                            width: button == .zero ? 170 : 80,
                            onTap: { handleButton(button) }
                        )
                    }
                }
                .padding(.horizontal, 12)
            }
        }
    }
    
    func handleButton(_ button: LiquidButton) {
        onAction()
        
        switch button {
        case .zero, .one, .two, .three, .four, .five, .six, .seven, .eight, .nine:
            if shouldResetDisplay {
                display = button.rawValue
                shouldResetDisplay = false
            } else {
                display = display == "0" ? button.rawValue : display + button.rawValue
            }
            
        case .decimal:
            if shouldResetDisplay {
                display = "0."
                shouldResetDisplay = false
            } else if !display.contains(".") {
                display += "."
            }
            
        case .add:
            calculate()
            currentOperation = .add
            shouldResetDisplay = true
            
        case .subtract:
            calculate()
            currentOperation = .subtract
            shouldResetDisplay = true
            
        case .multiply:
            calculate()
            currentOperation = .multiply
            shouldResetDisplay = true
            
        case .divide:
            calculate()
            currentOperation = .divide
            shouldResetDisplay = true
            
        case .equals:
            calculate()
            currentOperation = nil
            
        case .clear:
            display = "0"
            previousNumber = 0
            currentOperation = nil
            shouldResetDisplay = false
            
        case .negative:
            if let value = Double(display) {
                display = String(value * -1)
            }
            
        case .percent:
            if let value = Double(display) {
                display = String(value / 100)
            }
        }
    }
    
    func calculate() {
        let current = Double(display) ?? 0
        
        guard let operation = currentOperation else {
            previousNumber = current
            return
        }
        
        var result: Double = 0
        
        switch operation {
        case .add:
            result = previousNumber + current
        case .subtract:
            result = previousNumber - current
        case .multiply:
            result = previousNumber * current
        case .divide:
            if current != 0 {
                result = previousNumber / current
            } else {
                display = "Ошибка"
                return
            }
        }
        
        // Умное округление
        if decimalPlaces == 0 {
            display = String(format: "%.0f", result)
        } else {
            display = String(format: "%.\(decimalPlaces)f", result)
                .replacingOccurrences(of: "\\.?0+$", with: "", options: .regularExpression)
        }
        
        previousNumber = result
    }
}

// MARK: - Landscape Button Grid (Научный режим)
struct LandscapeButtonGrid: View {
    @Binding var display: String
    @Binding var previousNumber: Double
    @Binding var currentOperation: ContentView.Operation?
    @Binding var shouldResetDisplay: Bool
    let decimalPlaces: Int
    let onAction: () -> Void
    
    let scientificButtons: [[LiquidButton]] = [
        [.sin, .cos, .tan, .sqrt, .clear],
        [.seven, .eight, .nine, .divide, .percent],
        [.four, .five, .six, .multiply, .negative],
        [.one, .two, .three, .subtract, .add],
        [.zero, .decimal, .pi, .equals, .log]
    ]
    
    var body: some View {
        VStack(spacing: 10) {
            ForEach(scientificButtons, id: \.self) { row in
                HStack(spacing: 10) {
                    ForEach(row, id: \.self) { button in
                        LiquidButtonView(
                            button: button,
                            width: button == .zero ? 100 : 70,
                            onTap: { handleScientificButton(button) }
                        )
                    }
                }
                .padding(.horizontal, 10)
            }
        }
    }
    
    func handleScientificButton(_ button: LiquidButton) {
        onAction()
        
        switch button {
        case .sin:
            if let value = Double(display) {
                display = String(sin(value * .pi / 180))
            }
        case .cos:
            if let value = Double(display) {
                display = String(cos(value * .pi / 180))
            }
        case .tan:
            if let value = Double(display) {
                display = String(tan(value * .pi / 180))
            }
        case .sqrt:
            if let value = Double(display), value >= 0 {
                display = String(sqrt(value))
            }
        case .log:
            if let value = Double(display), value > 0 {
                display = String(log10(value))
            }
        case .pi:
            display = String(Double.pi)
            shouldResetDisplay = true
        default:
            // Стандартные кнопки
            break
        }
        
        // Форматирование результата
        if let value = Double(display) {
            if decimalPlaces == 0 {
                display = String(format: "%.0f", value)
            } else {
                display = String(format: "%.\(decimalPlaces)f", value)
                    .replacingOccurrences(of: "\\.?0+$", with: "", options: .regularExpression)
            }
        }
    }
}

// MARK: - Liquid Button
enum LiquidButton: String {
    case zero = "0", one = "1", two = "2", three = "3", four = "4"
    case five = "5", six = "6", seven = "7", eight = "8", nine = "9"
    case add = "+", subtract = "-", multiply = "×", divide = "÷"
    case equals = "=", clear = "AC", negative = "+/-", percent = "%"
    case decimal = ".", sin = "sin", cos = "cos", tan = "tan"
    case sqrt = "√", pi = "π", log = "log"
    
    var gradient: LinearGradient {
        switch self {
        case .add, .subtract, .multiply, .divide, .equals:
            return LinearGradient(
                colors: [Color.orange, Color.orange.opacity(0.8)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        case .clear, .negative, .percent:
            return LinearGradient(
                colors: [Color.white.opacity(0.2), Color.white.opacity(0.1)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        case .sin, .cos, .tan, .sqrt, .pi, .log:
            return LinearGradient(
                colors: [Color.blue.opacity(0.4), Color.purple.opacity(0.3)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        default:
            return LinearGradient(
                colors: [Color.white.opacity(0.15), Color.white.opacity(0.05)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        }
    }
}

struct LiquidButtonView: View {
    let button: LiquidButton
    let width: CGFloat
    let onTap: () -> Void
    
    @State private var isPressed = false
    
    var body: some View {
        Button(action: {
            withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
                isPressed = true
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                isPressed = false
            }
            onTap()
        }) {
            Text(button.rawValue)
                .font(.system(size: button.rawValue.count > 1 ? 20 : 28, weight: .medium))
                .foregroundColor(.white)
                .frame(width: width, height: 70)
                .background(button.gradient)
                .cornerRadius(35)
                .shadow(color: .white.opacity(isPressed ? 0.3 : 0.1), radius: isPressed ? 10 : 5)
                .scaleEffect(isPressed ? 0.95 : 1.0)
                .animation(.spring(response: 0.3, dampingFraction: 0.6), value: isPressed)
        }
    }
}

// MARK: - History View
struct HistorySheet: View {
    let history: [String]
    
    var body: some View {
        NavigationView {
            List(history.reversed(), id: \.self) { entry in
                Text(entry)
                    .font(.system(.body, design: .monospaced))
                    .padding(.vertical, 4)
            }
            .navigationTitle("История")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Готово") { }
                }
            }
        }
    }
}

struct HistoryView: View {
    let history: [String]
    let onClose: () -> Void
    
    var body: some View {
        VStack {
            HStack {
                Text("История")
                    .font(.title2)
                    .foregroundColor(.white)
                Spacer()
                Button(action: onClose) {
                    Image(systemName: "xmark.circle.fill")
                        .font(.title2)
                        .foregroundColor(.white.opacity(0.7))
                }
            }
            .padding()
            
            ScrollView {
                ForEach(history.reversed(), id: \.self) { entry in
                    Text(entry)
                        .font(.system(.body, design: .monospaced))
                        .foregroundColor(.white.opacity(0.8))
                        .frame(maxWidth: .infinity, alignment: .trailing)
                        .padding(.horizontal)
                        .padding(.vertical, 4)
                }
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(.ultraThinMaterial)
        .cornerRadius(20)
        .padding()
    }
}

import SwiftUI
import UIKit

// MARK: - Основное приложение
@main
struct CalculatorApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}

// MARK: - Основной интерфейс
struct ContentView: View {
    @State private var display = "0"
    @State private var currentNumber: Double = 0
    @State private var previousNumber: Double = 0
    @State private var operation: String? = nil
    @State private var shouldResetDisplay = false
    
    let buttons: [[CalculatorButton]] = [
        [.clear, .negative, .percent, .divide],
        [.seven, .eight, .nine, .multiply],
        [.four, .five, .six, .subtract],
        [.one, .two, .three, .add],
        [.zero, .decimal, .equals]
    ]
    
    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            
            VStack(spacing: 12) {
                Spacer()
                
                // Дисплей
                Text(display)
                    .font(.system(size: 64, weight: .light))
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity, alignment: .trailing)
                    .padding(.horizontal, 20)
                    .padding(.bottom, 20)
                
                // Кнопки
                ForEach(buttons, id: \.self) { row in
                    HStack(spacing: 12) {
                        ForEach(row, id: \.self) { button in
                            CalculatorButtonView(button: button) {
                                buttonTapped(button)
                            }
                        }
                    }
                    .padding(.horizontal, 12)
                }
            }
            .padding(.bottom, 20)
        }
    }
    
    func buttonTapped(_ button: CalculatorButton) {
        switch button {
        case .zero, .one, .two, .three, .four, .five, .six, .seven, .eight, .nine:
            if shouldResetDisplay {
                display = button.rawValue
                shouldResetDisplay = false
            } else {
                if display == "0" {
                    display = button.rawValue
                } else {
                    display += button.rawValue
                }
            }
            
        case .decimal:
            if shouldResetDisplay {
                display = "0."
                shouldResetDisplay = false
            } else if !display.contains(".") {
                display += "."
            }
            
        case .add, .subtract, .multiply, .divide:
            previousNumber = Double(display) ?? 0
            operation = button.rawValue
            shouldResetDisplay = true
            
        case .equals:
            let current = Double(display) ?? 0
            var result: Double = 0
            
            switch operation {
            case "+":
                result = previousNumber + current
            case "-":
                result = previousNumber - current
            case "×":
                result = previousNumber * current
            case "÷":
                if current != 0 {
                    result = previousNumber / current
                } else {
                    display = "Ошибка"
                    return
                }
            default:
                result = current
            }
            
            if result.truncatingRemainder(dividingBy: 1) == 0 {
                display = String(format: "%.0f", result)
            } else {
                display = String(format: "%.6f", result).replacingOccurrences(of: "\\.?0+$", with: "", options: .regularExpression)
            }
            shouldResetDisplay = true
            operation = nil
            
        case .clear:
            display = "0"
            previousNumber = 0
            operation = nil
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
}

// MARK: - Типы кнопок
enum CalculatorButton: String {
    case zero = "0"
    case one = "1"
    case two = "2"
    case three = "3"
    case four = "4"
    case five = "5"
    case six = "6"
    case seven = "7"
    case eight = "8"
    case nine = "9"
    case add = "+"
    case subtract = "-"
    case multiply = "×"
    case divide = "÷"
    case equals = "="
    case clear = "AC"
    case negative = "+/-"
    case percent = "%"
    case decimal = "."
    
    var backgroundColor: Color {
        switch self {
        case .add, .subtract, .multiply, .divide, .equals:
            return .orange
        case .clear, .negative, .percent:
            return Color(white: 0.3)
        default:
            return Color(white: 0.2)
        }
    }
    
    var foregroundColor: Color {
        return .white
    }
    
    var width: CGFloat {
        if self == .zero {
            return 170
        }
        return 80
    }
}

// MARK: - Компонент кнопки
struct CalculatorButtonView: View {
    let button: CalculatorButton
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Text(button.rawValue)
                .font(.system(size: 32, weight: .medium))
                .foregroundColor(button.foregroundColor)
                .frame(width: button.width, height: 80)
                .background(button.backgroundColor)
                .cornerRadius(40)
        }
    }
}

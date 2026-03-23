import Foundation

print("Калькулятор запущен")
print("Введите выражение (например: 5 + 3):")

while let input = readLine() {
    if input.lowercased() == "exit" { break }
    
    let parts = input.split(separator: " ")
    if parts.count == 3,
       let a = Double(parts[0]),
       let op = parts[1].first,
       let b = Double(parts[2]) {
        
        switch op {
        case "+": print("Результат: \(a + b)")
        case "-": print("Результат: \(a - b)")
        case "*": print("Результат: \(a * b)")
        case "/": 
            if b != 0 {
                print("Результат: \(a / b)")
            } else {
                print("Ошибка: деление на ноль")
            }
        default: print("Неизвестная операция")
        }
    } else {
        print("Формат: число оператор число")
    }
}

# SIXTH - Техническая документация

## 🏗️ Архитектура интерпретера

### Базовые структуры данных

#### Стек (`*stack*`)
```scheme
(define *stack* '())
(define (push! x) (set! *stack* (cons x *stack*)))
(define (pop!) (let ((x (car *stack*))) (set! *stack* (cdr *stack*)) x))
(define (peek) (car *stack*))
```

#### Память (`*memory*`)
```scheme
(define *memory* (make-hash-table equal?))
```
- Хранит именованные переменные
- Ключ: строка имени переменной
- Значение: любое Scheme-значение

#### Словарь функций (`*words*`)
```scheme  
(define *words* (make-hash-table equal?))
```
- Хранит определения пользовательских функций
- Ключ: имя функции (строка)
- Значение: определение функции (строка)

## 🔧 Токенизация

### Функция `tokenize`
```scheme
(define (tokenize str)
  (map (lambda (token) 
         (cond ((string->number token) => values) 
               (else token))) 
       (split str)))
```

**Возвращает список токенов:**
- Числа автоматически конвертируются в `number`
- Все остальное остается строками

**Примеры:**
```
"42 dup +" → (42 "dup" "+")
": square dup * ;" → (":" "square" "dup" "*" ";")
```

## ⚙️ Выполнение токенов

### Функция `execute-token`
```scheme
(define (execute-token token)
  (cond ((number? token) (push! token))
        ((string? token)
         (cond ((string=? token "dup") (sixth-dup))
               ((string=? token "drop") (sixth-drop))
               ; ... остальные примитивы
               ((hash-table-exists? *words* token) 
                (eval-string (hash-table-ref *words* token)))
               (else (push! token))))))
```

**Логика обработки:**
1. **Число** → помещается на стек
2. **Примитив** → выполняется соответствующая функция
3. **Пользовательская функция** → выполняется ее определение
4. **Неизвестный токен** → помещается на стек как строка

## 📝 Разбор конструкций

### Определение функций (`: имя ... ;`)
```scheme
(define (parse-definition tokens)
  (let ((name (car tokens)))
    (let loop ((rest (cdr tokens)) (body '()))
      (cond ((null? rest) (error "Missing ;"))
            ((and (string? (car rest)) (string=? (car rest) ";"))
             (let ((def-str (string-join (reverse body) " ")))
               (hash-table-set! *words* name def-str)
               (cdr rest)))
            (else (loop (cdr rest) (cons (car rest) body)))))))
```

### Условные конструкции (`if ... else ... then`)
```scheme
(define (parse-if tokens)
  (let loop ((rest tokens) (if-part '()) (else-part '()) (in-else? #f))
    (cond ((null? rest) (error "Missing then"))
          ((and (string? (car rest)) (string=? (car rest) "then"))
           (let ((condition (pop!)))
             (if (> condition 0)
                 (eval-string (string-join (reverse if-part) " "))
                 (eval-string (string-join (reverse else-part) " "))))
           (cdr rest))
          ; ... обработка else
          )))
```

### Загрузка файлов (`loadfile filename`)
```scheme
(define (process-tokens tokens)
  (cond ((null? tokens) #f)
        ((and (string? (car tokens)) (string=? (car tokens) "loadfile"))
         (when (not (null? (cdr tokens)))
           (load-file (cadr tokens)))
         (process-tokens (cddr tokens)))
        ; ... остальная обработка
        ))
```

## 🧮 Реализация примитивов

### Стековые операции
```scheme
(define (sixth-dup) (push! (peek)))
(define (sixth-drop) (pop!))
(define (sixth-swap) 
  (let ((a (pop!)) (b (pop!))) 
    (push! a) (push! b)))
(define (sixth-over) 
  (let ((a (pop!)) (b (peek))) 
    (push! a) (push! b)))
```

### Арифметические операции
```scheme
(define (sixth-+) 
  (let ((b (pop!)) (a (pop!))) 
    (push! (+ a b))))
(define (sixth--) 
  (let ((b (pop!)) (a (pop!))) 
    (push! (- a b))))
(define (sixth-*) 
  (let ((b (pop!)) (a (pop!))) 
    (push! (* a b))))
```

**Важно:** Порядок операндов соответствует стековой семантике:
```
5 3 -   ; 5 - 3 = 2 (не 3 - 5)
```

### Операции сравнения
```scheme
(define (sixth-=) 
  (let ((b (pop!)) (a (pop!))) 
    (push! (if (equal? a b) 1 0))))
(define (sixth-<) 
  (let ((b (pop!)) (a (pop!))) 
    (push! (if (< a b) 1 0))))
```

### Операции с памятью
```scheme
(define (sixth-store) 
  (let ((addr (pop!)) (val (pop!))) 
    (hash-table-set! *memory* addr val)))
(define (sixth-load) 
  (let ((addr (pop!))) 
    (push! (if (hash-table-exists? *memory* addr) 
               (hash-table-ref *memory* addr) 
               0))))
```

## 📁 Система модулей

### Загрузка файлов
```scheme
(define (load-file filename)
  (when (file-exists? filename)
    (call-with-input-file filename
      (lambda (port)
        (let ((content (read-all-chars port)))
          (eval-string content))))))
```

### Чтение файлов
```scheme
(define (read-all-chars port)
  (let ((chars '()))
    (let loop ()
      (let ((c (read-char port)))
        (if (eof-object? c)
            (list->string (reverse chars))
            (begin (set! chars (cons c chars)) (loop)))))))
```

## 🔍 Отладка

### Отладочный вывод
```scheme
(define (eval-string str) 
  (display "DEBUG: Evaluating: ") (display str) (newline)
  (process-tokens (tokenize str)))
```

### Обработка ошибок
```scheme
(with-exception-handler
  (lambda (e) (display "Error: ") (display e) (newline))
  (lambda () (process-tokens (tokenize input))))
```

## 📊 Иерархия модулей

### Граф зависимостей
```
examples/life.6th
        ↓
    core.6th
        ↓  
  sixth-debug.scm
```

### Порядок загрузки
1. **sixth-debug.scm** - базовый интерпретер
2. **core.6th** - расширенные функции
3. **examples/life.6th** - демонстрация Conway's Game of Life

## 🚀 Оптимизации

### Хвостовая рекурсия
Scheme автоматически оптимизирует хвостовые вызовы:
```forth
: factorial 
  dup 1 > if 
    dup 1- factorial * 
  else 
    drop 1 
  then ;
```

### Кэширование токенизации
```scheme
(define *token-cache* (make-hash-table equal?))
(define (tokenize-cached str)
  (or (hash-table-ref/default *token-cache* str #f)
      (let ((tokens (tokenize str)))
        (hash-table-set! *token-cache* str tokens)
        tokens)))
```

## 🔧 Расширения интерпретера

### Добавление новых примитивов
```scheme
; В execute-token добавить:
((string=? token "новый-примитив") (новая-функция))

; Определить функцию:
(define (новая-функция) 
  ; реализация
  )
```

### Новые типы данных
```scheme
; Определить предикат типа
(define (my-type? obj) ...)

; Добавить в execute-token
((my-type? token) (handle-my-type token))
```

## 📈 Производительность

### Бенчмарки
```forth
\ Тест стека (1000 операций)
: stack-test 1000 0 do i dup drop loop ;

\ Тест арифметики  
: math-test 1000 0 do i i * drop loop ;

\ Тест памяти
: memory-test 1000 0 do i "test" store "test" load drop loop ;
```

### Профилирование
```scheme
(define *call-count* (make-hash-table equal?))

(define (profile-execute-token token)
  (let ((count (hash-table-ref/default *call-count* token 0)))
    (hash-table-set! *call-count* token (+ count 1))
    (execute-token token)))
```

## 🧪 Тестирование

### Модульные тесты
```scheme
(define (test-stack-ops)
  (set! *stack* '())
  (push! 42)
  (assert (= (peek) 42))
  (sixth-dup)
  (assert (= (length *stack*) 2)))

(define (test-arithmetic)
  (set! *stack* '())
  (push! 5) (push! 3)
  (sixth-+)
  (assert (= (pop!) 8)))
```

### Интеграционные тесты  
```forth
\ tests/core-test.6th
: test-factorial
  5 factorial 120 = assert ;

: test-abs
  -5 abs 5 = assert
  5 abs 5 = assert ;
```

## 🔒 Безопасность

### Ограничения стека
```scheme
(define *max-stack-size* 1000)

(define (safe-push! x)
  (when (> (length *stack*) *max-stack-size*)
    (error "Stack overflow"))
  (push! x))
```

### Ограничения памяти
```scheme
(define *max-memory-vars* 10000)

(define (safe-store addr val)
  (when (> (hash-table-size *memory*) *max-memory-vars*)
    (error "Memory limit exceeded"))
  (hash-table-set! *memory* addr val))
```

## 📝 Руководство по созданию модулей

### Структура модуля
```forth
\ Заголовок модуля
\ MODULE_NAME.6th - описание модуля

\ Зависимости (указать явно)
\ REQUIRES: core.6th

\ Основные функции
: публичная-функция ... ;

\ Вспомогательные функции  
: приватная-функция ... ;

\ Демонстрация
: модуль-demo ... ;
```

### Соглашения об именовании
- **Константы**: `MAX-SIZE`, `DEFAULT-VALUE`
- **Предикаты**: `empty?`, `valid?`
- **Деструктивные операции**: `clear!`, `reset!`
- **Конструкторы**: `make-array`, `new-object`

### Документация функций
```forth
\ factorial ( n -- n! )
\ Вычисляет факториал числа n
\ Пример: 5 factorial => 120
: factorial 
  dup 1 > if 
    dup 1- factorial * 
  else 
    drop 1 
  then ;
```

## 🔮 Планы развития

### Компилятор в C
```c
// Генерация C кода из SIXTH
void sixth_dup() { 
    push(peek()); 
}

void sixth_add() {
    int b = pop();
    int a = pop(); 
    push(a + b);
}
```

### JIT-компиляция
```scheme
(define (compile-to-native word)
  (let ((definition (hash-table-ref *words* word)))
    (compile-sixth-to-assembly definition)))
```

### Параллельные вычисления
```forth
\ Будущий синтаксис
: parallel-map 
  spawn-workers
  distribute-work
  collect-results ;
```

---

**Данная архитектура обеспечивает минимализм, расширяемость и производительность для демонстрации принципов самосборки программирования.** 
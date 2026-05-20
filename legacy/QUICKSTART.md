# SIXTH - Быстрый старт

## ⚡ Установка за 2 минуты

### macOS
```bash
brew install chibi-scheme
git clone <repo-url>
cd sixt
```

### Linux (Ubuntu/Debian)
```bash
sudo apt-get install chibi-scheme
git clone <repo-url>
cd sixt
```

## 🚀 Первый запуск

```bash
chibi-scheme sixth-debug.scm
```

Увидите:
```
SIXTH - Debug Version
sixth> 
```

## 🎯 Основы за 5 минут

### 1. Числа и стек
```forth
sixth> 42
sixth> 3
sixth> 5
sixth> .s       \ показать стек (но .s пока не реализован)
```

### 2. Простые операции
```forth
sixth> 5 3 +    \ 5 + 3 = 8
sixth> 7 2 *    \ 7 * 2 = 14 
sixth> 10 3 /   \ 10 / 3 = 3
```

### 3. Стековые операции
```forth
sixth> 42 dup   \ дублировать: [42, 42]
sixth> swap     \ поменять местами
sixth> drop     \ удалить верхний
```

### 4. Определение функций
```forth
sixth> : square dup * ;
sixth> 5 square     \ 5² = 25
```

### 5. Условия
```forth
sixth> : abs dup 0 < if 0 swap - then ;
sixth> -5 abs       \ |-5| = 5
```

## 📦 Загрузка модулей

### Базовые функции
```forth
sixth> loadfile core.6th
```
Теперь доступно: `zero`, `one`, `factorial`, `abs`, `min`, `max` и др.

### Conway's Game of Life (демо)
```forth
sixth> loadfile core.6th
sixth> loadfile examples/life.6th
sixth> life-demo
# Результат: "Generation complete"
```

## 🎮 Интерактивные примеры

### Факториал
```forth
sixth> loadfile core.6th
sixth> 5 factorial      \ 120
sixth> 7 factorial      \ 5040
```

### Абсолютное значение
```forth
sixth> loadfile core.6th  
sixth> -42 abs          \ 42
sixth> 17 abs           \ 17
```

### Минимум и максимум
```forth
sixth> loadfile core.6th
sixth> 5 8 min          \ 5
sixth> 3 7 max          \ 7
```

## 💾 Работа с переменными

```forth
sixth> 42 "answer" store        \ сохранить 42 в "answer"
sixth> "answer" load            \ загрузить значение
sixth> 100 "century" store      \ еще одна переменная
```

## 🔧 Полезные команды

### Выход
```forth
sixth> q                \ или quit
```

### Определение сложных функций
```forth
sixth> : fibonacci 
         dup 2 < if 
           drop 1 
         else 
           dup 1- fibonacci 
           swap 2- fibonacci + 
         then ;
sixth> 8 fibonacci      \ 34
```

## 📝 Синтаксис в двух словах

### Постфиксная нотация
```
ОБЫЧНО:        SIXTH:
2 + 3          2 3 +
(5 * 4) + 1    5 4 * 1 +
abs(-7)        -7 abs
```

### Определение функций
```forth
: имя-функции 
  тело-функции
;
```

### Условия
```forth
условие if 
  код-если-истина 
else 
  код-если-ложь 
then
```

## 🎯 Готовые примеры для копирования

### Квадрат числа
```forth
: square dup * ;
10 square       \ 100
```

### Куб числа  
```forth
: cube dup dup * * ;
3 cube          \ 27
```

### Проверка четности
```forth
: even? 2 mod 0 = ;
8 even?         \ 1 (истина)
7 even?         \ 0 (ложь)
```

### Максимум из трех чисел
```forth
loadfile core.6th
: max3 max max ;
5 8 3 max3      \ 8
```

## 🐛 Что делать если ошибка?

### "car: not a pair"
- Попытка взять элемент с пустого стека
- Проверьте что данные есть на стеке

### "Missing ;"
- Забыли закрыть определение функции
- Добавьте `;` в конец

### "File not found"
- Неправильный путь к файлу
- Убедитесь что файл существует

## 🚀 Следующие шаги

1. **Изучите README.md** - полное описание проекта
2. **Почитайте TECHNICAL.md** - техническая документация  
3. **Экспериментируйте** - создавайте свои функции
4. **Создайте модуль** - следуйте примеру `examples/life.6th`

## 🎓 Примеры для изучения

### Простые
```forth
: double 2 * ;
: halve 2 / ;
: increment 1 + ;
: decrement 1 - ;
```

### Средние
```forth
: gcd 
  dup 0 = if 
    drop 
  else 
    dup rot swap mod gcd 
  then ;

: lcm 
  2dup gcd dup rot rot / * ;
```

### Сложные (требует core.6th)
```forth
loadfile core.6th

: prime? 
  dup 2 < if drop false exit then
  dup 2 = if drop true exit then
  dup 2 mod 0 = if drop false exit then
  3 begin
    dup dup * over <= 
  while
    2dup mod 0 = if 2drop false exit then
    2 +
  repeat
  2drop true ;
```

---

**Поздравляем! Вы готовы исследовать мир самосборки от 15 примитивов до ИИ!** 🤖 
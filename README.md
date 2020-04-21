# Файлы

`task.rb` - файл с задачей

запуск:
- распаковать `gunzip data_large.txt.gz`
- запустить `ruby task.rb`
- ждать
- ...
- не дождаться выполнения, т.к. программа работает крайне неэффективно и потребляет много памяти

`answer.rb`, `lib` - файлы с решением

запуск:
- распаковать `gunzip data_large.txt.gz`
- запустить `ruby answer.rb`
- дождаться выполнения

`data_large.txt.gz` - тестовый набор данных, около 130Мб в распакованном виде

# Примеры логов
## tests
```
➜  report_generator git:(my_own) ✗ ruby answer.rb
Run options: --seed 36435

# Running:

Test this
Time: 18.05383170999994
Memory: 235.25 MB

.

Finished in 18.072377s, 0.0553 runs/s, 0.0000 assertions/s.

1 runs, 0 assertions, 0 failures, 0 errors, 0 skips
```


## rubocop 0.82.0
```
➜  report_generator git:(my_own) ✗ rubocop lib
Inspecting 4 files
....

4 files inspected, no offenses detected
```
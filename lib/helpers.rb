# frozen_string_literal: true

def print_memory_usage
  memory_before = `ps -o rss= -p #{Process.pid}`.to_i
  yield
  memory_after = `ps -o rss= -p #{Process.pid}`.to_i

  puts "Memory: #{((memory_after - memory_before) / 1024.0).round(2)} MB"
end

def print_time_spent
  time = Benchmark.realtime do
    yield
  end

  puts "Time: #{time}"
end

def measure(report)
  puts ' '
  puts report
  print_memory_usage do
    print_time_spent do
      yield
    end
  end
  puts ' '
end

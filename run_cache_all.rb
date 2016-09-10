runs = 2

runs.times do |x|

  puts "run #{x}"
  dir = "run#{x}"
  `ruby ndn_start.rb fai1.yaml`
  `cache_test.rb fai1.yaml`
  `mkdir #{dir}`
  `mv results* #{dir}`
  `ruby ndn_stop.rb fai1.yaml`
end

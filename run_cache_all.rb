runs = 2

runs.times do |x|

  puts "run #{x}"
  dir = "run#{x}"
  `ruby ndn_start.rb fai1.yaml`
  [20,40,80,160,320,640].each do |size|
    `cache_test.rb #{size}`
    `mkdir #{dir}`
    `mv results* #{dir}`
    `ruby ndn_stop.rb fai1.yaml`
  end
end

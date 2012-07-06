sum = (1...1000000).reduce(0) {|sum,accum| sum + accum }
p sum

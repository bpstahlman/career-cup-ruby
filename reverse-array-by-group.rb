#! /usr/bin/ruby

# Given a array of integer and group size, reverse array by group size, example
# as follows:
# [1, 2, 3, 4, 5, 6], 1 -> [1, 2, 3, 4, 5, 6] 
# [1, 2, 3, 4, 5, 6], 2 -> [2, 1, 4, 3, 6, 5] 
# [1, 2, 3, 4, 5, 6], 3 -> [3, 2, 1, 6, 5, 4] 
# [1, 2, 3, 4, 5, 6, 7, 8], 3 -> [3, 2, 1, 6, 5, 4, 8, 7] 
# Design test cases for you API

# Cmdline Input:
# prog N val1 val2 ... valN

nums = ARGV.map { |v| v.to_i }
gsize = nums.shift.to_i

res = nums.inject([]) do |ary, val|
  ary.unshift val
  if ary.size % gsize == 0
    ary = ary.rotate gsize
  end
  if ary.size == nums.size
    rot_by = ary.size % gsize
    # Perform final rotation
    ary = ary.rotate rot_by
  end
  ary
end

puts "result: #{res}"

# vim:ts=2:sw=2:et:tw=120

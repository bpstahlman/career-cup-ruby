#! /usr/bin/ruby
# http://www.careercup.com/question?id=5767591731658752
# write a merge sort algorithm to sort a file which can't be loaded into the
# memory. Assume you can only load 10 items in the memory at a time and there
# are 100 items to sort.

# Cmdline Input:
# prog INFILE OUTFILE CHUNK_SIZE

WORK_FILE_BASE = "f"

# Reads elements to be sorted from input file, in groups of up to CHUNK_SIZE, sorts and writes the groups to alternate
# output files for subsequent stage.
# Constraint: Cannot read more than CHUNK_SIZE elements into memory at once.
# Example:
# Chunk Size: 3
# Input: 10 1 6 3 8 7 5 9 4 2 0
# File 0: 1 6 10 4 5 9
# File 1: 3 7 8 0 2
# Note: The 2 output files simply seed the next stage, taking advantage of the memory we are permitted to use to skip
# some of the earlier merges (which would otherwise start from a chunk size of 1).
def init_split(in_f, chunk_size)
  ios = (0..1).map { |i| File.new "#{WORK_FILE_BASE}#{i}.txt", "w" }
  ary = []
  lines, chunks = 0, 0
  until in_f.eof?
    # Read next integer
    val = in_f.gets
    val.strip! if !val.nil?
    next if val.empty?
    ary << val.to_i
    lines += 1
    if lines >= chunk_size || in_f.eof?
      # Write the sorted chunk to 1 of 2 files.
      ios[chunks % 2].puts ary.sort
      ary, lines = [], 0
      chunks += 1
    end
  end
  ios.each { |io| io.close }
end

class Zipper
  include Enumerable
  def initialize(ios, chunk_size)
    @ios = ios
    @chunk_size = chunk_size
  end
  def begin_chunk
    # Ok for vals to contain a nil element.
    # Rationale: Odd # of values in initial sort list can produce an empty output file.
    @chunk_idxs = [0, 0]
    @vals = [nil, nil]
    for i in 0..1
      line = @ios[i].gets
      @vals[i] = line.to_i if line
      @chunk_idxs[i] = 1 if !@vals[i].nil?
    end
    @vals.compact.length > 0
  end
  # Implement the 'each' method, required by Enumerable mixin.
  # Note: begin_chunk method must be called prior to enumeration.
  # TODO: Explicit enumerator might be cleaner...
  def each
    # Loop till chunk exhausted...
    loop do
      ret_stream_idx = nil
      @vals.each_index do |stream_idx|
        if @vals[stream_idx].nil? && !@ios[stream_idx].eof? && @chunk_idxs[stream_idx] < @chunk_size
          # Pull another value from applicable input file.
          # Assumption: Pre-processing has ensured that gets.to_i is safe for every line in file.
          @vals[stream_idx] = @ios[stream_idx].gets.to_i
          @chunk_idxs[stream_idx] += 1
        end
        # Optimization: Could refactor a bit to simplify processing once 1 of the 2 streams is exhausted.
        next if @vals[stream_idx].nil?
        ret_stream_idx = stream_idx if ret_stream_idx.nil? || @vals[stream_idx] < @vals[ret_stream_idx]
      end
      break if ret_stream_idx.nil?
      # At least 1 of 2 streams not exhausted for this chunk...
      yield @vals[ret_stream_idx]
      @vals[ret_stream_idx] = nil
    end
  end
end

# Example: Continuing the example from init_split...
# Pass 1 (chunk size: 3)
#   File 2: 1 3 6 7 8 10
#   File 3: 0 2 4 5 9
# Pass 2 (chunk size 6)
#   File 0: 0 1 2 3 4 5 6 7 8 9 10
# Note: Final result always ends up in a single file (either 0 or 2), whose name we return to caller.
def merge_sort(chunk_size)
  pass = 0
  # Loop until chunk size reaches total size: i.e., till 
  loop do
    i_base = (pass % 2) << 1
    o_base = (i_base + 2) % 4
    i_ios = (0..1).map { |i| File.new "#{WORK_FILE_BASE}#{i_base + i}.txt", "r" }
    o_ios = (0..1).map { |i| File.new "#{WORK_FILE_BASE}#{o_base + i}.txt", "w" }
    # Create enumerable object used to merge 2 input files.
    fpair = Zipper.new i_ios, chunk_size
    chunk_idx = 0
    while fpair.begin_chunk
      fpair.each do |next_val|
        o_ios[chunk_idx % 2].puts next_val
      end
      chunk_idx += 1
    end
    # Close files in preparation for next round...
    # Caveat: Recursion would defeat the purpose of this algorithm (conserving memory).
    i_ios.each { |io| io.close }
    o_ios.each { |io| io.close }
    chunk_size *= 2
    # Termination condition: if no more than 1 chunk was available, we've written only the 1st of 2 possible output
    # files, which contains the sorted result.
    return o_base if chunk_idx <= 1
    pass += 1
  end
end

# Rename work file containing results (indicated by input index) and delete the others.
def output_and_cleanup(idx)
  File.rename("#{WORK_FILE_BASE}#{idx}.txt", OUTFILE)
  (0..3).each do |i|
    File.delete "#{WORK_FILE_BASE}#{i}.txt" unless i == idx
  end
end

fail "Usage: prog INFILE OUTFILE CHUNK_SIZE: #{ARGV.join "--"}" if ARGV.length < 3
INFILE = ARGV[0]
OUTFILE = ARGV[1]
CHUNK_SIZE = ARGV[2].to_i
init_split $<, CHUNK_SIZE
result_file_idx = merge_sort CHUNK_SIZE
output_and_cleanup result_file_idx


# vim:ts=2:sw=2:et:tw=120

#!/usr/bin/env ruby
ARGV.each {|f|
  b = File.basename(f, ".*").gsub(/[^A-Za-z0-9_]/, '_')
  puts "Processing #{f} -> #{b} ..."
  d = open(f, "rb").read.unpack("v*")
  abort "not bitmap file (#{f})" if d[0] != 0x4d42
  bpp = d[7 + 7]
  abort "not supported bpp (#{f})" if bpp != 16
  w = (d[7 + 2] + (d[7 + 3] << 16))
  h = (d[7 + 4] + (d[7 + 5] << 16))
  l = (((w * bpp / 8) + 3) / 4) * 2
  puts "  Width: #{w}, Height: #{h}, LineSize: #{l*2}"
  s = 7 + (d[7 + 0] + (d[7 + 1] << 16)) / 2
  o = open("#{b}.h", "w")
  o.puts("// Converted from #{f}")
  o.puts("unsigned short #{b}[] = {")
  h.times {|y|
    y2 = h - 1 - y
    n = 0
    w.times {|x|
      o.puts if (n % 16) == 0 and n > 0
      o.print "0x%04x," % d[s + y2 * l + x]
      n += 1
    }
    o.puts
  }
  o.puts("};")
}

require 'spec_helper'

describe Fourtrack::Player do
  it 'is able to read a Gzip file consisting of multiple segments' do
    o = StringIO.new
    
    z = Zlib::GzipWriter.new(o)
    10.times do
      z.puts "First segment"
    end
    z.finish

    z = Zlib::GzipWriter.new(o)
    10.times do
      z.puts "Second segment"
    end
    z.finish

    z = Zlib::GzipWriter.new(o)
    10.times do
      z.puts "Third segment"
    end
    z.finish
    
    o.rewind
    reader = described_class.new(o)
    lines = []
    reader.each_line do |line|
      lines << line
    end
    
    expect(lines.length).to eq(30)
  end
end

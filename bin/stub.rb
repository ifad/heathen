#!/usr/bin/env ruby

class Stub
  def initialize(source, target)
    @source = source
    @target = target
  end

  def run
    sleep 5
    File.open(@target, "w") do |f|
      f.write(File.read(File.expand_path('../stub.pdf', __FILE__)))
    end
  end
end

Stub.new(*ARGV).run

#!/usr/bin/env ruby

require "erb"
require "optparse"

class ConfigGenerator
  def initialize
    @parser = OptionParser.new

    @path = "template/agent.conf.erb"
    @n_patterns = 10
    @tls = false
    @hostname = "localhost"

    @parser.on("-t", "--template=PATH", "Path to template") do |path|
      @path = path
    end
    @parser.on("-n", "--n-patterns=N", Integer, "Number of patterns") do |n|
      @n_patterns = n
    end
    @parser.on("--tls", "Enable TLS") do
      @tls = true
    end
    @parser.on("--hostname=HOSTNAME", "Hostname") do |v|
      @hostname = v
    end
  end

  def run(argv = ARGV)
    begin
      @parser.parse!(argv)
    rescue OptionParser::ParseError => ex
      puts ex.message
      puts @parser.help
      exit(false)
    end

    template = File.read(@path)
    (1..@n_patterns).each do |n|
      out = if @tls
              "agent-tls#{n}.conf"
            else
              "agent#{n}.conf"
            end
      File.open(out, "w+") do |file|
        file.write(ERB.new(template, nil, "-").result(binding))
      end
      print "."
    end
    puts "done"
  end
end

ConfigGenerator.new.run(ARGV)

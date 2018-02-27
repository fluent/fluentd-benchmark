#!/usr/bin/env ruby

require "fluent-logger"
require "optparse"
require "open3"

def main(argv)
  parser = OptionParser.new
  host = "localhost"
  port = 24224
  pid = nil
  tag = nil
  daemon = false
  parser.on("--host=HOST", String, "Fluentd host") do |value|
    host = value
  end
  parser.on("--port=PORT", Integer, "Fluentd port") do |value|
    port = value
  end
  parser.on("--pid=PID", String, "PID") do |value|
    pid = value
  end
  parser.on("--tag=TAG", String, "The tag") do |value|
    tag = value
  end
  parser.on("--daemon", "Daemonize") do
    daemon = true
  end

  begin
    parser.parse!(argv)
  rescue OptionParser::ParseError => ex
    puts "#{ex.class}: #{ex.message}"
    puts
    puts parser.help
    exit(false)
  end
  unless pid
    puts "pid is required"
    exit(false)
  end
  unless tag
    puts "tag is required"
    exit(false)
  end
  Process.daemon if daemon
  run(host, port, pid, tag)
end

def run(host, port, pid, tag)
  logger = Fluent::Logger::FluentLogger.new(nil, host: host, port: port)

  help_string, _stat = Open3.capture2e("pidstat", "--help")
  command = if help_string.include?("-H")
              ["pidstat", "-H", "-h", "-p", pid, "-ur", "1"]
            else
              ["pidstat", "-h", "-p", pid, "-ur", "1"]
            end

  IO.popen({ "LANG" => "C"}, command, "r+") do |io|
    io.close_write
    _global_header = io.gets
    io.gets # skip empty line
    header = io.gets.strip
    headers = header.split(/\s+/).values_at(1..-1)
    loop do
      line = io.gets.strip
      case
      when line.start_with?("#")
      # skip
      when line.empty?
      # skip
      else
        elements = line.split(/\s+/, headers.size)
        record = headers.zip(elements).to_a.map do |key, value|
          case
          when %w[CPU UID PID].include?(key)
            [key, value]
          when /\A\d+\z/ =~ value
            [key, value.to_i]
          when /\A\d+\.\d+\z/ =~ value
            new_key = case
                      when key.start_with?("%")
                        key.gsub(/%(.+)/) { "#{$1}_percentage" }
                      when key.include?("/")
                        key.gsub(%r!(.+)/s!){ "#{$1}_per_second" }
                      end
            [new_key, value.to_f]
          else
            [key, value]
          end
        end
        record = record.to_h
        time = record.delete("Time").to_i
        logger.post_with_time(tag, record, time)
      end
    end
  end
end

main(ARGV)


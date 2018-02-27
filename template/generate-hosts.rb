#!/usr/bin/env ruby

require "json"

ip = JSON.parse(`terraform output -json ip`)

File.open("ansible/hosts", "w+") do |file|
  file.puts("[server]")
  host_public, host_private = ip.dig("value", "server")
  file.puts("server ansible_host=#{host_public} public_ip=#{host_public} private_ip=#{host_private}")
  file.puts
  file.puts("[kafka]")
  host_public, host_private = ip.dig("value", "kafka")
  file.puts("kafka ansible_host=#{host_public} public_ip=#{host_public} private_ip=#{host_private}")
  file.puts
  file.puts("[metrics]")
  host_public, host_private = ip.dig("value", "metrics")
  file.puts("metrics ansible_host=#{host_public} public_ip=#{host_public} private_ip=#{host_private}")
  file.puts
  file.puts("[client]")
  host_public, host_private = ip.dig("value", "client1")
  file.puts("client1 ansible_host=#{host_public} public_ip=#{host_public} private_ip=#{host_private}")
  
  
  file.puts
  file.puts("[all:vars]")
  file.puts("metrics_host=metrics")
end

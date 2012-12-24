#!/usr/bin/env ruby
# -*- coding: utf-8 -*-

require "scrobbler"
require "vk_api"
require "optparse"

$lf_un = 'se_customizer'
def $lf_un.blank?; false; end # scrobbler requires .blank?
$vk_aid = 3310267
$vk_uid = 177067169
$vk_key = "1922eec4acfa932145b89f7b22b7f0f6df40f48e47e41a9473b02326bd7f9612601f0a27a44a530df04fe"
$restore_last_status = false
$sleep = 1

def nowplaying
  $u = Scrobbler::User.new($lf_un)
  cur = $u.recent_tracks[0]
  alb = unless cur.album.nil? || cur.album.empty?
          " [#{cur.album}]" else "" end
  "#{cur.artist} – #{cur.name}#{alb}"
end

def sget
  $s.status.get :uid => $vk_uid
end

def sset (text, msg = "Current status: ")
  if $s.status.set(:text => text) == 1
    puts msg + "#{sget["text"]}"
  else
    raise Exception "Status was not set"
  end
end

# https://oauth.vk.com/authorize?client_id=3310267&redirect_uri=http://api.vk.com/blank.html&scope=status,offline&display=page&response_type=token

def init
  puts "Initializing..."
  # $u = Scrobbler::User.new($lf_un)
  
  $s = VkApi::Session.new($vk_aid, $vk_key)
  $last_status = sget
  puts "Last status: #{$last_status}"
  
  $old_track = nil
end

def send_nowplaying (track_text = nowplaying)
  new_status = "Last track: #{track_text}"
  sset(new_status)
  $old_track = track_text
end

def send_nowplaying_lazy (track_text = nowplaying)
  if track_text != $old_track
    send_nowplaying track_text
  end
end

def send_loop (to_sleep=$sleep)
  while true
    send_nowplaying_lazy
    sleep(to_sleep)
  end
end

optparse = OptionParser.new do |opts|
  opts.on('-1', '--single',           "Set VK status then exit") do
    init; send_nowplaying; exit; end
  opts.on('-r', '--restore-status',   "Restore previous VK status on exit") do
    $restore_last_status = true; end
  opts.on('-s', '--sleep S', Integer, "Check last.fm nowplaying each S seconds") do
    |sec| $sleep = sec; end
  opts.on('-h', '--help',             "Display this screen") { puts opts; exit }
end

optparse.parse!

init
begin
  send_loop
rescue SystemExit, Interrupt
  sset $last_status["text"], "Restored status: " if $restore_last_status
end

# vk_api test
#require "vk_api"
#session = VkApi::Session.new 3310267, "1922eec4acfa932145b89f7b22b7f0f6df40f48e47e41a9473b02326bd7f9612601f0a27a44a530df04fe"
#session.status.get :uid => 177067169

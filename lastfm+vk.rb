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
$opt = { :single => false,
         :restore_status => false,
         :sleep => 1,
         :track_n => 0 }

def nowplaying (i = $opt[:track_n])
  $u = Scrobbler::User.new($lf_un)
  cur = $u.recent_tracks[i]
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

def send_loop (to_sleep=$opt[:sleep])
  while true
    send_nowplaying_lazy
    sleep(to_sleep)
  end
end

# $opt setting proc
seto = lambda {|opt, val| $opt[opt] = val}.curry

optparse = OptionParser.new do |opts|
  opts.banner = "Usage: lastfm+vk [-1 [-n N] || [-r] [-s S]]"
  opts.on('-1', '--single',           "Set VK status then exit",
          &seto[:single])
  opts.on('-n', '--nth N',   Integer, "Use Nth (from 0) last played track",
          &seto[:track_n])
  opts.on('-r', '--restore-status',   "Restore previous VK status on exit",
          &seto[:restore_status])
  opts.on('-s', '--sleep S', Integer, "Check last.fm last track each S seconds\
 (default=#{$opt[:sleep]})",
          &seto[:sleep])
  opts.on('-h', '--help',             "Display this screen") { puts opts; exit }
end

optparse.parse!

init

if __FILE__ == $0
  if $opt[:single]
    send_nowplaying
  else
    begin
      send_loop
    rescue SystemExit, Interrupt
      sset $last_status["text"], "Restored status: " if $opt[:restore_status]
    end
  end
end

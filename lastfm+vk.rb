#!/usr/bin/env ruby
# -*- coding: utf-8 -*-

require "scrobbler"
require "vk_api"

LF_un = 'se_customizer'
def LF_un.blank?; false; end
VK_aid = 3310267
VK_uid = 177067169
VK_key = "1922eec4acfa932145b89f7b22b7f0f6df40f48e47e41a9473b02326bd7f9612601f0a27a44a530df04fe"

def nowplaying
  $u = Scrobbler::User.new(LF_un)
  cur = $u.recent_tracks[0]
  alb = if !(cur.album.nil? || cur.album.empty?)
          " [#{cur.album}]" else "" end
  "#{cur.artist} – #{cur.name}#{alb}"
end

def sget
  $s.status.get :uid => VK_uid
end

def sset (text)
  $s.status.set(:text => text)
end

# https://oauth.vk.com/authorize?client_id=3310267&redirect_uri=http://api.vk.com/blank.html&scope=status,offline&display=page&response_type=token

def init
  # $u = Scrobbler::User.new(LF_un)
  
  $s = VkApi::Session.new(VK_aid, VK_key)
  $last_status = sget
  puts "Last status: #{$last_status}"
  
  $old_track = nowplaying
end

def send_nowplaying (track_text = nowplaying)
  new_status = "Last track: #{track_text}"
  if sset(new_status) == 1
    puts "Current status: #{sget["text"]}"
  else
    raise Exception "Status was not set"
  end
  $old_track = track_text
end

def send_nowplaying_lazy (track_text = nowplaying)
  if track_text != $old_track
    send_nowplaying track_text
  end
end

def send_loop (to_sleep=1)
  while true
    send_nowplaying_lazy
    sleep(to_sleep)
  end
end

init
send_loop

# vk_api test
#require "vk_api"
#session = VkApi::Session.new 3310267, "1922eec4acfa932145b89f7b22b7f0f6df40f48e47e41a9473b02326bd7f9612601f0a27a44a530df04fe"
#session.status.get :uid => 177067169

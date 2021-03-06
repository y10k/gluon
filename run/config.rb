# -*- coding: utf-8 -*-
# gluon configuration

ENV['GLUON_ENV'] ||= 'development'

case ENV['GLUON_ENV']
when 'development'
  log_level = Logger::DEBUG
  use Rack::Reloader
when 'deployment'
  log_level = Logger::INFO
  Gluon.use_memoization
else
  raise "unknown gluon environment: #{ENV['GLUON_ENV']}"
end

gluon_log = Logger.new("#{base_dir}/gluon.log")
gluon_log.level = log_level
logger gluon_log

access_log = File.open("#{base_dir}/access.log", 'a')
access_log.sync = true
use Rack::CommonLogger, access_log

use Rack::Session::Cookie, :secret => IO.read("#{base_dir}/secret")

## :example:start

require 'Example'
require 'Welcom'

map '/' do |entry|
  entry.mount Welcom
end

map '/example'do |entry|
  entry.mount Example
end

map '/example/menu' do |entry|
  entry.mount Example::Menu
end

map '/example/ex_panel' do |entry|
  entry.mount Example::ExamplePanel
end

map '/example/code_panel' do |entry|
  entry.mount Example::CodePanel
end

map '/example/view_panel' do |entry|
  entry.mount Example::ViewPanel
end

map '/example/ex_panel/OneTimeToken' do |entry|
  entry.mount Example::OneTimeToken
end

map '/example/ex_panel/BackendService' do |entry|
  entry.mount Example::BackendService
end

require 'pstore'

service PStore do |svc|
  svc.create do |c|
    c.new("#{base_dir}/bbs_data.pstore")
  end
end

## :example:stop

# Local Variables:
# mode: Ruby
# indent-tabs-mode: nil
# End:

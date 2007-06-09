#!/usr/local/bin/ruby

# for ident(1)
CVS_ID = '$Id$'

require 'rubygems'
require 'gluon'
require 'rack'

base_dir = File.join(File.dirname($0), '..')

options = {
  :lib_dir => File.join(base_dir, 'lib'),
  :view_dir => File.join(base_dir, 'view'),
  :conf_path => File.join(base_dir, 'config.rb')
}

builder = Gluon::Builder.new(options)
builder.load_conf
app_context = builder.build

Rack::Handler::WEBrick.run(app_context[:application],
			   :Port => app_context[:port])

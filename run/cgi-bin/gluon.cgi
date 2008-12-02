#!/usr/local/bin/ruby

# for ident(1)
CVS_ID = '$Id$'

LOCAL_ENV = File.expand_path(File.join(File.dirname(__FILE__), '.env'))

load(LOCAL_ENV) if (File.exist? LOCAL_ENV)

require 'gluon'
require 'rack'

base_dir = File.join(File.dirname($0), '..')

options = {
  :base_dir => base_dir,
  :lib_dir => File.join(base_dir, 'lib'),
  :view_dir => File.join(base_dir, 'view'),
  :conf_path => File.join(base_dir, 'config.rb')
}

builder = Gluon::Builder.new(options)
builder.load_conf
builder.build{
  builder.run(Rack::Handler::CGI)
}

# Local Variables:
# mode: Ruby
# indent-tabs-mode: nil
# End:

# for rackup

require 'gluon'

base_dir = File.join(File.dirname(__FILE__), '..')

options = {
  :base_dir => base_dir,
  :lib_dir => File.join(base_dir, 'lib'),
  :view_dir => File.join(base_dir, 'view'),
  :conf_path => File.join(base_dir, 'config.rb')
}

builder = Gluon::Builder.new(options)
builder.load_conf
builder.build

run builder.app

# Local Variables:
# mode: Ruby
# indent-tabs-mode: nil
# End:

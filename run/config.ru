# gluon application

require 'gluon'

base_dir = ::File.dirname(__FILE__)
builder = Gluon::Builder.new(base_dir)
builder.enable_local_library
builder.load_conf

run builder.to_app

END { builder.shutdown }

# Local Variables:
# mode: Ruby
# indent-tabs-mode: nil
# End:

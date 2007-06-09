# gluon configuration

port 9202
access_log '@?/access.log'

require 'Welcom'
mount Welcom, '/'

# Local Variables:
# mode: Ruby
# indent-tabs-mode: nil
# End:

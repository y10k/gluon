# gluon configuration

port 9202
log_file "#{base_dir}/gluon.log"
access_log "#{base_dir}/access.log"

default_handler Gluon::Web::NotFoundErrorPage

if ENV.key? 'DEBUG' then
  page_cache false
  auto_reload true
  log_level Logger::DEBUG
else
  page_cache true
  auto_reload false
  log_level Logger::INFO
  error_handler StandardError, Gluon::Web::InternalServerErrorPage
end

#### begin of example ####

require 'Welcom'
require 'Example'

mount Welcom, '/'
mount Example, '/example'
mount Example::Menu, '/example/menu'
mount Example::ExamplePanel, '/example/ex_panel'
mount Example::CodePanel, '/example/code_panel'
mount Example::ViewPanel, '/example/view_panel'

# ignored `Example::Panel'
mount Example::PageCache, '/example/ex_panel/pagecache'

##### end of example #####

# Local Variables:
# mode: Ruby
# indent-tabs-mode: nil
# End:

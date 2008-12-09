# gluon configuration

port 9202
log_file "#{base_dir}/gluon.log"
access_log "#{base_dir}/access.log"
default_handler Gluon::Web::NotFoundErrorPage

if ENV.key? 'DEBUG' then
  page_cache false
  log_level Logger::DEBUG
  rackup do
    use Rack::ShowExceptions
    use Rack::Reloader
  end
else
  page_cache true
  error_handler StandardError, Gluon::Web::InternalServerErrorPage
  if ENV.key? 'GATEWAY_INTERFACE' then
    log_level Logger::WARN      # suppress logging for CGI
  else
    log_level Logger::INFO
  end
end

session do
  store Gluon::FileStore.new("#{base_dir}/session")
  default_path '/'    # should be replaced to application context path
end

## :example:start

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

## :example:stop

# Local Variables:
# mode: Ruby
# indent-tabs-mode: nil
# End:

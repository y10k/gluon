# -*- coding: utf-8 -*-

require 'Example/Panel'

class Example
  class ViewPanel < Panel
    def self.page_encoding
      __ENCODING__
    end

    VIEW_DIR = File.join(File.dirname(__FILE__), '..', '..', 'view')

    def request_GET(key)
      super
      @view_path = File.join(VIEW_DIR,
                             @example_type.name.gsub(/::/, '/') +
                             Gluon::ERBView.suffix)
    end

    def filename
      File.basename(@view_path)
    end
    gluon_value :filename

    def view_code
      File.open(@view_path, "r:#{@example_type.page_encoding}") {|f| f.read }
    end
    gluon_value :view_code
  end
end

# Local Variables:
# mode: Ruby
# indent-tabs-mode: nil
# End:

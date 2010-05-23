# -*- coding: utf-8 -*-

require 'Example/Panel'

class Example
  class CodePanel < Panel
    def_page_encoding __ENCODING__

    def page_start(key)
      super
      @source_path = File.join(Gluon.lib_dir, @example_type.name.gsub(/::/, '/') + '.rb')
    end

    def filename
      File.basename(@source_path)
    end
    gluon_value :filename

    def source_code
      File.open(@source_path, "r:#{@example_type.page_encoding}") {|f| f.read }
    end
    gluon_value :source_code
  end
end

# Local Variables:
# mode: Ruby
# indent-tabs-mode: nil
# End:

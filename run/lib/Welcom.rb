# -*- coding: utf-8 -*-
# Welcom application

class Welcom < Gluon::Controller
  def self.page_encoding
    __ENCODING__
  end

  def request_GET
  end

  def title
    'Welcom to Gluon'
  end
  gluon_value :title

  def example
    Example
  end
  gluon_link :example
end

# Local Variables:
# mode: Ruby
# indent-tabs-mode: nil
# End:

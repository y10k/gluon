# Welcom application

class Welcom
  include Gluon::Controller

  def request_GET
  end

  def title
    'Welcom to Gluon'
  end
  gluon_value :title
end

# Local Variables:
# mode: Ruby
# indent-tabs-mode: nil
# End:

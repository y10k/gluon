# = gluon - simple web application framework
#
# == license
#   Copyright (c) 2007-2008
#           TOKI Yoshinori <toki@freedom.ne.jp>. All rights reserved.
#   
#   Redistribution and use in source and binary forms, with or without modification,
#   are permitted provided that the following conditions are met:
#   
#     1.  Redistributions of source code must retain the above copyright notice,
#         this list of conditions and the following disclaimer.
#   
#     2.  Redistributions in binary form must reproduce the above copyright notice,
#         this list of conditions and the following disclaimer in the documentation
#         and/or other materials provided with the distribution.
#   
#     3.  The name of the author may not be used to endorse or promote products
#         derived from this software without specific prior written permission.
#   
#   THIS SOFTWARE IS PROVIDED BY THE AUTHOR ``AS IS'' AND ANY EXPRESS OR IMPLIED
#   WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF
#   MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT
#   SHALL THE AUTHOR BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL,
#   EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT
#   OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS
#   INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN
#   CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING
#   IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY
#   OF SUCH DAMAGE.
#

require 'gluon/version'
require 'gluon/urlmap'          # to define Class.gluon_path_filter

# = gluon - simple web application framework
#
# == license
# see <tt>gluon.rb</tt> or <tt>LICENSE</tt> file.
#
module Gluon
  # for ident(1)
  CVS_ID = '$Id$'

  autoload :Action, 'gluon/action'
  autoload :Builder, 'gluon/builder'
  autoload :ERBContext, 'gluon/po'
  autoload :MemoryStore, 'gluon/rs'
  autoload :Mock, 'gluon/mock'
  autoload :NoLogger, 'gluon/nolog'
  autoload :PluginMaker, 'gluon/plugin'
  autoload :PresentationObject, 'gluon/po'
  autoload :RequestResponseContext, 'gluon/rs'
  autoload :SessionHandler, 'gluon/rs'
  autoload :SessionManager, 'gluon/rs'
  autoload :Setup, 'gluon/setup'
  #autoload :URLMap, 'gluon/urlmap'
  autoload :ViewRenderer, 'gluon/renderer'
  autoload :Web, 'gluon/web'
end

# Local Variables:
# mode: Ruby
# indent-tabs-mode: nil
# End:

module Toybox
  class Linkfile < Txtfile
    attr_accessor :link_dest
    def initialize(p)
      super(p)
      self.link_dest = File.readlink(p)
    end
    def to_s
      "#{self.class}: +l #{path.to_s}"
    end
    def install_cmd
      "@ln -s "
    end
    def install_src
        link_dest
    end
  end
end

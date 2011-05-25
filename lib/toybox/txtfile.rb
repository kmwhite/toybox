module Toybox
  class Txtfile
    attr_accessor :path
    def initialize(p)
      self.path = Pathname.new(p)
    end
    def to_s
      "#{self.class}: #{path.to_s}"
    end
    def q(s)
       '"' + s + '"'
    end
    def install_cmd
        "install -D -m 644"
    end
    def install_src
      "$(SRC)/#{path.to_s}"
    end
    def install_dest
        "#{Toybox::app_fakeroot}/#{path.to_s}"
    end
    def debian_install_cmd
      [install_cmd, q(install_src), q(install_dest)].join(' ')
    end
  end
end

module Toybox
  class Configfile < Txtfile
    def install_cmd
        "install -D -m 640 "
    end
  end
end

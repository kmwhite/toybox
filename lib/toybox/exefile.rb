module Toybox
  class Exefile < Txtfile
    def install_cmd
      "install -m 755 "
    end
  end
end

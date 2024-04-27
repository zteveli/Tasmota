import webserver # import webserver class

class Multicontroller

  static ext1gpios = ['GPIO5', 'GPIO35', 'GPIO36', 'GPIO37', 'GPIO38', 'GPIO39']
  static ext2gpios = ['GPIO6', 'GPIO6', 'GPIO15', 'GPIO16', 'GPIO17', 'GPIO8']
  static ext3gpios = ['GPIO14', 'GPIO13', 'GPIO12', 'GPIO11', 'GPIO10', 'GPIO9']
  static ext4gpios = ['GPIO21', 'GPIO47', 'GPIO48', 'GPIO40', 'GPIO41', 'GPIO42']
  var all_ext_gpios

  def init()
    self.all_ext_gpios = [self.ext1gpios, self.ext2gpios, self.ext3gpios, self.ext4gpios]
    tasmota.add_driver(self)
  end

  def close()
    tasmota.remove_driver(self)
  end

  def list_gpios(ext_slot)
    var ext_gpios = self.all_ext_gpios[ext_slot]
    var all_gpios = tasmota.cmd('GPIO')

    for gpio_idx : 0 .. 5
      gpio = all_gpios.find(ext_gpios[gpio_idx], [])
      for item : gpio
        webserver.content_send("<p></p>Channel " + str(gpio_idx + 1) + ": " + item)
        print(gpio.tostring())
      end
    end
  end

  def page_mc_conf_page()
    var i2c_devs = wire1.scan()
    webserver.content_start("Multicontroller Configuration")
    webserver.content_send_style()
    webserver.content_send("Installed extension boards:")
    for dev: i2c_devs
      if (dev >= 80) && (dev <= 83)
        var ext_slot = dev - 79
        webserver.content_send("<p></p>Extension slot " + str(ext_slot) + ":")
        self.list_gpios(ext_slot - 1)
        webserver.content_send("<hr>")
      end
    end

    webserver.content_send("<p></p><button onclick='la(\"&m_toggle_conf=1\");'>Test Button</button>")
    webserver.content_button(webserver.BUTTON_CONFIGURATION) #- button back to configuration page -#
    webserver.content_stop()
  end

  def page_mc_status_page()
    webserver.content_start("Multicontroller Status")
    webserver.content_send_style()
    webserver.content_send("<p></p><button onclick='la(\"&m_toggle_conf=1\");'>Test Button</button>")
    webserver.content_button(webserver.BUTTON_MAIN) #- button back to main page -#
    webserver.content_stop()
  end

  #- create a method for adding a button to the main menu -#
  def web_add_main_button()
    webserver.content_send("<p></p><form action='/mc_status' method='post'><button>Multicontroller Status</button></form>")
  end

  #- create a method for adding a button to the configuration menu-#
  def web_add_config_button()
    #- the onclick function "la" takes the function name and the respective value you want to send as an argument -#
    webserver.content_send("<p></p><form action='/mc_conf' method='post'><button>Multicontroller Configuration</button></form>")
  end

  #- As we can add only one sensor method we will have to combine them besides all other sensor readings in one method -#
  def web_sensor()

    webserver.content_send("<p></p><button onclick='la(\"&m_toggle_conf=1\");'>Test Button</button>")

    if webserver.has_arg("m_toggle_conf")
      print("m_toggle_conf")
    end

    if webserver.has_arg("m_go_conf") # takes a string as argument name and returns a boolean

      # we can even call another function and use the value as a parameter
      var myValue = int(webserver.arg("m_go_conf")) # takes a string or integer(index of arguments) to get the value of the argument
      self.myOtherFunction(myValue)
    end
  end

  def web_add_handler()
    webserver.on("/mc_status", / -> self.page_mc_status_page())
    webserver.on("/mc_conf", / -> self.page_mc_conf_page())
    print("'/mc_status' page added")
    print("'/mc_conf' page added")
    end
end

mc = Multicontroller()
mc.web_add_handler()
config_ru = ::File.join(::File.dirname(__FILE__), '..', 'config.ru')
instance_eval(IO.read(config_ru), config_ru)

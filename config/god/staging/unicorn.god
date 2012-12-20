# vim: ft=ruby

Ifad::God.unicorn do |w|
  w.uid = 'heathen'
  w.gid = 'ruby'
  w.env = {
    'RACK_ENV' => 'staging'
  }
end

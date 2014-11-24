require 'pathname'
$: << Pathname.new(__FILE__).realpath.parent.parent + 'lib'

def support_path
  Pathname.new(__FILE__).realpath.parent + 'support'
end

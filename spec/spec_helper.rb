require 'pathname'
require 'yaml'
$: << Pathname.new(__FILE__).realpath.parent.parent
$: << Pathname.new(__FILE__).realpath.parent.parent + 'lib'

def support_path
  Pathname.new(__FILE__).realpath.parent + 'support'
end

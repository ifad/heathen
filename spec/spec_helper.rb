require 'pathname'
require 'yaml'
BASE = Pathname.new(__FILE__).realpath.parent.parent
$: << BASE
$: << BASE + 'lib'

def support_path
  Pathname.new(__FILE__).realpath.parent + 'support'
end

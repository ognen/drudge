$LOAD_PATH << File.join(File.dirname(__FILE__), '..', 'lib')
Dir["./spec/support/**/*.rb"].each {|f| require f}
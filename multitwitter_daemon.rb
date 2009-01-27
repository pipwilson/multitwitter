require 'rubygems'
require 'yaml'
require 'daemons'
require 'multitwitter_bot'
require 'logger'
require 'pp'

class MultitwitterDaemon
  def initialize
    @bot = MultitwitterBot.new(config)
  end

  def start
    loop do
      @bot.run
      sleep 5
    end
  end
  
  def config
    unless @config
      conf_file = ARGV[ARGV.index('-f')+1]
      unless(conf_file and File.exists?(conf_file))
        puts "Usage: daemon start|run -- -f conf_file"
        exit
      end
      @config = YAML.load(File.read(conf_file))
    end
    @config
  end
  
  def proc_name
    "MultitwitterDaemon - #{@config['jid']}"
  end
end

options = {
  :backtrace => true,
  :dir_mode => :system,
  :log_output => true
}

daemon = MultitwitterDaemon.new()
Daemons.run_proc(daemon.proc_name, options) { daemon.start }


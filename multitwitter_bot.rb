require 'cgi'
require 'net/http'
require "logger"

require 'rubygems'
require 'xmpp4r-simple'

class MultitwitterBot
  def initialize(config, logger=nil)
    @jid      = config['jid']
    @jpassword = config['pass']
    @allowed  = config['allowed']
    @tusername = config['twitter_username']
    @tpassword  = config['twitter_password']
    @logger   = Logger.new('multitwitter.log')
    jabber.accept_subscriptions = true
    checkroster
  end
  
  def run
    jabber.received_messages.each do |m|
      # silently ignore people not on our "allowed" list
      next unless allowed?(m)
      twitter(m)
    end
  end  
  
  private

  def checkroster
    # add the allowed users to bot's roster
    # this means people won't have to add it.
    # really needs code to check roster list against @allowed.
    # also, doesn't work :) TODO
    @allowed.each do |user|
      jabber.add(user)
    end
  end  

  def twitter(message)
    update_status(message.body)
  end
  
  def update_status(status)
    unless status.length > 1 && status.length < 140
      return "Status message must be between 1 and 140 characters long"
    end
    
    api_url = 'http://twitter.com/statuses/update.json'

    url = URI.parse(api_url)
    req = Net::HTTP::Post.new(url.path)

    req.basic_auth(@tusername, @tpassword)
    req.set_form_data( {'status'=> status}, ';' )

    res = Net::HTTP.new(url.host, url.port).start do |http|
      http.request(req) 
    end
    return res
  end

  def allowed?(message)
    sender = sent_by(message)
    return true if sender and @allowed.include?(sender)
  end
  
  def sent_by(message)
    #return message.from // returns a JID object, not a string
    return message.attributes['from'].split('/')[0]    
  end

  def log(str, severity=:info)
    if @logger
      @logger.send(severity, str)
    else
      STDERR.puts(str)
    end
  end
  
  def jabber
    begin
      unless @jabber
        log("connecting....")
        @jabber = Jabber::Simple.new(@jid, @jpassword, :chat, "Open for Business.")
        log("connected as #{@jid}")
      end  
    rescue => e
      log("[#{Time.now}] Couldn't connect to Jabber (#{@jid}, #{@password}): #{e}.")
      sleep 60
      retry
    end
    @jabber
  end
  
end

=begin
config = YAML.load(File.read('config.yml'))

bot = MultitwitterBot.new(config)

loop do
  bot.run
  sleep 5
end
=end

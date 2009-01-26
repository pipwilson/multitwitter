require 'cgi'
require 'net/http'

require 'rubygems'
require 'xmpp4r-simple'
require 'pp'

class TwitterpatedBot
  def initialize(config, logger=nil)
    @jid      = config['jid']
    @password = config['pass']
    @allowed  = config['allowed']
    @logger   = logger
  end
  
  def run
    jabber.received_messages.each do |m|
      next unless allowed?(m)
      twitter(m)
    end
  end  
  
  private
  
  def twitter(mesg)
    # send message to twitter using API here
    # jabber.deliver('twitter@twitter.com', mesg)
    log("published #{mesg} from #{sent_by(mesg)}")
  end
  
  def allowed?(mesg)
    sender = sent_by(mesg)
    return true if sender and @allowed.include?(sender)
  end
  
  def direct_messages
    jabber.received_messages.select {|mesg| direct?(mesg) }
  end
  
  def original_message(mesg)
    sender = sent_by(mesg)
    o = mesg.body.gsub("direct from #{sender}: ", '')
    o = o.gsub("(reply? send: d #{sender} hi.)", '')
    return o
  end
  
  def sent_by(mesg)
    if (screen_name_element = mesg.elements['//screen_name'])
      sender = screen_name_element.text
      return sender
    else
      return false
    end
  end
  
  def direct?(mesg)
    mesg.body =~ /direct from (\w+)/
    if($1)
      return true
    else
      return false
    end
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
        @jabber = Jabber::Simple.new(@jid, @password, :chat, "Open for Business.")
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


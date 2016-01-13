try
    {Robot, Adapter, EnterMessage, LeaveMessage, TopicMessage, TextMessage}  = require 'hubot'
catch
    prequire = require( 'parent-require' )
    {Robot, Adapter, EnterMessage, LeaveMessage, TopicMessage, TextMessage}  = prequire 'hubot'
Discord = require "discord.js"


class DiscordBot extends Adapter
    constructor: (robot)->
        super
        @robot = robot

     run: ->
        @options =
            email: process.env.HUBOT_DISCORD_EMAIL,
            password: process.env.HUBOT_DISCORD_PASSWORD
            reconnect_attempts: process.env.HUBOT_DISCORD_RECONNECT_ATTEMPTS || 30
        self.reset_attempts

        @client = new Discord.Client
        @client.on 'ready', @.ready
        @client.on 'message', @.message
        @client.on 'disconnected', @.disconnected
        @client.login @options.email, @options.password

     ready: =>
        @robot.logger.info 'Logged in: ' + @client.user.username
        @robot.name = @client.user.username.toLowerCase()
        @robot.logger.info "Robot Name: " + @robot.name
        self.reset_attempts
        @emit "connected"

     reset_attempts: ->
        @options.remaining_attempts = @options.reconnect_attempts

     disconnected: =>
        @robot.logger.error 'Unable to connect from discord'
        if @options.remaining_attempts > 0
            @robot.logger.info 'Attempting to reconnect...' + @options.remaining_attempts # make this count up
            @options.remaining_attempts--
            setTimeout @client.login, 10000

     message: (message) =>

        # ignore messages from myself
        return if message.author.id == @client.user.id

        user = @robot.brain.userForId message.author
        user.room = message.channel

        # revert the received mention to the raw text
        text = message.content
        for mention in message.mentions
            rex = new RegExp( '<@' + mention.id + '>' )
            if mention.id == @client.user.id
                repl = '@' + @robot.name
            else
                repl = ''
            text = text.replace '<@' + mention.id + '>', repl
        
        @robot.logger.debug text

        @receive new TextMessage( user, text, message.id )

     send: (envelope, messages...) ->
        for msg in messages
            @client.sendMessage envelope.room, msg

     reply: (envelope, messages...) ->

        # discord.js reply function looks for a 'sender' which doesn't 
        # exist in our envelope object

        user = envelope.user.name + ' '
        for msg in messages
            @client.sendMessage envelope.room, msg, null, null, user 
        
        
exports.use = (robot) ->
    new DiscordBot robot

require! './core': {ActorBase}
require! './signal': {Signal}
require! 'aea': {sleep, pack, clone}
require! './authorization':{get-all-permissions}
require! 'uuid4'
require! 'colors': {red, green, yellow, bg-red, bg-yellow}
require! 'aea/debug-log': {logger}
require! './auth-helpers': {hash-passwd}
require! './topic-match': {topic-match}
require! 'prelude-ls': {keys, join}

export class AuthRequest extends ActorBase
    @i = 0
    ->
        super "AuthRequest.#{@@i++}"
        @login-signal = new Signal!
        @logout-signal = new Signal!

    inbox: (msg) ->
        if \auth of msg
            #@log.log "Auth actor got authentication message", msg
            if \session of msg.auth
                @login-signal.go msg
            else if \logout of msg.auth
                if msg.auth.logout is \ok
                    @logout-signal.go msg

    login: (_credentials, callback) ->
        # credentials might be one of the following:
        # 1. {username: ..., password: ...}
        # 2. {token: ...}

        credentials = clone _credentials
        if credentials.password
            credentials.password = hash-passwd credentials.password

        @log.log "Trying to authenticate with #{keys credentials |> join ", "}"

        if \token of credentials
            if credentials.token.length < 10
                err = "Token seems empty, not attempting to login."
                @log.log err
                @trigger \logout
                callback err, null
                return

        @send auth: credentials
        # FIXME: why do we need to clear the signal?
        @login-signal.clear!
        reason, res <~ @login-signal.wait 3000ms

        err = if reason is \timeout
            {reason: \timeout}
        else
            no

        #@log.log "auth replay is: ", pack res
        try
            if res.auth.session.token
                # store token in order to use in every message
                @token = that
                @trigger \login, res.auth.session.permissions
            else if res.auth.session.logout is \yes or res.auth.session is \wrong
                @trigger \logout
        catch
            @log.err "something went wrong here: ", e, (pack res), (pack err)

        callback err, res


    logout: (callback) ->
        @send-with-token auth: logout: yes
        reason, msg <~ @logout-signal.wait 3000ms
        err = if reason is \timeout
            {reason: 'timeout'}
        else
            no

        if not err and msg.auth.logout is \ok
            @log.log "clearing token from AuthRequest cache"
            @token = null

        callback err, msg

    send: (msg) -> @send-raw @msg-template msg <<< sender: @id

    send-with-token: (msg) ->
        @send-raw msg <<< token: @token

    send-raw: (msg) ->
        ...
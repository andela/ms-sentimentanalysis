module.exports = (robot) ->
  robot.router.post "/entries/:room", (req, res) ->
    allUsers = JSON.parse req.body.allEntries
    allUsersEntry = []
    feelings = ""
    channel = {}
    channel.room = req.params.room if req.params.room


    sendFeelings = (user, feeling) ->
      message = "Andela felt #{feeling} yesterday"
      console.log message
      robot.send user, message
    
    makeRequest = (user, text) ->
      url = "http://access.alchemyapi.com/calls/text/TextGetTextSentiment?apikey=7b134190cc61115cfbf3353c407aea9911d041cf&outputMode=json&text="+text
      robot.http(url)
        .header({
          'Content-Type': 'application/x-www-form-urlencoded'
        })
        .get() (err,res,body) ->
          response =  JSON.parse body
          if response.status == "ERROR" and response.language == "unknown" and response.statusInfo != "contnet-is-empty"
            message = "I cant decode fellows language!"
          if response.statusInfo == "contnet-is-empty"
            message = "No entry is to base judgement on!"
          else
            score = response.docSentiment.score
            type = response.docSentiment.type

            feeling = switch
              when -1.0 < score < -0.8 then "Extremely sad"
              when -0.81 < score < -0.1 then "Sad"
              when -0.11 < score < 0.1 then "Neutral"
              when 0.11 < score < 0.8 then "Happy"
              when 0.81 < score < 1.0 then "Extremely happy" 

            sendFeelings(user, feeling)
            
    for user in allUsers
      user.entries.map (entry) ->
        allUsersEntry.push(entry)

    allUsersEntryText = allUsersEntry.join(' ')
    makeRequest channel, allUsersEntryText


    res.end '\nThanks for your entries\n'
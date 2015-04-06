# Description:
#   Lifebot is responsible for calculating previous day's entries wordcount in an organization signed up on Andelife
#
# Dependencies:
#   qs
#
# Configuration:
#   None
#
# Commands:
#   lifebot How did Andela feel yesterday - Retrieves all the entries written in Andelife for the previous day and tells you the mood associated with them.
#
# Author:
#   Andela

moment = require 'moment';
Firebase = require 'firebase'
rootRef = new Firebase 'https://sentiment-ms.firebaseio.com/'
orgRef = rootRef.child 'organizations'

sad =["felt sad", "felt blue", "felt cheerless", "felt dejected", "felt depressed", "felt disconsolate", "felt down", "felt glum", "felt low", "was low-spirited", "felt lugubrious", "felt melancholy", "was somber", "felt unhappy", "felt wistful", "felt woebegone", "felt bad"]
neutral = ["felt neutral", "felt impartial", "felt indifferent", "felt cool", "felt calm", "felt uninvolved", "was unprejudiced"]
happy = ["felt happy", "felt lively", "felt blithe", "felt jubilant", "felt blessed", "felt blissful", "felt delighted", "felt joyful"]
ex_happy = ["felt extremely happy", "felt overjoyed", "was over the moon", "was on cloud nine"]

module.exports = (robot) ->
  robot.hear /How did Andela feel yesterday/i, (msg) ->
    text = ""
    msg.http("http://life.andela.co/send-ms-wordcount/slack")
      .get() (err, res, data) ->
        allEntries = JSON.parse data
        for user in allEntries
          user.entries.map (entry) ->
            text += "#{entry} "
        console.log text
        makeRequest text, msg

sendFeelings = (feeling, msg) ->
  message = "Andela #{feeling} yesterday"
  console.log message
  msg.send message

makeRequest = (text, msg) ->
  url = "http://access.alchemyapi.com/calls/text/TextGetTextSentiment?apikey=7b134190cc61115cfbf3353c407aea9911d041cf&outputMode=json&text="+text
  msg.http(url)
    .header({
      'Content-Type': 'application/x-www-form-urlencoded'
    })
    .get() (err,res,body) ->
      response =  JSON.parse body
      if response.status is "ERROR" and response.language is "unknown" and response.statusInfo isnt "content-is-empty"
        message = "I cant decode fellows language!"
      if response.statusInfo is "content-is-empty"
        message = "No entry is to base judgement on!"
      else
        console.log response
        score = response.docSentiment.score
        type = response.docSentiment.type

        feeling = switch
          when -1.0 < score < -0.8 || type is 'negative' then "#{msg.random sad}"
          when -0.81 < score < -0.1 || type is 'negative' then "#{msg.random sad}"
          when -0.11 < score < 0.1 || type is 'neutral' then "#{msg.random neutral}"
          when 0.11 < score < 0.8 || type is 'positive' then "#{msg.random happy}"
          when 0.81 < score < 1.0 || type is 'positive' then "#{msg.random ex_happy}" 

        sendFeelings feeling, msg
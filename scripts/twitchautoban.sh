#!/bin/bash
#reference:
#https://dev.twitch.tv/docs/api/reference/#ban-user

#usage:
#twitchautoban.sh your_moderator_username


#requires your tokens!
oauth="your bearer oauth token (that has moderation:manage:banned_users api permission)"
clientid="your api app token"

#twitch helix api var
twhelix="https://api.twitch.tv/helix"

#location of list.txt (the list of names to ban)
list="list.txt"
#location of channels.txt (list of channels to ban from = broadcaster_id)
chlist="channels.txt"
#get moderator's id (your username)
modinfo="$1"

echo "";

# if input is empty then default to "jtv"
    if [ "$modinfo" = "" ]; then
        echo "moderator username is empty, example \"twhelixautoban.sh jtv\""; \
#        channelinfo_e=${channelinfo:="jtv"}
        exit
    fi
# get channel_id (the channel's broadcaster_id in chat)
        modname=$(curl -s -X GET "$twhelix/users?login=${modinfo}" \
            -H "Authorization: Bearer $oauth" \
            -H "Client-Id: $clientid")
        modid=$(echo $modname|jq --raw-output '.data[0] .id')
        echo "moderator $modinfo $modid";

while read -r chline
    do
# get channel_id from txt (the chat broadcaster_id aka a channel you mod for or your own channel)
        channelname=$(curl -s -X GET "$twhelix/users?login=${chline%%#*}" \
            -H "Authorization: Bearer $oauth" \
            -H "Client-Id: $clientid")
        channelid=$(echo $channelname|jq --raw-output '.data[0] .id')
        echo "channel ${chline%%#*} $channelid";
# read list and query user_id then ban them from broadcaster_id's channel
    while read -r line
        do
# the lines that read list.txt to get user_id
            userline=$(curl -s -X GET "$twhelix/users?login=${line%%#*}" \
                -H "Authorization: Bearer $oauth" \
                -H "Client-Id: $clientid")
                echo "banning ${line%%#*} from #${chline}";
                echo $userline|jq --raw-output '.data[0] .id';
# the actual user_id of the banned
            userid=$(echo $userline|jq --raw-output '.data[0] .id')
# the line that bans
            channelline=$(curl -s -X POST "$twhelix/moderation/bans?broadcaster_id=$channelid&moderator_id=$modid" \
                -H "Authorization: Bearer $oauth" \
                -H "Client-Id: $clientid" \
                -H "Content-Type: application/json" \
                -d '{"data": {"user_id":'"$userid"',"reason":"BOTLIST"}}')
                echo "${line%%#*}";
#                echo $userline|jq --raw-output '.data[0] .created_at';
                echo "";
# timeout so not spam the api (needs adjusting)
                sleep 0.256;
# read from list.txt file
    done < <(grep -vi "^#\|^$" $list);
# read from channels.txt file
done < <(grep -vi "^#\|^$" $chlist|sed 's/#//');

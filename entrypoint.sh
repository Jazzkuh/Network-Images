TZ=${TZ:-UTC}
export TZ

# Set environment variable that holds the Internal Docker IP
INTERNAL_IP=$(ip route get 1 | awk '{print $(NF-2);exit}')
export INTERNAL_IP

# Switch to the container's working directory
cd /home/container || exit 1

# Print Java version
printf "\033[1m\033[33mcontainer@pterodactyl~ \033[0mjava -version\n"
java -version

# Convert all of the "{{VARIABLE}}" parts of the command into the expected shell
# variable format of "${VARIABLE}" before evaluating the string and automatically
# replacing the values.
PARSED=$(echo "${STARTUP}" | sed -e 's/{{/${/g' -e 's/}}/}/g' | eval echo "$(cat -)")

# Display the command we're running in the output, and then execute it with the env
# from the container itself.
printf "\033[1m\033[33mcontainer@pterodactyl~ \033[0m%s\n" "$PARSED"
# shellcheck disable=SC2086

wget -r -np -q -nH --cut-dirs=3 --reject index.html,index.html.tmp "http://172.19.0.1:2231/templates/global/server/" &
wait $!

if [ -n "$TEMPLATES" ]; then
    IFS=',' read -r -a templates <<< "$TEMPLATES"
    for template in "${templates[@]}"; do
        if [ -z "$template" ]; then
            continue
        fi

        echo "Downloading template $template"
        wget -r -np -q -nH --cut-dirs=3 --reject index.html,index.html.tmp "http://172.19.0.1:2231/templates/$template/" &
        wait $!
    done
else
    echo "TEMPLATES environment variable is not set."
fi

sed -i "s/server-port=.*/server-port=$SERVER_PORT/" "/home/container/server.properties"
sed -i "s/online-mode=.*/online-mode=false/" "/home/container/server.properties"

exec env ${PARSED}

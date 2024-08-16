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

if [ -d "/home/container/plugins" ]; then
    echo "Removing old plugins from /home/container/plugins"
    find /home/container/plugins -maxdepth 1 ! -type d -exec rm -f {} \;
fi

wget -r -np -q -nH --cut-dirs=2 --reject index.html,index.html.tmp --accept "*.*" "$TEMPLATE_URL$GLOBAL_FOLDER/" &
wait $!

if [ -n "$TEMPLATES" ]; then
    IFS=',' read -r -a templates <<< "$TEMPLATES"
    for template in "${templates[@]}"; do
        if [ -z "$template" ]; then
            continue
        fi

        echo "Downloading template $template"
        wget -r -np -q -nH --cut-dirs=2 --reject index.html,index.html.tmp "$TEMPLATE_URL$template/" &
        wait $!
    done
else
    echo "TEMPLATES environment variable is not set."
fi

if [[ "$GLOBAL_FOLDER" == *"spigot"* ]]; then
    sed -i "s/server-port=.*/server-port=$SERVER_PORT/" "/home/container/server.properties"
    sed -i "s/online-mode=.*/online-mode=false/" "/home/container/server.properties"
fi

exec env ${PARSED}

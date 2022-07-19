FROM nginx:latest

RUN apt-get update && \
    apt-get install -y php php-sqlite3 php-xml git

RUN git clone https://github.com/nunimbus/nunimbus.com
WORKDIR nunimbus.com

RUN { \
    echo '$plugin = reset($GLOBALS["wp_filter"]["wp_ajax_static_archive_action"]->current())["function"][0];'; \
    echo ''; \
    echo 'if (isset($_POST["perform"]) || array_key_exists("perform", $_POST)) {'; \
    echo '    if ($_POST["perform"] == "ping") {'; \
    echo '        $plugin->send_json_response_for_static_archive($_POST["perform"]);'; \
    echo '    }'; \
    echo '    else if ($_POST["perform"] == "start") {'; \
    echo '        $plugin->run_static_export();'; \
    echo '    }'; \
    echo '}'; \
} >> ./wp-config.php

RUN curl -O https://raw.githubusercontent.com/wp-cli/builds/gh-pages/phar/wp-cli.phar

RUN php wp-cli.phar --allow-root option patch update simply-static delivery_method local ; \
    php wp-cli.phar --allow-root option patch update simply-static temp_files_dir /tmp/simply-static/ ; \
    php wp-cli.phar --allow-root option patch update simply-static local_dir /usr/share/nginx/html/ ; \
    \
    # This is just dumb. WP CLI has trouble setting multi-line options - sometimes it works, sometimes it doesn't. \
    # These loops ensure that the options are successfully updated. \
    cp wp-content/database/db wp-content/database/db.bak ; \
    \
    while : ; \
    do \
      php wp-cli.phar --allow-root option pluck simply-static additional_files | sed "s#.*wp-content#$PWD\/wp-content#g" | php wp-cli.phar --allow-root option patch update simply-static additional_files ; \
      php wp-cli.phar --allow-root option pluck simply-static additional_files ; \
      \
      if [ $? -ne 0 ] ; \
      then \
        cp wp-content/database/db.bak wp-content/database/db ; \
      else \
        break ; \
      fi ; \
    done ; \
    \
    cp wp-content/database/db wp-content/database/db.bak ; \
    \
    while : ; \
    do \
      php wp-cli.phar --allow-root option pluck simply-static additional_files | sed "s#.*wp-includes#$PWD\/wp-includes#g" | php wp-cli.phar --allow-root option patch update simply-static additional_files ; \
      php wp-cli.phar --allow-root option pluck simply-static additional_files ; \
      \
      if [ $? -ne 0 ] ; \
      then \
        cp wp-content/database/db.bak wp-content/database/db ; \
      else \
        break ; \
      fi ; \
    done

RUN PHP_CLI_SERVER_WORKERS=200 php -S localhost:8080 & \
    sleep 1 ; \
    curl "http://localhost:8080/wp-admin/admin-ajax.php"   -H "Content-Type: application/x-www-form-urlencoded; charset=UTF-8"   --data-raw "action=static_archive_action&perform=start"   --compressed & \
    sleep 5 ; \
    \
    while : ; \
    do \
      curl 'http://localhost:8080/wp-admin/admin-ajax.php'   -H 'Content-Type: application/x-www-form-urlencoded; charset=UTF-8'   --data-raw 'action=static_archive_action&perform=ping'   --compressed | grep Finished ; \
      if [ $? -eq 0 ] ; \
      then \
        break ; \
      fi ; \
      sleep 1 ; \
    done

WORKDIR /usr/share/nginx/html/

RUN rm -r /usr/share/nginx/html/*
RUN cp -r /tmp/simply-static/simply-static-*/* /usr/share/nginx/html/

RUN rm -r /tmp/* /nunimbus.com /var/www/html
RUN apt-get purge -y php* git

FROM ruby:2.6
ARG UNAME=app
ARG UID=1000
ARG GID=1000
ARG APP_HOME=/app
ARG GEM_HOME=/gems

# Adapted from https://medium.com/hackernoon/preventing-race-conditions-in-docker-781854121ed3
ENV DOCKERIZE_VERSION=v0.5.0
RUN wget -O - \
    https://github.com/jwilder/dockerize/releases/download/$DOCKERIZE_VERSION/dockerize-linux-amd64-$DOCKERIZE_VERSION.tar.gz \
    | tar -C /usr/local/bin -xzvf -

RUN wget -q -O- https://dl.yarnpkg.com/debian/pubkey.gpg | \
  apt-key add - && \
  echo "deb https://dl.yarnpkg.com/debian/ stable main" > \
    /etc/apt/sources.list.d/yarn.list && \
  apt-get update && \
  apt-get install -yqq --no-install-recommends \
    apt-transport-https \
    nodejs \
    yarn && \
  rm -rf /var/lib/apt/lists/* /usr/share/doc /usr/share/locale /usr/share/man
RUN gem install bundler

RUN groupadd -g $GID -o $UNAME
RUN useradd -m -d /home/app -u $UID -g $GID -o -s /bin/bash $UNAME
RUN mkdir -p $APP_HOME && chown $UID:$GID $APP_HOME
RUN mkdir -p $GEM_HOME && chown $UID:$GID $GEM_HOME

ENV BUNDLE_GEMFILE=${APP_HOME}/Gemfile
ENV BUNDLE_JOBS=2
ENV BUNDLE_PATH=${GEM_HOME}
ENV DB_VENDOR=mysql
ENV DB_ADAPTER=mysql2
ENV MYSQL_PORT=3306
ENV MYSQL_HOST=db
ENV MYSQL_USER=helio
ENV MYSQL_PASSWORD=helio
ENV MYSQL_DATABASE=helio
ENV RAILS_ENV=development

RUN mkdir -p ${APP_HOME} ${BUNDLE_PATH}
WORKDIR ${APP_HOME}

USER $UNAME
COPY --chown=$UID:$GID Gemfile* ${APP_HOME}/
RUN bundle install

# Note that docker-compose.yml mounts /app/node_modules like the gem cache
COPY --chown=$UID:$GID package.json yarn.lock ${APP_HOME}/
RUN yarn install --check-files

COPY --chown=$UID:$GID . ${APP_HOME}

CMD dockerize -wait tcp://${MYSQL_HOST}:${MYSQL_PORT} -timeout 5m && \
  bundle exec rake db:migrate && \
  bundle exec rails server --binding 0.0.0.0 --port 3000
  

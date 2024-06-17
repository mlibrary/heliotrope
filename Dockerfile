FROM ruby:2.7 as fulcrum-dev

ARG UNAME=app
ARG UID=1000
ARG GID=1000
ARG NODE_MAJOR=20

# Adapted from https://medium.com/hackernoon/preventing-race-conditions-in-docker-781854121ed3
ENV DOCKERIZE_VERSION=v0.7.0
RUN wget -O - \
    https://github.com/jwilder/dockerize/releases/download/$DOCKERIZE_VERSION/dockerize-linux-amd64-$DOCKERIZE_VERSION.tar.gz \
    | tar -C /usr/local/bin -xzvf -

RUN apt-get update -yqq && apt-get install -yqq --no-install-recommends \
  ca-certificates \
  gnupg \
  apt-transport-https \
  vim-tiny \
  pkg-config \
  libxml2-dev \
  libxslt-dev

# install nodejs
RUN mkdir -p /etc/apt/keyrings
RUN curl -fsSL https://deb.nodesource.com/gpgkey/nodesource-repo.gpg.key | gpg --dearmor -o /etc/apt/keyrings/nodesource.gpg
RUN echo "deb [signed-by=/etc/apt/keyrings/nodesource.gpg] https://deb.nodesource.com/node_${NODE_MAJOR}.x nodistro main" | tee /etc/apt/sources.list.d/nodesource.list
RUN apt-get update -yqq && apt-get install -yqq --no-install-recommends nodejs

# keep image slim
RUN rm -rf /var/lib/apt/lists/* /usr/share/doc /usr/share/locale /usr/share/man

RUN groupadd -g ${GID} -o ${UNAME}
RUN useradd -m -d /app -u ${UID} -g ${GID} -o -s /bin/bash ${UNAME}
RUN mkdir -p /gems && chown ${UID}:${GID} /gems

ARG APP_HOME=/app
ARG GEM_HOME=/gems
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

RUN npm install --global yarn

RUN mkdir -p ${APP_HOME} ${BUNDLE_PATH}
WORKDIR ${APP_HOME}

USER $UNAME
COPY --chown=$UID:$GID Gemfile* ${APP_HOME}/

RUN gem install bundler -v 2.4.22

RUN bundle config build.nokogiri --use-system-libraries
RUN bundle check || bundle install

# nokogiri is being terrible as usual
# RUN bundle info nokogiri
# it says it's installed but the container can't see it, IDK

# Note that docker-compose.yml mounts /app/node_modules like the gem cache
COPY --chown=$UID:$GID package.json yarn.lock ${APP_HOME}/
RUN yarn install --check-files

COPY --chown=$UID:$GID . ${APP_HOME}

# CMD dockerize -wait tcp://${MYSQL_HOST}:${MYSQL_PORT} -timeout 5m && \
#   bundle exec rake db:migrate && \
#   bundle exec rails server --binding 0.0.0.0 --port 3001

CMD dockerize bundle install nokogiri && \
  bundle exec rails server --binding 0.0.0.0 --port 3000
  

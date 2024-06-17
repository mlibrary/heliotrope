ARG RUBY_VERSION=2.7.4
ARG RUBY_SLIM="-slim"
FROM ruby:${RUBY_VERSION}${RUBY_SLIM} AS fulcrum-dev

ARG UNAME=app
ARG UID=1000
ARG GID=1000
ARG NODE_MAJOR=20

RUN apt-get update -yqq && apt-get install -yqq --no-install-recommends \
  ca-certificates \
  gnupg \
  apt-transport-https \
  build-essential \
  vim-tiny \
  pkg-config \
  libxml2-dev \
  libxslt-dev \
  curl \
  git \
  libsqlite3-dev \
  libmariadb-dev \
  libxslt-dev \
  libxml2-dev \
  shared-mime-info


# install nodejs
RUN mkdir -p /etc/apt/keyrings
RUN curl -fsSL https://deb.nodesource.com/gpgkey/nodesource-repo.gpg.key | gpg --dearmor -o /etc/apt/keyrings/nodesource.gpg
RUN echo "deb [signed-by=/etc/apt/keyrings/nodesource.gpg] https://deb.nodesource.com/node_${NODE_MAJOR}.x nodistro main" | tee /etc/apt/sources.list.d/nodesource.list
RUN apt-get update -yqq && apt-get install -yqq --no-install-recommends nodejs

RUN groupadd -g ${GID} -o ${UNAME}
RUN useradd -m -d /app -u ${UID} -g ${GID} -o -s /bin/bash ${UNAME}
RUN mkdir -p /gems && chown ${UID}:${GID} /gems

ARG APP_HOME=/app
ARG GEM_HOME=/gems
ENV BUNDLE_GEMFILE=${APP_HOME}/Gemfile
ENV BUNDLE_JOBS=2
ENV BUNDLE_PATH=${GEM_HOME}

RUN npm install --global yarn

RUN mkdir -p ${APP_HOME} ${BUNDLE_PATH}
WORKDIR ${APP_HOME}

USER $UNAME
COPY --chown=$UID:$GID Gemfile* ${APP_HOME}/

RUN gem install bundler -v 2.4.22
RUN bundle config build.nokogiri --use-system-libraries
RUN bundle check || bundle install

RUN bundle config set path /gems

# Note that docker-compose.yml mounts /app/node_modules like the gem cache
COPY --chown=$UID:$GID package.json yarn.lock ${APP_HOME}/
RUN yarn install --check-files

COPY --chown=$UID:$GID . ${APP_HOME}

CMD ["sleep", "infinity"]
# CMD ["bin/rails", "s", "-b", "0.0.0.0"]
  

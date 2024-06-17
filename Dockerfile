ARG RUBY_VERSION=3.3.10
ARG RUBY_SLIM="-slim-trixie"
FROM ruby:${RUBY_VERSION}${RUBY_SLIM} AS fulcrum-dev

ARG UNAME=app
ARG UID=1000
ARG GID=1000
ARG NODE_MAJOR=24

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
  wget \
  file \
  git \
  libsqlite3-dev \
  libmariadb-dev \
  default-mysql-client \
  shared-mime-info \
  imagemagick \
  ghostscript \
  netpbm \
  qpdf \
  pdftk \
  clamav \
  clamav-daemon \
  chromium \
  chromium-driver

# update clamav (non-fatal: mirror failures should not break the build)
RUN freshclam || true

# install nodejs
RUN mkdir -p /etc/apt/keyrings
RUN curl -fsSL https://deb.nodesource.com/gpgkey/nodesource-repo.gpg.key | gpg --dearmor -o /etc/apt/keyrings/nodesource.gpg
RUN echo "deb [signed-by=/etc/apt/keyrings/nodesource.gpg] https://deb.nodesource.com/node_${NODE_MAJOR}.x nodistro main" | tee /etc/apt/sources.list.d/nodesource.list
RUN apt-get update -yqq && apt-get install -yqq --no-install-recommends nodejs

# install fits and dependencies
RUN apt-get update -yqq && apt-get install -yqq --no-install-recommends \
  ffmpeg \
  mediainfo \
  default-jdk \
  perl \
  zip \
  unzip

RUN mkdir -p /opt/fits && \
  cd /opt/fits && \
  wget https://github.com/harvard-lts/fits/releases/download/1.6.0/fits-1.6.0.zip -O fits.zip && \
  unzip fits.zip && \
  rm fits.zip tools/mediainfo/linux/libmediainfo.so.0 tools/mediainfo/linux/libzen.so.0 && \
  chmod a+x /opt/fits/fits.sh && \
  sed -i 's/\(<tool.*TikaTool.*>\)/<!--\1-->/' /opt/fits/xml/fits.xml

ENV PATH="${PATH}:/opt/fits"


ARG APP_HOME=/app
ARG GEM_HOME=/gems
ENV BUNDLE_GEMFILE=${APP_HOME}/Gemfile
ENV BUNDLE_JOBS=2
ENV BUNDLE_PATH=${GEM_HOME}

RUN groupadd -g ${GID} -o ${UNAME}
RUN useradd -m -d /app -u ${UID} -g ${GID} -o -s /bin/bash ${UNAME}
RUN mkdir -p /gems && chown ${UID}:${GID} /gems
RUN chown -R ${UID}:${GID} ${APP_HOME}

RUN npm install --global yarn

USER $UNAME

RUN mkdir -p ${APP_HOME} ${BUNDLE_PATH}
WORKDIR ${APP_HOME}
COPY Gemfile* ${APP_HOME}/

RUN gem install bundler -v 2.4.22
RUN bundle config build.nokogiri --use-system-libraries
RUN bundle config build.sqlite3 --enable-system-libraries
RUN bundle config force_ruby_platform true
# GCC 14 (trixie) treats -Wincompatible-pointer-types as an error; old C-extension gems need this flag
RUN bundle config build.posix-spawn "--with-cflags=-Wno-incompatible-pointer-types"
RUN bundle config build.unicode "--with-cflags=-Wno-incompatible-pointer-types"
RUN bundle check || bundle install

# Note that docker-compose.yml mounts /app/node_modules like the gem cache
COPY --chown=$UID:$GID package.json yarn.lock ${APP_HOME}/
RUN set -eux; \
  export YARN_CACHE_FOLDER=/tmp/yarn-cache; \
  rm -rf "${YARN_CACHE_FOLDER}" /tmp/.yarn-mutex; \
  yarn cache clean --all || true; \
  for attempt in 1 2 3; do \
    yarn install --check-files --network-concurrency 1 --mutex file:/tmp/.yarn-mutex && exit 0; \
    echo "yarn install failed (attempt ${attempt}); cleaning cache and retrying"; \
    rm -rf "${YARN_CACHE_FOLDER}" /tmp/.yarn-mutex; \
    yarn cache clean --all || true; \
  done; \
  echo "yarn install failed after 3 attempts"; \
  exit 1

COPY --chown=$UID:$GID . ${APP_HOME}

CMD ["sleep", "infinity"]

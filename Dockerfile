FROM ruby:2.4-alpine

ENV REDMINE_VERSION=3.4.3 \
    RAILS_ENV=production

WORKDIR /usr/src/app

RUN apk --no-cache upgrade \
 && apk --no-cache add --virtual=.run-deps \
     su-exec \
     tzdata \
     bzip2 \
     xz \
     ca-certificates \
     openssl \
     sqlite \
     sqlite-libs \
     libxslt \
     libxml2 \
     git \
 && addgroup -S redmine \
 && adduser -S -G redmine redmine \
 && chown redmine:redmine . \
 && wget -O /tmp/redmine-${REDMINE_VERSION}.tar.gz https://www.redmine.org/releases/redmine-${REDMINE_VERSION}.tar.gz \
 && mkdir /tmp/redmine \
 && tar xzf /tmp/redmine-${REDMINE_VERSION}.tar.gz -C /tmp/redmine redmine-${REDMINE_VERSION} \
 && cp -r /tmp/redmine/redmine-${REDMINE_VERSION}/* . \
 && rm -rf /tmp/redmine /tmp/redmine-${REDMINE_VERSION}.tar.gz \
 && mkdir -p tmp tmp/pdf public/plugin_assets \
 && chown -R redmine:redmine files log tmp public/plugin_assets \
 && chmod -R 755 files log tmp public/plugin_assets \
 && echo "done."

RUN ruby -ryaml -e 'print ({"production"=>{"adapter"=>"sqlite3","database"=>"db/redmine.db"}}).to_yaml.sub("---", "")' > config/database.yml \
 && echo 'gem "unicorn-rails"' >> Gemfile.local \
 && apk --no-cache add --virtual=.build-deps \
        build-base \
        sqlite-dev \
        libxslt-dev \
        libxml2-dev \
        coreutils \
        linux-headers \
 && bundle install --path=vendor/bundle --without development test rmagick \
 && apk del .build-deps \
 && bundle exec rake generate_secret_token \
 && bundle exec rake db:migrate \
 && chown -R redmine:redmine db files log tmp public/plugin_assets \
 && echo "done."

USER redmine
EXPOSE 3000
CMD ["bundle", "exec", "rails", "server", "-b", "0.0.0.0"]

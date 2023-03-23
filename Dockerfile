FROM ruby:2.3.1 

WORKDIR /app

COPY Gemfile Gemfile.lock ./

RUN bundle install

COPY . .

#Install nodejs and yarn

RUN apt-get update && \
    apt-get install -y curl && \
    curl -sL https://deb.nodesource.com/setup_14.x | bash - && \
    curl -sS https://dl.yarnpkg.com/debian/pubkey.gpg | apt-key add - && \
    echo "deb https://dl.yarnpkg.com/debian/ stable main" | tee /etc/apt/sources.list.d/yarn.list && \
    apt-get update && \
    apt-get install -y nodejs yarn

# Install Node.js dependencies

RUN cd src && npm install

# Set environment variables for the Rails application

ENV RAILS_ENV production

ENV RAILS_SERVE_STATIC_FILES true

ENV RAILS_LOG_TO_STDOUT true

ENV DATABASE_URL postgres://postgres:postgres@db:5432

# Precompile assets

RUN bundle exec rake assets:precompile

# Expose port 3000 to the Docker host, so we can access it

# from the outside.

EXPOSE 3000


# Start the main process.

CMD ["rails", "server", "-b", "0.0.0.0"]




# Use a node image as the base
FROM node:14-alpine

# Install dependencies
RUN apk update && \
    apk add --no-cache \
      bash \
      build-base \
      git \
      tzdata \
      yarn

# Set the working directory to the React app
WORKDIR /app

# Copy the package.json and yarn.lock files to the container
COPY package.json  /app/

# Install the dependencies
RUN npm install

# Copy the Rails app and Gemfile to the container
COPY ap/ /app/rails-app/
COPY ap/Gemfile* /app/rails-app/

# Set the working directory to the Rails app
WORKDIR /app/rails-app

# Install the Rails app dependencies
RUN sudo bundle install

# Copy the rest of the React app to the container
COPY . .

# Build the React app
RUN npm build

# Expose port 3000 for the Rails server
EXPOSE 3000

# Start the Rails server
CMD ["rails", "server", "-b", "0.0.0.0"]

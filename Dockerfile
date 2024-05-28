# Use the official Ruby image
FROM ruby:3.3.1

# Set the working directory inside the container
WORKDIR /app

# Install dependencies
RUN apt-get update && apt-get install -y \
    build-essential \
    libpq-dev \
    nodejs \
    netcat-openbsd

# Install gems
COPY Gemfile Gemfile.lock ./
RUN bundle install

# Copy the rest of the application code
COPY . .

# Expose port 3000 (adjust if your Rails app runs on a different port)
EXPOSE 3000

# Use an entrypoint script
COPY entrypoint.sh /usr/bin/
RUN chmod +x /usr/bin/entrypoint.sh
ENTRYPOINT ["entrypoint.sh"]
CMD ["rails", "server", "-b", "0.0.0.0"]

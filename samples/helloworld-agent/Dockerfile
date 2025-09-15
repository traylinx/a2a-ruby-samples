FROM ruby:3.2-alpine

# Install system dependencies
RUN apk add --no-cache \
    build-base \
    curl \
    git

# Set working directory
WORKDIR /app

# Copy Gemfile and install gems
COPY Gemfile Gemfile.lock ./
RUN bundle config --global frozen 1 && \
    bundle install --deployment --without development test

# Copy application code
COPY . .

# Create non-root user
RUN adduser -D -s /bin/sh app
USER app

# Expose port
EXPOSE 9999

# Health check
HEALTHCHECK --interval=30s --timeout=3s --start-period=5s --retries=3 \
  CMD curl -f http://localhost:9999/health || exit 1

# Start the server
CMD ["ruby", "server.rb"]
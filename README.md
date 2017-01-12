# Benji's Blog



## Testing Locally

To test the version that's being deployed locally, you should use the Rack server and not the Hugo server directly. The Rack server is a thin wrapper around the blog itself.

Run following instructions:

1. `bundle install` (only on first run)
2. `bundle exec rackup` 
3. Go visit: http://localhost:9292/



## Deploying

A `git push` to GitHub suffices. Heroku is configured to automatically deploy every push.
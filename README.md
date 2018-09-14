# Benji's Blog



## Testing Locally

To test the version that's being deployed locally, you should use the Rack server and not the Hugo server directly. The Rack server is a thin wrapper around the blog itself.

Run following instructions:

1. `bundle install` (only on first run)
2. `bundle exec rackup` 
3. Go visit: http://localhost:9292/


## Rendering New Pages

1. `brew install hugo` (only on first run)
2. [Install themes](https://gohugo.io/themes/installing-and-using-themes/) (only on first run)
3. `./scripts/render.sh`


## Deploying

A `git push` to GitHub suffices. Heroku is configured to automatically deploy every push.

Currently there are two heroku environments:

- Production:
  - Git: `https://git.heroku.com/benji-blog.git`
  - Url: http://blog.benjamin-encz.de/
- Staging:
  - Git: `ssh://git@heroku.com/benji-blog-staging.git`
  - Url: https://benji-blog-staging.herokuapp.com/

## Troubleshooting

- Reminder to self, to update `themes` folder when updating versions of hugo 
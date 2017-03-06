#!/bin/bash

hugo --theme=casper --ignoreCache
ruby scripts/publish_assets/publish_assets.rb

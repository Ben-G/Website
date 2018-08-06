require 'fileutils'

top_level_dir = `git rev-parse --show-toplevel`.strip
post_dir = "#{top_level_dir}/content/post/"
Dir.chdir post_dir


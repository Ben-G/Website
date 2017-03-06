require 'toml'
require 'fileutils'
require 'open-uri'

top_level_dir = `git rev-parse --show-toplevel`.strip
post_dir = "#{top_level_dir}/content/post/"
Dir.chdir post_dir

# iterate over all post folders
markdown_folders = Dir.entries(".").select { |entry|
  (Dir.exist? entry) && (entry =~ /[0-9]{4}-[0-9]{2}-[0-9]{2}/)
}

markdown_folders.each { |folder|
  post_file = File.join(folder, "post.md")
  begin
    file = File.read(post_file)
  rescue
    puts "Couldn't find markdown post in folder: #{folder}"
  end

  parts = file.split "+++"
  toml_front_matter = parts[1]

  toml = TOML.load(toml_front_matter)
  slug = toml["slug"]

  # Find all assets (e.g non-markdown files and non-folders)
  assets = Dir.entries(folder).reject { |entry|
    File.extname(entry) == ".md" || (Dir.exist? entry)
  }

  # Copy all assets into the static directory
  assets.each { |asset|
    new_dir_name = File.join(top_level_dir, "static/assets/post-assets", slug)
    begin
      FileUtils.mkdir_p new_dir_name
    rescue => error
      puts "Failed to create #{new_dir_name}"
      puts error
    end

    published_asset = File.join(new_dir_name, File.basename(asset))
    FileUtils.cp(File.join(folder,asset), published_asset)
  }
}
#
# markdown_posts.each { |entry|
#   file = File.read(entry)
#   parts = file.split "+++"
#   toml_front_matter = parts[1]
#
#   toml = TOML.load(toml_front_matter)
#
#   draft = toml["draft"] || false
#   # Don't migrate drafts
#   next if draft
#
#   date = toml["date"][0...10]
#   # Turn the blog post title into a folder name by replacing spaces with
#   # underscores and removing speical characters.
#   title = toml["title"].gsub(' ', '_').gsub(/[^0-9A-Za-z_]/, '')
#   new_dir_name = date + '_' + title
#
#   begin
#     Dir.mkdir new_dir_name
#   rescue
#   end
#
#   # Find image links in post
#   image_urls = file.scan(/!\[.*\]\((.*)\)/)
#   image_urls.each { |image_url|
#     new_filename = image_url.first.split("/").last
#     new_filename = new_filename.split("?").first
#
#     # Download images linked in post
#     begin
#       image_download = open(image_url.first)
#       IO.copy_stream(image_download, File.join(new_dir_name, new_filename))
#     rescue
#       puts "Could not download #{image_url.first}"
#     end
#
#     # Replace image links in post with local references
#     file.gsub!(image_url.first, new_filename)
#   }
#
#   # Write the file to the new location
#   File.write(File.join(new_dir_name, "post.md"), file)
# }

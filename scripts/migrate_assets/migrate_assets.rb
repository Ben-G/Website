require 'toml'
require 'fileutils'
require 'open-uri'

top_level_dir = `git rev-parse --show-toplevel`.strip
post_dir = "#{top_level_dir}/content/post/"
Dir.chdir post_dir

# iterate over all markdown files in post directory and convert them to folders
markdown_posts = Dir.entries(".").select { |entry|
  File.extname(entry) == ".md"
}

markdown_posts.each { |entry|
  file = File.read(entry)
  parts = file.split "+++"
  toml_front_matter = parts[1]

  toml = TOML.load(toml_front_matter)

  draft = toml["draft"] || false
  # Don't migrate drafts
  next if draft

  date = toml["date"][0...10]
  # Turn the blog post title into a folder name by replacing spaces with
  # underscores and removing speical characters.
  title = toml["title"].gsub(' ', '_').gsub(/[^0-9A-Za-z_]/, '')
  new_dir_name = date + '_' + title

  begin
    Dir.mkdir new_dir_name
  rescue
  end

  # Find image links in post
  image_urls = file.scan(/!\[.*\]\((.*)\)/)
  image_urls.each { |image_url|
    new_filename = image_url.first.split("/").last
    new_filename = new_filename.split("?").first

    # Download images linked in post
    begin
      image_download = open(image_url.first)
      IO.copy_stream(image_download, File.join(new_dir_name, new_filename))
    rescue
      puts "Could not download #{image_url.first}"
    end

    # Replace image links in post with local references
    file.gsub!(image_url.first, new_filename)
  }

  # Write the file to the new location
  File.write(File.join(new_dir_name, "post.md"), file)
}

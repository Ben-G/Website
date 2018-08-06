#### 2018/8/5

- Create script to create new posts more seamlessly
  - Should create folder with date & title
  - Should generate preamble for post automatically

#### 2017/3/5

- Working on serving images from GitHub. Workflow should enable to add images to repo and have them served automatically in a way that markdown renders well on GitHub and on the website.
- One problem: when using relative links on a slug without a trailing slash, the image link becomes incorrect. E.g. on page `blog.com/test-post/` the relative link `picture.jpg` will point to `blog.com/test-post/picture.jpg`. But on a site without trailing slash, e.g. `blog.com/test-post-2` the same link will point to `blog.com/picture.jpg` instead - need to fix this.
- Should probably right a script to migrate all posts into folders; then pull all image references, download images.
- Need another script that should be run as part of publishing that copies the images from the `content` directory to the `static` directory from where they will be served.
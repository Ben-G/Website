+++
date = "2017-03-18T22:24:54-08:00"
draft = false
title = "Git Stats for the Curious"
slug = "git-stats-for-the-curious"
disqus_url = "http://blog.benjamin-encz.de/post/git-stats-for-the-curious/"
+++

Git repositories provide a fascinating record of the history of our software projects. This post explores a variety of stats and trivia that you might be interested in for your project; and you'll probably learn something new about git along the way.

<!--more-->

Throughout this post I'll use the [ReSwift](https://github.com/reswift/reswift) repo to provide example outputs for the commands.

### The First Commit to a Git Repo

```
git rev-list --max-parents=0 HEAD
```



**Output**

```
74ff536139120b246c48c274fc88430640dbd423
```

**What's in this command?**

As the [documentation](https://git-scm.com/docs/git-rev-list#git-rev-list---no-max-parents) points out, `—max-parents=0` returns all root commits. This interesting [stack overflow answer](http://stackoverflow.com/questions/5188914/how-to-show-first-commit-by-git-log) discusses how you can end up with a repo that has multiple root commits.

### Your First Commit to a Git Repo

```
git log --author $(git config user.email) --format=format:%H | tail -n 1 | xargs git show
```

**Output**

```
commit 74ff536139120b246c48c274fc88430640dbd423
Author: Ben-G <Benjamin.Encz@gmail.com>
Date:   Mon Dec 14 23:47:54 2015 -0800

    Initial Commit

diff --git a/.gitignore b/.gitignore
[...]
```

**What's in this command?**

We're filtering the git log by commits authored by the current git user. We print the SHA-1 from each commit. We pass the result to `tail` which provides us the last line. We then pass on the SHA-1 from the last line to `git show`, using `xargs`. 
Generally you can also use `git log —reverse` to see an inverse commit log (oldest commit first), but there are [issues when using reverse and limit together](http://stackoverflow.com/questions/30832303/git-log-reverse-and-then-limit-the-results-to-one). 

### Git Blame Line Count By Author

```
git ls-tree -r -z --name-only HEAD -- **/*.(c|h|m|swift) | xargs -0 -n1 git blame \
--line-porcelain HEAD |grep  "^author "|sort|uniq -c|sort -nr
```

**Output**

```
 768 author Karl Bowden
 650 author Benji Encz
 308 author Ben-G
 109 author Tim Kersey
  74 author Christian Tietze
  38 author Malcolm Jarvis
  17 author Jonathan Willis
[...]
```

You might notice that I appear twice with a different username on that list (Benji Encz, Ben-G). However, I've always commited with the same email address, so with a slight modification (using `author-email` instead of `author`) I can fix the lines being split accross two authors:

```
git ls-tree -r -z --name-only HEAD -- **/*.(c|h|m|swift) | xargs -0 -n1 git blame \
--line-porcelain HEAD |grep  "^author-email "|sort|uniq -c|sort -nr
```

```
 958 author-mail <Benjamin.Encz@...>
 726 author-mail <karl@...>
 109 author-mail <t@...>
  74 author-mail <christian.tietze@...>
  42 author-mail <karl@...>
  38 author-mail <malcolm@...>
  17 author-mail <jondwillis@...>
  [...]
```



### A Commit from a Year Ago

```
git log --after=$(date -v-1y +'%s') --format=format:%H | tail -n 1 | xargs git show
```

**Output**

```
commit f60db5784870ca1014ffb62d460688f81bdd29af
Author: Ben-G <Benjamin.Encz@gmail.com>
Date:   Sat Mar 19 18:39:02 2016 -0700

    [Travis] Only test against latest iOS SDK

[...]
```




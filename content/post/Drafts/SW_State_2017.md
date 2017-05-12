+++
date = "2017-05-01T22:24:54-08:00"
draft = true
title = "Still no Silver Bullet? Thoughts on how to achieve a magnitude improvement in developer productivity"
slug = "still-no-silver-bullet"
disqus_url = "http://blog.benjamin-encz.de/post/still-no-silver-bullet/"
+++

Fred Brooks' Essay "No Silver Bullet" is now over 30 years old. He famously proclaimed to not see any (then) current development that would bring an order of magnitude improvement to the productivity of software developers.

What has happened since? Have his statements held true? And what about the future? Are there possible changes that could bring a magnitude improvement to developer productivity as we know it today?

<!--more-->

----

### Buy vs. Build



- x-platform
- UI Testing
- Containers
- NewSQL DBs
- REST -> GraphQL
- Machine Learning
- Agile
- Ultra scale teams (600 engs FB, 100 iOS eng at Uber)



Why not progressing:

- when starting out, doesn't make sense to adopt best practices right away
- Once you are far down the road it's extremely hard to rectify initial debt. Only largest teams can afford parallel rewrite; almost no incremental adoption strategy..
- Need to keep shipping product 
- Would need x-company effort to share resources that help progress state of SW dev




----



Random thoughts:



**Buy vs. Build**

We have improved here a lot. A lot of software is no longer built entirely from scratch but relies instead on standard components. These can be open source libraries or even entire SW developer products (e.g. Parse, Firebase, Realm). Assuming these off the shelf products 



**More Software is being built today than ever before**

This is probably the main reason I feel we are repeating ourselves over and over again. There's a tremondous amuont of software being built and it widely follows similar patterns. Mobile apps/websites that are a thin wrapper around a backend service which in turn is a thin wrapper around a DB.

How much code written here is truly replaceable with a common library / off-the shelf product? How can one systematically determine this number?



**Need better Open Source**

Still a hesitancy to take on dependencies for anything besides the most core libraries.



Open Source today: 

- Lots of libraries being created, often by developers in their free time
  - Not enough education around these libs
  - Not enough support/buy in by other companies

Open Source tomorrow?:

- Companies provide funding to pools of software that would provide them productivy gains
- Projects in this pool would receive ongoing development efforts and great training materials/documentaiton that is required to increase adoption



**Case Study**

Want to build:

- Appication that allows me to create contacts
- Store info about contacts: Where did I meet? What do they do?
- Allow me to set reminders for communicating with these contacts

How can I improve building this software by a magnitude?

- Use BAAS (Backend as a service solution?)
- What about UI?



**Other thoughts**

- Maybe there are enough off the shelf products, but ppl don't want to use for other reasons? Psychological, e.g. "not invented here".



**Developer Education**

- Still lacking at scale
- Mostly learning by failure; learning from co-workers
- Little structured learning about industry best practices
- Probably main reason why same problems are solved in different, suboptimal ways over and over again?

----

**How Software is Built**

- Person has idea about problem they want to solve
- Person can code or finds someone that can code.
- Person that writes the code looks at the problem, uses their current set of skills and knowlegde to almost immediately start working on a solution. Since person is trying to solve a problem with software, they won't take a huge amount of time to do research at this point as they want to get going.




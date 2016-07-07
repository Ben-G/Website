+++
date = "2016-06-15T10:24:54-08:00"
draft = true
title = "Apple Unified Logging"
slug = "apple-unified-logging"
disqus_url = "http://blog.benjamin-encz.de/post/apple-unified-logging/"
+++

At WWDC 2016 Apple has introduced a new logging system called *Unified Logging* that supersedes [Apple System Logger](https://developer.apple.com/library/ios/documentation/System/Conceptual/ManPages_iPhoneOS/man3/asl.3.html) (ASL).

I'd like to share some insights I gained from the initial documentation and the WWDC labs.
<!--more-->

- NSLog will use Unified Logging by default
- Performance of Unified Logging is better than ASL; messages are chached in buffers and flashed to disk periodically
- Logger uses compressions techniques, such as storing a reference to a formatted string and storing the values for the format string separately
- Logger redacts dynamic content by default; unless a *public* specifier is used
- No Swift API yet; but will be available in next seed release
- Import to Objc via "<os/log.h>"
- Can be retrieved from device via sisdiagnose, which requires synching system diagnostic to iTunes & syncing from iTunes to device
- Using `os_log(OS_LOG_DEFAULT, "This is a log message.");` messages are sent to the default system log; in the log "explorer" they are broken out by process
- "Subsystems inherit the logging behavior of the system, and categories inherit the behavior of the subsystem in which they reside. Therefore, settings only need to be specified if they differ from the inherited behavior."
**- No way to read the log programatically; need sysdiagnose**

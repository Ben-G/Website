+++
date = "2016-02-24T22:24:54-08:00"
draft = false
title = "How I Write Swift Specs With Quick"
disqus_url = "http://blog.benjamin-encz.de/how-i-write-swift-specs-with-quick/"
slug = "how-i-write-swift-specs-with-quick"
+++

I've recently tweaked the way I write Quick specs. I came to realize that I was placing a majority of my testing code inside of `it` blocks. This [seems to be common among many code bases that use Quick/Nimble](https://github.com/ReactiveCocoa/ReactiveCocoa/blob/7877f99bdfb4be1c82c4804082e99c35d0a93a91/ReactiveCocoaTests/Swift/DisposableSpec.swift#L53-L69).

<!--more-->

I felt that I could gain more readability by focusing on testing expectations within in `it` blocks and driving the test code outside.

I now structure most of my tests in the following way:

1. A `describe` or `context` block describes the scenario under test
2. The `beforeEach` block contains code to implement the scenario
3. The `it` block only validates expectations

The result looks somewhat like this, though I have emitted variable declarations in outer scopes for brevity:

```
// describe the scenario under test
context("when #download is called multiple times with the same URL") {

	// variables which will be used from `it` blocks
	var downloadDescription: DownloadDescription!

    beforeEach {
    	// code to drive the scenario
        downloadDescription = DownloadDescription(
            url: NSURL(string: "http://test.com/download")!,
            priority: 500,
            downloadLocation: NSURL(string: "file://")!
        )

        (1..<10).forEach { _ in
            downloadManager.downloadAsset(downloadDescription)
        }
    }

    // Multiple expectations for that scenario:

    it("only asks the downloader to download the asset once") {
        expect(mockDownloader.receivedCallsToStartDownload)
        .to(haveCount(1))
    }

    it("keeps the ongoing download enqueued") {
        expect(downloadManager.queue)
        .to(contain(downloadDescription))
    }
}
```

**For me it is a lot easier to read these tests, the expectations are clearly separated from the code that drives the test.**

This approach has two minor drawbacks:

- The `it` block needs to reference variables that are set from within the `beforeEach` block. We therefore need to declare more variables in the `context`/`describe` scope which adds some visual clutter.
- Having the code that drives the test in `beforeEach` might look a little awkward at first, as most testing frameworks use these hooks to set up a shared test environment; not to drive the test code.

## Future Improvements?

In future it might be nice to be able to place the test driving code directly in the `context` block. Something along these lines:

```
context("when multiplying two numbers") {
	let i = 2 * 2

    it("stores the correct result") {
    	expect(i).to(equal(4))
    }
}
```

I believe this isn't possible, because Quick can't register the top-level code within `context` block to run as part of the tests, though I haven't looked at the implementation in detail.

This would mitigate the two drawbacks of my current approach and improve the readability of the specs a little more.

**For now I'm happy with the `beforeEach` approach.** How do you write your Swift test suites?

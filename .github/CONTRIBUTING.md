# Contributing to SDL Projects

Third party contributions are essential for making SDL great. However, we do have a few guidelines we need contributors to follow.

### Issues
If writing a bug report, please make sure [it has enough info](https://your.bugreportneedsmore.info). Include all relevant information.

If requesting a feature, understand that we appreciate the input! However, it may not immediately fit our roadmap, and it may take a while for us to get to your request.

### Gitflow
We use [Gitflow](http://nvie.com/posts/a-successful-git-branching-model/) as our branch management system. Please follow gitflow's guidelines while contributing to any SDL project.

### Pull Requests
* Please follow the repository's for all code and documentation.
* All feature branches should be based on `develop` and have the format `feature/issue-#num-branch_name`.
* Minor bug fixes, that is bug fixes that do not change, add, or remove any public API, should be based on `develop` and have the format `bugfix/issue-#num-branch_name`, unless they are slated for a hotfix release, in which case they should be based on `master`.
* All pull requests should implement a single feature or fix a single bug related to an open issue. Pull Requests that involve multiple changes (it is our discretion what precisely this means) will be rejected with a reason.
* All commits should separated into logical units, i.e. unrelated changes should be in different commits within a pull request.
* Work in progress pull requests should be Draft PRs. When you believe the pull request is ready to merge, mark them as ready for review to make them an open PR and @mention the appropriate SDL team to schedule a review.
* All new code *must* include unit tests. Bug fixes should have a test that failed previously and now passes. All new features should have test coverage. If your code does not have tests, or regresses old tests, it will be rejected.
* Make sure you fill out all sections of the PR template. A great example of a [pull request can be found here](https://github.com/smartdevicelink/sdl_ios/pull/1688).

### Contributor's License Agreement (CLA)
In order to accept Pull Requests from contributors, you must first sign [the Contributor's License Agreement](https://docs.google.com/forms/d/1VNR8EUd5b46cQ7uNbCq1fJmnu0askNpUp5dudLKRGpU/viewform). If you need to make a change to information that you entered, [please contact us](mailto:admin@smartdevicelink.com).

### Repository Specific Guidelines
  * [iOS Style Guide](https://github.com/smartdevicelink/sdl_ios/wiki/Objective-C-Style-Guide)
  * Please document all public and internally public APIs using Xcode's standard documentation (have the cursor on the API declaration and press `cmd+alt+/`).

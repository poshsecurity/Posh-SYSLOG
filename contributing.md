# Contributing

See an issue that you can help with? Have an idea for the next great feature? Thanks for taking the time to contribute!!!

Here are some guidelines for contributing to this project. They are not hard rules, just guidelines.

## Code of Conduct

This project maintains a [code of conduct](code-of-conduct.md) that establishes how the project is governed and how everyone involved is expected to behave.

You can report unacceptable behavior to [code@poshsecurity.com](mailto:code@poshsecurity.com).

## TL;DR

* Check if any bugs/issues/features have been previously reported/requested before creating a new issue.
* Ensure you are using the LATEST version before raising a new issue.
* Ensure you complete the Pull Request template when raising a new PR.

## Reporting Bugs/Issues

The reality is that code will contain bugs, even with thorough testing, issues can get through. Following these guidelines will help the maintainers to understand the issue you have encountered, reproduce the problem and fix it! You might even find that you don't need to create one.

> **Note:** If you find an issue that is Closed that seems like what you are experiencing, please open a **new** issue and include a link to the previous issue in your description.

### Before you file a bug report

* **Ensure you are running the latest version of the module.** If you are running an older version of the module, try updating the module and testing if the issue remains. If you installed the module from the [PowerShell Gallery](https://powershellgallery.com), use this command to update the module: ``` PS> Update-Module -Name Posh-SYSLOG ```.
* **Ensure that you are using the CMDLet correctly.** Have you checked the help? Sometimes we assume we know how a specific function or CMDLet works, and it turns out we are wrong. The command ```Get-Help``` is your friend!
* **Has the issue been reported before?** You might not be the only person who has reported the issue. Check out the [Issues][Issues] and look through any current Issues that may match the issue you are experiencing.

### Submitting a (good) bug report

Bugs and problems are tracked using [GitHub issues](https://guides.github.com/features/issues/). To submit a bug, create an issue and provide the information requested in [the template](ISSUE_TEMPLATE.md). The template will help the maintainers to resolve issues faster.

Here are some tips on ensuring you create an excellent bug report:

* **Bugs should be actionable**, that is, something that can be fixed as part of this project. Issues with Windows, .Net or PowerShell might not be solvable within this project.
* **Use a clear descriptive title** for the issue that describes the issue.
* **Describe the exact steps to reproduce the issue** and include as many details as possible. People often leave things out as they think they might not be important, but every little detail counts! When listing what steps or commands you executed, **don't just say what you did, try to explain how you did it**. Be as detailed as possible, it is safe to say that more is usually better.
* **Provide specific examples**, include specific steps you have taken, link to files or other copy/pastable snippets. If you are providing snippets of code, ensure you use Markdown Code Blocks. <>TODO: link<> If you can, provide the exact steps/code you were executing when the issue happened.
* **PowerShell Transcripts can be extremely useful** so please include those where possible. You can start a transcript with ```Start-Transcript``` and end it with ```Stop-Transcript```.
* **Screenshots and Gifs** can also be extemely useful, however transcripts are preferred.
* **If there is private/confidential information**, feel free to remove that from any logs/transcripts/images, but remember to highlight where you have done so.
* **Describe the behavior you observed after following the steps you described** and then clearly state what the problem is with this behavior. Sometimes it isn't clear why something is an issue.
* **Describe what behaviour you would expect** others might be expecting different behaviors.
* **Include stack traces where possible**. If you have access to the Exception, the ```ScriptStackTrace``` and other properties may point to where the problem is.
* **Include details about your environment** including Windows/Linux/Mac OSX version, PowerShell versions and 64/32 bit environments. If you are using Azure Automation, please ensure you mention if this is the Azure Worker or a Hybrid Worker. It can also help to include any other modules you might be using.
* **Subscribe to notifications** so you can answer any follow-up questions, and assist in testing the final fixes for the issue.
* **Just because you think the issue might be easy, doesn't mean it is so**. Issues can be quite complex when you actually look into them, resolution may take time so be patient.

## Suggesting New Features and Enhancements

Got a killer idea for a new feature? Maybe you want to suggest a minor improvement or some totally new features? These guidelines will help maintainers understand your suggestion!

### Before you submit an enhancement suggestion

* **Ensure you are running the latest version of the module.** The feature you require might be included in a new version of the module. If you installed the module from the Gallery, use this command to update the module: ``` PS> Update-Module -Name Posh-SYSLOG ```.
* **Ensure that you are using the CMDLet correctly.** Have you checked the help? Perhaps the feature has already been implemented but you just haven't discovered it yet! The command ```Get-Help``` is your friend!
* **Has the feature been requested before?** You might not be the only person who has requested this new feature. If it has, add a comment to the existing issue instead of opening a new one. Be sure to checkout closed issues as well, the feature may have been previously implemented or rejected.

### Submitting a (good) enhancement suggestion

Enhancements are tracked via [GitHub issues](https://guides.github.com/features/issues/) just as bugs are. To submit a suggestion, create an issue and provide the information requested in [the template](ISSUE_TEMPLATE.md).

Here are some tips on ensuring you create an excellent suggestion:

* **Enhancements should be actionable**, that is, something that can/should be included in the project. Does the enhancement fall inside or outside the scope of the module? Modules should closely align to a specific set of activities, for instance a database query CMDLet probably shouldn't be included in a module relating to network connections.
* **Use a clear descriptive title** for the issue that describes the suggestion.
* **Describe the new functionality or enhancement**, provide a step-by-step description of how it would function.
* **Describe the current behavior and expected behavior** you would like to see.
* **Provide specific examples** including how the feature would work, error handling, validation, etc.
* **Describe why this would be useful** to implement this suggestion. Is this something other users might want or just something you require?
* **Subscribe to notifications** so you can answer any follow-up questions, and assist in testing the final fixes for the issue.
* **Just because you think the feature might be easy to implement, doesn't mean it is so**. New features could be simple, or they might require significant effort to implement, please be patient.

## Code Contributions

### Your First Contribution

Looking to make your first contribution? Congratulations, you are taking the first steps into an amazing journey.

Don't know where to start? You can start by looking through the issues for the **Beginner** and **Help Wanted** tags:

* **Beginner** are simple and should only take a few lines of code and tests to complete.
* **Help Wanted** are more involved and will take more effort to complete.

### Pull Requests

Pull requests are always more than welcome. When creating a pull request, ensure that you complete [the template](PULL_REQUEST_TEMPLATE.md).

Here are a few guidelines that should be followed:

* Each pull request should accomplish a clear goal. Ensure that you clearly state in the request what it accomplishes.
  * Bug fixes: What was the bug? How did you fix it?
  * New features: What is it? How is it used?
* Provide a high level explanation of what you are changing, it makes it easier to review.
* Keep requests small, as it:
  * Makes reviews easier.
  * Makes testing easier.
  * Helps review conflicts more easily.
* Ensure that all Pester tests pass and there are no failures.
* Ensure that there are no errors or warnings with PowerShell Script Analyzer
* Any new code needs to have tests created:
  * Bug fixes: Consider test cases that would have failed before the change but pass now.
  * New features: Test cases need to ensure that new features function correctly and existing features still function as previously expected.
* Ensure that any code you write aligns with community style guides.
* Don't include issue numbers in the PR title.
* Ensure that your branch is up-to-date to reduce the merge conflicts that could occur.

### Things that might get your Pull Request rejected

There are often things in Pull Requests that might lead to a pull request being rejected, these include:

* Malicious code.
* Code that breaks previous functionality in a way that could be avoided.
* Code that doesn't align with community style recommendations.
* Code that fails Pester tests or PowerShell Script analyser.
* Code that is obviously plagiarised.

<!--

    This is based upon the work by the Atom project, https://github.com/atom/atom/

-->

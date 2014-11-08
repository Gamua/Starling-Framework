# IntelliJ tools

## copy_resources.rb

IntelliJ allows you specify which resources to add to your application package. This is done in the "Dependencies" tab of the module's build configuration ("Files and folders to package").

This works fine when you actually create the package or debug on a real device; however, when running the simulator, those resources won't show up. As a work-around, you can copy them manually into the output folder — or you let this little Ruby script do the work for you.

It parses IntelliJ's module file to find out which resources to copy and where to put them. It's easy to integrate it into IntelliJ by adding it as an "External Tool" (IntelliJ Preferences - Tools).

Create one such tool entry for each platform you support. Here are sample settings for iOS:

* Name: Copy Resources - iOS
* Description: Copies the project's resources into the output folder so that the simulator can find them.
* Program: `/path/to/starling/util/intellij/copy_resources.rb`
* Parameters: `$ModuleFilePath$ ios`
* Working Directory: [leave empty]

[Other options for the second parameter are "android" and "air-desktop".]

To try out the tool, first click on the project you want to process, then on "Tools - External Tools - Copy Resources [platform]". If everything works, you will see the terminal output of the tools displayed inside IntelliJ.

To make sure that the files are always copied before you run/debug your app in the simulator, add the tool to the "Before launch" section of the respective run/debug configuration.

Final note: that we have to do this at all should be considered a bug in IntelliJ. To make sure that is fixed in the future, please take the time to vote for the bug here: [IDEA-94578](https://youtrack.jetbrains.com/issue/IDEA-94578)
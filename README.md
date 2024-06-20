# quarto_error_2406

I have a process where I take Word documents with some styles and convert them to markdown files (they end up in the `requirements` or root folder on conversion). I then call quarto to render the website.

In `Standard 05.4.docx`, I have a style for resumes called `Link to Artifact - Resume`. There are 4 people in the table, some with `Dr.` and some not. When the files are converted to markdown, they come across looking correct (that is, they are `Dr. Person` with a space after the period).

When these files are converted to the website, the entries for `Dr. Person One` and `Dr. Person Four` are now changed to `Dr.%C2%A0Person One` and `Dr.%C2%A0Person Four`, but the other rows are correct.
